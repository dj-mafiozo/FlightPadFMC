program GuiSmoke;
{$APPTYPE CONSOLE}
uses System.SysUtils, Vcl.Forms, Vcl.Graphics,
  FMCMain in '..\..\Common\FMCMain.pas', Profile in '..\Profile.pas',
  Transport in '..\..\Common\Transport.pas';
var F: TFMCForm; B: TBitmap;
begin
  Application.Initialize;
  F := TFMCForm.CreateConfigured(nil,CreateProfile,ExtractFilePath(ParamStr(0))+'..\','',False); B := TBitmap.Create;
  try
    F.HandleNeeded; Application.ProcessMessages;
    B.SetSize(F.ClientWidth,F.ClientHeight);
    F.PaintTo(B.Canvas.Handle,0,0);
    B.SaveToFile('gui-preview.bmp');
    Writeln('PASS: VCL construction, assets, painting, worker shutdown');
  finally B.Free; F.Free end;
end.
