object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'GoogleEarth Update Checker'
  ClientHeight = 338
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
    Top = 307
    Width = 75
    Height = 25
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'Exit'
    TabOrder = 1
    OnClick = btnExitClick
    ExplicitTop = 291
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
    Top = 195
    Width = 334
    Height = 108
    Align = alTop
    Caption = 'Google Maps'
    TabOrder = 3
  end
  object btnAbout: TButton
    Left = 3
    Top = 307
    Width = 25
    Height = 25
    Align = alCustom
    Anchors = [akLeft, akBottom]
    Caption = '?'
    TabOrder = 4
    OnClick = btnAboutClick
    ExplicitTop = 291
  end
end
