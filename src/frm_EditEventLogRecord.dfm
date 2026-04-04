object frmEditEventLogRecord: TfrmEditEventLogRecord
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Edit Record'
  ClientHeight = 79
  ClientWidth = 325
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblVersion: TLabel
    Left = 8
    Top = 16
    Width = 39
    Height = 13
    Caption = 'Version:'
  end
  object btnCancel: TButton
    Left = 242
    Top = 47
    Width = 75
    Height = 24
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    Default = True
    ModalResult = 2
    TabOrder = 2
    OnClick = btnCancelClick
  end
  object btnApply: TButton
    Left = 161
    Top = 47
    Width = 75
    Height = 24
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'Apply'
    ModalResult = 1
    TabOrder = 1
    OnClick = btnApplyClick
  end
  object edtVersion: TEdit
    Left = 53
    Top = 13
    Width = 264
    Height = 21
    TabOrder = 0
  end
end
