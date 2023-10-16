unit u_DownloaderFactory;

interface

uses
  i_Downloader,
  i_DownloaderFactory;

type
  TDownloaderFactoryType = (dftIndy, dftHttpClient);

  TDownloaderFactory = class(TInterfacedObject, IDownloaderFactory)
  private
    FType: TDownloaderFactoryType;
  private
    { IDownloaderFactory }
    function BuildDownloader: IDownloader;
    function BuildDownloaderWithCache: IDownloader;
  public
    constructor Create(const AType: TDownloaderFactoryType);
  end;

implementation

uses
  System.SysUtils,
  u_DownloaderByIndy,
  u_DownloaderByHttpClient,
  u_DownloaderWithRamCache;

{ TDownloaderFactory }

constructor TDownloaderFactory.Create(const AType: TDownloaderFactoryType);
begin
  inherited Create;
  FType := AType;
end;

function TDownloaderFactory.BuildDownloader: IDownloader;
var
  VProxyParams: TProxyParams;
begin
  case FType of
    dftIndy: begin
       VProxyParams.UseProxy := False;
       Result := TDownloaderByIndy.Create(VProxyParams);
    end;
    dftHttpClient: begin
      Result := TDownloaderByHttpClient.Create;
    end;
  else
    raise Exception.Create(
      'Unknown DownloaderFactory Type: ' + IntToStr(Integer(FType))
    );
  end;
end;

function TDownloaderFactory.BuildDownloaderWithCache: IDownloader;
begin
  Result := TDownloaderWithRamCache.Create(Self.BuildDownloader);
end;

end.
