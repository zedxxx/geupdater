unit u_AppLog;

interface

procedure DoTestLogException;

implementation

uses
  Windows,
  SysUtils,
  SynLog;

type
  TSynLogCustom = class(TSynLog)
  protected
    procedure ComputeFileName; override;
  end;

{ TSynLogCustom }

procedure TSynLogCustom.ComputeFileName;
var
  VExeName: string;
begin
  VExeName := ExtractFileName(ParamStr(0));
  fFileName := fFamily.DestinationPath + ChangeFileExt(VExeName, '_StackTrace.log');
end;

procedure InitAppLog;
var
  VLogPath: string;
begin
  VLogPath := ExtractFilePath(ParamStr(0));
  with TSynLogCustom.Family do begin
    Level := LevelStackTrace;
    WithUnitName := True;
    IncludeComputerNameInFileName := False;
    DestinationPath := VLogPath;
    ArchivePath := VLogPath;
    FileExistsAction := acOverwrite;
    NoFile := False;
    NoEnvironmentVariable := True;
    OnArchive := EventArchiveDelete;
    ArchiveAfterDays := 365000;
    RotateFileCount := 0;
  end;
end;

procedure DoTestLogException;
var
  I: Integer;
begin
  try
    I := 0;
    if (10 div I) = 0 then; // will raise EDivByZero
  except
    //
  end;
end;

initialization
  InitAppLog;

end.
