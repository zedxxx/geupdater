unit u_TaskInfoListener;

interface

uses
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  fr_TaskInfo,
  t_TaskInfo,
  i_TaskInfoListener;

type
  TTaskInfoListener = class(TInterfacedObject, ITaskInfoListener)
  private
    FFrame: TfrTaskInfo;
  private
    { ITaskInfoListener }
    procedure Update(const AInfo: TTaskInfo);
  public
    constructor Create(const APanel: TPanel);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  u_DateTimeUtils;

{ TTaskInfoListener }

constructor TTaskInfoListener.Create(const APanel: TPanel);
begin
  inherited Create;
  FFrame := TfrTaskInfo.Create(APanel);
  FFrame.Parent := APanel;
  FFrame.Align := alClient;
  FFrame.Show;
end;

destructor TTaskInfoListener.Destroy;
begin
  FreeAndNil(FFrame);
  inherited Destroy;
end;

procedure TTaskInfoListener.Update(const AInfo: TTaskInfo);
const
  cStateCaptionText: array[TTaskState] of string = (
    'waiting...', 'in progress...', 'HTTP ERROR', 'FAILED', ''
  );
var
  VInfo: TTaskInfo;
begin
  VInfo := AInfo;

  TThread.Synchronize(nil, procedure()
    begin
      FFrame.lblName.Caption := VInfo.Conf.DisplayName + ':';

      if VInfo.State = tsFinished then begin
        if VInfo.LastModified <> 0 then begin
          FFrame.lblLastModified.Caption :=
            FormatDateTime('yyyy-mm-dd hh:nn:ss', UTCToLocalTime(VInfo.LastModified));
        end else
        if VInfo.TimeStamp <> 0 then begin
          FFrame.lblLastModified.Caption :=
            FormatDateTime('yyyy-mm-dd hh:nn:ss', UTCToLocalTime(VInfo.TimeStamp));

          FFrame.lblLastModified.Font.Color := clGrayText;
          //FFrame.lblLastModified.Font.Style := [fsItalic];
        end else begin
          FFrame.lblLastModified.Caption := '';
        end;

        if VInfo.IsUpdatesFound then begin
          FFrame.lblVersion.Font.Color := clGreen;
          FFrame.lblVersion.Font.Style := [fsBold];

          FFrame.lblNew.Font.Color := clRed;
          FFrame.lblNew.Caption := 'New!';
        end else begin
          FFrame.lblVersion.Font.Color := clDefault;
          FFrame.lblNew.Caption := '';
        end;

        FFrame.lblVersion.Caption := VInfo.Version;
      end else begin
        FFrame.lblVersion.Caption := cStateCaptionText[VInfo.State];
      end;
    end
  );
end;

end.
