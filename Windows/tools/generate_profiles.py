"""Generate Windows aircraft geometry from the checked-in Android sources."""
import re
import shutil
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
WINDOWS = ROOT / 'Windows'
MODULES = [('FMC737','PMDG737','737','PMDG 737 FMC',False,False),
           ('FMC777','PMDG777','777','PMDG 777 FMC',False,False),
           ('FBWA320','FBWA320','A320','FlyByWire A320 MCDU',True,False),
           ('FenixA320','FenixA320','FENIXA320','Fenix A320 MCDU',True,True),
           ('iFly737MAX','iFly737MAX','IFLY737MAX','iFly 737 MAX FMC',False,False)]
import sys
for module, folder, aircraft, title, airbus, fenix in MODULES:
    if len(sys.argv)>1 and folder not in sys.argv[1:]:
        continue
    source = ROOT / module / 'app/src/main'
    view = next((source / 'java').rglob('*View.java'))
    text = view.read_text(encoding='utf-8-sig')
    rects = {name: re.sub(r'f\b','',coords.strip()) for name,coords in
             re.findall(r'float\[\]\s+(\w+)\s*=\s*\{([^}]+)\}',text)}
    screen = [re.search(rf'float SCREEN_{k}\s*=\s*([0-9.]+)f',text)[1] for k in 'LTRB']
    hints = re.findall(r'new Hint\("([^"]+)",\s*([0-9.]+)f,\s*([0-9.]+)f,\s*([0-9.]+)f,\s*([0-9.]+)f,\s*(RR|CR)\)',text)
    assert len(hints) == (70 if airbus else 69), (module,len(hints))
    target = WINDOWS / folder
    (target / 'assets').mkdir(parents=True, exist_ok=True)
    skin = 'mcdu_skin_a320.png' if airbus else 'cdu_skin'+('777' if module=='FMC777' else '737')+'.png'
    shutil.copyfile(source/'res/drawable'/skin, target/f'assets/background_{folder}.png')
    shutil.copyfile(source/'assets/fonts/B612Mono-Bold.ttf',target/'assets/B612Mono-Bold.ttf')
    shutil.copyfile(source/'res/raw/button_click.wav',target/f'assets/button_click_{folder}.wav')
    lines = ['// Geometry and key names from '+str(view.relative_to(ROOT)).replace('\\','/'),
             'unit Profile;', 'interface', 'uses AircraftTypes;',
             'function CreateProfile: TAircraftProfile;', 'implementation', 'uses Vcl.Graphics;',
             'function CreateProfile: TAircraftProfile;', 'begin',
             '  Result.ScreenOnly := False;',
             f"  Result.Title := '{title}'; Result.Aircraft := '{aircraft}';",
             f"  Result.SettingsName := '{'iFly' if folder=='iFly737MAX' else folder}';",
             f"  Result.BackgroundFile := 'background_{folder}.png'; Result.SoundFile := 'button_click_{folder}.wav';",
             f'  Result.Airbus := {str(airbus)}; Result.Fenix := {str(fenix)};',
             f'  Result.SupportsSide := {str(not airbus and folder!="iFly737MAX")};',
             '  Result.Screen := NormRect('+','.join(screen)+');']
    for field, name in [('SettingsButton','SETTINGS_BTN_RECT'),('CloseButton','CLOSE_BTN_RECT')]:
        lines.append(f'  Result.{field} := NormRect({rects[name]});')
    lines.append('  Result.ExecLed := NormRect('+ ('0,0,0,0' if airbus else rects['EXEC_LED_RECT'])+');')
    for key,x,y,hw,hh,shape in hints:
        lines.append(f"  AddHint(Result,'{key}',{x},{y},{hw},{hh},{str(shape=='CR')});")
    if airbus:
        slots = [('FM1','TOP_LED_FM1_RECT',False,'$0000A0FF','$00001932'),
                 ('FM2','TOP_LED_FM2_RECT',False,'$0000A0FF','$00001932'),
                 ('FM','LEFT_STRIP_BOTTOM_RECT',True,'clWhite','$003C3C3C'),
                 ('IND','TOP_LED_IND_RECT',False,'$0000A0FF','$00001932'),
                 ('RDY','TOP_LED_RDY_RECT',False,'clLime','$00001E00'),
                 ('FAIL','LEFT_STRIP_TOP_RECT',True,'clRed','$00000032'),
                 ('MCDU MENU','RIGHT_STRIP_RECT',True,'$0000A0FF','$00001932'),
                 ('FM','TOP_LED_FM_TOP_RECT',False,'clWhite','$003C3C3C')]
    else:
        slots = [('DSPY' if module=='FMC777' else 'CALL','ANNUN_LEFT_TOP_RECT',True,'clWhite','$00505050'),
                 ('FAIL','ANNUN_LEFT_BOTTOM_RECT',True,'clRed','$00000050'),
                 ('MSG','ANNUN_RIGHT_TOP_RECT',True,'clWhite','$00505050'),
                 ('OFST','ANNUN_RIGHT_BOTTOM_RECT',True,'$0000A0FF','$00003250')]
    for name,rect,vertical,on,off in slots:
        lines.append(f"  AddLed(Result,'{name}',NormRect({rects[rect]}),{str(vertical)},{on},{off});")
    lines += ['end;','end.']
    (target/'Profile.pas').write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
    name = 'iFlyFMC' if folder=='iFly737MAX' else (folder+'FMC' if not airbus else folder+'MCDU')
    dpr = f"program {name};\nuses Vcl.Forms, FMCMain in '..\\Common\\FMCMain.pas' {{FMCForm}},\n  AircraftTypes in '..\\Common\\AircraftTypes.pas',\n  ScreenModel in '..\\Common\\ScreenModel.pas',\n  Transport in '..\\Common\\Transport.pas', Profile in 'Profile.pas';\nbegin\n  Application.Initialize; Application.MainFormOnTaskbar := True;\n  Application.CreateForm(TFMCForm,FMCForm); Application.Run;\nend.\n"
    (target/(name+'.dpr')).write_text(dpr,encoding='utf-8-sig')
    print(f'{folder}: {len(hints)} keys, {len(slots)} LED slots, {aircraft}')
