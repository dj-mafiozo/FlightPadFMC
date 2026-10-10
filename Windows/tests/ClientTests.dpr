Program ClientTests;
{$APPTYPE CONSOLE}

Uses
 Winapi.Windows, System.SysUtils, System.Math, System.Classes, System.IOUtils, System.IniFiles,
 Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Controls, Vcl.Imaging.pngimage,
 AircraftTypes, Profile, ScreenModel, FMCMain, Transport, ClientSettings, SettingsForm;

Type
 TTestFMCForm = Class(TFMCForm)
  Public
   SettingsOpened : Boolean;
   DragCount      : Integer;
   Procedure BeginWindowDrag; Override;
   Procedure ShowSettings; Override;
 End;

Procedure TTestFMCForm.BeginWindowDrag;
 Begin
  Inc(DragCount)
 End;

Procedure TTestFMCForm.ShowSettings;
 Begin
  SettingsOpened := True
 End;

Var
 P                                                      : TAircraftProfile;
 M                                                      : TScreenModel;
 F                                                      : TFMCForm;
 B                                                      : TBitmap;
 PNG                                                    : TPngImage;
 Data, Changed, Config, Preview, FixtureRoot, AssetRoot : String;
 I                                                      : Integer;
 Rejected                                               : Boolean;
 Paint                                                  : TPaintBox;
 NewSettings                                            : TClientSettings;
 Key                                                    : Char;
 WordKey                                                : Word;
 Deadline                                               : UInt64;
 Scale                                                  : Double;
 W, H, X, Y                                             : Integer;
 SentFirst, SentSecond, Done                            : Boolean;

Procedure Check(Condition : Boolean; Const Message : String);
 Begin
  If Not Condition Then
   Raise Exception.Create(Message)
 End;

Procedure CheckSettingsDialog;
 Var
  D              : TSettingsForm;
  Values, Loaded : TClientSettings;
  Edit           : TEdit;
  Save           : TButton;
  Mode, Side     : TRadioGroup;
  Sound          : TCheckBox;
  FileName       : String;
 Begin
  Values := DefaultSettings;
  D      := TSettingsForm.CreateSettings(Nil, P, Values, 'Connected (127.0.0.1:8765)');
  Try
   Mode  := TRadioGroup(D.FindComponent('ConnectionMode'));
   Edit  := TEdit(D.FindComponent('ServerPort'));
   Save  := TButton(D.FindComponent('SaveButton'));
   Sound := TCheckBox(D.FindComponent('ButtonSound'));
   Side  := TRadioGroup(D.FindComponent('DefaultSide'));
   Check(Side.Visible, 'CDU side remains visible');
   Check(Side.Enabled = P.SupportsSide, 'CDU side enabled only for supported profiles');
   Edit.Text := '0';
   Save.Click;
   Check(D.ModalResult <> mrOk, 'Invalid port cannot close Settings');
   Check(D.Values.Port = 8765, 'Validation cannot commit partial settings');
   Edit.Text                                              := '18765';
   Mode.ItemIndex                                         := 1;
   Sound.Checked                                          := False;
   TCheckBox(D.FindComponent('BorderlessWindow')).Checked := True;
   TEdit(D.FindComponent('ServerHost')).Text              := ' 127.0.0.1 ';
   If P.SupportsSide Then
    Side.ItemIndex := 1;
   Save.Click;
   Check(D.ModalResult = mrOk, 'Settings Save handler');
   Values := D.Values;
   Check((Values.Port = 18765) And (Values.Host = '127.0.0.1') And Not Values.AutoDiscover And Not Values.Sound, 'Settings values and host trimming');
   If P.SupportsSide Then
    Check(Values.Side = 'fo', 'Saved FO side')
   Else
    Check(Values.Side = 'capt', 'Single-side profile');
   FileName := TPath.Combine(ExtractFilePath(ParamStr(0)), 'preferences.ini');
   ClientSettings.SaveSettings(FileName, Values);
   Loaded := ClientSettings.LoadSettings(FileName);
   Check((Loaded.Host = Values.Host) And (Loaded.Port = 18765) And Not Loaded.Sound And Not Loaded.AutoDiscover And (Loaded.Side = Values.Side) And Loaded.Borderless, 'Persist and reload all settings');
  Finally
   D.Free
  End;
  D := TSettingsForm.CreateSettings(Nil, P, Values, 'Not connected');
  Try
   Check(TCheckBox(D.FindComponent('BorderlessWindow')).Checked, 'Borderless preference loads into Settings');
   TCheckBox(D.FindComponent('BorderlessWindow')).Checked := False;
   TEdit(D.FindComponent('ServerPort')).Text              := '12345';
   TButton(D.FindComponent('CancelButton')).Click;
   Check((D.ModalResult = mrCancel) And (D.Values.Port = Values.Port) And D.Values.Borderless, 'Cancel does not commit changes');
  Finally
   D.Free
  End;
 End;

Procedure CheckWindowPosition;
 Var
  Form                : TFMCForm;
  Preferences         : TClientSettings;
  FileName            : String;
  Area                : TRect;
  SavedLeft, SavedTop : Integer;
 Begin
  FileName               := TPath.Combine(ExtractFilePath(ParamStr(0)), 'window-position.ini');
  Preferences            := DefaultSettings;
  Preferences.Borderless := True;
  ClientSettings.SaveSettings(FileName, Preferences);
  Form := TFMCForm.CreateConfigured(Nil, P, AssetRoot, FileName, False);
  Try
   Form.HandleNeeded;
   Area      := Form.Monitor.WorkareaRect;
   Form.Left := Area.Left + 20;
   Form.Top  := Area.Top + 20;
   SavedLeft := Form.Left;
   SavedTop  := Form.Top;
   Form.Close;
  Finally
   Form.Free
  End;
  Preferences := ClientSettings.LoadSettings(FileName);
  Check(Preferences.HasPosition And (Preferences.WindowLeft = SavedLeft) And (Preferences.WindowTop = SavedTop), 'Closing saves window screen coordinates');
  Form := TFMCForm.CreateConfigured(Nil, P, AssetRoot, FileName, False);
  Try
   Form.HandleNeeded;
   Check((Form.BorderStyle = bsNone) And (Form.Left = SavedLeft) And (Form.Top = SavedTop), 'Restart restores borderless window position');
  Finally
   Form.Free
  End;
  Preferences.WindowLeft := 100000;
  Preferences.WindowTop  := 100000;
  ClientSettings.SaveSettings(FileName, Preferences);
  Form := TFMCForm.CreateConfigured(Nil, P, AssetRoot, FileName, False);
  Try
   Area := Form.Monitor.WorkareaRect;
   Check((Form.Left >= Area.Left) And (Form.Top >= Area.Top) And (Form.Left + Form.Width <= Area.Right) And (Form.Top + Form.Height <= Area.Bottom), 'Disconnected monitor position returns to visible work area');
  Finally
   Form.Free
  End;
 End;

Procedure TypeChar(C : Char);
 Begin
  Key := C;
  F.OnKeyPress(F, Key)
 End;

Procedure TypeShortcut(K : Word; Shift : TShiftState);
 Begin
  WordKey := K;
  F.OnKeyDown(F, WordKey, Shift)
 End;

Begin
 Try
  Application.Initialize;
  P           := CreateProfile;
  AssetRoot   := ParamStr(1);
  FixtureRoot := ParamStr(2);
  Check((AssetRoot <> '') And (FixtureRoot <> ''), 'Usage: ClientTests <aircraft folder> <fixtures folder>');
  If P.Airbus Then
   Data := TFile.ReadAllText(TPath.Combine(FixtureRoot, 'airbus.json'), TEncoding.UTF8)
  Else
   Data := TFile.ReadAllText(TPath.Combine(FixtureRoot, 'boeing.json'), TEncoding.UTF8);
  M     := TScreenModel.Create(P);
  Try
   M.Parse(Data);
   Check(M.State.Cells[0, 0].Symbol = 'T', 'Title/grid parsing');
   If P.Airbus Then
    Begin
     Check(M.State.Cells[1, 0].Symbol = 'L', 'Left slot');
     Check(M.State.Cells[1, 23].Symbol = 'R', 'Right slot [left,right,center]');
     Check(M.State.Cells[1, 11].Symbol = 'C', 'Center slot');
     Check(M.State.Cells[1, 0].Small, 'Label row must be small');
     Check(M.State.Cells[2, 0].Color = clLime, 'Color tag');
     Check(M.State.Cells[2, 1].Color = clAqua, 'Mixed colors in one row');
     Check(Not M.State.Cells[2, 0].Small, 'Data row must be large');
     Check(M.State.Cells[3, 20].Symbol = 'R', 'Inline right alignment');
     Check(M.State.Cells[0, 23].Symbol = #$2192, 'Right slew arrow');
     Check(M.State.Cells[0, 22].Symbol = #$2190, 'Left slew arrow');
     Check(M.State.Cells[4, 0].Symbol = 'C', 'Malformed nested brace keeps COPY');
     Check(M.State.Cells[4, 4].Symbol = ' ', '{sp}');
     Check(M.LedOn('FM') And M.LedOn('FM1') And M.LedOn('RDY'), 'Airbus LEDs');
     If P.Fenix Then
      Begin
       Check(M.State.Cells[13, 0].Symbol = #$25AE, 'Fenix entry box');
       Check(M.State.Cells[13, 1].Symbol = #$2190, 'Fenix previous arrow');
       Check(M.LedOn('FAIL') And M.LedOn('MCDU MENU'), 'Fenix extra LEDs');
      End
     Else
      Begin
       Check(M.State.Cells[13, 3].Symbol = #$25AE, 'FBW entry box code ' + IntToStr(Ord(M.State.Cells[13, 3].Symbol[1])));
       Check(Not M.LedOn('FAIL'), 'FBW decorative FAIL remains off');
      End;
     Changed := 'update:{"left":{"lines":[["{cyan}X{end}Y{big}Z{unknown}Q","",""]]}}';
     M.Parse(Changed);
     Check(M.State.Cells[1, 1].Color = clAqua, '{end} preserves current color');
     Check(Not M.State.Cells[1, 2].Small, '{big} overrides label size');
     M.Parse(Data);
     Changed := '{"left":{"titleLeft":"BAD","lines":[false]}}';
    End
   Else
    Begin
     Check(M.State.Cells[0, 1].Color = clAqua, 'Grid color 1');
     Check(M.State.Cells[0, 2].Color = clLime, 'Grid color 2');
     Check(M.State.Cells[0, 5].Color = clRed, 'Grid color 5');
     Check(M.LedOn('EXEC'), 'Embedded EXEC');
     M.Parse('{"type":"exec_led","value":false}');
     Check(Not M.LedOn('EXEC'), 'Legacy EXEC value');
     M.Parse('{"type":"led_update","name":"MSG","led_on":true}');
     Check(M.LedOn('MSG'), 'Named MSG');
     If P.SupportsSide Then
      Begin
       M.Side := 'fo';
       M.Parse(Data);
       Check(M.State.Cells[0, 0].Symbol = 'T', 'Stale capt frame ignored');
       Changed := StringReplace(Data, '"s": "T"', '"s": "X"', []);
       M.Parse(Changed);
       Check(M.State.Cells[0, 0].Symbol = 'T', 'Wrong side cannot overwrite screen');
       Changed := StringReplace(Changed, '"side": "capt"', '"side": "fo"', []);
       M.Parse(Changed);
       Check(M.State.Cells[0, 0].Symbol = 'X', 'FO screen accepted');
       M.Side := 'capt';
       M.Parse(Data);
      End;
     Changed := StringReplace(Data, '"c": 5', '"c": "broken"', []);
    End;
   Rejected := False;
   Try
    M.Parse(Changed)
   Except
    On E : Exception Do
     Rejected := True
   End;
   Check(Rejected, 'Malformed snapshot should be rejected');
   Check(M.State.Cells[0, 0].Symbol = 'T', 'Malformed snapshot must not partially update screen');
   M.Parse('{"type":"status_message","text":"diagnosis"}');
   Check(M.State.Overlay = 'diagnosis', 'Status overlay');
   M.Parse('{"type":"status_message","text":""}');
   Check(M.State.Overlay = '', 'Clear overlay');
   M.Reset;
   Check(Not M.LedOn('MSG') And Not M.LedOn('FM1'), 'Disconnect clears LEDs');
  Finally
   M.Free
  End;
  CheckSettingsDialog;
  CheckWindowPosition;
  // Exercise the real VCL renderer in both portrait and landscape without a visible window.
  F := TTestFMCForm.CreateConfigured(Nil, P, AssetRoot, '', False);
  B := TBitmap.Create;
  Try
   F.HandleNeeded;
   F.Model.Parse(Data);
   Check(F.ControlCount = 1, 'Main window must contain only the CDU, no top panel');
   Paint := Nil;
   For I := 0 To F.ComponentCount - 1 Do
    If F.Components[I] Is TPaintBox Then
     Paint := TPaintBox(F.Components[I]);
   Check((Paint <> Nil) And (Paint.Height = F.ClientHeight), 'CDU fills entire client area');
   PNG := TPngImage.Create;
   Try
    PNG.LoadFromFile(TPath.Combine(AssetRoot, 'assets\' + P.BackgroundFile));
    B.SetSize(Paint.Width, Paint.Height);
    F.RenderCDU(B.Canvas, B.Width, B.Height);
    Scale := Min(Paint.Width / PNG.Width, Paint.Height / PNG.Height);
    W     := Round(PNG.Width * Scale);
    H     := Round(PNG.Height * Scale);
    Check((Abs(Paint.Width - W) <= 1) And (Abs(Paint.Height - H) <= 1), 'Startup client area matches background aspect ratio without black bars');
    X := (Paint.Width - W) Div 2 + Round((P.SettingsButton.L + P.SettingsButton.R) * W / 2);
    Y := (Paint.Height - H) Div 2 + Round((P.SettingsButton.T + P.SettingsButton.B) * H / 2);
    Paint.OnMouseDown(Paint, mbLeft, [], X, Y);
    Check(TTestFMCForm(F).SettingsOpened, 'Skin Settings button opens separate settings window');
    NewSettings              := F.Settings;
    NewSettings.Port         := 18765;
    NewSettings.Sound        := False;
    NewSettings.AutoDiscover := False;
    W                        := F.ClientWidth;
    H                        := F.ClientHeight;
    NewSettings.Borderless   := True;
    F.UpdateSettings(NewSettings, False);
    Check((F.BorderStyle = bsNone) And (F.ClientWidth = W) And (F.ClientHeight = H), 'Borderless hides frame and preserves CDU dimensions');
    B.SetSize(Paint.Width, Paint.Height);
    F.RenderCDU(B.Canvas, B.Width, B.Height);
    Paint.OnMouseDown(Paint, mbLeft, [], Round(Paint.Width * 0.5), Round(Paint.Height * 0.995));
    Check(TTestFMCForm(F).DragCount = 1, 'Unused skin begins borderless native drag');
    Paint.OnMouseDown(Paint, mbRight, [], Round(Paint.Width * 0.5), Round(Paint.Height * 0.995));
    Paint.OnMouseDown(Paint, mbLeft, [], Round(Paint.Width * (P.Screen.L + P.Screen.R) / 2), Round(Paint.Height * (P.Screen.T + P.Screen.B) / 2));
    Paint.OnMouseDown(Paint, mbLeft, [], X, Y);
    Check(TTestFMCForm(F).DragCount = 1, 'Screen, Settings and right click do not drag');
    NewSettings.Borderless := False;
    F.UpdateSettings(NewSettings, False);
    Check((F.BorderStyle = bsSizeable) And (F.ClientWidth = W) And (F.ClientHeight = H), 'Window frame can be restored without resizing CDU');
    Paint.OnMouseDown(Paint, mbLeft, [], Round(Paint.Width * 0.5), Round(Paint.Height * 0.995));
    Check(TTestFMCForm(F).DragCount = 1, 'Framed window does not drag via background');
    Check((F.Settings.Port = 18765) And Not F.Settings.Sound, 'Settings apply without hidden main-window controls');
   Finally
    PNG.Free
   End;
   B.SetSize(560, 790);
   F.RenderCDU(B.Canvas, B.Width, B.Height);
   Preview := TPath.Combine(ExtractFilePath(ParamStr(0)), 'preview.bmp');
   B.SaveToFile(Preview);
   B.SetSize(800, 500);
   F.RenderCDU(B.Canvas, B.Width, B.Height);
   B.SaveToFile(TPath.Combine(ExtractFilePath(ParamStr(0)), 'landscape.bmp'));
  Finally
   B.Free;
   F.Free
  End;
  Writeln('PASS ' + P.Aircraft + ': parser, colors, size, alignment, LEDs, validation, render');
  // Connect a hidden real form to the Python mock and drive its actual input handlers.
  Config := TPath.Combine(ExtractFilePath(ParamStr(0)), 'test.ini');
  With TIniFile.Create(Config) Do
   Try
    WriteString('Server', 'Host', '127.0.0.1');
    WriteInteger('Server', 'Port', 18765);
    WriteString('CDU', 'Side', 'capt');
    WriteString('Server', 'Mode', 'manual');
    WriteBool('Feedback', 'Sound', False);
   Finally
    Free
   End;
  F   := TFMCForm.CreateConfigured(Nil, P, AssetRoot, Config, True);
  B   := TBitmap.Create;
  PNG := TPngImage.Create;
  Try
   F.HandleNeeded;
   PNG.LoadFromFile(TPath.Combine(AssetRoot, 'assets\' + P.BackgroundFile));
   Paint := Nil;
   For I := 0 To F.ComponentCount - 1 Do
    Begin
     If F.Components[I] Is TPaintBox Then
      Paint := TPaintBox(F.Components[I]);

    End;
   Check(Paint <> Nil, 'CDU paint control');
   SentFirst  := False;
   SentSecond := False;
   Done       := False;
   Deadline   := GetTickCount64 + 15000;
   While GetTickCount64 < Deadline Do
    Begin
     Application.ProcessMessages;
     If Not SentFirst And (F.Model.State.Cells[0, 0].Symbol = 'T') And (F.Model.State.Overlay = '') Then
      Begin
       TypeChar(#13);
       TypeChar('.');
       TypeChar('/');
       TypeChar('+');
       TypeChar(' ');
       TypeChar(#8);
       TypeShortcut(VK_F1, []);
       TypeShortcut(VK_F6, [ssShift]);
       If P.Airbus Then
        Begin
         TypeShortcut(VK_LEFT, []);
         TypeShortcut(VK_UP, [])
        End
       Else
        Begin
         TypeShortcut(VK_PRIOR, []);
         TypeShortcut(VK_NEXT, [])
        End;
       B.SetSize(Paint.Width, Paint.Height);
       F.RenderCDU(B.Canvas, B.Width, B.Height);
       Scale := Min(Paint.Width / PNG.Width, Paint.Height / PNG.Height);
       W     := Round(PNG.Width * Scale);
       H     := Round(PNG.Height * Scale);
       X     := (Paint.Width - W) Div 2 + Round(P.Hints[12].X * W);
       Y     := (Paint.Height - H) Div 2 + Round(P.Hints[12].Y * H);
       Paint.OnMouseDown(Paint, mbLeft, [], X, Y);
       If P.SupportsSide Then
        Begin
         NewSettings      := F.Settings;
         NewSettings.Side := 'fo';
         F.UpdateSettings(NewSettings, False)
        End;
       SentFirst := True;
      End;
     If SentFirst And Not SentSecond And (F.Model.State.Cells[0, 0].Symbol = 'R') And (F.Model.State.Overlay = '') Then
      Begin
       If P.SupportsSide Then
        Check(F.Model.Side = 'fo', 'Reconnect restores FO side');
       TypeChar(#13);
       SentSecond := True;
      End;
     If SentSecond And (F.Model.State.Overlay = 'DONE') Then
      Begin
       Done := True;
       Break
      End;
     Sleep(10);
    End;
   Check(Done, 'GUI WebSocket round trip timed out');
  Finally
   PNG.Free;
   B.Free;
   F.Free
  End;
  Writeln('PASS ' + P.Aircraft + ': identify, actual keyboard and mouse handlers, side selection, reconnect, shutdown');
 Except
  On E : Exception Do
   Begin
    Writeln('FAIL: ' + E.Message);
    Halt(1)
   End
 End;

End.
