unit u_DownloaderFactory;

interface

uses
  i_Downloader,
  i_DownloaderFactory;

type
  TDownloaderFactory = class(TInterfacedObject, IDownloaderFactory)
  private
    FType: Byte;
  private
    { IDownloaderFactory }
    function BuildDownloader: IDownloader;
    function BuildDownloaderWithCache: IDownloader;
  public
    constructor Create(const AType: Byte = 0);
  end;

implementation

uses
  System.SysUtils,
  u_DownloaderByIndy,
  u_DownloaderByHttpClient,
  u_DownloaderWithRamCache;

{ TDownloaderFactory }

constructor TDownloaderFactory.Create(const AType: Byte);
begin
  inherited Create;
  FType := AType;
end;

function TDownloaderFactory.BuildDownloader: IDownloader;
var
  VProxyParams: TProxyParams;
begin
  case FType of
    0: begin
       VProxyParams.UseProxy := False;
       Result := TDownloaderByIndy.Create(VProxyParams);
    end;
    1: Result := TDownloaderByHttpClient.Create;
  else
    raise Exception.Create('Unknown downloader type: ' + IntToStr(FType));
  end;
end;

function TDownloaderFactory.BuildDownloaderWithCache: IDownloader;
begin
  Result := TDownloaderWithRamCache.Create(Self.BuildDownloader);
end;

end.
