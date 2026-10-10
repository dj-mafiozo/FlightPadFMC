Unit Transport;

Interface

 Uses
  System.Classes, System.SysUtils, System.SyncObjs, IdTCPClient, IdGlobal;

 Type
  TTransport = Class(TThread)
   Private
    FHost                : String;
    FAircraft            : String;
    FAutoDiscover        : Boolean;
    FPort                : Integer;
    FLock                : TCriticalSection;
    FIncoming, FOutgoing : TStringList;
    Procedure Post(Const S : String);
    Procedure Frame(Client : TIdTCPClient; Opcode : Byte; Const Data : TIdBytes);
   Protected
    Procedure Execute; Override;
   Public
    Constructor Create(Const Host : String; Port : Integer; Const Aircraft : String; AutoDiscover : Boolean = False);
    Destructor Destroy; Override;
    Procedure Send(Const S : String);
    Procedure Drain(Dest : TStrings);
  End;

Implementation

 Uses
  System.Hash, System.NetEncoding, System.JSON, Discovery;

 Constructor TTransport.Create(Const Host : String; Port : Integer; Const Aircraft : String; AutoDiscover : Boolean);
  Begin
   Inherited Create(False);
   FHost         := Host;
   FAircraft     := Aircraft;
   FAutoDiscover := AutoDiscover;
   FPort         := Port;
   FLock         := TCriticalSection.Create;
   FIncoming     := TStringList.Create;
   FOutgoing     := TStringList.Create;
  End;

 Destructor TTransport.Destroy;
  Begin
   Terminate;
   WaitFor;
   FIncoming.Free;
   FOutgoing.Free;
   FLock.Free;
   Inherited;
  End;

 Procedure TTransport.Post(Const S : String);
  Begin
   FLock.Acquire;
   Try
    If FIncoming.Count < 512 Then
     FIncoming.Add(S);
   Finally
    FLock.Release
   End;
  End;

 Procedure TTransport.Send(Const S : String);
  Begin
   FLock.Acquire;
   Try
    If FOutgoing.Count < 128 Then
     FOutgoing.Add(S);
   Finally
    FLock.Release
   End;
  End;

 Procedure TTransport.Drain(Dest : TStrings);
  Begin
   FLock.Acquire;
   Try
    Dest.Assign(FIncoming);
    FIncoming.Clear;
   Finally
    FLock.Release
   End;
  End;

 Procedure TTransport.Frame(Client : TIdTCPClient; Opcode : Byte; Const Data : TIdBytes);
  Var
   B       : TIdBytes;
   I, N, H : Integer;
   Mask    : Array [0 .. 3] Of Byte;
   G       : TGUID;
  Begin
   N := Length(Data);
   If N > 65535 Then
    Raise Exception.Create('Outgoing frame too large');
   H := 2;
   If N >= 126 Then
    H := 4;
   SetLength(B, H + 4 + N);
   B[0] := $80 Or Opcode;
   If H = 2 Then
    B[1] := $80 Or N
   Else
    Begin
     B[1] := $FE;
     B[2] := N Shr 8;
     B[3] := N And $FF
    End;
   CreateGUID(G);
   Move(G, Mask, 4);
   For I         := 0 To 3 Do
    B[H + I]     := Mask[I];
   For I         := 0 To N - 1 Do
    B[H + 4 + I] := Data[I] Xor Mask[I Mod 4];
   Client.IOHandler.Write(B);
  End;

 Procedure TTransport.Execute;
  Var
   C                            : TIdTCPClient;
   Work                         : TStringList;
   Line, Key, Accept, Expected  : String;
   B, Payload, MessageData      : TIdBytes;
   First, Second, Op, MessageOp : Byte;
   N                            : UInt64;
   I, Old                       : Integer;
   Fin                          : Boolean;
   G                            : TGUID;
   Identify                     : TJSONObject;
   ConnectHost                  : String;
   ConnectPort                  : Integer;
  Begin
   C    := TIdTCPClient.Create(Nil);
   Work := TStringList.Create;
   Try
    C.Host           := FHost;
    C.Port           := FPort;
    C.ConnectTimeout := 1500;
    C.ReadTimeout    := 1500;
    While Not Terminated Do
     Begin
      Try
       ConnectHost := FHost;
       ConnectPort := FPort;
       If FAutoDiscover Then
        Begin
         Post('@Searching for FlightPadFMC (mDNS)');
         Try
          If Not DiscoverServer(
            Function : Boolean
            Begin
             Result := Terminated
            End, ConnectHost, ConnectPort) Then
           Begin
            ConnectHost := FHost;
            ConnectPort := FPort;
            Post('@Server not discovered; trying manual address');
           End;
         Except
          On E : Exception Do
           Begin
            ConnectHost := FHost;
            ConnectPort := FPort;
            Post('@Discovery unavailable; trying manual address');
           End
         End;
        End;
       If Terminated Then
        Break;
       C.Host := ConnectHost;
       C.Port := ConnectPort;
       Post('@Connecting');
       Post('@Endpoint ' + ConnectHost + ':' + IntToStr(ConnectPort));
       C.Connect;
       CreateGUID(G);
       SetLength(B, SizeOf(G));
       Move(G, B[0], SizeOf(G));
       Key := TNetEncoding.Base64.EncodeBytesToString(TBytes(B));
       C.IOHandler.Write('GET / HTTP/1.1'#13#10 + 'Host: ' + ConnectHost + ':' + IntToStr(ConnectPort) + #13#10 + 'Upgrade: websocket'#13#10 + 'Connection: Upgrade'#13#10 + 'Sec-WebSocket-Key: ' + Key + #13#10 + 'Sec-WebSocket-Version: 13'#13#10#13#10,
       IndyTextEncoding_ASCII);
       Line := C.IOHandler.ReadLn;
       If Pos(' 101 ', Line) = 0 Then
        Raise Exception.Create('WebSocket upgrade rejected');
       Accept := '';
       Repeat
        Line := C.IOHandler.ReadLn;
        If SameText(Copy(Line, 1, 21), 'Sec-WebSocket-Accept:') Then
         Accept := Trim(Copy(Line, 22, MaxInt));
       Until Line = '';
       Expected := TNetEncoding.Base64.EncodeBytesToString(THashSHA1.GetHashBytes(Key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'));
       If Accept <> Expected Then
        Raise Exception.Create('Invalid WebSocket handshake');
       Identify := TJSONObject.Create;
       Try
        Identify.AddPair('type', 'identify');
        Identify.AddPair('aircraft', FAircraft);
        Identify.AddPair('version', '0.4.1');
        Frame(C, 1, ToBytes(Identify.ToJSON, IndyTextEncoding_UTF8));
       Finally
        Identify.Free
       End;
       FLock.Acquire;
       Try
        FOutgoing.Clear
       Finally
        FLock.Release
       End;
       Post('@Connected');
       SetLength(MessageData, 0);
       MessageOp := 0;
       While Not Terminated Do
        Begin
         FLock.Acquire;
         Try
          Work.Assign(FOutgoing);
          FOutgoing.Clear
         Finally
          FLock.Release
         End;
         For I := 0 To Work.Count - 1 Do
          Frame(C, 1, ToBytes(Work[I], IndyTextEncoding_UTF8));
         If C.IOHandler.InputBufferIsEmpty Then
          Begin
           C.IOHandler.CheckForDataOnSource(25);
           C.IOHandler.CheckForDisconnect;
           If C.IOHandler.InputBufferIsEmpty Then
            Continue;
          End;
         First  := C.IOHandler.ReadByte;
         Second := C.IOHandler.ReadByte;
         Fin    := (First And $80) <> 0;
         Op     := First And $0F;
         If ((First And $70) <> 0) Or ((Second And $80) <> 0) Then
          Raise Exception.Create('Unsupported WebSocket frame');
         N := Second And $7F;
         If N = 126 Then
          Begin
           N := C.IOHandler.ReadByte;
           N := N * 256 + C.IOHandler.ReadByte
          End
         Else If N = 127 Then
          Begin
           N     := 0;
           For I := 1 To 8 Do
            Begin
             If N > 1048576 Then
              Raise Exception.Create('Frame too large');
             N := N * 256 + C.IOHandler.ReadByte;
            End;
          End;
         If (N > 1048576) Or ((Op >= 8) And ((N > 125) Or Not Fin)) Then
          Raise Exception.Create('Invalid frame length');
         SetLength(Payload, 0);
         If N > 0 Then
          C.IOHandler.ReadBytes(Payload, Integer(N), False);
         Case Op Of
          8 :
           Begin
            Frame(C, 8, Payload);
            Raise Exception.Create('Server closed connection')
           End;
          9 :
           Frame(C, 10, Payload);
          10 :
           ;
          0, 1, 2 :
           Begin
            If Op <> 0 Then
             Begin
              If MessageOp <> 0 Then
               Raise Exception.Create('Invalid fragmentation');
              MessageOp := Op;
             End
            Else If MessageOp = 0 Then
             Raise Exception.Create('Unexpected continuation');
            Old := Length(MessageData);
            If Old + Integer(N) > 1048576 Then
             Raise Exception.Create('Message too large');
            SetLength(MessageData, Old + Integer(N));
            If N > 0 Then
             Move(Payload[0], MessageData[Old], Integer(N));
            If Fin Then
             Begin
              If MessageOp = 1 Then
               Post(BytesToString(MessageData, IndyTextEncoding_UTF8));
              SetLength(MessageData, 0);
              MessageOp := 0;
             End;
           End;
          Else
           Raise Exception.Create('Unsupported opcode')
         End;
        End;
      Except
       On E : Exception Do
        If Not Terminated Then
         Post('@Disconnected: ' + E.Message)
      End;
      C.Disconnect;
      For I := 1 To 60 Do
       Begin
        If Terminated Then
         Break;
        Sleep(50)
       End;
     End;
   Finally
    C.Free;
    Work.Free
   End;
  End;

End.
