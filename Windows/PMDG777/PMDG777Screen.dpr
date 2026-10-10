program PMDG777Screen;
uses Vcl.Forms, FMCMain in '..\Common\FMCMain.pas' {FMCForm},
  ScreenMain in '..\Common\ScreenMain.pas', AircraftTypes, Profile;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TScreenFMCForm, FMCForm);
  Application.Run;
end.
