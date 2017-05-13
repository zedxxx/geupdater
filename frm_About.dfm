object frmAbout: TfrmAbout
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 151
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object imgLogo: TImage
    Left = 8
    Top = 8
    Width = 128
    Height = 128
    Transparent = True
  end
  object txtVersion: TStaticText
    Left = 155
    Top = 19
    Width = 166
    Height = 17
    Caption = 'GoogleEarth Update Checker'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Transparent = False
  end
  object txtBuild: TStaticText
    Left = 155
    Top = 42
    Width = 49
    Height = 17
    Caption = 'Build Info'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Transparent = False
  end
  object txtCopyright: TStaticText
    Left = 155
    Top = 88
    Width = 148
    Height = 17
    Caption = 'Copyright (C) 2009-20xx, zed'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object txtMailTo: TStaticText
    Left = 155
    Top = 65
    Width = 118
    Height = 17
    Cursor = crHandPoint
    Hint = 'mailto: starmen@tut.by'
    Caption = 'e-mail: starmen@tut.by'
    DragCursor = crDefault
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Transparent = False
    OnClick = txtMailToClick
  end
end
