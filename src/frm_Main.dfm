object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'GoogleEarth Update Checker'
  ClientHeight = 362
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object grpGEClassic: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 334
    Height = 126
    Align = alTop
    Caption = 'Google Earth Classic'
    TabOrder = 0
  end
  object btnExit: TButton
    Left = 257
    Top = 331
    Width = 75
    Height = 25
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'Exit'
    TabOrder = 1
    OnClick = btnExitClick
    ExplicitTop = 307
  end
  object grpGEWeb: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 135
    Width = 334
    Height = 54
    Align = alTop
    Caption = 'Google Earth Web'
    TabOrder = 2
  end
  object grpGM: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 255
    Width = 334
    Height = 70
    Align = alTop
    Caption = 'Google Maps'
    TabOrder = 3
    ExplicitLeft = 8
    ExplicitTop = 231
  end
  object btnAbout: TButton
    Left = 3
    Top = 331
    Width = 25
    Height = 25
    Align = alCustom
    Anchors = [akLeft, akBottom]
    Caption = '?'
    TabOrder = 4
    OnClick = btnAboutClick
    ExplicitTop = 307
  end
  object grpGMClassic: TGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 195
    Width = 334
    Height = 54
    Align = alTop
    Caption = 'Google Maps Classic'
    TabOrder = 5
  end
end
