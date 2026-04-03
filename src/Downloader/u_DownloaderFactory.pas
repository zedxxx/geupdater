unit u_DownloaderFactory;

interface

uses
  i_Downloader,
  i_DownloaderFactory;

type
  TDownloaderFactory = class(TInterfacedObject, IDownloaderFactory)
  private
    { IDownloaderFactory }
    function BuildDownloader: IDownloader;
    function BuildDownloaderWithCache: IDownloader;
  end;

implementation

uses
  u_DownloaderByHttpClient,
  u_DownloaderWithRamCache;

{ TDownloaderFactory }

function TDownloaderFactory.BuildDownloader: IDownloader;
begin
  Result := TDownloaderByHttpClient.Create;
end;

function TDownloaderFactory.BuildDownloaderWithCache: IDownloader;
begin
  Result := TDownloaderWithRamCache.Create(Self.BuildDownloader);
end;

end.
