object FMCForm: TFMCForm
  Left = 0
  Top = 0
  Caption = 'FlightPadFMC'
  ClientHeight = 797
  ClientWidth = 564
  Color = clBlack
  Constraints.MinHeight = 580
  Constraints.MinWidth = 420
  DoubleBuffered = True
  KeyPreview = True
  Position = poScreenCenter
  OnClose = SaveWindowPosition
  OnShow = FitBackground
  OnKeyDown = Shortcut
  OnKeyPress = Keyboard
  PixelsPerInch = 96
  TextHeight = 13
  object FPaint: TPaintBox
    Left = 0
    Top = 0
    Width = 564
    Height = 797
    Align = alClient
    OnMouseDown = ClickCDU
    OnPaint = PaintCDU
  end
  object FTimer: TTimer
    Enabled = False
    Interval = 30
    OnTimer = Tick
    Left = 24
    Top = 24
  end
  object ScreenMenu: TPopupMenu
    Left = 64
    Top = 24
    object SettingsItem: TMenuItem
      Caption = 'Settings... (F10)'
      OnClick = MenuSettings
    end
    object FullscreenItem: TMenuItem
      Caption = 'Fullscreen (F11)'
      OnClick = MenuFullscreen
    end
    object CloseItem: TMenuItem
      Caption = 'Close'
      OnClick = MenuClose
    end
  end
end
