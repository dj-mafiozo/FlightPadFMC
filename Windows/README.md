# FlightPadFMC - Native Windows clients

Native Delphi VCL Win32 applications for the existing FlightPadFMCServer.
The aircraft in MSFS runs the FMC logic; these clients display its output
and forward key presses. No browser is required.

| Aircraft | Full CDU/MCDU | Screen-only display | Server identifier |
| --- | --- | --- | --- |
| PMDG 737 | PMDG737FMC.exe | PMDG737Screen.exe | 737 |
| PMDG 777 | PMDG777FMC.exe | PMDG777Screen.exe | 777 |
| FlyByWire A320 | FBWA320MCDU.exe | FBWA320Screen.exe | A320 |
| Fenix A320 | FenixA320MCDU.exe | FenixA320Screen.exe | FENIXA320 |
| iFly 737 MAX | iFlyFMC.exe | iFlyScreen.exe | IFLY737MAX |

## Physical DIY FMC/MCDU panels

The **Screen** executables are intended as displays for physical DIY
FMC/MCDU panels. Mount a suitable monitor behind the panel bezel and run
the matching screen-only client. It renders only the scalable CDU/MCDU
screen, without a graphical keypad or aircraft skin.

The physical keypad needs its own input integration. These clients retain
PC keyboard input; direct Arduino, HID or serial device integration is not
included. Full clients provide the aircraft skin and clickable keys for
normal desktop use.

## Getting started

1. Start MSFS and load the matching aircraft.
2. Configure its bridge as described in the main repository README:
   PMDG SDK/CDU broadcast, FBW SimBridge, Fenix GraphQL or the iFly plugin.
3. Run `FlightPadFMCServer.exe` from the repository's `dist` directory.
4. Extract `packages/FlightPadFMC-Windows.zip` and launch the matching EXE.
   Keep the `assets` directory beside the executables.

The combined ZIP contains all ten EXEs in one directory with shared assets.
Each aircraft package contains both its full and screen-only clients.
Backgrounds and sounds use aircraft-specific names, avoiding collisions;
B612 Mono is shared. Runtime packages are not required.

## Settings and window modes

Open Settings using the skin button in a full client, or right-click / **F10**
in a screen-only client. Settings includes connection mode, host, port,
button sound, connection status and CDU side. **Save** validates and applies
changes; **Cancel** discards them. Haptic feedback is unavailable on Windows.

- **Auto (mDNS)** searches for `_flightpadfmc._tcp.local` over IPv4 for up to
  15 seconds, then falls back to the configured host and port.
- **Manual IP** uses the saved endpoint directly. Default fallback:
  `127.0.0.1:8765`.
- **CDU Side** is visible for every profile and enabled only when supported
  (PMDG 737 and PMDG 777). First Officer CDU requires CDU.1 broadcasting.
- **Hide title bar and window borders** removes the main window frame.
- **Fullscreen**, available in screen-only clients, is independent of the
  borderless preference. **F11** toggles it; **Esc** returns to the previous
  window bounds and selected frame style on the current monitor.

Drag a borderless full client by unused skin areas outside buttons, the
screen and annunciators. Drag a borderless screen-only client by its display
when not in fullscreen. Closing saves the window position; startup restores
it to an available monitor's work area.

Preferences are stored in the user's home directory under `FlightPadFMC`:
`<profile>Windows.ini` for full clients and `<profile>ScreenWindows.ini` for
display clients. iFly uses `iFlyWindows.ini` and `iFlyScreenWindows.ini`.
Each variant has independent settings. After disconnecting, the client clears
its display/annunciators and retries approximately every three seconds.
PMDG side selection is restored after reconnection; stale updates for the
previous side are ignored.

## Keyboard controls

- Letters and digits: corresponding CDU/MCDU keys.
- Space: SP; Backspace: CLR; punctuation: corresponding symbol keys.
- Enter: Boeing EXEC or Airbus OVFY.
- F1-F6: left LSKs; Shift+F1-F6: right LSKs.
- Page Up / Page Down: Boeing PREV/NEXT PAGE or Airbus SLEW LEFT/RIGHT.
- Arrow keys: Airbus SLEW keys.
- Delete: Boeing DEL.

Screen-only clients reserve F10 for Settings, F11 for fullscreen and Esc
for leaving fullscreen. Mouse/touch hit maps in full clients come from
the Android aircraft profiles.

## Rendering and shared code

Both screen formats use a 14 x 24 grid. Boeing clients support colors, EXEC
and aircraft annunciators, including the legacy `exec_led` message. Airbus
clients support small/large text, colors within a line, left/right/center
alignment, scratchpad, arrows and input blocks. The parser accepts JSON
and the SimBridge `update:` prefix. Screen-only clients render the grid;
full clients also render the skin and annunciators.

All clients, including iFly, share `Common`: transport, mDNS discovery,
screen parsing/rendering, settings and profile types. Each aircraft's
`Profile.pas` defines geometry, keys, annunciators and server identity.
`Common/FMCMain.dfm` and `Common/SettingsForm.dfm` are editable in the Delphi
form designer and compiled into the EXEs.

## Building and compiler compatibility

Use Delphi with VCL, the Win32 compiler and the bundled Indy libraries.
**Delphi 10 and later are the intended compiler family.** Builds and local
tests have been verified with Delphi 10.2; other compiler versions have not
yet been tested here. No feature specifically requires Delphi 10.2.

The earliest source-compatible candidate is **Delphi XE8**, because
`Transport.pas` uses `System.Hash.THashSHA1`, introduced in XE8. This is a
source/API assessment, not a verified XE8 build. Older IDEs may need project
metadata migration; build scripts also need the appropriate installation
path. See [Embarcadero's System.Hash history](https://blogs.embarcadero.com/sha-hash-with-c-builder-and-delphi/).

Open `FlightPadFMC.groupproj` or an aircraft DPR/DPROJ in the IDE and build.
Alternatively, run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File Windows/build.ps1 -DelphiRoot "C:\Path\To\Delphi"
```

The installation path defaults to the compiler used for the verified build;
it can be changed with `-DelphiRoot`. `build.cmd` is a convenience wrapper.
Add `-Test` to build and run the tests (Python 3 required). The script builds
all ten EXEs, individual aircraft ZIPs and the combined Windows ZIP.

`tools/generate_profiles.py` extracts geometry, keys and assets from the
checked-in Android sources. It regenerates full-client profiles and DPRs;
review any custom profile edits before using it.

## Verification and limits

Local tests cover actual VCL forms and input handlers, aircraft identification,
both screen formats, colors, text sizing/alignment, special symbols,
annunciators, malformed data, Captain/FO selection, reconnect, fragmented
WebSocket frames, ping/pong and shutdown. Settings tests cover validation,
Save/Cancel, persistence, profile-dependent side controls, borderless mode,
drag hit areas and window-position restoration. Screen tests cover rendering,
context menus, independent fullscreen, restart and main-form registration.
Separate mDNS tests cover compressed/split PTR/SRV/A responses, pointer loops,
cancellation and local UDP discovery. Rendering previews are generated in
`tests/build`.

Simulator integration still needs verification with a running MSFS aircraft
and the real FlightPadFMCServer. Haptics and long key presses are not
implemented. Windows clients require the existing server and aircraft bridge.

Skins, fonts and sounds originate from the Android modules in this repository.
See the repository root `LICENSE` for licensing.
Windows client development: © 2026 DJ M@fi0zo™.
