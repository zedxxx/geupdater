unit u_EventLogViewConfig;

interface

uses
  System.Types,
  Winapi.Windows;

type
  TTreeColumnState = record
    Name: string;
    Size: Integer;
    Position: Integer;
  end;
  TTreeColumnsState = array of TTreeColumnState;

  TTreeShowOptRec = record
    SortColumn: Integer;
    SortDirection: Integer;
  end;

  TEventLogViewConfig = class
  private
    FIniFileName: string;
    FBoundsRect: TRect;
    FTreeColumnsState: TTreeColumnsState;
    FTreeShowOpt: TTreeShowOptRec;
  private
    procedure DoReadConfig;
    procedure DoWriteConfig;
  public
    function GetBoundsRect: TRect;
    procedure SetWindowPosition(const ARect: TRect);

    function GetTreeColumnsState: TTreeColumnsState;
    procedure SetTreeColumnsState(const AValue: TTreeColumnsState);
    property TreeColumnsState: TTreeColumnsState read GetTreeColumnsState write SetTreeColumnsState;

    function GetTreeShowOpt: TTreeShowOptRec;
    procedure SetTreeShowOpt(const AValue: TTreeShowOptRec);
    property TreeShowOpt: TTreeShowOptRec read GetTreeShowOpt write SetTreeShowOpt;
  public
    constructor Create(
      const ABoundsRect: TRect;
      const ATreeColumnsState: TTreeColumnsState;
      const ATreeShowOpt: TTreeShowOptRec
    );
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.IniFiles;

const
  cSectionName = 'EventLogView';

{ TEventLogViewConfig }

constructor TEventLogViewConfig.Create(
  const ABoundsRect: TRect;
  const ATreeColumnsState: TTreeColumnsState;
  const ATreeShowOpt: TTreeShowOptRec
);
begin
  inherited Create;
  FBoundsRect := ABoundsRect;
  FTreeColumnsState := ATreeColumnsState;
  FTreeShowOpt := ATreeShowOpt;

  FIniFileName :=
    ExtractFilePath(ParamStr(0)) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');

  DoReadConfig;
end;

destructor TEventLogViewConfig.Destroy;
begin
  DoWriteConfig;
  inherited Destroy;
end;

procedure TEventLogViewConfig.DoReadConfig;
var
  I: Integer;
  VIni: TMemIniFile;
begin
  if not FileExists(FIniFileName) then begin
    Exit;
  end;

  VIni := TMemIniFile.Create(FIniFileName, TEncoding.UTF8);
  try
    FBoundsRect := Bounds(
      VIni.ReadInteger(cSectionName, 'Left', FBoundsRect.Left),
      VIni.ReadInteger(cSectionName, 'Top', FBoundsRect.Top),
      VIni.ReadInteger(cSectionName, 'Width', FBoundsRect.Right - FBoundsRect.Top),
      VIni.ReadInteger(cSectionName, 'Height', FBoundsRect.Bottom - FBoundsRect.Top)
    );

    for I := 0 to Length(FTreeColumnsState) - 1 do begin
      FTreeColumnsState[I].Size :=
        VIni.ReadInteger(
          cSectionName,
          'ColSize_' + IntToStr(I),
          FTreeColumnsState[I].Size
        );
      FTreeColumnsState[I].Position :=
        VIni.ReadInteger(
          cSectionName,
          'ColPosition_' + IntToStr(I),
          FTreeColumnsState[I].Position
        );
    end;

    FTreeShowOpt.SortColumn :=
      VIni.ReadInteger(cSectionName, 'SortColumn', FTreeShowOpt.SortColumn);

    FTreeShowOpt.SortDirection :=
      VIni.ReadInteger(cSectionName, 'SortDirection', FTreeShowOpt.SortDirection);
  finally
    VIni.Free;
  end;
end;

procedure TEventLogViewConfig.DoWriteConfig;
var
  I: Integer;
  VIni: TMemIniFile;
  VHandle: THandle;
begin
  if not FileExists(FIniFileName) then begin
    VHandle := FileCreate(FIniFileName);
    if VHandle = INVALID_HANDLE_VALUE then begin
      RaiseLastOSError;
    end;
    FileClose(VHandle);
  end;

  VIni := TMemIniFile.Create(FIniFileName, TEncoding.UTF8);
  try
    VIni.WriteInteger(cSectionName, 'Left', FBoundsRect.Left);
    VIni.WriteInteger(cSectionName, 'Top', FBoundsRect.Top);
    VIni.WriteInteger(cSectionName, 'Width', FBoundsRect.Right - FBoundsRect.Left);
    VIni.WriteInteger(cSectionName, 'Height', FBoundsRect.Bottom - FBoundsRect.Top);

    for I := 0 to Length(FTreeColumnsState) - 1 do begin
      VIni.WriteInteger(cSectionName, 'ColSize_' + IntToStr(I), FTreeColumnsState[I].Size);
      VIni.WriteInteger(cSectionName, 'ColPosition_' + IntToStr(I), FTreeColumnsState[I].Position);
    end;

    VIni.WriteInteger(cSectionName, 'SortColumn', FTreeShowOpt.SortColumn);
    VIni.WriteInteger(cSectionName, 'SortDirection', FTreeShowOpt.SortDirection);

    VIni.UpdateFile;
  finally
    VIni.Free;
  end;
end;

function TEventLogViewConfig.GetBoundsRect: TRect;
begin
  Result := FBoundsRect;
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

procedure TEventLogViewConfig.SetWindowPosition(const ARect: TRect);
begin
  FBoundsRect := ARect;
end;

end.
