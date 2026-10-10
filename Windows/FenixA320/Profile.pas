// Geometry and key names from FenixA320/app/src/main/java/com/virtualfmc/fenixa320/MCDUView.java
Unit Profile;

Interface

 Uses
  AircraftTypes;
 Function CreateProfile : TAircraftProfile;

Implementation

 Uses
  Vcl.Graphics;

 Function CreateProfile : TAircraftProfile;
  Begin
   Result.ScreenOnly := False;
   Result.Title          := 'Fenix A320 MCDU';
   Result.Aircraft       := 'FENIXA320';
   Result.SettingsName   := 'FenixA320';
   Result.BackgroundFile := 'background_FenixA320.png';
   Result.SoundFile := 'button_click_FenixA320.wav';
   Result.Airbus         := True;
   Result.Fenix          := True;
   Result.SupportsSide   := False;
   Result.Screen         := NormRect(0.15924072, 0.07854814, 0.8425598, 0.4440826);
   Result.SettingsButton := NormRect(0.0811, 0.0104, 0.1370, 0.0459);
   Result.CloseButton    := NormRect(0.8702, 0.0104, 0.9261, 0.0459);
   Result.ExecLed        := NormRect(0, 0, 0, 0);
   AddHint(Result, 'LSK1L', 0.0566, 0.14510710, 0.025, 0.025, False);
   AddHint(Result, 'LSK2L', 0.0566, 0.19505244, 0.025, 0.025, False);
   AddHint(Result, 'LSK3L', 0.0566, 0.24437086, 0.025, 0.025, False);
   AddHint(Result, 'LSK4L', 0.0566, 0.29550040, 0.025, 0.025, False);
   AddHint(Result, 'LSK5L', 0.0566, 0.34541090, 0.025, 0.025, False);
   AddHint(Result, 'LSK6L', 0.0566, 0.39594835, 0.025, 0.025, False);
   AddHint(Result, 'LSK1R', 0.9473, 0.14510710, 0.025, 0.025, False);
   AddHint(Result, 'LSK2R', 0.9473, 0.19505244, 0.025, 0.025, False);
   AddHint(Result, 'LSK3R', 0.9473, 0.24437086, 0.025, 0.025, False);
   AddHint(Result, 'LSK4R', 0.9473, 0.29550040, 0.025, 0.025, False);
   AddHint(Result, 'LSK5R', 0.9473, 0.34659510, 0.025, 0.025, False);
   AddHint(Result, 'LSK6R', 0.9473, 0.39831677, 0.025, 0.025, False);
   AddHint(Result, 'DIR', 0.16479492, 0.51718944, 0.055, 0.028, False);
   AddHint(Result, 'PROG', 0.28329468, 0.51718944, 0.055, 0.028, False);
   AddHint(Result, 'PERF', 0.39718628, 0.51718944, 0.055, 0.028, False);
   AddHint(Result, 'INIT', 0.51385500, 0.51718944, 0.055, 0.028, False);
   AddHint(Result, 'DATA', 0.63052370, 0.51718944, 0.055, 0.028, False);
   AddHint(Result, 'FPLN', 0.16387940, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'RADNAV', 0.28051758, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'FUELPRED', 0.39535522, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'SECFPLN', 0.51940920, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'ATCCOMM', 0.63421630, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'MCDU_MENU', 0.74996950, 0.5706874, 0.055, 0.028, False);
   AddHint(Result, 'AIRPORT', 0.15924072, 0.6206327, 0.055, 0.028, False);
   AddHint(Result, 'SLEW_LEFT', 0.15924072, 0.67472273, 0.045, 0.030, False);
   AddHint(Result, 'SLEW_UP', 0.27774048, 0.67472273, 0.045, 0.030, False);
   AddHint(Result, 'SLEW_RIGHT', 0.15924072, 0.72585230, 0.045, 0.030, False);
   AddHint(Result, 'SLEW_DOWN', 0.27682495, 0.72585230, 0.045, 0.030, False);
   AddHint(Result, 'A', 0.47219850, 0.65034217, 0.045, 0.028, False);
   AddHint(Result, 'B', 0.56478880, 0.64678960, 0.045, 0.028, False);
   AddHint(Result, 'C', 0.65551760, 0.64797380, 0.045, 0.028, False);
   AddHint(Result, 'D', 0.75274660, 0.64797380, 0.045, 0.028, False);
   AddHint(Result, 'E', 0.84255980, 0.64501330, 0.045, 0.028, False);
   AddHint(Result, 'F', 0.47125244, 0.70620850, 0.045, 0.028, False);
   AddHint(Result, 'G', 0.56756590, 0.70801970, 0.045, 0.028, False);
   AddHint(Result, 'H', 0.65551760, 0.70861170, 0.045, 0.028, False);
   AddHint(Result, 'I', 0.75274660, 0.70979595, 0.045, 0.028, False);
   AddHint(Result, 'J', 0.84625244, 0.70620850, 0.045, 0.028, False);
   AddHint(Result, 'K', 0.47219850, 0.77161810, 0.045, 0.028, False);
   AddHint(Result, 'L', 0.56478880, 0.76803070, 0.045, 0.028, False);
   AddHint(Result, 'M', 0.65921020, 0.76862276, 0.045, 0.028, False);
   AddHint(Result, 'N', 0.75274660, 0.76684650, 0.045, 0.028, False);
   AddHint(Result, 'O', 0.84347534, 0.76803070, 0.045, 0.028, False);
   AddHint(Result, '1', 0.15924072, 0.79063493, 0.045, 0.028, True);
   AddHint(Result, '2', 0.25460815, 0.79063493, 0.045, 0.028, True);
   AddHint(Result, '3', 0.35089110, 0.79063493, 0.045, 0.028, True);
   AddHint(Result, 'P', 0.47219850, 0.82689240, 0.045, 0.028, False);
   AddHint(Result, 'Q', 0.56292725, 0.82985290, 0.045, 0.028, False);
   AddHint(Result, 'R', 0.66107180, 0.82985290, 0.045, 0.028, False);
   AddHint(Result, 'S', 0.74996950, 0.82866865, 0.045, 0.028, False);
   AddHint(Result, 'T', 0.84347534, 0.82866865, 0.045, 0.028, False);
   AddHint(Result, '4', 0.15924072, 0.84235660, 0.045, 0.028, True);
   AddHint(Result, '5', 0.25552368, 0.84235660, 0.045, 0.028, True);
   AddHint(Result, '6', 0.35183716, 0.84235660, 0.045, 0.028, True);
   AddHint(Result, 'U', 0.47219850, 0.88812244, 0.045, 0.028, False);
   AddHint(Result, 'V', 0.56478880, 0.88812244, 0.045, 0.028, False);
   AddHint(Result, 'W', 0.65551760, 0.88693820, 0.045, 0.028, False);
   AddHint(Result, 'X', 0.74902344, 0.88871450, 0.045, 0.028, False);
   AddHint(Result, 'Y', 0.84255980, 0.88871450, 0.045, 0.028, False);
   AddHint(Result, '7', 0.15924072, 0.89822290, 0.045, 0.028, True);
   AddHint(Result, '8', 0.25738525, 0.89703876, 0.045, 0.028, True);
   AddHint(Result, '9', 0.35461426, 0.89345133, 0.045, 0.028, True);
   AddHint(Result, 'DOT', 0.15832520, 0.94994456, 0.045, 0.028, True);
   AddHint(Result, '0', 0.25738525, 0.94694924, 0.045, 0.028, True);
   AddHint(Result, 'PLUSMINUS', 0.35461426, 0.94694924, 0.045, 0.028, True);
   AddHint(Result, 'Z', 0.47125244, 0.94994456, 0.045, 0.028, False);
   AddHint(Result, 'DIV', 0.56201170, 0.94694924, 0.045, 0.028, False);
   AddHint(Result, 'SP', 0.65551760, 0.94517297, 0.045, 0.028, False);
   AddHint(Result, 'OVFY', 0.74996950, 0.94813347, 0.045, 0.028, False);
   AddHint(Result, 'CLR', 0.84347534, 0.94694924, 0.045, 0.028, False);
   AddLed(Result, 'FM1', NormRect(0.2398, 0.0069, 0.3263, 0.0374), False, $0000A0FF, $00001932);
   AddLed(Result, 'FM2', NormRect(0.6755, 0.0073, 0.7620, 0.0378), False, $0000A0FF, $00001932);
   AddLed(Result, 'FM', NormRect(0.0505, 0.7712, 0.0889, 0.8275), True, clWhite, $003C3C3C);
   AddLed(Result, 'IND', NormRect(0.3480, 0.0069, 0.4345, 0.0374), False, $0000A0FF, $00001932);
   AddLed(Result, 'RDY', NormRect(0.4579, 0.0073, 0.5445, 0.0378), False, clLime, $00001E00);
   AddLed(Result, 'FAIL', NormRect(0.0499, 0.6867, 0.0895, 0.7681), True, clRed, $00000032);
   AddLed(Result, 'MCDU MENU', NormRect(0.9123, 0.6852, 0.9513, 0.8295), True, $0000A0FF, $00001932);
   AddLed(Result, 'FM', NormRect(0.5661, 0.0073, 0.6526, 0.0378), False, clWhite, $003C3C3C);
  End;

End.
