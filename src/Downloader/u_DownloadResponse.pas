unit u_DownloadResponse;

interface

uses
  Classes,
  SysUtils,
  i_DownloadResponse;

type
  TDownloadResponse = class(TInterfacedObject, IDownloadResponse)
  private
    FCode: Integer;
    FRawHeaders: string;
    FLastModified: TDateTime;
    FBody: TMemoryStream;
    FBodyAsText: string;
  protected
    function GetCode: Integer;
    function GetRawHeaders: string;
    function GetLastModified: TDateTime;
    function GetBody: Pointer;
    function GetBodySize: Int64;
    function GetBodyAsText: string;
  public
    constructor Create(
      const ACode: Integer;
      const ARawHeaders: string;
      const ALastModified: TDateTime;
      const ABody: TMemoryStream
    );
    destructor Destroy; override;
  end;

type
  EDownloadResponse = class(Exception);

implementation

{ TDownloadResponse }

constructor TDownloadResponse.Create(
  const ACode: Integer;
  const ARawHeaders: string;
  const ALastModified: TDateTime;
  const ABody: TMemoryStream
);
begin
  if not Assigned(ABody) then begin
    raise EDownloadResponse.Create('Response body not assigned!');
  end;

  inherited Create;

  FCode := ACode;
  FRawHeaders := ARawHeaders;
  FLastModified := ALastModified;
  FBody := ABody;
  FBody.Position := 0;
  FBodyAsText := '';
end;

destructor TDownloadResponse.Destroy;
begin
  FreeAndNil(FBody);
  inherited;
end;

function TDownloadResponse.GetBody: Pointer;
begin
  Result := FBody.Memory;
end;

function TDownloadResponse.GetBodySize: Int64;
begin
  Result := FBody.Size;
end;

function TDownloadResponse.GetBodyAsText: string;
var
  VText: AnsiString;
begin
  Result := FBodyAsText;
  if (Result = '') and (FBody.Size > 0) then begin
    SetLength(VText, FBody.Size);
    FBody.Position := 0;
    FBody.ReadBuffer(VText[1], FBody.Size);
    FBody.Position := 0;
    FBodyAsText := string(VText);
    Result := FBodyAsText;
  end;
end;

function TDownloadResponse.GetCode: Integer;
begin
  Result := FCode;
end;

function TDownloadResponse.GetLastModified: TDateTime;
begin
  Result := FLastModified;
end;

function TDownloadResponse.GetRawHeaders: string;
begin
  Result := FRawHeaders;
end;

end.
