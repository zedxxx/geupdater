unit u_TaskInfoListener;

interface

uses
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  t_TaskInfo,
  i_TaskInfoListener;

const
  cInfoItemsCount = 4;

type
  TTaskInfoListener = class(TInterfacedObject, ITaskInfoListener)
  private
    FPanel: TPanel;
    FLabel: array [0..cInfoItemsCount-1] of TLabel;
    procedure BuildPanel(const AParent: TWinControl);
  protected
    procedure Update(const AInfo: TTaskInfo);
  public
    constructor Create(const AParent: TWinControl);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics;

const
  cNameIndex           = 0;
  cLastModifiedIndex   = 2;
  cVersionIndex        = 1;
  cIsUpdatesFoundIndex = 3;

  cStatusInfoIndex     = 1;

{ TTaskInfoListener }

constructor TTaskInfoListener.Create(const AParent: TWinControl);
begin
  inherited Create;
  BuildPanel(AParent);
end;

destructor TTaskInfoListener.Destroy;
begin
  if Assigned(FPanel) then begin
    FreeAndNil(FPanel);
  end;
  inherited Destroy;
end;

procedure TTaskInfoListener.Update(const AInfo: TTaskInfo);
var
  VInfo: TTaskInfo;
begin
  VInfo := AInfo;

  TThread.Synchronize(nil, procedure()
    begin
      FLabel[cNameIndex].Caption := VInfo.Name + ':';

      if VInfo.State = tsFinished then begin
        if VInfo.LastModified <> 0 then begin
          FLabel[cLastModifiedIndex].Caption :=
            FormatDateTime('dd-mm-yyyy hh:mm:ss', VInfo.LastModified);
        end else begin
          FLabel[cLastModifiedIndex].Caption := '';
        end;

        if VInfo.IsUpdatesFound then begin
          FLabel[cVersionIndex].Font.Color := clGreen;
          FLabel[cVersionIndex].Font.Style := [fsBold];

          FLabel[cIsUpdatesFoundIndex].Font.Color := clRed;
          FLabel[cIsUpdatesFoundIndex].Caption := 'New!';
        end else begin
          FLabel[cVersionIndex].Font.Color := clDefault;
          FLabel[cIsUpdatesFoundIndex].Caption := '';
        end;

        FLabel[cVersionIndex].Caption := VInfo.Version;

      end else begin
        case VInfo.State of
          tsNone : FLabel[cStatusInfoIndex].Caption := 'waiting...';
          tsInProgress: FLabel[cStatusInfoIndex].Caption := 'in progress...';
          tsFailed: FLabel[cStatusInfoIndex].Caption := 'FAILED';
        end;
      end;
    end
  );
end;

procedure TTaskInfoListener.BuildPanel(const AParent: TWinControl);
const
  cPos: array [0..cInfoItemsCount-1] of Integer = (60, 80, 140, 270);
var
  I: Integer;
begin
  FPanel := TPanel.Create(nil);

  FPanel.Parent := AParent;
  FPanel.Top := 5;
  FPanel.Height := 18;
  FPanel.Align := alTop;
  FPanel.BevelOuter := bvNone;

  for I := 0 to cInfoItemsCount - 1 do begin
    FLabel[I] := TLabel.Create(FPanel);
    with FLabel[I] do begin
      Parent := FPanel;
      Left := cPos[I];
      if I = cNameIndex then begin
        Alignment := taRightJustify;
      end;
      Caption := '';
    end;
  end;
end;

end.
