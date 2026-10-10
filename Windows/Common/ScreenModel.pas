Unit ScreenModel;

Interface

 Uses
  System.SysUtils, System.JSON, Vcl.Graphics, AircraftTypes;

 Const
  LedNames : Array [0 .. 11] Of String = ('EXEC', 'CALL', 'DSPY', 'FAIL', 'MSG', 'OFST', 'FM1', 'FM2', 'FM', 'IND', 'RDY', 'MCDU MENU');

 Type
  TScreenCell = Record
   Symbol : String;
   Color  : TColor;
   Small  : Boolean;
  End;

  TScreenState = Record
   Cells   : Array [0 .. 13, 0 .. 23] Of TScreenCell;
   Leds    : Array [0 .. 11] Of Boolean;
   Overlay : String;
  End;

  TScreenModel = Class
   Private
    FProfile : TAircraftProfile;
   Public
    State : TScreenState;
    Side  : String;
    Constructor Create(Const Profile : TAircraftProfile);
    Procedure Reset;
    Procedure Parse(Const Message : String);
    Function LedOn(Const Name : String) : Boolean;
  End;

 Function LedIndex(Const Name : String) : Integer;

Implementation

 Uses
  System.Math, System.Generics.Collections;

 Type
  TSegment = Record
   Text : String;
   Color : TColor;
   Small : Boolean;
   Align : Integer End;
   Function LedIndex(Const Name : String) : Integer;

   Var
    I : Integer;
   Begin
    Result := -1;
    For I  := Low(LedNames) To High(LedNames) Do
     If SameText(Name, LedNames[I]) Then
      Exit(I);
   End;
   Function TextValue(O : TJSONObject; Const Name : String; Const Default : String = '') : String;

   Var
    V : TJSONValue;
   Begin
    V      := O.GetValue(Name);
    Result := Default;
    If V = Nil Then
     Exit;
    If Not(V Is TJSONString) Then
     Raise Exception.Create('Expected string: ' + Name);
    Result := V.Value;
   End;
   Function BoolValue(O : TJSONObject; Const Name : String) : Boolean;

   Var
    V : TJSONValue;
   Begin
    V      := O.GetValue(Name);
    Result := False;
    If V = Nil Then
     Exit;
    If Not(V Is TJSONBool) Then
     Raise Exception.Create('Expected boolean: ' + Name);
    Result := SameText(V.Value, 'true');
   End;
   Function ObjectValue(O : TJSONObject; Const Name : String) : TJSONObject;

   Var
    V : TJSONValue;
   Begin
    V      := O.GetValue(Name);
    Result := Nil;
    If V = Nil Then
     Exit;
    If Not(V Is TJSONObject) Then
     Raise Exception.Create('Expected object: ' + Name);
    Result := TJSONObject(V);
   End;
   Function ArrayValue(O : TJSONObject; Const Name : String) : TJSONArray;

   Var
    V : TJSONValue;
   Begin
    V      := O.GetValue(Name);
    Result := Nil;
    If V = Nil Then
     Exit;
    If Not(V Is TJSONArray) Then
     Raise Exception.Create('Expected array: ' + Name);
    Result := TJSONArray(V);
   End;
   Procedure ClearCells(Var S : TScreenState);

   Var
    R, C : Integer;
   Begin
    For R  := 0 To 13 Do
     For C := 0 To 23 Do
      Begin
       S.Cells[R, C].Symbol := ' ';
       S.Cells[R, C].Color  := clWhite;
       S.Cells[R, C].Small  := False;
      End;
   End;
   Constructor TScreenModel.Create(Const Profile : TAircraftProfile);
   Begin
    Inherited Create;
    FProfile := Profile;
    Side     := 'capt';
    Reset
   End;
   Procedure TScreenModel.Reset;
   Begin
    ClearCells(State);
    FillChar(State.Leds, SizeOf(State.Leds), 0);
    State.Overlay := ''
   End;
   Function TScreenModel.LedOn(Const Name : String) : Boolean;

   Var
    I : Integer;
   Begin
    I      := LedIndex(Name);
    Result := (I >= 0) And State.Leds[I]
   End;
   Procedure TaggedSegments(Const Text : String; DefaultSmall : Boolean; DefaultAlign : Integer; Segments : TList<TSegment>);

   Var
    Current, Next : TSegment;
    I, J, K       : Integer;
    Tag           : String;
    Procedure Flush;
    Begin
     If Current.Text <> '' Then
      Segments.Add(Current);
     Current.Text := '';
    End;
    Begin
     Current.Text  := '';
     Current.Color := clWhite;
     Current.Small := DefaultSmall;
     Current.Align := DefaultAlign;
     I             := 1;
     While I <= Length(Text) Do
      Begin
       If Text[I] = '{' Then
        Begin
         J := I + 1;
         While (J <= Length(Text)) And (Text[J] <> '}') Do
          Inc(J);
         K := I + 1;
         While (K <= Length(Text)) And (Text[K] <> '{') Do
          Inc(K);
         If (J <= Length(Text)) And (K < J) Then
          Begin
           Inc(I);
           Continue
          End;
         If J <= Length(Text) Then
          Begin
           Tag  := LowerCase(Copy(Text, I + 1, J - I - 1));
           Next := Current;
           If Tag = 'amber' Then
            Next.Color := $0000A0FF
           Else If Tag = 'red' Then
            Next.Color := clRed
           Else If Tag = 'green' Then
            Next.Color := clLime
           Else If Tag = 'cyan' Then
            Next.Color := clAqua
           Else If Tag = 'white' Then
            Next.Color := clWhite
           Else If Tag = 'magenta' Then
            Next.Color := clFuchsia
           Else If Tag = 'yellow' Then
            Next.Color := clYellow
           Else If Tag = 'blue' Then
            Next.Color := $00FFB464
           Else If Tag = 'small' Then
            Next.Small := True
           Else If Tag = 'big' Then
            Next.Small := False
           Else If Tag = 'left' Then
            Next.Align := 0
           Else If Tag = 'center' Then
            Next.Align := 1
           Else If Tag = 'right' Then
            Next.Align := 2
           Else If Tag = 'sp' Then
            Current.Text := Current.Text + ' ';
           If (Current.Color <> Next.Color) Or (Current.Small <> Next.Small) Or (Current.Align <> Next.Align) Then
            Flush;
           Current.Color := Next.Color;
           Current.Small := Next.Small;
           Current.Align := Next.Align;
           I             := J + 1;
           Continue;
          End;
        End;
       Current.Text := Current.Text + Text[I];
       Inc(I);
      End;
     Flush;
    End;
    Function TranslateGlyph(C : Char; Fenix : Boolean) : Char;
    Begin
     Result := C;
     If C = '|' Then
      Result := '/'
     Else If Fenix Then
      Case C Of
       #$00A3 :
        Result := #$2190;
       #$00A2 :
        Result := #$2192;
       '#' :
        Result := #$25AE
      End
     Else If C = '_' Then
      Result := #$25AE;
    End;
    Procedure PlaceText(Var S : TScreenState; R, Col : Integer; Const Text : String; Color : TColor; Small, Fenix : Boolean);

   Var
    I : Integer;
   Begin
    For I := 1 To Length(Text) Do
     Begin
      If Col + I - 1 > 23 Then
       Break;
      If Col + I - 1 < 0 Then
       Continue;
      S.Cells[R, Col + I - 1].Symbol := TranslateGlyph(Text[I], Fenix);
      S.Cells[R, Col + I - 1].Color  := Color;
      S.Cells[R, Col + I - 1].Small  := Small;
     End;
   End;
   Procedure RenderRow(Var S : TScreenState; R : Integer; Const Left, Center, Right : String; Small, Fenix : Boolean);

   Var
    Segs              : TList<TSegment>;
    Seg               : TSegment;
    Align, Total, Col : Integer;

   Const
    Order : Array [0 .. 2] Of Integer = (0, 2, 1);
   Begin
    Segs := TList<TSegment>.Create;
    Try
     TaggedSegments(Left, Small, 0, Segs);
     TaggedSegments(Center, Small, 1, Segs);
     TaggedSegments(Right, Small, 2, Segs);
     // Preserve Android overlap precedence: left, right, then center.
     For Align In Order Do
      Begin
       Total := 0;
       For Seg In Segs Do
        If Seg.Align = Align Then
         Inc(Total, Length(Seg.Text));
       Case Align Of
        0 :
         Col := 0;
        1 :
         Col := Max(0, (24 - Total) Div 2);
        Else
         Col := Max(0, 24 - Total)
       End;
       For Seg In Segs Do
        If Seg.Align = Align Then
         Begin
          PlaceText(S, R, Col, Seg.Text, Seg.Color, Seg.Small, Fenix);
          Inc(Col, Length(Seg.Text));
         End;
      End;
    Finally
     Segs.Free
    End;
   End;
   Procedure TScreenModel.Parse(Const Message : String);

   Var
    V                         : TJSONValue;
    Root, Cell, Left, Ann     : TJSONObject;
    Rows, Row, Arrows         : TJSONArray;
    Next                      : TScreenState;
    Text, Kind, Name, L, C, R : String;
    I, J, N, Code, Col        : Integer;

   Const
    GridColors : Array [0 .. 5] Of TColor  = (clWhite, clAqua, clLime, clFuchsia, $0000BFFF, clRed);
    ArrowChars : Array [0 .. 3] Of Char    = (#$2191, #$2193, #$2190, #$2192);
    AirbusKeys : Array [0 .. 6] Of String  = ('fm1', 'fm2', 'fm', 'ind', 'rdy', 'fail', 'mcdu_menu');
    AirbusNames : Array [0 .. 6] Of String = ('FM1', 'FM2', 'FM', 'IND', 'RDY', 'FAIL', 'MCDU MENU');
    Function Slot(A : TJSONArray; Index : Integer) : String;
    Begin
     Result := '';
     If Index >= A.Count Then
      Exit;
     If Not(A.Items[Index] Is TJSONString) Then
      Raise Exception.Create('Expected MCDU line string');
     Result := A.Items[Index].Value;
    End;
    Begin
     If Copy(Message, 1, 6) = 'print:' Then
      Exit;
     Text := Message;
     If Copy(Text, 1, 7) = 'update:' Then
      Delete(Text, 1, 7);
     V := TJSONObject.ParseJSONValue(Text);
     Try
      If Not(V Is TJSONObject) Then
       Raise Exception.Create('Invalid JSON object');
      Root := TJSONObject(V);
      Next := State;
      Kind := TextValue(Root, 'type');
      If FProfile.SupportsSide And (Kind = 'screen_update') And (TextValue(Root, 'side', 'capt') <> Side) Then
       Exit;
      If Kind = 'status_message' Then
       Next.Overlay := TextValue(Root, 'text')
      Else If Kind = 'exec_led' Then
       Next.Leds[0] := BoolValue(Root, 'value')
      Else If Kind = 'led_update' Then
       Begin
        Name := TextValue(Root, 'name', 'EXEC');
        I    := LedIndex(Name);
        If I >= 0 Then
         Next.Leds[I] := BoolValue(Root, 'led_on');
       End
      Else If (Kind = 'screen_update') And Not FProfile.Airbus Then
       Begin
        Rows := ArrayValue(Root, 'screen');
        If (Rows = Nil) Or (Rows.Count <> 14) Then
         Raise Exception.Create('Expected 14 CDU rows');
        For I := 0 To 13 Do
         Begin
          If Not(Rows.Items[I] Is TJSONArray) Then
           Raise Exception.Create('Expected CDU row array');
          Row := TJSONArray(Rows.Items[I]);
          If Row.Count <> 24 Then
           Raise Exception.Create('Expected 24 CDU columns');
          For J := 0 To 23 Do
           Begin
            If Not(Row.Items[J] Is TJSONObject) Then
             Raise Exception.Create('Expected CDU cell');
            Cell := TJSONObject(Row.Items[J]);
            Name := TextValue(Cell, 's');
            If Name = '' Then
             Name                   := ' ';
            Next.Cells[I, J].Symbol := Copy(Name, 1, 1);
            If Not(Cell.GetValue('c') Is TJSONNumber) Or Not TryStrToInt(Cell.GetValue('c').Value, Code) Then
             Raise Exception.Create('Expected integer CDU color');
            If (Code < 0) Or (Code > 5) Then
             Code                  := 0;
            Next.Cells[I, J].Color := GridColors[Code];
            Next.Cells[I, J].Small := False;
           End;
         End;
        If Root.GetValue('led') <> Nil Then
         Next.Leds[0] := BoolValue(Root, 'led');
        Next.Overlay  := '';
       End
      Else If FProfile.Airbus And (Root.GetValue('left') <> Nil) Then
       Begin
        Left := ObjectValue(Root, 'left');
        ClearCells(Next);
        RenderRow(Next, 0, TextValue(Left, 'titleLeft'), TextValue(Left, 'page'), TextValue(Left, 'title'), False, FProfile.Fenix);
        Arrows := ArrayValue(Left, 'arrows');
        If (Arrows <> Nil) And (Arrows.Count >= 4) Then
         Begin
          Col   := 23;
          For I := 3 Downto 0 Do
           Begin
            If Not(Arrows.Items[I] Is TJSONBool) Then
             Raise Exception.Create('Expected boolean slew arrow');
            If SameText(Arrows.Items[I].Value, 'true') Then
             Begin
              PlaceText(Next, 0, Col, ArrowChars[I], clWhite, False, FProfile.Fenix);
              Dec(Col);
             End;
           End;
         End;
        Rows := ArrayValue(Left, 'lines');
        If Rows <> Nil Then
         For I := 0 To Min(11, Rows.Count - 1) Do
          Begin
           L := '';
           C := '';
           R := '';
           If Rows.Items[I] Is TJSONArray Then
            Begin
             Row := TJSONArray(Rows.Items[I]);
             L   := Slot(Row, 0);
             R   := Slot(Row, 1);
             C   := Slot(Row, 2);
            End
           Else If Rows.Items[I] Is TJSONString Then
            L := Rows.Items[I].Value
           Else
            Raise Exception.Create('Expected MCDU line');
           RenderRow(Next, I + 1, L, C, R, I Mod 2 = 0, FProfile.Fenix);
          End;
        RenderRow(Next, 13, TextValue(Left, 'scratchpad'), '', '', False, FProfile.Fenix);
        Ann := ObjectValue(Left, 'annunciators');
        If Ann <> Nil Then
         For I := 0 To 6 Do
          Begin
           Name := AirbusKeys[I];
           If Not FProfile.Fenix Then
            Begin
             If I = 2 Then
              Name := 'blank';
             If I >= 5 Then
              Continue;
            End;
           N            := LedIndex(AirbusNames[I]);
           Next.Leds[N] := BoolValue(Ann, Name);
          End;
        Next.Overlay := '';
       End
      Else
       Exit;
      // Commit only fully parsed snapshots; malformed messages cannot leave a half-painted screen.
      State := Next;
     Finally
      V.Free
     End;
    End;

End.
