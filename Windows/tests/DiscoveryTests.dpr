Program DiscoveryTests;
{$APPTYPE CONSOLE}

Uses
 Winapi.Windows, System.SysUtils, System.IOUtils, IdGlobal, Discovery;

Var
 Cache           : TDiscoveryCache;
 B               : TIdBytes;
 Host            : String;
 Port            : Integer;
 Rejected, Found : Boolean;
 Started         : UInt64;

Procedure Check(Condition : Boolean; Const Message : String);
 Begin
  If Not Condition Then
   Raise Exception.Create(Message)
 End;

Begin
 Try
  B := DiscoveryQuery(FMCService, 12);
  Check((B[5] = 1) And (B[High(B) - 1] = $80) And (B[High(B)] = 1), 'QU query encoding');
  Cache := TDiscoveryCache.Create;
  Try
   Cache.AddPacket(TIdBytes(TFile.ReadAllBytes(ParamStr(1) + '\dns-service.bin')));
   Check(Not Cache.Resolve(Host, Port), 'Split DNS response should wait for address');
   Cache.AddPacket(TIdBytes(TFile.ReadAllBytes(ParamStr(1) + '\dns-address.bin')));
   Check(Cache.Resolve(Host, Port) And (Host = '127.0.0.1') And (Port = 18765), 'Compressed PTR/SRV/A response');
   Rejected := False;
   Try
    Cache.AddPacket(TIdBytes(TFile.ReadAllBytes(ParamStr(1) + '\dns-loop.bin')))
   Except
    On E : Exception Do
     Rejected := True
   End;
   Check(Rejected, 'DNS compression loop must be rejected');
  Finally
   Cache.Free
  End;
  Started := GetTickCount64;
  Found   := DiscoverServer(
    Function : Boolean
    Begin
     Result := True
    End, Host, Port, '127.0.0.1', 15353, 15000);
  Check(Not Found And (GetTickCount64 - Started < 500), 'Discovery cancellation must not block shutdown');
  Found := DiscoverServer(
   Function : Boolean
    Begin
     Result := False
    End, Host, Port, '127.0.0.1', 15353, 3000);
  Check(Found And (Host = '127.0.0.1') And (Port = 18765), 'UDP DNS discovery round trip');
  Writeln('PASS: mDNS query, compressed names, split PTR/SRV/A, loop rejection, cancellation, UDP discovery');
 Except
  On E : Exception Do
   Begin
    Writeln('FAIL: ' + E.Message);
    Halt(1)
   End
 End;

End.
