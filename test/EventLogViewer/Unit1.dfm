object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Form1'
  ClientHeight = 214
  ClientWidth = 260
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 106
  TextHeight = 14
  object btn1: TButton
    Left = 8
    Top = 181
    Width = 105
    Height = 25
    Align = alCustom
    Anchors = [akLeft, akBottom]
    Caption = 'Log'
    TabOrder = 0
    OnClick = btn1Click
  end
  object btnExit: TButton
    Left = 147
    Top = 181
    Width = 105
    Height = 25
    Caption = 'Exit'
    TabOrder = 1
    OnClick = btnExitClick
  end
end
