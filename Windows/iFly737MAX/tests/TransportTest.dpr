program TransportTest;
{$APPTYPE CONSOLE}
uses Winapi.Windows, System.SysUtils, System.Classes, Transport in '..\..\Common\Transport.pas';
var T: TTransport; Items: TStringList; Deadline: UInt64; I, Connections, Disconnections: Integer;
  GotMessage: Boolean;
begin
  T := TTransport.Create('127.0.0.1',18765,'IFLY737MAX'); Items := TStringList.Create;
  Connections := 0; Disconnections := 0; GotMessage := False;
  try
    Deadline := GetTickCount64+12000;
    while GetTickCount64 < Deadline do begin
      T.Drain(Items);
      for I := 0 to Items.Count-1 do begin
        Writeln(Items[I]);
        if Pos('@Disconnected',Items[I]) = 1 then Inc(Disconnections);
        if Items[I] = '@Connected' then begin
          Inc(Connections); T.Send('{"type":"key_press","key":"EXEC"}');
        end;
        if Items[I] = '{"type":"status_message","text":"fragmented"}' then GotMessage := True;
      end;
      if GotMessage and (Connections >= 2) and (Disconnections >= 2) then Break;
      Sleep(20);
    end;
  finally T.Free; Items.Free end;
  if not GotMessage or (Connections < 2) or (Disconnections < 2) then Halt(1);
end.

