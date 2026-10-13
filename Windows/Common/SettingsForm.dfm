object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 754
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poOwnerFormCenter
  DesignSize = (
    450
    754)
  PixelsPerInch = 96
  TextHeight = 17
  object HeaderLabel: TLabel
    Left = 20
    Top = 16
    Width = 410
    Height = 24
    AutoSize = False
    Caption = 'Server Settings'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object HelpLabel: TLabel
    Left = 20
    Top = 49
    Width = 410
    Height = 20
    AutoSize = False
    Caption = 'FlightPadFMC Server must be running on the MSFS PC.'
  end
  object HostLabel: TLabel
    Left = 20
    Top = 163
    Width = 410
    Height = 20
    AutoSize = False
    Caption = 'Server IP Address / Host (MSFS PC)'
  end
  object PortLabel: TLabel
    Left = 20
    Top = 227
    Width = 410
    Height = 20
    AutoSize = False
    Caption = 'Server Port (default 8765)'
  end
  object FallbackLabel: TLabel
    Left = 20
    Top = 286
    Width = 410
    Height = 20
    AutoSize = False
    Caption = 'Auto searches for 15 seconds, then uses the address above.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object StatusLabel: TLabel
    Left = 20
    Top = 606
    Width = 410
    Height = 40
    Anchors = [akLeft, akRight, akBottom]
    AutoSize = False
    Caption = 'Connection:'
    WordWrap = True
  end
  object ErrorLabel: TLabel
    Left = 20
    Top = 652
    Width = 410
    Height = 44
    Anchors = [akLeft, akRight, akBottom]
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object ConnectionMode: TRadioGroup
    Left = 20
    Top = 80
    Width = 410
    Height = 70
    Caption = 'Connection Mode'
    Columns = 2
    Items.Strings = (
      'Auto (mDNS)'
      'Manual IP')
    TabOrder = 0
  end
  object ServerHost: TEdit
    Left = 20
    Top = 188
    Width = 410
    Height = 25
    TabOrder = 1
    TextHint = '192.168.0.x'
  end
  object ServerPort: TEdit
    Left = 20
    Top = 251
    Width = 410
    Height = 25
    NumbersOnly = True
    TabOrder = 2
  end
  object ButtonSound: TCheckBox
    Left = 20
    Top = 318
    Width = 410
    Height = 24
    Caption = 'Button Press Sound'
    TabOrder = 3
  end
  object HapticFeedback: TCheckBox
    Left = 20
    Top = 348
    Width = 410
    Height = 24
    Caption = 'Haptic Feedback (not available on Windows)'
    Enabled = False
    TabOrder = 4
  end
  object BorderlessWindow: TCheckBox
    Left = 20
    Top = 382
    Width = 410
    Height = 24
    Caption = 'Hide title bar and window borders'
    TabOrder = 5
  end
  object FullscreenWindow: TCheckBox
    Left = 20
    Top = 416
    Width = 410
    Height = 24
    Caption = 'Fullscreen (F11)'
    TabOrder = 6
  end
  object RefocusMSFS: TCheckBox
    Left = 20
    Top = 452
    Width = 410
    Height = 24
    Caption = 'Automatically refocus MSFS 2024'
    TabOrder = 7
  end
  object RefocusLabel: TLabel
    Left = 20
    Top = 487
    Width = 290
    Height = 20
    Caption = 'Refocus interval (seconds, 1-60)'
  end
  object RefocusInterval: TEdit
    Left = 336
    Top = 484
    Width = 94
    Height = 25
    NumbersOnly = True
    TabOrder = 8
  end
  object SideSection: TPanel
    Left = 0
    Top = 520
    Width = 450
    Height = 86
    BevelOuter = bvNone
    TabOrder = 9
    object DefaultSide: TRadioGroup
      Left = 20
      Top = 0
      Width = 410
      Height = 70
      Caption = 'CDU Side'
      Columns = 2
      Items.Strings = (
        'Captain CDU'
        'First Officer CDU')
      TabOrder = 0
    end
  end
  object SaveButton: TButton
    Left = 232
    Top = 706
    Width = 94
    Height = 30
    Anchors = [akRight, akBottom]
    Caption = 'Save'
    Default = True
    TabOrder = 10
    OnClick = SaveClick
  end
  object CancelButton: TButton
    Left = 336
    Top = 706
    Width = 94
    Height = 30
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 11
  end
end
