"""Test the compiled Delphi clients against a local WebSocket server (stdlib only)."""
import sys
import base64
import hashlib
import json
import socket
import struct
import subprocess
import threading
from pathlib import Path
ROOT = Path(__file__).resolve().parent
WINDOWS = ROOT.parent
screen = [[{'s': 'T' if r == c == 0 else ' ', 'c': c % 6} for c in range(24)] for r in range(14)]
boeing = {'type': 'screen_update', 'side': 'capt', 'screen': screen, 'led': True}
airbus = {'left': {'titleLeft': 'TEST', 'page': '1/2', 'title': '{green}TITLE',
                  'lines': [['L','R','C'], ['{green}A{cyan}B','',''],
                            ['{right}R123','',''], ['{cyan}{COPY{sp}ACTIVE{end}','','']],
                  'scratchpad': '#£¢_|', 'arrows': [False,False,True,True],
                  'annunciators': {'fm1': True, 'fm2': False, 'fm': True, 'blank': True,
                                   'ind': True, 'rdy': True, 'fail': True, 'mcdu_menu': True}}}
(ROOT/'boeing.json').write_text(json.dumps(boeing),encoding='utf-8')
(ROOT/'airbus.json').write_text(json.dumps(airbus,ensure_ascii=False),encoding='utf-8')

def exact(conn, count):
    data = b''
    while len(data) < count:
        chunk = conn.recv(count-len(data))
        if not chunk:
            raise RuntimeError('Unexpected disconnect')
        data += chunk
    return data

def receive(conn):
    first, second = exact(conn, 2)
    assert second & 128, 'Client frame must be masked'
    size = second & 127
    if size == 126:
        size = struct.unpack('!H',exact(conn,2))[0]
    elif size == 127:
        size = struct.unpack('!Q',exact(conn,8))[0]
    mask = exact(conn,4)
    data = exact(conn,size)
    return first & 15, bytes(v ^ mask[i % 4] for i,v in enumerate(data))

def send(conn, opcode, data, final=True):
    first = opcode | (128 if final else 0)
    head = bytes([first,len(data)]) if len(data) < 126 else bytes([first,126])+struct.pack('!H',len(data))
    conn.sendall(head+data)

def read_json(conn):
    op,data = receive(conn)
    assert op == 1, (op,data)
    return json.loads(data)

def mock(listener, aircraft, errors):
    try:
        air = aircraft in ('A320','FENIXA320')
        supports_side = aircraft in ('737','777')
        enter = 'OVFY' if air else 'EXEC'
        keys = [enter,'DOT' if air else '.', 'DIV' if air else '/',
                'PLUSMINUS' if air else '+/-','SP','CLR','LSK1L','LSK6R',
                'SLEW_LEFT' if air else 'PREV PAGE','SLEW_UP' if air else 'NEXT PAGE',
                'DIR' if air else ('INIT REF' if aircraft=='IFLY737MAX' else 'INIT')]
        for iteration in range(2):
            conn,_ = listener.accept()
            with conn:
                conn.settimeout(8)
                header = b''
                while not header.endswith(b'\r\n\r\n'):
                    header += exact(conn,1)
                key = next(line.split(b':',1)[1].strip() for line in header.split(b'\r\n')
                           if line.lower().startswith(b'sec-websocket-key:'))
                accept = base64.b64encode(hashlib.sha1(key+b'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest())
                conn.sendall(b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\n'
                             b'Connection: Upgrade\r\nSec-WebSocket-Accept: '+accept+b'\r\n\r\n')
                assert read_json(conn) == {'type':'identify','aircraft':aircraft,'version':'0.4.1'}
                if iteration and supports_side:
                    assert read_json(conn) == {'type':'select_side','side':'fo'}
                payload = json.loads(json.dumps(airbus if air else boeing))
                marker = 'R' if iteration else 'T'
                if air:
                    payload['left']['titleLeft'] = marker+'EST'
                    data = ('update:'+json.dumps(payload,ensure_ascii=False)).encode()
                else:
                    payload['screen'][0][0]['s'] = marker
                    payload['side'] = 'fo' if iteration else 'capt'
                    data = json.dumps(payload).encode()
                # Ping may arrive between fragments. A full CDU uses a 16-bit frame length.
                send(conn,1,data[:20],final=False)
                send(conn,9,b'ping')
                send(conn,0,data[20:])
                expected = [enter] if iteration else keys
                got_pong = False
                received = []
                side_received = not supports_side or bool(iteration)
                while len(received) < len(expected) or not got_pong or not side_received:
                    op,data = receive(conn)
                    if op == 10:
                        assert data == b'ping'
                        got_pong = True
                    else:
                        assert op == 1
                        message = json.loads(data)
                        if message['type'] == 'select_side':
                            assert message == {'type':'select_side','side':'fo'}
                            side_received = True
                        else:
                            assert message['type'] == 'key_press'
                            received.append(message['key'])
                assert received == expected, (aircraft,received,expected)
                if not iteration:
                    send(conn,8,b'\x03\xe8')
                    op,data = receive(conn)
                    assert op == 8 and data == b'\x03\xe8'
                else:
                    send(conn,1,b'{"type":"status_message","text":"DONE"}')
                    assert conn.recv(1) == b'', 'Client did not release the socket'
    except BaseException as exc:
        errors.append(repr(exc))

for folder,aircraft in [('PMDG737','737'),('PMDG777','777'),('FBWA320','A320'),('FenixA320','FENIXA320'),('iFly737MAX','IFLY737MAX')]:
    errors = []
    with socket.socket() as listener:
        listener.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        listener.bind(('127.0.0.1',18765)); listener.listen(); listener.settimeout(18)
        worker = threading.Thread(target=mock,args=(listener,aircraft,errors),daemon=True)
        worker.start()
        exe = ROOT/'build'/folder/'ClientTests.exe'
        result = subprocess.run([str(exe),str(Path(sys.argv[1]).resolve() if len(sys.argv)>1 else WINDOWS/folder),str(ROOT)],
                                capture_output=True,text=True,timeout=22)
        worker.join(timeout=2)
        print(result.stdout.strip())
        assert result.returncode == 0, (result.stdout,result.stderr,errors)
        assert not errors, errors
        assert not worker.is_alive(), 'Mock did not finish'
print('PASS: all five Delphi clients, real VCL inputs, both screen formats, ping/pong, reconnect and FO replay')
