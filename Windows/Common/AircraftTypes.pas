Unit AircraftTypes;

Interface

 Uses
  Vcl.Graphics;

 Type
  TNormRect = Record
   L, T, R, B : Double;
  End;

  TButtonHint = Record
   Key          : String;
   X, Y, HW, HH : Double;
   Circular     : Boolean;
  End;

  TLedSlot = Record
   Name              : String;
   Bounds            : TNormRect;
   Vertical          : Boolean;
   ColorOn, ColorOff : TColor;
  End;

  TAircraftProfile = Record
   ScreenOnly : Boolean;
   Title, Aircraft, SettingsName                : String;
   BackgroundFile, SoundFile                    : String;
   Airbus, Fenix, SupportsSide                  : Boolean;
   Screen, SettingsButton, CloseButton, ExecLed : TNormRect;
   Hints                                        : TArray<TButtonHint>;
   Leds                                         : TArray<TLedSlot>;
  End;

 Function NormRect(L, T, R, B : Double) : TNormRect;
 Procedure AddHint(Var P : TAircraftProfile; Const Key : String; X, Y, HW, HH : Double; Circular : Boolean);
 Procedure AddLed(Var P : TAircraftProfile; Const Name : String; Bounds : TNormRect; Vertical : Boolean; ColorOn, ColorOff : TColor);

Implementation

 Function NormRect(L, T, R, B : Double) : TNormRect;
  Begin
   Result.L := L;
   Result.T := T;
   Result.R := R;
   Result.B := B
  End;

 Procedure AddHint(Var P : TAircraftProfile; Const Key : String; X, Y, HW, HH : Double; Circular : Boolean);
  Var
   N : Integer;
  Begin
   N := Length(P.Hints);
   SetLength(P.Hints, N + 1);
   P.Hints[N].Key      := Key;
   P.Hints[N].X        := X;
   P.Hints[N].Y        := Y;
   P.Hints[N].HW       := HW;
   P.Hints[N].HH       := HH;
   P.Hints[N].Circular := Circular;
  End;

 Procedure AddLed(Var P : TAircraftProfile; Const Name : String; Bounds : TNormRect; Vertical : Boolean; ColorOn, ColorOff : TColor);
  Var
   N : Integer;
  Begin
   N := Length(P.Leds);
   SetLength(P.Leds, N + 1);
   P.Leds[N].Name     := Name;
   P.Leds[N].Bounds   := Bounds;
   P.Leds[N].Vertical := Vertical;
   P.Leds[N].ColorOn  := ColorOn;
   P.Leds[N].ColorOff := ColorOff;
  End;

End.
