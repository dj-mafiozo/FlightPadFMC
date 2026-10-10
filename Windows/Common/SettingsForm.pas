Unit SettingsForm;

Interface

 Uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, ClientSettings, AircraftTypes;

 Type
  TSettingsForm = Class(TForm)
   Published
    ConnectionMode, DefaultSide                                     : TRadioGroup;
    ServerHost, ServerPort                                          : TEdit;
    FullscreenWindow, BorderlessWindow, ButtonSound, HapticFeedback : TCheckBox;
    HeaderLabel, HelpLabel, HostLabel, PortLabel, FallbackLabel     : TLabel;
    ErrorLabel, StatusLabel                                         : TLabel;
    SaveButton, CancelButton                                        : TButton;
    SideSection                                                     : TPanel;
    Procedure SaveClick(Sender : TObject);
   Private
    FValues : TClientSettings;
   Public
    Constructor CreateSettings(AOwner : TComponent; Const P : TAircraftProfile; Const Values : TClientSettings; Const Status : String);
    Function TryAccept : Boolean;
    Property Values : TClientSettings Read FValues;
  End;

Implementation

 {$R *.dfm}

 Constructor TSettingsForm.CreateSettings(AOwner : TComponent; Const P : TAircraftProfile; Const Values : TClientSettings; Const Status : String);
  Begin
   Inherited Create(AOwner);
   Caption                  := P.Title + ' - Settings';
   FValues                  := Values;
   FullscreenWindow.Visible := P.ScreenOnly;
   FullscreenWindow.Checked := Values.Fullscreen;
   If Values.AutoDiscover Then
    ConnectionMode.ItemIndex := 0
   Else
    ConnectionMode.ItemIndex := 1;
   ServerHost.Text           := Values.Host;
   ServerPort.Text           := IntToStr(Values.Port);
   ButtonSound.Checked       := Values.Sound;
   BorderlessWindow.Checked  := Values.Borderless;
   If Values.Side = 'fo' Then
    DefaultSide.ItemIndex := 1
   Else
    DefaultSide.ItemIndex := 0;
   DefaultSide.Visible    := True;
   SideSection.Visible    := True;
   DefaultSide.Enabled    := P.SupportsSide;
   If Not P.SupportsSide Then
    DefaultSide.ItemIndex := 0;
   StatusLabel.Caption    := 'Connection: ' + Status;
  End;

 Function TSettingsForm.TryAccept : Boolean;
  Var
   Candidate : TClientSettings;
   Error     : String;
  Begin
   Candidate      := FValues;
   Candidate.Host := Trim(ServerHost.Text);
   If Not TryStrToInt(ServerPort.Text, Candidate.Port) Then
    Candidate.Port        := 0;
   Candidate.AutoDiscover := ConnectionMode.ItemIndex = 0;
   Candidate.Sound        := ButtonSound.Checked;
   Candidate.Borderless   := BorderlessWindow.Checked;
   Candidate.Fullscreen   := FullscreenWindow.Visible And FullscreenWindow.Checked;
   Candidate.Side         := 'capt';
   If DefaultSide.Enabled And (DefaultSide.ItemIndex = 1) Then
    Candidate.Side    := 'fo';
   Result             := ValidateSettings(Candidate, Error);
   ErrorLabel.Caption := Error;
   If Result Then
    FValues := Candidate;
  End;

 Procedure TSettingsForm.SaveClick(Sender : TObject);
  Begin
   If TryAccept Then
    ModalResult := mrOk
  End;

End.
