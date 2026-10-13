Unit ClientSettings;

Interface

 Uses
  System.SysUtils;

 Type
  TClientSettings = Record
   RefocusMSFS : Boolean;
   RefocusSeconds : Integer;
   Host                  : String;
   Port                  : Integer;
   AutoDiscover, Sound   : Boolean;
   Fullscreen            : Boolean;
   Borderless            : Boolean;
   HasPosition           : Boolean;
   WindowLeft, WindowTop : Integer;
   Side                  : String;
  End;

 Function DefaultSettings : TClientSettings;
 Function LoadSettings(Const FileName : String) : TClientSettings;
 Procedure SaveSettings(Const FileName : String; Const Settings : TClientSettings);
 Function ValidateSettings(Const Settings : TClientSettings; Out Error : String) : Boolean;

Implementation

 Uses
  System.IniFiles;

 Function DefaultSettings : TClientSettings;
  Begin
   Result.RefocusMSFS := False;
   Result.RefocusSeconds := 2;
   Result.Host         := '127.0.0.1';
   Result.Port         := 8765;
   Result.AutoDiscover := True;
   Result.Sound        := True;
   Result.Fullscreen   := False;
   Result.Borderless   := False;
   Result.HasPosition  := False;
   Result.WindowLeft   := 0;
   Result.WindowTop    := 0;
   Result.Side         := 'capt';
  End;

 Function ValidateSettings(Const Settings : TClientSettings; Out Error : String) : Boolean;
  Begin
   Error := '';
   If Trim(Settings.Host) = '' Then
    Error := 'Enter a server IP address or host name.'
   Else If (Settings.Port < 1) Or (Settings.Port > 65535) Then
    Error := 'Server port must be between 1 and 65535.'
   Else If (Settings.RefocusSeconds < 1) Or (Settings.RefocusSeconds > 60) Then
    Error := 'Refocus interval must be between 1 and 60 seconds.'
   Else If (Settings.Side <> 'capt') And (Settings.Side <> 'fo') Then
    Error := 'Select Captain or First Officer CDU.';
   Result := Error = '';
  End;

 Function LoadSettings(Const FileName : String) : TClientSettings;
  Var
   Ini : TIniFile;
  Begin
   Result := DefaultSettings;
   If FileName = '' Then
    Exit;
   Ini := TIniFile.Create(FileName);
   Try
    Result.Host := Ini.ReadString('Server', 'Host', Result.Host);
    Result.Port := Ini.ReadInteger('Server', 'Port', Result.Port);
    // Preserve manual connection for INI files written by earlier Windows versions.
    Result.AutoDiscover := Ini.ReadString('Server', 'Mode', 'manual') = 'auto';
    If Not Ini.ValueExists('Server', 'Host') And Not Ini.ValueExists('Server', 'Mode') Then
     Result.AutoDiscover := True;
    Result.RefocusMSFS := Ini.ReadBool('MSFS', 'Refocus', False);
    Result.RefocusSeconds := Ini.ReadInteger('MSFS', 'RefocusSeconds', 2);
    If (Result.RefocusSeconds < 1) Or (Result.RefocusSeconds > 60) Then Result.RefocusSeconds := 2;
    Result.Fullscreen := Ini.ReadBool('Window', 'Fullscreen', False);
    Result.Borderless    := Ini.ReadBool('Window', 'Borderless', False);
    Result.HasPosition := Ini.ReadBool('Window', 'HasPosition', False);
    Result.WindowLeft := Ini.ReadInteger('Window', 'Left', 0);
    Result.WindowTop := Ini.ReadInteger('Window', 'Top', 0);
    Result.Sound         := Ini.ReadBool('Feedback', 'Sound', True);
    Result.Side          := Ini.ReadString('CDU', 'Side', 'capt');
    If Result.Side <> 'fo' Then
     Result.Side := 'capt';
    If Trim(Result.Host) = '' Then
     Result.Host := '127.0.0.1';
    If (Result.Port < 1) Or (Result.Port > 65535) Then
     Result.Port := 8765;
   Finally
    Ini.Free
   End;
  End;

 Procedure SaveSettings(Const FileName : String; Const Settings : TClientSettings);
  Var
   Ini   : TIniFile;
   Error : String;
  Begin
   If Not ValidateSettings(Settings, Error) Then
    Raise Exception.Create(Error);
   If FileName = '' Then
    Exit;
   If ExtractFilePath(FileName) <> '' Then
    ForceDirectories(ExtractFilePath(FileName));
   Ini := TIniFile.Create(FileName);
   Try
    Ini.WriteString('Server', 'Host', Trim(Settings.Host));
    Ini.WriteInteger('Server', 'Port', Settings.Port);
    If Settings.AutoDiscover Then
     Ini.WriteString('Server', 'Mode', 'auto')
    Else
     Ini.WriteString('Server', 'Mode', 'manual');
    Ini.WriteBool('MSFS', 'Refocus', Settings.RefocusMSFS);
    Ini.WriteInteger('MSFS', 'RefocusSeconds', Settings.RefocusSeconds);
    Ini.WriteBool('Window', 'Fullscreen', Settings.Fullscreen);
    Ini.WriteBool('Window', 'Borderless', Settings.Borderless);
    Ini.WriteBool('Window', 'HasPosition', Settings.HasPosition);
    Ini.WriteInteger('Window', 'Left', Settings.WindowLeft);
    Ini.WriteInteger('Window', 'Top', Settings.WindowTop);
    Ini.WriteBool('Feedback', 'Sound', Settings.Sound);
    Ini.WriteString('CDU', 'Side', Settings.Side);
   Finally
    Ini.Free
   End;
  End;

End.
