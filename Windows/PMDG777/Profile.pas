// Geometry and key names from FMC777/app/src/main/java/com/virtualfmc/fmc777/CDUView.java
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
   Result.Title          := 'PMDG 777 FMC';
   Result.Aircraft       := '777';
   Result.SettingsName   := 'PMDG777';
   Result.BackgroundFile := 'background_PMDG777.png';
   Result.SoundFile := 'button_click_PMDG777.wav';
   Result.Airbus         := False;
   Result.Fenix          := False;
   Result.SupportsSide   := True;
   Result.Screen         := NormRect(0.14666007, 0.07033213, 0.84544694, 0.43650627);
   Result.SettingsButton := NormRect(0.0613, 0.0027, 0.1250, 0.0446);
   Result.CloseButton    := NormRect(0.8786, 0.0027, 0.9423, 0.0446);
   Result.ExecLed        := NormRect(0.7782, 0.5377, 0.8714, 0.5569);
   AddHint(Result, 'LSK1L', 0.060290247, 0.13249597, 0.04, 0.025, False);
   AddHint(Result, 'LSK2L', 0.05340007, 0.18277177, 0.04, 0.025, False);
   AddHint(Result, 'LSK3L', 0.057346556, 0.23488782, 0.04, 0.025, False);
   AddHint(Result, 'LSK4L', 0.05340007, 0.28891772, 0.04, 0.025, False);
   AddHint(Result, 'LSK5L', 0.057346556, 0.34103380, 0.04, 0.025, False);
   AddHint(Result, 'LSK6L', 0.057346556, 0.39318663, 0.04, 0.025, False);
   AddHint(Result, 'LSK1R', 0.94161830, 0.12874186, 0.04, 0.025, False);
   AddHint(Result, 'LSK2R', 0.93964505, 0.18402314, 0.04, 0.025, False);
   AddHint(Result, 'LSK3R', 0.94161830, 0.23613920, 0.04, 0.025, False);
   AddHint(Result, 'LSK4R', 0.93964505, 0.28891772, 0.04, 0.025, False);
   AddHint(Result, 'LSK5R', 0.94161830, 0.34103380, 0.04, 0.025, False);
   AddHint(Result, 'LSK6R', 0.93867460, 0.39318663, 0.04, 0.025, False);
   AddHint(Result, 'INIT', 0.1594, 0.5257, 0.04, 0.025, False);
   AddHint(Result, 'RTE', 0.2860, 0.5238, 0.04, 0.025, False);
   AddHint(Result, 'DEP ARR', 0.4057, 0.5257, 0.04, 0.025, False);
   AddHint(Result, 'ALTN', 0.5343, 0.5251, 0.04, 0.025, False);
   AddHint(Result, 'CRZ', 0.6590, 0.5238, 0.04, 0.025, False);
   AddHint(Result, 'FIX', 0.1614, 0.5829, 0.04, 0.025, False);
   AddHint(Result, 'LEGS', 0.2860, 0.5829, 0.04, 0.025, False);
   AddHint(Result, 'HOLD', 0.4087, 0.5816, 0.04, 0.025, False);
   AddHint(Result, 'FMC', 0.5314, 0.5866, 0.04, 0.025, False);
   AddHint(Result, 'PROG', 0.6570, 0.5835, 0.04, 0.025, False);
   AddHint(Result, 'EXEC', 0.8229, 0.5835, 0.04, 0.025, False);
   AddHint(Result, 'MENU', 0.1594, 0.6425, 0.04, 0.025, False);
   AddHint(Result, 'NAV', 0.2831, 0.6432, 0.04, 0.025, False);
   AddHint(Result, 'A', 0.4352, 0.6620, 0.04, 0.025, False);
   AddHint(Result, 'B', 0.5382, 0.6633, 0.04, 0.025, False);
   AddHint(Result, 'C', 0.6413, 0.6614, 0.04, 0.025, False);
   AddHint(Result, 'D', 0.7414, 0.6583, 0.04, 0.025, False);
   AddHint(Result, 'E', 0.8484, 0.6614, 0.04, 0.025, False);
   AddHint(Result, 'PREV PAGE', 0.1614, 0.7060, 0.04, 0.025, False);
   AddHint(Result, 'NEXT PAGE', 0.2831, 0.7066, 0.04, 0.025, False);
   AddHint(Result, 'F', 0.4352, 0.7198, 0.04, 0.025, False);
   AddHint(Result, 'G', 0.5382, 0.7198, 0.04, 0.025, False);
   AddHint(Result, 'H', 0.6423, 0.7198, 0.04, 0.025, False);
   AddHint(Result, 'I', 0.7414, 0.7210, 0.04, 0.025, False);
   AddHint(Result, 'J', 0.8454, 0.7179, 0.04, 0.025, False);
   AddHint(Result, '1', 0.1319, 0.7807, 0.04, 0.025, True);
   AddHint(Result, '2', 0.2281, 0.7807, 0.04, 0.025, True);
   AddHint(Result, '3', 0.3312, 0.7770, 0.04, 0.025, True);
   AddHint(Result, 'K', 0.4352, 0.7807, 0.04, 0.025, False);
   AddHint(Result, 'L', 0.5373, 0.7770, 0.04, 0.025, False);
   AddHint(Result, 'M', 0.6423, 0.7776, 0.04, 0.025, False);
   AddHint(Result, 'N', 0.7463, 0.7807, 0.04, 0.025, False);
   AddHint(Result, 'O', 0.8454, 0.7770, 0.04, 0.025, False);
   AddHint(Result, '4', 0.1300, 0.8385, 0.04, 0.025, True);
   AddHint(Result, '5', 0.2311, 0.8367, 0.04, 0.025, True);
   AddHint(Result, '6', 0.3223, 0.8373, 0.04, 0.025, True);
   AddHint(Result, 'P', 0.4352, 0.8367, 0.04, 0.025, False);
   AddHint(Result, 'Q', 0.5382, 0.8385, 0.04, 0.025, False);
   AddHint(Result, 'R', 0.6384, 0.8367, 0.04, 0.025, False);
   AddHint(Result, 'S', 0.7404, 0.8385, 0.04, 0.025, False);
   AddHint(Result, 'T', 0.8484, 0.8367, 0.04, 0.025, False);
   AddHint(Result, '7', 0.1261, 0.8963, 0.04, 0.025, True);
   AddHint(Result, '8', 0.2291, 0.8951, 0.04, 0.025, True);
   AddHint(Result, '9', 0.3272, 0.8951, 0.04, 0.025, True);
   AddHint(Result, 'U', 0.4382, 0.8951, 0.04, 0.025, False);
   AddHint(Result, 'V', 0.5373, 0.8944, 0.04, 0.025, False);
   AddHint(Result, 'W', 0.6384, 0.8951, 0.04, 0.025, False);
   AddHint(Result, 'X', 0.7414, 0.8951, 0.04, 0.025, False);
   AddHint(Result, 'Y', 0.8454, 0.8963, 0.04, 0.025, False);
   AddHint(Result, '.', 0.1270, 0.9522, 0.04, 0.025, True);
   AddHint(Result, '0', 0.2281, 0.9528, 0.04, 0.025, True);
   AddHint(Result, '+/-', 0.3272, 0.9560, 0.04, 0.025, True);
   AddHint(Result, 'Z', 0.4352, 0.9528, 0.04, 0.025, False);
   AddHint(Result, 'SP', 0.5382, 0.9522, 0.04, 0.025, False);
   AddHint(Result, 'DEL', 0.6413, 0.9528, 0.04, 0.025, False);
   AddHint(Result, '/', 0.7444, 0.9560, 0.04, 0.025, False);
   AddHint(Result, 'CLR', 0.8425, 0.9522, 0.04, 0.025, False);
   AddLed(Result, 'DSPY', NormRect(0.0343, 0.6762, 0.0745, 0.7442), True, clWhite, $00505050);
   AddLed(Result, 'FAIL', NormRect(0.0349, 0.7473, 0.0745, 0.8215), True, clRed, $00000050);
   AddLed(Result, 'MSG', NormRect(0.9237, 0.6758, 0.9639, 0.7350), True, clWhite, $00505050);
   AddLed(Result, 'OFST', NormRect(0.9237, 0.7362, 0.9639, 0.8215), True, $0000A0FF, $00003250);
  End;

End.
