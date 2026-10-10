Unit Discovery;

Interface

 Uses
  System.SysUtils, System.Generics.Collections, IdGlobal;

 Const
  FMCService = '_flightpadfmc._tcp.local';

 Type
  TDiscoveryCache = Class
   Private
    FInstances           : TList<String>;
    FTargets, FAddresses : TDictionary<String, String>;
    FPorts               : TDictionary<String, Integer>;
   Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure AddPacket(Const Data : TIdBytes);
    Function Resolve(Out Host : String; Out Port : Integer) : Boolean;
    Function NeededNames : TArray<String>;
  End;

 Function DiscoveryQuery(Const Name : String; Kind : Word) : TIdBytes;
 Function DiscoverServer(Const Cancelled : TFunc<Boolean>; Out Host : String; Out Port : Integer; Const QueryHost : String = '224.0.0.251'; QueryPort : Integer = 5353; TimeoutMS : Integer = 15000) : Boolean;

Implementation

 Uses
  Winapi.Windows, IdUDPClient, System.Classes;

 Function ReadWord(Const B : TIdBytes; Var P : Integer) : Word;
  Begin
   If (P < 0) Or (P + 2 > Length(B)) Then
    Raise Exception.Create('Truncated DNS word');
   Result := B[P] * 256 + B[P + 1];
   Inc(P, 2);
  End;

 Function ReadName(Const B : TIdBytes; Var P : Integer) : String;
  Var
   At, Count, N, Target, I : Integer;
   Jumped                  : Boolean;
   Part                    : TIdBytes;
  Begin
   Result := '';
   At     := P;
   Count  := 0;
   Jumped := False;
   Repeat
    Inc(Count);
    If (Count > 128) Or (At < 0) Or (At >= Length(B)) Then
     Raise Exception.Create('Invalid DNS name');
    N := B[At];
    Inc(At);
    If N = 0 Then
     Begin
      If Not Jumped Then
       P := At;
      Break
     End;
    If (N And $C0) = $C0 Then
     Begin
      If At >= Length(B) Then
       Raise Exception.Create('Truncated DNS pointer');
      Target := (N And $3F) * 256 + B[At];
      Inc(At);
      If Not Jumped Then
       P     := At;
      Jumped := True;
      At     := Target;
      Continue;
     End;
    If (N > 63) Or (At + N > Length(B)) Then
     Raise Exception.Create('Invalid DNS label');
    SetLength(Part, N);
    For I    := 0 To N - 1 Do
     Part[I] := B[At + I];
    If Result <> '' Then
     Result := Result + '.';
    Result  := Result + BytesToString(Part, IndyTextEncoding_UTF8);
    If Length(Result) > 255 Then
     Raise Exception.Create('DNS name too long');
    Inc(At, N);
   Until False;
   Result := LowerCase(Result);
  End;

 Constructor TDiscoveryCache.Create;
  Begin
   Inherited;
   FInstances := TList<String>.Create;
   FTargets   := TDictionary<String, String>.Create;
   FAddresses := TDictionary<String, String>.Create;
   FPorts     := TDictionary<String, Integer>.Create;
  End;

 Destructor TDiscoveryCache.Destroy;
  Begin
   FInstances.Free;
   FTargets.Free;
   FAddresses.Free;
   FPorts.Free;
   Inherited
  End;

 Procedure TDiscoveryCache.AddPacket(Const Data : TIdBytes);
  Var
   P, Q, Count, I, Kind, Size, DataPos, AfterData, Port : Integer;
   Flags                                                : Word;
   Name, Target                                         : String;
   TTL                                                  : Cardinal;
  Begin
   If Length(Data) < 12 Then
    Exit;
   P     := 2;
   Flags := ReadWord(Data, P);
   If (Flags And $8000) = 0 Then
    Exit;
   Q     := ReadWord(Data, P);
   Count := ReadWord(Data, P);
   Inc(Count, ReadWord(Data, P));
   Inc(Count, ReadWord(Data, P));
   If (Q > 256) Or (Count > 1024) Then
    Raise Exception.Create('DNS packet too large');
   For I := 1 To Q Do
    Begin
     ReadName(Data, P);
     ReadWord(Data, P);
     ReadWord(Data, P)
    End;
   For I := 1 To Count Do
    Begin
     Name := ReadName(Data, P);
     Kind := ReadWord(Data, P);
     ReadWord(Data, P);
     TTL       := ReadWord(Data, P);
     TTL       := (TTL Shl 16) Or ReadWord(Data, P);
     Size      := ReadWord(Data, P);
     DataPos   := P;
     AfterData := P + Size;
     If AfterData > Length(Data) Then
      Raise Exception.Create('Truncated DNS record');
     If TTL > 0 Then
      Case Kind Of
       12 :
        If Name = FMCService Then
         Begin
          Target := ReadName(Data, DataPos);
          If DataPos > AfterData Then
           Raise Exception.Create('Invalid PTR length');
          If Not FInstances.Contains(Target) Then
           FInstances.Add(Target);
         End;
       33 :
        Begin
         ReadWord(Data, DataPos);
         ReadWord(Data, DataPos);
         Port   := ReadWord(Data, DataPos);
         Target := ReadName(Data, DataPos);
         If (DataPos > AfterData) Or (Port = 0) Then
          Raise Exception.Create('Invalid SRV record');
         FTargets.AddOrSetValue(Name, Target);
         FPorts.AddOrSetValue(Name, Port);
        End;
       1 :
        If Size = 4 Then
         FAddresses.AddOrSetValue(Name, Format('%d.%d.%d.%d', [Data[P], Data[P + 1], Data[P + 2], Data[P + 3]]));
      End;
     P := AfterData;
    End;
  End;

 Function TDiscoveryCache.Resolve(Out Host : String; Out Port : Integer) : Boolean;
  Var
   Instance, Target : String;
  Begin
   Result := False;
   Host   := '';
   Port   := 0;
   For Instance In FInstances Do
    If FTargets.TryGetValue(Instance, Target) And FPorts.TryGetValue(Instance, Port) And FAddresses.TryGetValue(Target, Host) Then
     Exit(True);
  End;

 Function TDiscoveryCache.NeededNames : TArray<String>;
  Var
   Names            : TList<String>;
   Instance, Target : String;
  Begin
   Names := TList<String>.Create;
   Try
    For Instance In FInstances Do
     Begin
      Names.Add(Instance);
      If FTargets.TryGetValue(Instance, Target) Then
       Names.Add(Target);
     End;
    Result := Names.ToArray;
   Finally
    Names.Free
   End;
  End;

 Function DiscoveryQuery(Const Name : String; Kind : Word) : TIdBytes;
  Var
   Labels    : TArray<String>;
   LabelText : String;
   B         : TIdBytes;
   At, I, N  : Integer;
  Begin
   SetLength(Result, 12);
   FillChar(Result[0], 12, 0);
   Result[5] := 1;
   Labels    := Name.Split(['.']);
   At        := 12;
   For LabelText In Labels Do
    Begin
     B := ToBytes(LabelText, IndyTextEncoding_UTF8);
     N := Length(B);
     If (N < 1) Or (N > 63) Then
      Raise Exception.Create('Invalid DNS query label');
     SetLength(Result, At + N + 1);
     Result[At] := N;
     Inc(At);
     For I           := 0 To N - 1 Do
      Result[At + I] := B[I];
     Inc(At, N);
    End;
   SetLength(Result, At + 5);
   Result[At]     := 0;
   Result[At + 1] := Kind Shr 8;
   Result[At + 2] := Kind And $FF;
   // QU requests a unicast reply to the ephemeral client port, avoiding a second listener on port 5353.
   Result[At + 3] := $80;
   Result[At + 4] := 1;
  End;

 Function DiscoverServer(Const Cancelled : TFunc<Boolean>; Out Host : String; Out Port : Integer; Const QueryHost : String; QueryPort : Integer; TimeoutMS : Integer) : Boolean;
  Var
   UDP                 : TIdUDPClient;
   Cache               : TDiscoveryCache;
   B                   : TIdBytes;
   Deadline, NextQuery : UInt64;
   N                   : Integer;
   Name                : String;
  Begin
   Result := False;
   Host   := '';
   Port   := 0;
   UDP    := TIdUDPClient.Create(Nil);
   Cache  := TDiscoveryCache.Create;
   Try
    UDP.IPVersion := Id_IPv4;
    UDP.Host      := QueryHost;
    UDP.Port      := QueryPort;
    UDP.Active    := True;
    Deadline      := GetTickCount64 + UInt64(TimeoutMS);
    NextQuery     := 0;
    While (GetTickCount64 < Deadline) And Not Cancelled() Do
     Begin
      If GetTickCount64 >= NextQuery Then
       Begin
        UDP.SendBuffer(DiscoveryQuery(FMCService, 12));
        For Name In Cache.NeededNames Do
         Begin
          UDP.SendBuffer(DiscoveryQuery(Name, 33));
          UDP.SendBuffer(DiscoveryQuery(Name, 1));
         End;
        NextQuery := GetTickCount64 + 1000;
       End;
      SetLength(B, 65535);
      N := UDP.ReceiveBuffer(B, 100);
      If N > 0 Then
       Begin
        SetLength(B, N);
        Try
         Cache.AddPacket(B)
        Except
         On E : Exception Do
          Continue
        End;
        If Cache.Resolve(Host, Port) Then
         Exit(True);
       End;
     End;
   Finally
    Cache.Free;
    UDP.Free
   End;
  End;

End.
