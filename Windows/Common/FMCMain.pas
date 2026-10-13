Unit FMCMain;

Interface

 Uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types, System.JSON,
  System.IniFiles, System.IOUtils, System.Math, Vcl.Forms, Vcl.Controls,
  Vcl.Graphics, Vcl.Menus, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  AircraftTypes, ScreenModel, Transport, ClientSettings;

 Type
  TFMCForm = Class(TForm)
   Published
    ScreenMenu: TPopupMenu;
    SettingsItem, FullscreenItem, CloseItem: TMenuItem;
    FPaint                         : TPaintBox;
    FRefocusTimer: TTimer;
    FTimer                         : TTimer;
    Procedure MenuSettings(Sender: TObject);
    Procedure MenuFullscreen(Sender: TObject);
    Procedure MenuClose(Sender: TObject);
    Procedure SaveWindowPosition(Sender : TObject; Var Action : TCloseAction);
    Procedure FitBackground(Sender : TObject);
    Procedure PaintCDU(Sender : TObject);
    Procedure ClickCDU(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    Procedure RefocusTick(Sender: TObject);
    Procedure Tick(Sender : TObject);
    Procedure Keyboard(Sender : TObject; Var Key : Char);
    Procedure Shortcut(Sender : TObject; Var Key : Word; Shift : TShiftState);
   Private
    FSettingsOpen: Boolean;
    FFullscreen: Boolean;
    FWindowedBounds: TRect;
    FProfile                       : TAircraftProfile;
    FModel                         : TScreenModel;
    FSkin                          : TPngImage;
    FSettings                      : TClientSettings;
    FStatus, FEndpoint, FSoundFile : String;
    FTransport                     : TTransport;
    FConfig, FFontFile             : String;
    FImage                         : TRect;
    FPressed                       : Integer;
    FPressedUntil                  : UInt64;
    FConnected                     : Boolean;
    Procedure Initialize(Const P : TAircraftProfile; Const AssetBase, ConfigFile : String; AutoConnect : Boolean);
    Procedure Connect(Sender : TObject);
    Procedure ApplySide;
    Procedure ApplyWindowStyle;
    Procedure ApplyFullscreen;
    Procedure RestoreWindowPosition;
    Procedure SendKey(Const Key : String);
    Function SkinRect(Const Bounds : TNormRect) : TRect;
   Protected
    Procedure BeginWindowDrag; Virtual;
   Public
    Constructor Create(AOwner : TComponent); Override;
    Constructor CreateConfigured(AOwner : TComponent; Const P : TAircraftProfile; Const AssetBase, ConfigFile : String; AutoConnect : Boolean);
    Destructor Destroy; Override;
    Procedure RenderCDU(Canvas : TCanvas; Width, Height : Integer);
    Procedure ShowSettings; virtual;
    Procedure UpdateSettings(Const Values : TClientSettings; Reconnect : Boolean = True);
    Property Settings : TClientSettings Read FSettings;
    Property Model : TScreenModel Read FModel;
  End;

 Var
  FMCForm : TFMCForm;

Implementation

{$R *.dfm}

 Uses
  Profile, SettingsForm, SimFocus, Winapi.MMSystem;

 Constructor TFMCForm.Create(AOwner : TComponent);
  Var
   P : TAircraftProfile;
  Begin
   Inherited Create(AOwner);
   P := CreateProfile;
   Initialize(P, ExtractFilePath(ParamStr(0)), TPath.Combine(TPath.GetHomePath, 'FlightPadFMC\' + P.SettingsName + 'Windows.ini'), True);
  End;

 Constructor TFMCForm.CreateConfigured(AOwner : TComponent; Const P : TAircraftProfile; Const AssetBase, ConfigFile : String; AutoConnect : Boolean);
  Begin
   Inherited Create(AOwner);
   Initialize(P, AssetBase, ConfigFile, AutoConnect)
  End;

 Procedure TFMCForm.Initialize(Const P : TAircraftProfile; Const AssetBase, ConfigFile : String; AutoConnect : Boolean);
  Begin
   FProfile              := P;
   FConfig               := ConfigFile;
   FPressed              := -1;
   Caption               := P.Title;
   FModel                := TScreenModel.Create(P);
   FSettings             := ClientSettings.LoadSettings(FConfig);
   If Not P.SupportsSide Then
    FSettings.Side    := 'capt';
   FStatus            := 'Not connected';
   FSkin              := TPngImage.Create;
   FSkin.LoadFromFile(IncludeTrailingPathDelimiter(AssetBase) + 'assets\' + P.BackgroundFile);
   If P.ScreenOnly Then
    Begin
     Caption := P.Title + ' - Screen';
     Constraints.MinWidth := 320; Constraints.MinHeight := 200;
     ClientWidth := 720;
     ClientHeight := Round(720 * FSkin.Height * (P.Screen.B-P.Screen.T) /
       (FSkin.Width * (P.Screen.R-P.Screen.L)));
     FPaint.PopupMenu := ScreenMenu;
    End;
   ApplyWindowStyle;
   If FSettings.HasPosition Then
    Begin
     Position := poDesigned;
     Left := FSettings.WindowLeft;
     Top := FSettings.WindowTop;
    End;
   FitBackground(Nil);
   RestoreWindowPosition;
   ApplyFullscreen;
   FFontFile  := IncludeTrailingPathDelimiter(AssetBase) + 'assets\B612Mono-Bold.ttf';
   FSoundFile := IncludeTrailingPathDelimiter(AssetBase) + 'assets\' + P.SoundFile;
   AddFontResourceEx(PChar(FFontFile), FR_PRIVATE, Nil);
   FRefocusTimer.Interval := FSettings.RefocusSeconds * 1000;
   FRefocusTimer.Enabled := FSettings.RefocusMSFS;
   FTimer.Enabled := True;
   If AutoConnect Then
    Connect(Nil);
  End;

 Destructor TFMCForm.Destroy;
  Begin
   If FRefocusTimer <> Nil Then FRefocusTimer.Enabled := False;
   If FTimer <> Nil Then
    FTimer.Enabled := False;
   FTransport.Free;
   FModel.Free;
   FSkin.Free;
   If FFontFile <> '' Then
    RemoveFontResourceEx(PChar(FFontFile), FR_PRIVATE, Nil);
   Inherited;
  End;

 Procedure TFMCForm.ShowSettings;
  Var
   Dialog : TSettingsForm;
   Status : String;
  Begin
   Status := FStatus;
   If FEndpoint <> '' Then
    Status := Status + ' (' + FEndpoint + ')';
   Dialog  := TSettingsForm.CreateSettings(Self, FProfile, FSettings, Status);
   FSettingsOpen := True;
   Try
    If Dialog.ShowModal = mrOk Then
     UpdateSettings(Dialog.Values);
   Finally
    FSettingsOpen := False;
    Dialog.Free
   End;
  End;

 Procedure TFMCForm.UpdateSettings(Const Values : TClientSettings; Reconnect : Boolean);
  Var
   Candidate : TClientSettings;
   Error     : String;
   Changed   : Boolean;
  Begin
   Candidate      := Values;
   Candidate.Host := Trim(Candidate.Host);
   If Not FProfile.SupportsSide Then
    Candidate.Side := 'capt';
   If Not ValidateSettings(Candidate, Error) Then
    Raise Exception.Create(Error);
   Changed := (Candidate.Host <> FSettings.Host) Or (Candidate.Port <> FSettings.Port) Or (Candidate.AutoDiscover <> FSettings.AutoDiscover);
   ClientSettings.SaveSettings(FConfig, Candidate);
   FSettings := Candidate;
   FRefocusTimer.Enabled := False;
   FRefocusTimer.Interval := FSettings.RefocusSeconds * 1000;
   FRefocusTimer.Enabled := FSettings.RefocusMSFS;
   ApplyFullscreen;
   ApplyWindowStyle;
   If Reconnect And (Changed Or Not FConnected) Then
    Connect(Nil)
   Else
    ApplySide;
   FPaint.Invalidate;
  End;

 Procedure TFMCForm.ApplyWindowStyle;
  Var
   Style : TFormBorderStyle;
   W, H : Integer;
  Begin
   If FFullscreen Then Exit;
   If FSettings.Borderless Then Style := bsNone Else Style := bsSizeable;
   If BorderStyle = Style Then Exit;
   W := ClientWidth;
   H := ClientHeight;
   // Changing the native window frame must preserve the CDU's client area.
   BorderStyle := Style;
   ClientWidth := W;
   ClientHeight := H;
  End;

 Procedure TFMCForm.ApplyFullscreen;
  Var Area: TRect;
  Begin
   If Not FProfile.ScreenOnly Then Exit;
   If FSettings.Fullscreen = FFullscreen Then Exit;
   If FSettings.Fullscreen Then
    Begin
     FWindowedBounds := BoundsRect;
     Area := Monitor.BoundsRect;
     WindowState := wsNormal;
     BorderStyle := bsNone;
     FFullscreen := True;
     SetBounds(Area.Left, Area.Top, Area.Width, Area.Height);
    End
   Else
    Begin
     FFullscreen := False;
     ApplyWindowStyle;
     SetBounds(FWindowedBounds.Left, FWindowedBounds.Top,
       FWindowedBounds.Width, FWindowedBounds.Height);
    End;
   FullscreenItem.Checked := FFullscreen;
   FPaint.Invalidate;
  End;

 Procedure TFMCForm.MenuSettings(Sender: TObject);
  Begin ShowSettings End;
 Procedure TFMCForm.MenuFullscreen(Sender: TObject);
  Var Values: TClientSettings;
  Begin
   Values := FSettings; Values.Fullscreen := Not Values.Fullscreen;
   UpdateSettings(Values, False);
  End;
 Procedure TFMCForm.MenuClose(Sender: TObject);
  Begin Close End;

 Procedure TFMCForm.RestoreWindowPosition;
  Var
   Area : TRect;
  Begin
   If Not FSettings.HasPosition Then Exit;
   Area := Screen.MonitorFromRect(BoundsRect, mdNearest).WorkareaRect;
   Left := EnsureRange(FSettings.WindowLeft, Area.Left, Max(Area.Left, Area.Right - Width));
   Top := EnsureRange(FSettings.WindowTop, Area.Top, Max(Area.Top, Area.Bottom - Height));
  End;

 Procedure TFMCForm.SaveWindowPosition(Sender : TObject; Var Action : TCloseAction);
  Var
   Bounds : TRect;
   Placement : TWindowPlacement;
   TargetMonitor : TMonitor;
  Begin
   Bounds := BoundsRect;
   If FFullscreen Then Bounds := FWindowedBounds;
   If Not FFullscreen And (WindowState <> wsNormal) Then
    Begin
     FillChar(Placement, SizeOf(Placement), 0);
     Placement.length := SizeOf(Placement);
     If GetWindowPlacement(Handle, @Placement) Then
      Begin
       Bounds := Placement.rcNormalPosition;
       // WINDOWPLACEMENT uses workspace coordinates for normal top-level windows.
       TargetMonitor := Screen.MonitorFromWindow(Handle);
       OffsetRect(Bounds, TargetMonitor.WorkareaRect.Left - TargetMonitor.BoundsRect.Left,
         TargetMonitor.WorkareaRect.Top - TargetMonitor.BoundsRect.Top);
      End;
    End;
   FSettings.HasPosition := True;
   FSettings.WindowLeft := Bounds.Left;
   FSettings.WindowTop := Bounds.Top;
   ClientSettings.SaveSettings(FConfig, FSettings);
  End;

 Procedure TFMCForm.BeginWindowDrag;
  Begin
   ReleaseCapture;
   SendMessage(Handle, WM_SYSCOMMAND, SC_MOVE Or HTCAPTION, 0);
  End;

 Procedure TFMCForm.Connect(Sender : TObject);
  Begin
   FConnected := False;
   FreeAndNil(FTransport);
   FModel.Reset;
   FModel.Side          := 'capt';
   FModel.State.Overlay := 'Connecting';
   FStatus              := 'Connecting';
   FEndpoint            := '';
   FTransport           := TTransport.Create(FSettings.Host, FSettings.Port, FProfile.Aircraft, FSettings.AutoDiscover);
   ActiveControl        := Nil;
  End;

 Procedure TFMCForm.ApplySide;
  Var
   Side : String;
  Begin
   If Not FProfile.SupportsSide Or Not FConnected Then
    Exit;
   Side := FSettings.Side;
   If FModel.Side = Side Then
    Exit;
   FModel.Reset;
   FModel.Side := Side;
   If Side = 'fo' Then
    FModel.State.Overlay := 'Waiting for FO CDU'
   Else
    FModel.State.Overlay := 'Waiting for Captain CDU';
   FTransport.Send('{"type":"select_side","side":"' + Side + '"}');
  End;

 Function TFMCForm.SkinRect(Const Bounds : TNormRect) : TRect;
  Begin
   With Bounds Do
    Result := Rect(FImage.Left + Round(L * FImage.Width), FImage.Top + Round(T * FImage.Height), FImage.Left + Round(R * FImage.Width), FImage.Top + Round(B * FImage.Height));
  End;

 // Match the client area to the skin without stretching the CDU geometry.
 Procedure TFMCForm.FitBackground(Sender : TObject);
  Var
   Area : TRect;
   FrameWidth, FrameHeight, W, H : Integer;
   Scale : Double;
  Begin
   If FProfile.ScreenOnly Then Exit;
   If (FSkin = Nil) Or (FSkin.Width = 0) Or (FSkin.Height = 0) Then Exit;
   Area := Monitor.WorkareaRect;
   FrameWidth := Width - ClientWidth;
   FrameHeight := Height - ClientHeight;
   Scale := Min(ClientWidth / FSkin.Width, ClientHeight / FSkin.Height);
   Scale := Min(Scale, Max(1, Area.Width - FrameWidth) / FSkin.Width);
   Scale := Min(Scale, Max(1, Area.Height - FrameHeight) / FSkin.Height);
   W := Max(1, Round(FSkin.Width * Scale));
   H := Max(1, Round(FSkin.Height * Scale));
   // Allow the fitted size even on a monitor smaller than the DFM minimum.
   Constraints.MinWidth := Min(Constraints.MinWidth, W + FrameWidth);
   Constraints.MinHeight := Min(Constraints.MinHeight, H + FrameHeight);
   ClientWidth := W;
   ClientHeight := H;
   FPaint.Invalidate;
  End;

 Procedure TFMCForm.PaintCDU(Sender : TObject);
  Begin
   RenderCDU(FPaint.Canvas, FPaint.Width, FPaint.Height)
  End;

 Procedure TFMCForm.RenderCDU(Canvas : TCanvas; Width, Height : Integer);
  Var
   Scale, CW, CH                       : Double;
   R, Col, I, J, X, Y, FontSize, LineH : Integer;
   Screen, A                           : TRect;
   S                                   : String;
   Slot                                : TLedSlot;
   Cell                                : TScreenCell;
  Begin
   If (FModel = Nil) Or (FSkin = Nil) Then Exit;
   Canvas.Brush.Color := clBlack;
   Canvas.FillRect(Rect(0, 0, Width, Height));
   If (Width <= 0) Or (Height <= 0) Then
    Exit;
   If FProfile.ScreenOnly Then Screen := Rect(0, 0, Width, Height)
   Else
    Begin
   Scale  := Min(Width / FSkin.Width, Height / FSkin.Height);
   X      := Round(FSkin.Width * Scale);
   Y      := Round(FSkin.Height * Scale);
   FImage := Rect((Width - X) Div 2, (Height - Y) Div 2, (Width + X) Div 2, (Height + Y) Div 2);
   Canvas.StretchDraw(FImage, FSkin);
   Screen             := SkinRect(FProfile.Screen);
    End;
   Canvas.Brush.Color := clBlack;
   Canvas.FillRect(Screen);
   Canvas.Brush.Style := bsClear;
   CW                 := Screen.Width / 24;
   CH                 := Screen.Height / 14;
   Canvas.Font.Name   := 'B612 Mono';
   Canvas.Font.Style  := [fsBold];
   FontSize := Max(8, Round(CH * 0.80));
   If FProfile.ScreenOnly Then FontSize := Max(8, Round(Min(CH * 0.65, CW * 1.6)));
   If FModel.State.Overlay = '' Then
    Begin
     For R    := 0 To 13 Do
      For Col := 0 To 23 Do
       Begin
        Cell := FModel.State.Cells[R, Col];
        S    := Cell.Symbol;
        If Cell.Small Then
         Canvas.Font.Height := -Max(6, Round(FontSize * 0.72))
        Else
         Canvas.Font.Height := -FontSize;
        Canvas.Font.Color   := Cell.Color;
        // Entry boxes and navigation arrows may be absent from B612 on Windows.
        If (S = #$25AE) Then
         Begin
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := Cell.Color;
          A                  := Rect(Screen.Left + Round((Col + 0.25) * CW), Screen.Top + Round((R + 0.25) * CH), Screen.Left + Round((Col + 0.75) * CW), Screen.Top + Round((R + 0.85) * CH));
          Canvas.FillRect(A);
          Canvas.Brush.Style := bsClear;
         End
        Else
         Begin
          If (S = #$2190) Or (S = #$2191) Or (S = #$2192) Or (S = #$2193) Then
           Canvas.Font.Name := 'Segoe UI Symbol'
          Else
           Canvas.Font.Name := 'B612 Mono';
          Y := Screen.Top + Round((R + 0.90) * CH) - Canvas.TextHeight(S);
          If FProfile.ScreenOnly Then
           Y := Screen.Top + Round(R * CH + Max(0, (CH - Canvas.TextHeight(S)) / 2));
          Canvas.TextOut(Screen.Left + Round((Col + 0.5) * CW) - Canvas.TextWidth(S) Div 2, Y, S);
         End;
       End;
    End
   Else
    Begin
     Canvas.Font.Name   := 'Segoe UI';
     Canvas.Font.Color  := $0000A0FF;
     Canvas.Font.Height := -Max(9, Round(Screen.Height * 0.07));
     A                  := Screen;
     InflateRect(A, -8, -8);
     DrawText(Canvas.Handle, PChar(FModel.State.Overlay), -1, A, DT_CENTER Or DT_WORDBREAK Or DT_NOPREFIX);
    End;
   If FProfile.ScreenOnly Then Exit;
   If Not FProfile.Airbus Then
    Begin
     Canvas.Brush.Style := bsSolid;
     Canvas.Pen.Style   := psClear;
     If FModel.LedOn('EXEC') Then
      Canvas.Brush.Color := clWhite
     Else
      Canvas.Brush.Color := $00282828;
     A                   := SkinRect(FProfile.ExecLed);
     Canvas.RoundRect(A.Left, A.Top, A.Right, A.Bottom, 4, 4);
     Canvas.Pen.Style := psSolid;
    End;
   Canvas.Brush.Style := bsClear;
   Canvas.Font.Name   := 'Consolas';
   Canvas.Font.Height := -Max(8, Round(FImage.Height * 0.0166));
   LineH              := Abs(Canvas.Font.Height);
   For Slot In FProfile.Leds Do
    Begin
     A := SkinRect(Slot.Bounds);
     X := (A.Left + A.Right) Div 2;
     Y := (A.Top + A.Bottom) Div 2;
     If FModel.LedOn(Slot.Name) Then
      Canvas.Font.Color := Slot.ColorOn
     Else
      Canvas.Font.Color := Slot.ColorOff;
     S                  := Slot.Name;
     If Slot.Vertical Then
      Begin
       For J := 1 To Length(S) Do
        Canvas.TextOut(X - Canvas.TextWidth(S[J]) Div 2, Y - Round(Length(S) * LineH / 2) + (J - 1) * LineH, S[J]);
      End
     Else
      Canvas.TextOut(X - Canvas.TextWidth(S) Div 2, Y - Canvas.TextHeight(S) Div 2, S);
    End;
   If (FPressed >= 0) And (GetTickCount64 < FPressedUntil) Then
    Begin
     With FProfile.Hints[FPressed] Do
      A               := SkinRect(NormRect(X - HW, Y - HH, X + HW, Y + HH));
     Canvas.Pen.Color := clSilver;
     If FProfile.Hints[FPressed].Circular Then
      Canvas.Ellipse(A)
     Else
      Canvas.Rectangle(A);
    End;
   Canvas.Brush.Style := bsSolid;
  End;

 Procedure TFMCForm.SendKey(Const Key : String);
  Var
   Obj : TJSONObject;
  Begin
   If Not FConnected Or (FTransport = Nil) Then
    Exit;
   Obj := TJSONObject.Create;
   Try
    Obj.AddPair('type', 'key_press');
    Obj.AddPair('key', Key);
    FTransport.Send(Obj.ToJSON);
    If FSettings.Sound And FileExists(FSoundFile) Then
     PlaySound(PChar(FSoundFile), 0, SND_FILENAME Or SND_ASYNC Or SND_NODEFAULT);
   Finally
    Obj.Free
   End;
  End;

 Procedure TFMCForm.ClickCDU(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
  Var
   I      : Integer;
   NX, NY : Double;
   Function Inside(Const Bounds : TNormRect) : Boolean;
    Begin
     Result := (NX >= Bounds.L) And (NX <= Bounds.R) And
       (NY >= Bounds.T) And (NY <= Bounds.B);
    End;
  Begin
   If FProfile.ScreenOnly Then
    Begin
     If (Button = mbLeft) And (BorderStyle = bsNone) And Not FFullscreen Then BeginWindowDrag;
     Exit;
    End;
   If (Button <> mbLeft) Or Not PtInRect(FImage, Point(X, Y)) Then
    Exit;
   ActiveControl := Nil;
   NX            := (X - FImage.Left) / FImage.Width;
   NY            := (Y - FImage.Top) / FImage.Height;
   With FProfile.CloseButton Do
    If (NX >= L) And (NX <= R) And (NY >= T) And (NY <= B) Then
     Begin
      Close;
      Exit
     End;
   With FProfile.SettingsButton Do
    If (NX >= L) And (NX <= R) And (NY >= T) And (NY <= B) Then
     Begin
      ShowSettings;
      Exit
     End;
   For I := 0 To High(FProfile.Hints) Do
    If (Abs(NX - FProfile.Hints[I].X) <= FProfile.Hints[I].HW) And (Abs(NY - FProfile.Hints[I].Y) <= FProfile.Hints[I].HH) Then
     Begin
      SendKey(FProfile.Hints[I].Key);
      FPressed      := I;
      FPressedUntil := GetTickCount64 + 120;
      FPaint.Invalidate;
      Exit;
     End;
   If BorderStyle <> bsNone Then Exit;
   If Inside(FProfile.Screen) Or Inside(FProfile.ExecLed) Then Exit;
   For I := 0 To High(FProfile.Leds) Do
    If Inside(FProfile.Leds[I].Bounds) Then Exit;
   BeginWindowDrag;
  End;

 Procedure TFMCForm.Keyboard(Sender : TObject; Var Key : Char);
  Var
   K : String;
  Begin
   If (ActiveControl Is TEdit) Or (ActiveControl Is TComboBox) Then
    Exit;
   K := UpCase(Key);
   If CharInSet(Key, ['a' .. 'z', 'A' .. 'Z', '0' .. '9']) Then
    SendKey(K)
   Else
    Case Key Of
     #8 :
      SendKey('CLR');
     #13 :
      If FProfile.Airbus Then
       SendKey('OVFY')
      Else
       SendKey('EXEC');
     ' ' :
      SendKey('SP');
     '.' :
      If FProfile.Airbus Then
       SendKey('DOT')
      Else
       SendKey('.');
     '/' :
      If FProfile.Airbus Then
       SendKey('DIV')
      Else
       SendKey('/');
     '+', '-' :
      If FProfile.Airbus Then
       SendKey('PLUSMINUS')
      Else
       SendKey('+/-');
    End;
   Key := #0;
  End;

 Procedure TFMCForm.Shortcut(Sender : TObject; Var Key : Word; Shift : TShiftState);
  Begin
   If FProfile.ScreenOnly Then
    Begin
     If Key = VK_F11 Then Begin MenuFullscreen(Nil); Key := 0; Exit End;
     If (Key = VK_ESCAPE) And FFullscreen Then Begin MenuFullscreen(Nil); Key := 0; Exit End;
     If Key = VK_F10 Then Begin ShowSettings; Key := 0; Exit End;
    End;
   If (ActiveControl Is TEdit) Or (ActiveControl Is TComboBox) Then
    Exit;
   If (Key >= VK_F1) And (Key <= VK_F6) Then
    Begin
     If ssShift In Shift Then
      SendKey('LSK' + IntToStr(Key - VK_F1 + 1) + 'R')
     Else
      SendKey('LSK' + IntToStr(Key - VK_F1 + 1) + 'L');
     Key := 0;
    End
   Else If FProfile.Airbus Then
    Begin
     Case Key Of
      VK_LEFT :
       SendKey('SLEW_LEFT');
      VK_RIGHT :
       SendKey('SLEW_RIGHT');
      VK_UP :
       SendKey('SLEW_UP');
      VK_DOWN :
       SendKey('SLEW_DOWN');
      VK_PRIOR :
       SendKey('SLEW_LEFT');
      VK_NEXT :
       SendKey('SLEW_RIGHT');
      Else
       Exit
     End;
     Key := 0;
    End
   Else
    Case Key Of
     VK_PRIOR :
      Begin
       SendKey('PREV PAGE');
       Key := 0
      End;
     VK_NEXT :
      Begin
       SendKey('NEXT PAGE');
       Key := 0
      End;
     VK_DELETE :
      Begin
       SendKey('DEL');
       Key := 0
      End;
    End;
  End;

 Procedure TFMCForm.RefocusTick(Sender: TObject);
  Var PID: DWORD;
  Begin
   If Not FSettings.RefocusMSFS Then Exit;
   PID := 0;
   GetWindowThreadProcessId(GetForegroundWindow, @PID);
   If CanRefocus(PID, GetCurrentProcessId, FSettingsOpen, GetCapture <> 0) Then
    RefocusMSFS2024;
  End;

 Procedure TFMCForm.Tick(Sender : TObject);
  Var
   Work : TStringList;
   I    : Integer;
  Begin
   Work := TStringList.Create;
   Try
    If FTransport <> Nil Then
     FTransport.Drain(Work);
    For I := 0 To Work.Count - 1 Do
     Begin
      If Copy(Work[I], 1, 1) = '@' Then
       Begin
        If Copy(Work[I], 1, 10) = '@Endpoint ' Then
         Begin
          FEndpoint := Copy(Work[I], 11, MaxInt);
          Continue;
         End;
        FStatus    := Copy(Work[I], 2, MaxInt);
        FConnected := FStatus = 'Connected';
        If FConnected Then
         Begin
          FModel.Side          := 'capt';
          FModel.State.Overlay := 'Waiting for CDU data';
          ApplySide;
         End
        Else
         Begin
          FModel.Reset;
          FModel.State.Overlay := FStatus
         End;
       End
      Else
       Try
        FModel.Parse(Work[I])
       Except
        On E : Exception Do
         FStatus := 'Invalid server message: ' + E.Message
       End;
     End;
    If (Work.Count > 0) Or (FPressed >= 0) Then
     FPaint.Invalidate;
    If GetTickCount64 >= FPressedUntil Then
     FPressed := -1;
   Finally
    Work.Free
   End;
  End;

End.
