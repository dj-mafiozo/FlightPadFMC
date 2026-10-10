# FlyByWire A320 - Native Windows clients

- **FBWA320MCDU.exe**: full CDU/MCDU skin with clickable keys and PC keyboard input.
- **FBWA320Screen.exe**: scalable display for a physical DIY FMC/MCDU panel,
  without a graphical keypad. Physical keypad integration is supplied by
  your panel setup; the client accepts PC keyboard input.

Run MSFS with the matching aircraft and FlightPadFMCServer, then launch
one of the clients. Keep `assets` beside the EXE. Full and screen-only
variants store their preferences separately.

The skin Settings button opens configuration in the full client. In the
screen-only client use right-click or F10; F11 toggles fullscreen and Esc
leaves it. Borderless and fullscreen settings are independent. Window
positions are restored on startup.

Aircraft resources: `assets/background_FBWA320.png`,
`assets/button_click_FBWA320.wav` and the shared B612 Mono font.
All aircraft EXEs can share a directory and its assets folder.

Delphi VCL / Win32; intended for Delphi 10 and later. Local builds and tests
were verified with Delphi 10.2; other versions remain unverified. XE8 is the
earliest source-compatible candidate based on the RTL APIs in use.

Projects: `FBWA320MCDU.dpr` / `FBWA320Screen.dpr` (DPROJ files included).
Shared forms: `../Common/FMCMain.dfm` and `../Common/SettingsForm.dfm`.

See [Windows documentation](../README.md) for setup, controls, compiler
compatibility, building and tests. See the root LICENSE for licensing.
Windows client development: © 2026 DJ M@fi0zo™.
