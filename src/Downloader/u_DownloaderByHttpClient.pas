unit u_DownloaderByHttpClient;

interface

uses
  System.SyncObjs,
  System.Net.HttpClient,
  System.Net.URLClient,
  i_Downloader,
  i_DownloadResponse;

type
  TDownloaderByHttpClient = class(TInterfacedObject, IDownloader)
  private
    FLock: TCriticalSection;
    FHttpClient: THttpClient;

    function RawHeadersToNetHeaders(
      const ARawHeaders: string
    ): TNetHeaders;
    function BuildResponse(
      const AHttpResponse: IHttpResponse
    ): IDownloadResponse;
  private
    { IDownloader }
    function DoHeadRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
    function DoGetRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  IdGlobalProtocols, // for GMTToLocalDateTime
  u_DateTimeUtils,
  u_DownloadResponse;

{ TDownloaderByHttpClient }

constructor TDownloaderByHttpClient.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FHttpClient := THTTPClient.Create;
  FHttpClient.AutomaticDecompression := [THTTPCompressionMethod.Any];
end;

destructor TDownloaderByHttpClient.Destroy;
begin
  FreeAndNil(FHttpClient);
  FreeAndNil(FLock);
  inherited;
end;

function TDownloaderByHttpClient.RawHeadersToNetHeaders(
  const ARawHeaders: string
): TNetHeaders;
var
  I: Integer;
  VStringList: TStringList;
begin
  VStringList := TStringList.Create;
  try
    VStringList.NameValueSeparator := ':';
    VStringList.Text := ARawHeaders;
    SetLength(Result, VStringList.Count);
    for I := 0 to VStringList.Count - 1 do begin
      Result[I].Name := VStringList.Names[I];
      Result[I].Value := VStringList.ValueFromIndex[I];
    end;
  finally
    VStringList.Free;
  end;
end;

function TDownloaderByHttpClient.BuildResponse(
  const AHttpResponse: IHttpResponse
): IDownloadResponse;
var
  VHeader: TNetHeader;
  VStringBuilder: TStringBuilder;
  VStream: TMemoryStream;
  VLastModifiedUTC: TDateTime;
  VRawHeaders: string;
begin
  VLastModifiedUTC := GMTToLocalDateTime(AHttpResponse.LastModified);
  if VLastModifiedUTC <> 0 then begin
    VLastModifiedUTC := LocalTimeToUTC(VLastModifiedUTC);
  end;

  VStringBuilder := TStringBuilder.Create;
  try
    for VHeader in AHttpResponse.Headers do begin
      VStringBuilder.Append(VHeader.Name + ':' + VHeader.Value + #13#10);
    end;
    VRawHeaders := VStringBuilder.ToString;
  finally
    VStringBuilder.Free;
  end;

  VStream := TMemoryStream.Create;
  try
    if AHttpResponse.ContentStream <> nil then begin
      VStream.LoadFromStream(AHttpResponse.ContentStream);
    end;

    Result :=
      TDownloadResponse.Create(
        AHttpResponse.StatusCode,
        VRawHeaders,
        VLastModifiedUTC,
        VStream
      );

    VStream := nil;
  finally
    VStream.Free;
  end;
end;

function TDownloaderByHttpClient.DoGetRequest(
  const AUrl, ARawHeaders: string
): IDownloadResponse;
var
  VHeaders: TNetHeaders;
  VHttpResponse: IHttpResponse;
begin
  FLock.Acquire;
  try
    VHeaders := RawHeadersToNetHeaders(ARawHeaders);
    VHttpResponse := FHttpClient.Get(AURL, nil, VHeaders);
    Result := BuildResponse(VHttpResponse);
  finally
    FLock.Release;
  end;
end;

function TDownloaderByHttpClient.DoHeadRequest(
  const AUrl, ARawHeaders: string
): IDownloadResponse;
var
  VHeaders: TNetHeaders;
  VHttpResponse: IHttpResponse;
begin
  FLock.Acquire;
  try
    VHeaders := RawHeadersToNetHeaders(ARawHeaders);
    VHttpResponse := FHttpClient.Head(AURL, VHeaders);
    Result := BuildResponse(VHttpResponse);
  finally
    FLock.Release;
  end;
end;

end.
