Program FBWA320MCDU;

Uses
 Vcl.Forms,
 FMCMain        In '..\Common\FMCMain.pas' {FMCForm} ,
 AircraftTypes  In '..\Common\AircraftTypes.pas',
 ScreenModel    In '..\Common\ScreenModel.pas',
 Transport      In '..\Common\Transport.pas',
 Profile        In 'Profile.pas',
 ClientSettings In '..\Common\ClientSettings.pas',
 Discovery      In '..\Common\Discovery.pas',
 SettingsForm   In '..\Common\SettingsForm.pas' {SettingsForm};

Begin
 Application.Initialize;
 Application.MainFormOnTaskbar := True;
 Application.CreateForm(TFMCForm, FMCForm);
 Application.Run;
End.
