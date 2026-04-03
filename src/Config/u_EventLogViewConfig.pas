unit u_EventLogViewConfig;

interface

uses
  System.Types,
  System.IniFiles,
  i_EventLogViewConfig;

type
  TEventLogViewConfig = class(TInterfacedObject, IEventLogViewConfig)
  private
    FBounds: TRect;
    FTreeColumnsState: TTreeColumnsState;
    FTreeShowOpt: TTreeShowOptRec;
  private
    { IConfigBase }
    procedure DoReadConfig(const AIni: TMemIniFile);
    procedure DoWriteConfig(const AIni: TMemIniFile);
  private
    { IEventLogViewConfig }
    function GetBounds: TRect;
    procedure SetBounds(const ARect: TRect);

    function GetTreeColumnsState: TTreeColumnsState;
    procedure SetTreeColumnsState(const AValue: TTreeColumnsState);

    function GetTreeShowOpt: TTreeShowOptRec;
    procedure SetTreeShowOpt(const AValue: TTreeShowOptRec);
  public
    constructor Create;
  end;

implementation

uses
  System.SysUtils;

const
  cSectionName = 'EventLogView';

{ TEventLogViewConfig }

constructor TEventLogViewConfig.Create;
begin
  inherited Create;

  FBounds := Rect(0, 0, 0, 0);

  SetLength(FTreeColumnsState, 5);

  FTreeShowOpt.SortColumn := 0;
  FTreeShowOpt.SortDirection := 1;
end;

procedure TEventLogViewConfig.DoReadConfig(const AIni: TMemIniFile);
var
  I: Integer;
begin
  FBounds := Bounds(
    AIni.ReadInteger(cSectionName, 'Left', FBounds.Left),
    AIni.ReadInteger(cSectionName, 'Top', FBounds.Top),
    AIni.ReadInteger(cSectionName, 'Width', FBounds.Right - FBounds.Top),
    AIni.ReadInteger(cSectionName, 'Height', FBounds.Bottom - FBounds.Top)
  );

  for I := 0 to Length(FTreeColumnsState) - 1 do begin
    FTreeColumnsState[I].Size := AIni.ReadInteger(cSectionName, 'ColSize_' + IntToStr(I), -1);
    FTreeColumnsState[I].Position := AIni.ReadInteger(cSectionName, 'ColPosition_' + IntToStr(I), -1);
  end;

  FTreeShowOpt.SortColumn := AIni.ReadInteger(cSectionName, 'SortColumn', FTreeShowOpt.SortColumn);
  FTreeShowOpt.SortDirection := AIni.ReadInteger(cSectionName, 'SortDirection', FTreeShowOpt.SortDirection);
end;

procedure TEventLogViewConfig.DoWriteConfig(const AIni: TMemIniFile);
var
  I: Integer;
begin
  AIni.WriteInteger(cSectionName, 'Left', FBounds.Left);
  AIni.WriteInteger(cSectionName, 'Top', FBounds.Top);
  AIni.WriteInteger(cSectionName, 'Width', FBounds.Right - FBounds.Left);
  AIni.WriteInteger(cSectionName, 'Height', FBounds.Bottom - FBounds.Top);

  for I := 0 to Length(FTreeColumnsState) - 1 do begin
    AIni.WriteInteger(cSectionName, 'ColSize_' + IntToStr(I), FTreeColumnsState[I].Size);
    AIni.WriteInteger(cSectionName, 'ColPosition_' + IntToStr(I), FTreeColumnsState[I].Position);
  end;

  AIni.WriteInteger(cSectionName, 'SortColumn', FTreeShowOpt.SortColumn);
  AIni.WriteInteger(cSectionName, 'SortDirection', FTreeShowOpt.SortDirection);
end;

function TEventLogViewConfig.GetBounds: TRect;
begin
  Result := FBounds;
end;

function TEventLogViewConfig.GetTreeColumnsState: TTreeColumnsState;
begin
  Result := FTreeColumnsState;
end;

function TEventLogViewConfig.GetTreeShowOpt: TTreeShowOptRec;
begin
  Result := FTreeShowOpt;
end;

procedure TEventLogViewConfig.SetTreeColumnsState(const AValue: TTreeColumnsState);
begin
  FTreeColumnsState := AValue;
end;

procedure TEventLogViewConfig.SetTreeShowOpt(const AValue: TTreeShowOptRec);
begin
  FTreeShowOpt := AValue;
end;

procedure TEventLogViewConfig.SetBounds(const ARect: TRect);
begin
  FBounds := ARect;
end;

end.
