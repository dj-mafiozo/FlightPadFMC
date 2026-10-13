unit SimFocus;
interface
uses Winapi.Windows;
function CanRefocus(ForegroundPID, ClientPID: DWORD; SettingsOpen, Capturing: Boolean): Boolean;
function RefocusMSFS2024: Boolean;
implementation
uses System.SysUtils;
type PWindowHandle = ^HWND;
const QueryLimitedInformation = $1000;
function QueryProcessImage(Process: THandle; Flags: DWORD; Name: PChar; var Size: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'QueryFullProcessImageNameW';
function CanRefocus(ForegroundPID, ClientPID: DWORD; SettingsOpen, Capturing: Boolean): Boolean;
begin
  Result := (ForegroundPID = ClientPID) and (ForegroundPID <> 0) and
    not SettingsOpen and not Capturing;
end;
function FindSimulator(Window: HWND; Data: LPARAM): BOOL; stdcall;
var PID: DWORD; Process: THandle; Size: DWORD; Path: array[0..32767] of Char;
begin
  Result := True;
  if not IsWindowVisible(Window) or (GetWindow(Window, GW_OWNER) <> 0) then Exit;
  GetWindowThreadProcessId(Window, @PID);
  Process := OpenProcess(QueryLimitedInformation, False, PID);
  if Process = 0 then Exit;
  try
    Size := Length(Path);
    if QueryProcessImage(Process, 0, Path, Size) and
      SameText(ExtractFileName(string(Path)), 'FlightSimulator2024.exe') then
    begin
      PWindowHandle(Data)^ := Window;
      Result := False;
    end;
  finally CloseHandle(Process) end;
end;
function RefocusMSFS2024: Boolean;
var Window: HWND;
begin
  Window := 0;
  EnumWindows(@FindSimulator, LPARAM(@Window));
  Result := False;
  if Window = 0 then Exit;
  if IsIconic(Window) then ShowWindow(Window, SW_RESTORE);
  Result := SetForegroundWindow(Window);
end;
end.
