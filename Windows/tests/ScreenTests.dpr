Program ScreenTests;
{$APPTYPE CONSOLE}

Uses
 Winapi.Windows, System.SysUtils, System.IOUtils, System.Types,
 Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, AircraftTypes, Profile, FMCMain,
 ClientSettings, SettingsForm, ScreenMain, SimFocus;

Var
 F             : TFMCForm;
 P             : TAircraftProfile;
 S             : TClientSettings;
 B             : TBitmap;
 I, J, Colored : Integer;
 D             : TSettingsForm;
 Config        : String;
 Bounds, Full  : TRect;

Procedure Check(Value : Boolean; Const Text : String);
 Begin
  If Not Value Then
   Raise Exception.Create(Text)
 End;

Begin
 Try
  Check(CanRefocus(5,5,False,False),'Refocus allowed for client foreground');
  Check(Not CanRefocus(6,5,False,False),'Refocus does not steal other app focus');
  Check(Not CanRefocus(5,5,True,False),'Settings pauses refocus');
  Check(Not CanRefocus(5,5,False,True),'Mouse capture pauses refocus');
  Application.Initialize;
  P            := CreateProfile;
  P.ScreenOnly := True;
  Config       := TPath.Combine(ExtractFilePath(ParamStr(0)), 'screen-test.ini');
  S            := DefaultSettings;
  D := TSettingsForm.CreateSettings(Nil, P, S, 'Test');
  Try
   Check(Not D.RefocusMSFS.Checked, 'Refocus defaults off');
   D.RefocusMSFS.Checked := True;
   D.RefocusInterval.Text := '0';
   Check(Not D.TryAccept, 'Refocus interval rejects zero');
   D.RefocusInterval.Text := '3';
   Check(D.TryAccept, 'Refocus options accepted');
   S := D.Values;
  Finally D.Free End;
  ClientSettings.SaveSettings(Config, S);
  S := ClientSettings.LoadSettings(Config);
  Check(S.RefocusMSFS And (S.RefocusSeconds = 3), 'Refocus persistence');
  S.RefocusMSFS := False;
  ClientSettings.SaveSettings(Config, S);
  F := TFMCForm.CreateConfigured(Nil, P, ParamStr(1), Config, False);
  B := TBitmap.Create;
  Try
   F.HandleNeeded;
   Check(F.FPaint.PopupMenu = F.ScreenMenu, 'Screen context menu');
   If P.Airbus Then
    F.Model.Parse(TFile.ReadAllText(TPath.Combine(ParamStr(2), 'airbus.json'), TEncoding.UTF8))
   Else
    F.Model.Parse(TFile.ReadAllText(TPath.Combine(ParamStr(2), 'boeing.json'), TEncoding.UTF8));
   Check(F.Model.State.Cells[0, 0].Symbol = 'T', 'Screen receives aircraft data');
   B.SetSize(900, 350);
   F.RenderCDU(B.Canvas, B.Width, B.Height);
   Check(B.Canvas.Pixels[0, 0] = clBlack, 'Screen has no skin');
   Colored := 0;
   For I   := 0 To 70 Do
    For J  := 0 To 30 Do
     If B.Canvas.Pixels[I, J] <> clBlack Then
      Inc(Colored);
   Check(Colored > 0, 'Scaled screen renders first row text');
   B.SaveToFile(TPath.Combine(ExtractFilePath(ParamStr(0)), 'screen-preview.bmp'));
   B.SetSize(400, 650);
   F.RenderCDU(B.Canvas, B.Width, B.Height);
   B.SaveToFile(TPath.Combine(ExtractFilePath(ParamStr(0)), 'screen-tall.bmp'));
   S            := F.Settings;
   S.Borderless := True;
   F.UpdateSettings(S, False);
   Check(F.BorderStyle = bsNone, 'Screen borderless');
   Bounds       := F.BoundsRect;
   Full         := F.Monitor.BoundsRect;
   S.Fullscreen := True;
   F.UpdateSettings(S, False);
   Check((F.BorderStyle = bsNone) And EqualRect(F.BoundsRect, Full), 'Fullscreen covers monitor');
   S.Fullscreen := False;
   F.UpdateSettings(S, False);
   Check(EqualRect(F.BoundsRect, Bounds) And (F.BorderStyle = bsNone), 'Fullscreen restores borderless window');
   S.Borderless := False;
   F.UpdateSettings(S, False);
   Check(F.BorderStyle = bsSizeable, 'Screen frame restored');
   D := TSettingsForm.CreateSettings(Nil, P, S, 'Test');
   Try
    Check(D.FullscreenWindow.Visible, 'Fullscreen setting available')
   Finally
    D.Free
   End;
   S.Fullscreen := True;
   F.UpdateSettings(S, False);
   F.Close;
  Finally
   B.Free;
   F.Free
  End;
  F := TFMCForm.CreateConfigured(Nil, P, ParamStr(1), Config, False);
  Try
   Check(F.Settings.Fullscreen And EqualRect(F.BoundsRect, F.Monitor.BoundsRect), 'Fullscreen persists across restart');
   F.MenuFullscreen(Nil);
   Check(F.BorderStyle = bsSizeable, 'Exit persisted fullscreen');
  Finally
   F.Free
  End;
  Application.CreateForm(TScreenFMCForm, F);
  Try
   Check(Application.MainForm = F, 'Screen EXE registers a main form for Application.Run');
   Check(Application.ShowMainForm, 'Application.Run will show screen main form');
  Finally
   F.Free
  End;
  Writeln('PASS ', P.Aircraft, ': screen rendering, context menu, borderless, independent fullscreen, restart');
 Except
  On E : Exception Do
   Begin
    Writeln(E.ClassName, ': ', E.Message);
    Halt(1)
   End
 End;

End.
