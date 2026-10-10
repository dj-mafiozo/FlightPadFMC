"""Integration test for the real Delphi transport; uses only Python standard library."""
import base64
import hashlib
import json
import socket
import struct
import subprocess
import threading
from pathlib import Path

errors = []

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
    assert second & 128, 'Client frames must be masked'
    size = second & 127
    if size == 126:
        size = struct.unpack('!H', exact(conn, 2))[0]
    elif size == 127:
        size = struct.unpack('!Q', exact(conn, 8))[0]
    mask = exact(conn, 4)
    data = exact(conn, size)
    return first & 15, bytes(v ^ mask[i % 4] for i, v in enumerate(data))

def send(conn, opcode, data, final=True):
    size = len(data)
    head = bytes([opcode | (128 if final else 0)])
    head += bytes([size]) if size < 126 else b'\x7e' + struct.pack('!H', size)
    conn.sendall(head + data)

def server(listener):
    try:
        for iteration in range(2):
            conn, _ = listener.accept()
            with conn:
                conn.settimeout(5)
                headers = b''
                while not headers.endswith(b'\r\n\r\n'):
                    headers += exact(conn, 1)
                key = next(line.split(b':', 1)[1].strip() for line in headers.split(b'\r\n')
                           if line.lower().startswith(b'sec-websocket-key:'))
                accept = base64.b64encode(hashlib.sha1(key + b'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest())
                conn.sendall(b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\n'
                             b'Connection: Upgrade\r\nSec-WebSocket-Accept: ' + accept + b'\r\n\r\n')
                op, data = receive(conn)
                assert op == 1 and json.loads(data)['aircraft'] == 'IFLY737MAX'
                payload = b'{"type":"status_message","text":"fragmented"}'
                send(conn, 1, payload[:15], final=False)
                send(conn, 9, b'ping')
                send(conn, 0, payload[15:])
                got_key = got_pong = False
                while not (got_key and got_pong):
                    op, data = receive(conn)
                    if op == 10:
                        assert data == b'ping'
                        got_pong = True
                    elif op == 1:
                        assert json.loads(data) == {'type': 'key_press', 'key': 'EXEC'}
                        got_key = True
                # Exercise extended frame length as used by CDU screen snapshots.
                screen = [[{'s': 'A', 'c': col % 6} for col in range(24)] for _ in range(14)]
                send(conn, 1, json.dumps({'type': 'screen_update', 'screen': screen}).encode())
                send(conn, 8, b'\x03\xe8')
                op, data = receive(conn)
                assert op == 8 and data == b'\x03\xe8'
    except BaseException as exc:
        errors.append(repr(exc))
    finally:
        listener.close()

with socket.socket() as listener:
    listener.bind(('127.0.0.1', 18765))
    listener.listen()
    listener.settimeout(15)
    thread = threading.Thread(target=server, args=(listener,))
    thread.start()
    result = subprocess.run([str(Path(__file__).with_name('TransportTest.exe'))],
                            capture_output=True, text=True, timeout=20)
    thread.join(timeout=16)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not errors, errors
    assert not thread.is_alive(), 'Mock server did not finish'
    print('PASS: handshake, identify, masked key, fragmentation, ping/pong, extended frame, close, reconnect')
