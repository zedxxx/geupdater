unit u_DownloaderByHttpClient;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Net.HttpClient,
  System.Net.URLClient,
  i_Downloader,
  i_DownloadRequest,
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
    function GetResponseBody(
      const AContentEncoding: string;
      const AContentStream: TStream
    ): TMemoryStream;
  private
    { IDownloader }
    function DoHeadRequest(const ARequest: IDownloadRequest): IDownloadResponse;
    function DoGetRequest(const ARequest: IDownloadRequest): IDownloadResponse;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.Zlib,
  System.SysUtils,
  u_DateTimeUtils,
  u_DownloadResponse;

{ TDownloaderByHttpClient }

constructor TDownloaderByHttpClient.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FHttpClient := THTTPClient.Create;
  FHttpClient.AutomaticDecompression := [];
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

function TDownloaderByHttpClient.GetResponseBody(
  const AContentEncoding: string;
  const AContentStream: TStream
): TMemoryStream;
const
  cZlibMagic = $9C78; // 0x789C
var
  VMagic: Word;
  VStream: TMemoryStream;
  VZlibStream: TDecompressionStream;
  VWindowBits: Integer;
begin
  if AContentStream = nil then begin
    Result := nil;
    Exit;
  end;

  VStream := TMemoryStream.Create;
  try
    if (AContentEncoding = '') or (AContentEncoding = 'identity') then begin
      VStream.LoadFromStream(AContentStream);
    end else begin
      VWindowBits := 15;
      if AContentEncoding = 'gzip' then begin
        VWindowBits := VWindowBits + 16;
      end else
      if AContentEncoding = 'deflate' then begin
        AContentStream.ReadBuffer(VMagic, 2);
        AContentStream.Seek(-2, soCurrent);
        if VMagic <> cZlibMagic then begin
          VWindowBits := -VWindowBits;
        end;
      end else begin
        raise Exception.Create('Unsupported Content-Encoding: ' + AContentEncoding);
      end;
      VZlibStream := TDecompressionStream.Create(AContentStream, VWindowBits);
      try
        VStream.LoadFromStream(VZlibStream);
      finally
        VZlibStream.Free;
      end;
    end;
    Result := VStream;
    VStream := nil;
  finally
    VStream.Free;
  end;
end;

function TDownloaderByHttpClient.BuildResponse(
  const AHttpResponse: IHttpResponse
): IDownloadResponse;
var
  VHeader: TNetHeader;
  VStringBuilder: TStringBuilder;
  VLastModifiedUTC: TDateTime;
  VRawHeaders: string;
begin
  VLastModifiedUTC := RFC1123ToDateTime(AHttpResponse.LastModified);

  VStringBuilder := TStringBuilder.Create;
  try
    for VHeader in AHttpResponse.Headers do begin
      VStringBuilder.Append(VHeader.Name + ':' + VHeader.Value + #13#10);
    end;
    VRawHeaders := VStringBuilder.ToString;
  finally
    VStringBuilder.Free;
  end;

  Result :=
    TDownloadResponse.Create(
      AHttpResponse.StatusCode,
      VRawHeaders,
      VLastModifiedUTC,
      GetResponseBody(
        LowerCase(AHttpResponse.ContentEncoding),
        AHttpResponse.ContentStream
      )
    );
end;

function TDownloaderByHttpClient.DoGetRequest(const ARequest: IDownloadRequest): IDownloadResponse;
var
  VHeaders: TNetHeaders;
  VHttpResponse: IHttpResponse;
begin
  FLock.Acquire;
  try
    VHeaders := RawHeadersToNetHeaders(ARequest.RawHeaders);
    if FHttpClient.AutomaticDecompression = [] then begin
      VHeaders := VHeaders + [TNetHeader.Create('Accept-Encoding', 'gzip, deflate')];
    end;
    VHttpResponse := FHttpClient.Get(ARequest.Url, nil, VHeaders);
    Result := BuildResponse(VHttpResponse);
  finally
    FLock.Release;
  end;
end;

function TDownloaderByHttpClient.DoHeadRequest(const ARequest: IDownloadRequest): IDownloadResponse;
var
  VHeaders: TNetHeaders;
  VHttpResponse: IHttpResponse;
begin
  FLock.Acquire;
  try
    VHeaders := RawHeadersToNetHeaders(ARequest.RawHeaders);
    VHttpResponse := FHttpClient.Head(ARequest.Url, VHeaders);
    Result := BuildResponse(VHttpResponse);
  finally
    FLock.Release;
  end;
end;

end.
