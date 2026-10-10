// Geometry and key names from iFly737MAX/app/src/main/java/com/virtualfmc/ifly737max/CDUView.java
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
   Result.Title          := 'iFly 737 MAX FMC';
   Result.Aircraft       := 'IFLY737MAX';
   Result.SettingsName   := 'iFly';
   Result.BackgroundFile := 'background_iFly737MAX.png';
   Result.SoundFile := 'button_click_iFly737MAX.wav';
   Result.Airbus         := False;
   Result.Fenix          := False;
   Result.SupportsSide   := False;
   Result.Screen         := NormRect(0.1457, 0.0792, 0.8592, 0.4427);
   Result.SettingsButton := NormRect(0.0921, 0.0071, 0.1606, 0.0500);
   Result.CloseButton    := NormRect(0.8417, 0.0048, 0.9163, 0.0529);
   Result.ExecLed        := NormRect(0.7839, 0.5624, 0.8676, 0.5824);
   AddHint(Result, 'LSK1L', 0.0467, 0.1554, 0.035, 0.025, False);
   AddHint(Result, 'LSK2L', 0.0487, 0.2025, 0.035, 0.025, False);
   AddHint(Result, 'LSK3L', 0.0467, 0.2514, 0.035, 0.025, False);
   AddHint(Result, 'LSK4L', 0.0467, 0.3003, 0.035, 0.025, False);
   AddHint(Result, 'LSK5L', 0.0487, 0.3510, 0.035, 0.025, False);
   AddHint(Result, 'LSK6L', 0.0517, 0.4012, 0.035, 0.025, False);
   AddHint(Result, 'LSK1R', 0.9532, 0.1554, 0.035, 0.025, False);
   AddHint(Result, 'LSK2R', 0.9552, 0.2025, 0.035, 0.025, False);
   AddHint(Result, 'LSK3R', 0.9552, 0.2532, 0.035, 0.025, False);
   AddHint(Result, 'LSK4R', 0.9552, 0.3021, 0.035, 0.025, False);
   AddHint(Result, 'LSK5R', 0.9552, 0.3510, 0.035, 0.025, False);
   AddHint(Result, 'LSK6R', 0.9562, 0.4000, 0.035, 0.025, False);
   AddHint(Result, 'INIT REF', 0.1635, 0.5430, 0.055, 0.025, False);
   AddHint(Result, 'RTE', 0.2922, 0.5411, 0.055, 0.025, False);
   AddHint(Result, 'DEP ARR', 0.4149, 0.5393, 0.055, 0.025, False);
   AddHint(Result, 'ATC', 0.5405, 0.5393, 0.055, 0.025, False);
   AddHint(Result, 'VNAV', 0.6642, 0.5418, 0.055, 0.025, False);
   AddHint(Result, 'FIX', 0.1675, 0.5969, 0.055, 0.025, False);
   AddHint(Result, 'LEGS', 0.2882, 0.5981, 0.055, 0.025, False);
   AddHint(Result, 'HOLD', 0.4149, 0.5969, 0.055, 0.025, False);
   AddHint(Result, 'FMC COMM', 0.5405, 0.5969, 0.055, 0.025, False);
   AddHint(Result, 'PROG', 0.6632, 0.5981, 0.055, 0.025, False);
   AddHint(Result, 'EXEC', 0.8295, 0.6018, 0.055, 0.025, False);
   AddHint(Result, 'MENU', 0.1635, 0.6588, 0.055, 0.025, False);
   AddHint(Result, 'N1 LIMIT', 0.2882, 0.6563, 0.055, 0.025, False);
   AddHint(Result, 'PREV PAGE', 0.1615, 0.7151, 0.055, 0.025, False);
   AddHint(Result, 'NEXT PAGE', 0.2941, 0.7151, 0.055, 0.025, False);
   AddHint(Result, 'A', 0.4554, 0.6607, 0.045, 0.025, False);
   AddHint(Result, 'B', 0.5544, 0.6619, 0.045, 0.025, False);
   AddHint(Result, 'C', 0.6543, 0.6607, 0.045, 0.025, False);
   AddHint(Result, 'D', 0.7503, 0.6607, 0.045, 0.025, False);
   AddHint(Result, 'E', 0.8473, 0.6588, 0.045, 0.025, False);
   AddHint(Result, 'F', 0.4584, 0.7176, 0.045, 0.025, False);
   AddHint(Result, 'G', 0.5554, 0.7189, 0.045, 0.025, False);
   AddHint(Result, 'H', 0.6494, 0.7189, 0.045, 0.025, False);
   AddHint(Result, 'I', 0.7513, 0.7157, 0.045, 0.025, False);
   AddHint(Result, 'J', 0.8453, 0.7195, 0.045, 0.025, False);
   AddHint(Result, '1', 0.1487, 0.7789, 0.045, 0.025, True);
   AddHint(Result, '2', 0.2506, 0.7789, 0.045, 0.025, True);
   AddHint(Result, '3', 0.3506, 0.7770, 0.045, 0.025, True);
   AddHint(Result, 'K', 0.4554, 0.7770, 0.045, 0.025, False);
   AddHint(Result, 'L', 0.5524, 0.7752, 0.045, 0.025, False);
   AddHint(Result, 'M', 0.6573, 0.7789, 0.045, 0.025, False);
   AddHint(Result, 'N', 0.7503, 0.7777, 0.045, 0.025, False);
   AddHint(Result, 'O', 0.8503, 0.7789, 0.045, 0.025, False);
   AddHint(Result, '4', 0.1536, 0.8365, 0.045, 0.025, True);
   AddHint(Result, '5', 0.2506, 0.8365, 0.045, 0.025, True);
   AddHint(Result, '6', 0.3466, 0.8365, 0.045, 0.025, True);
   AddHint(Result, 'P', 0.4525, 0.8365, 0.045, 0.025, False);
   AddHint(Result, 'Q', 0.5544, 0.8359, 0.045, 0.025, False);
   AddHint(Result, 'R', 0.6494, 0.8365, 0.045, 0.025, False);
   AddHint(Result, 'S', 0.7483, 0.8365, 0.045, 0.025, False);
   AddHint(Result, 'T', 0.8453, 0.8340, 0.045, 0.025, False);
   AddHint(Result, '7', 0.1487, 0.8922, 0.045, 0.025, True);
   AddHint(Result, '8', 0.2506, 0.8928, 0.045, 0.025, True);
   AddHint(Result, '9', 0.3466, 0.8922, 0.045, 0.025, True);
   AddHint(Result, 'U', 0.4554, 0.8947, 0.045, 0.025, False);
   AddHint(Result, 'V', 0.5544, 0.8947, 0.045, 0.025, False);
   AddHint(Result, 'W', 0.6543, 0.8947, 0.045, 0.025, False);
   AddHint(Result, 'X', 0.7503, 0.8947, 0.045, 0.025, False);
   AddHint(Result, 'Y', 0.8453, 0.8947, 0.045, 0.025, False);
   AddHint(Result, '.', 0.1536, 0.9523, 0.045, 0.025, True);
   AddHint(Result, '0', 0.2506, 0.9523, 0.045, 0.025, True);
   AddHint(Result, '+/-', 0.3495, 0.9523, 0.045, 0.025, True);
   AddHint(Result, 'Z', 0.4535, 0.9523, 0.045, 0.025, False);
   AddHint(Result, 'SP', 0.5544, 0.9535, 0.045, 0.025, False);
   AddHint(Result, 'DEL', 0.6514, 0.9510, 0.045, 0.025, False);
   AddHint(Result, '/', 0.7483, 0.9510, 0.045, 0.025, False);
   AddHint(Result, 'CLR', 0.8473, 0.9523, 0.045, 0.025, False);
   AddLed(Result, 'CALL', NormRect(0.0441, 0.7100, 0.0868, 0.7829), True, clWhite, $00505050);
   AddLed(Result, 'FAIL', NormRect(0.0434, 0.7876, 0.0875, 0.8605), True, clRed, $00000050);
   AddLed(Result, 'MSG', NormRect(0.9132, 0.7095, 0.9589, 0.7838), True, clWhite, $00505050);
   AddLed(Result, 'OFST', NormRect(0.9140, 0.7876, 0.9589, 0.8605), True, $0000A0FF, $00003250);
  End;

End.
