object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'GoogleEarth Update Checker'
  ClientHeight = 367
  ClientWidth = 354
  Color = clBtnFace
  CustomTitleBar.CaptionAlignment = taCenter
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object grpGEClassic: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 348
    Height = 126
    Align = alTop
    Caption = 'Google Earth Desktop'
    TabOrder = 0
    object pnlGEEarth: TPanel
      Left = 2
      Top = 15
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
    end
    object pnlGEHistory: TPanel
      Left = 2
      Top = 33
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
    end
    object pnlGESky: TPanel
      Left = 2
      Top = 51
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
    end
    object pnlGEMoon: TPanel
      Left = 2
      Top = 87
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 4
    end
    object pnlGEMars: TPanel
      Left = 2
      Top = 69
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 3
    end
    object pnlGEClient: TPanel
      Left = 2
      Top = 105
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 5
    end
  end
  object grpGEWeb: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 135
    Width = 348
    Height = 54
    Align = alTop
    Caption = 'Google Earth Web'
    TabOrder = 1
    object pnlGEWebEarth: TPanel
      Left = 2
      Top = 15
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
    end
    object pnlGEWebClient: TPanel
      Left = 2
      Top = 33
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
    end
  end
  object grpGM: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 255
    Width = 348
    Height = 73
    Align = alTop
    Caption = 'Google Maps'
    TabOrder = 3
    object pnlGMEarth: TPanel
      Left = 2
      Top = 15
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
    end
    object pnlGMMars: TPanel
      Left = 2
      Top = 33
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
    end
    object pnlGMMoon: TPanel
      Left = 2
      Top = 51
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
    end
  end
  object grpGMClassic: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 195
    Width = 348
    Height = 54
    Align = alTop
    Caption = 'Google Maps Classic'
    TabOrder = 2
    object pnlGMClassicEarth: TPanel
      Left = 2
      Top = 15
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
    end
    object pnlGMClassicJSAPI: TPanel
      Left = 2
      Top = 33
      Width = 344
      Height = 18
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 331
    Width = 354
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 4
    object btnAbout: TButton
      Left = 5
      Top = 5
      Width = 25
      Height = 25
      Align = alCustom
      Anchors = [akLeft, akBottom]
      Caption = '?'
      TabOrder = 0
      OnClick = btnAboutClick
    end
    object btnExit: TButton
      Left = 274
      Top = 5
      Width = 75
      Height = 25
      Align = alCustom
      Anchors = [akRight, akBottom]
      Caption = 'Exit'
      TabOrder = 2
      OnClick = btnExitClick
    end
    object btnTimeLine: TButton
      Left = 36
      Top = 5
      Width = 75
      Height = 25
      Align = alCustom
      Anchors = [akLeft, akBottom]
      Caption = 'Time Line'
      TabOrder = 1
      OnClick = btnTimeLineClick
    end
  end
end
