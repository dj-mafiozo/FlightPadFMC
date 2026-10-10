unit ScreenMain;
interface
uses System.Classes, FMCMain;
type
  TScreenFMCForm = class(TFMCForm)
  public
    constructor Create(AOwner: TComponent); override;
  end;
implementation
uses System.SysUtils, System.IOUtils, AircraftTypes, Profile;
constructor TScreenFMCForm.Create(AOwner: TComponent);
var P: TAircraftProfile;
begin
  P := CreateProfile;
  P.ScreenOnly := True;
  inherited CreateConfigured(AOwner, P, ExtractFilePath(ParamStr(0)),
    TPath.Combine(TPath.GetHomePath, 'FlightPadFMC\' + P.SettingsName + 'ScreenWindows.ini'), True);
end;
end.
