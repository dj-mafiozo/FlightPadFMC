"""Test the Delphi discovery worker over localhost UDP, without querying the LAN."""
import socket
import struct
import subprocess
import threading
from pathlib import Path
ROOT = Path(__file__).resolve().parent

def name(text):
    return b''.join(bytes([len(p)])+p.encode() for p in text.split('.'))+b'\0'

def record(owner, kind, data):
    return owner + struct.pack('!HHIH',kind,1,120,len(data)) + data
service = name('_flightpadfmc._tcp.local')
instance = name('Test._flightpadfmc._tcp.local')
target = name('test-pc.local')
header = struct.pack('!HHHHHH',0,0x8400,0,2,0,0)
# The PTR owner and the service suffix of its target use DNS compression.
ptr = record(service,12,b'\x04Test\xc0\x0c')
instance_offset = 12 + len(service) + 10
srv_owner = struct.pack('!H',0xC000 | instance_offset)
srv = record(srv_owner,33,struct.pack('!HHH',0,0,18765)+target)
part_one = header + ptr + srv
part_two = struct.pack('!HHHHHH',0,0x8400,0,1,0,0) + record(target,1,socket.inet_aton('127.0.0.1'))
(ROOT/'dns-service.bin').write_bytes(part_one)
(ROOT/'dns-address.bin').write_bytes(part_two)
(ROOT/'dns-loop.bin').write_bytes(struct.pack('!HHHHHH',0,0x8400,0,1,0,0)+b'\xc0\x0c')
errors = []

def respond(sock):
    try:
        data,peer = sock.recvfrom(4096)
        assert data[4:6] == b'\0\x01' and data[-2:] == b'\x80\x01'
        assert b'_flightpadfmc' in data
        sock.sendto(part_one,peer)
        sock.sendto(part_two,peer)
    except BaseException as exc:
        errors.append(repr(exc))

with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sock:
    sock.bind(('127.0.0.1',15353)); sock.settimeout(5)
    worker = threading.Thread(target=respond,args=(sock,),daemon=True)
    worker.start()
    result = subprocess.run([str(ROOT/'build/DiscoveryTests.exe'),str(ROOT)],
                            capture_output=True,text=True,timeout=8)
    worker.join(timeout=1)
    print(result.stdout.strip())
    assert result.returncode == 0, (result.stdout,result.stderr,errors)
    assert not errors, errors
