unit u_Downloader;

interface

uses
  Classes,
  SyncObjs,
  IdHTTP,
  IdGlobal,
  i_Downloader,
  i_DownloadResponse;

type
  TProxyParams = record
    UseProxy: Boolean;
    ProxyServer: string;
    ProxyPort: Integer;
    ProxyUsername: string;
    ProxyPassword: string;
  end;

  TDownloaderByIndy = class(TInterfacedObject, IDownloader)
  private
    type
      TRequestType = (rtGet, rtHead);
  private
    FIdHTTP: TIdHTTP;
    FIsChunked: Boolean;
    FProxyParams: TProxyParams;
    FLock: TCriticalSection;
    procedure OnChunkReceived(Sender: TObject; var Chunk: TIdBytes);
    procedure InitIdHTTP(const AIsHttps: Boolean);
    function DoRequest(
      const AUrl: string;
      const ARawHeaders: string;
      const ARequestType: TRequestType
    ): IDownloadResponse;
  protected
    function DoHeadRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
    function DoGetRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
  public
    constructor Create(const AProxyParams: TProxyParams);
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  IdSSLOpenSSL,
  IdCompressorZLib,
  u_DownloadResponse;

{ TDownloaderByIndy }

constructor TDownloaderByIndy.Create(const AProxyParams: TProxyParams);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FIdHTTP := nil;
  FProxyParams := AProxyParams;
end;

destructor TDownloaderByIndy.Destroy;
begin
  FreeAndNil(FIdHTTP);
  FreeAndNil(FLock);
  inherited Destroy;
end;

procedure TDownloaderByIndy.InitIdHTTP(const AIsHttps: Boolean);
var
  VIOHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  FIdHTTP := TIdHTTP.Create(nil);
  FIdHTTP.Compressor := TIdCompressorZLib.Create(FIdHTTP);
  if AIsHttps then begin
    VIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(FIdHTTP);
    VIOHandler.SSLOptions.SSLVersions :=
      [sslvSSLv2, sslvSSLv23, sslvSSLv3, sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
    VIOHandler.SSLOptions.CipherList := 'ALL';
    FIdHTTP.IOHandler := VIOHandler;
  end;
  if FProxyParams.UseProxy then begin
    FIdHTTP.ProxyParams.ProxyServer := FProxyParams.ProxyServer;
    FIdHTTP.ProxyParams.ProxyPort := FProxyParams.ProxyPort;
    FIdHTTP.ProxyParams.ProxyUsername := FProxyParams.ProxyUsername;
    FIdHTTP.ProxyParams.ProxyPassword := FProxyParams.ProxyPassword;
  end;
end;

procedure TDownloaderByIndy.OnChunkReceived(Sender: TObject; var Chunk: TIdBytes);
begin
  FIsChunked := True;
end;

function TDownloaderByIndy.DoRequest(
  const AUrl: string;
  const ARawHeaders: string;
  const ARequestType: TRequestType
): IDownloadResponse;
var
  VIsHttps: Boolean;
  VRetryCount: Integer;
  VRespStream: TMemoryStream;
begin
  Result := nil;
  FLock.Acquire;
  try
    VRetryCount := 0;
    repeat
      try
        Inc(VRetryCount);

        if not Assigned(FIdHTTP) then begin
          VIsHttps := Pos('https://', AUrl) = 1;
          InitIdHTTP(VIsHttps);
        end else begin
          FIdHTTP.CheckForGracefulDisconnect(False);
        end;

        FIdHTTP.Request.CustomHeaders.Text := ARawHeaders;

        FIsChunked := False;

        FIdHTTP.HTTPOptions := [
          hoNoParseMetaHTTPEquiv,
          hoNoParseXmlCharset,
          hoNoProtocolErrorException,
          hoWantProtocolErrorContent,
          hoKeepOrigProtocol
        ];

        FIdHTTP.Request.Accept := '';
        FIdHTTP.Request.AcceptEncoding := '';
        FIdHTTP.Request.UserAgent := '';
        FIdHTTP.HandleRedirects := True;
        FIdHTTP.OnChunkReceived := Self.OnChunkReceived;

        FIdHTTP.ConnectTimeout := 0; // 20 sec.
        FIdHTTP.ReadTimeout := 30000;

        VRespStream := TMemoryStream.Create;
        try
          case ARequestType of
            rtGet: FIdHTTP.Get(AUrl, VRespStream);
            rtHead: FIdHTTP.Head(AUrl);
          else
            Assert(False);
          end;

          Result := TDownloadResponse.Create(
            FIdHTTP.ResponseCode,
            FIdHTTP.Response.RawHeaders.Text,
            FIdHTTP.Response.LastModified,
            VRespStream
          );
          VRespStream := nil; // TDownloadResponse owns this stream
        finally
          VRespStream.Free;
        end;
      except

      end;
    until (Result <> nil) or (VRetryCount > 2);
  finally
    FLock.Release;
  end;
end;

function TDownloaderByIndy.DoGetRequest(
  const AUrl: string;
  const ARawHeaders: string
): IDownloadResponse;
begin
  Result := DoRequest(AUrl, ARawHeaders, rtGet);
end;

function TDownloaderByIndy.DoHeadRequest(
  const AUrl: string;
  const ARawHeaders: string
): IDownloadResponse;
begin
  Result := DoRequest(AUrl, ARawHeaders, rtHead);
end;

end.
