object frmAbout: TfrmAbout
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 138
  ClientWidth = 256
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object txtVersion: TStaticText
    Left = 30
    Top = 8
    Width = 195
    Height = 17
    Caption = 'Google Earth and Maps Update Checker'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Transparent = False
  end
  object txtBuild: TStaticText
    Left = 48
    Top = 31
    Width = 159
    Height = 17
    Caption = 'Build: 9999-99-99 99:99:99 UTC'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Transparent = False
  end
  object txtCopyright: TStaticText
    Left = 53
    Top = 77
    Width = 148
    Height = 17
    Caption = 'Copyright (C) 2009-20xx, zed'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object txtHomePage: TStaticText
    Left = 30
    Top = 54
    Width = 187
    Height = 17
    Cursor = crHandPoint
    Caption = 'https://github.com/zedxxx/geupdater'
    DragCursor = crDefault
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    ParentShowHint = False
    ShowHint = False
    TabOrder = 2
    Transparent = False
    OnClick = txtHomePageClick
  end
  object btnOk: TButton
    Left = 90
    Top = 100
    Width = 75
    Height = 25
    Caption = 'Ok'
    TabOrder = 4
    OnClick = btnOkClick
  end
end
