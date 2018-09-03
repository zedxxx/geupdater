unit Unit1;

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
  Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    btn1: TButton;
    btnExit: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  frm_EventLogView,
  i_EventLogStorage,
  u_EventLogStorage;

procedure TForm1.btn1Click(Sender: TObject);
var
  VStorage: IEventLogStorage;
  VEventLogViewer: TfrmEventLogViewer;
begin
  VStorage := TEventLogStorageBySQLite.Create('data_test.db3');
  VEventLogViewer := TfrmEventLogViewer.Create(Self, VStorage);
  try
    VEventLogViewer.ShowModal;
  finally
    VEventLogViewer.Free;
  end;
end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Close;
end;

end.
