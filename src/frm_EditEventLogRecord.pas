unit frm_EditEventLogRecord;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  t_EventLog,
  u_BaseForm;

type
  TfrmEditEventLogRecord = class(TBaseForm)
    btnCancel: TButton;
    btnApply: TButton;
    lblVersion: TLabel;
    edtVersion: TEdit;
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FItem: PEventLogItem;
  public
    function ShowModal(const AItem: PEventLogItem): Integer; reintroduce;
  end;


implementation

{$R *.dfm}

{ TfrmEditEventLogRecord }

function TfrmEditEventLogRecord.ShowModal(const AItem: PEventLogItem): Integer;
begin
  FItem := AItem;
  edtVersion.Text := FItem.Version;
  Result := inherited ShowModal;
end;

procedure TfrmEditEventLogRecord.btnApplyClick(Sender: TObject);
begin
  FItem.Version := Trim(edtVersion.Text);
  FItem := nil;
end;

procedure TfrmEditEventLogRecord.btnCancelClick(Sender: TObject);
begin
  Close;
end;

end.
