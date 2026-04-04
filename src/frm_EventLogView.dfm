object frmEventLogViewer: TfrmEventLogViewer
  Left = 0
  Top = 0
  Caption = 'Time Line'
  ClientHeight = 481
  ClientWidth = 655
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblInfo: TLabel
    Left = 8
    Top = 454
    Width = 30
    Height = 13
    Align = alCustom
    Anchors = [akLeft, akBottom]
    Caption = 'lblInfo'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object pnlTreeView: TPanel
    Left = 0
    Top = 0
    Width = 655
    Height = 443
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 0
  end
  object btnClose: TButton
    Left = 572
    Top = 449
    Width = 75
    Height = 24
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 1
    OnClick = btnCloseClick
  end
  object pmMain: TPopupMenu
    Left = 424
    Top = 296
    object mniEditVersion: TMenuItem
      Caption = 'Edit Version'
      ShortCut = 115
      OnClick = mniEditVersionClick
    end
    object mniDeleteRecord: TMenuItem
      Caption = 'Delete Record'
      ShortCut = 46
      OnClick = mniDeleteRecordClick
    end
  end
end
