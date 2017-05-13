unit u_DownloaderWithRamCache;

interface

uses
  System.SyncObjs,
  System.Generics.Collections,
  i_Downloader,
  i_DownloadResponse;

type
  TDownloaderWithRamCache = class(TInterfacedObject, IDownloader)
  private
    FDownloader: IDownloader;
    FLock: TCriticalSection;
    FCache: TDictionary<string, IDownloadResponse>;
  private
    function DoHeadRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;

    function DoGetRequest(
      const AUrl: string;
      const ARawHeaders: string
    ): IDownloadResponse;
  public
    constructor Create(const ADownloader: IDownloader);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ TDownloaderWithRamCache }

constructor TDownloaderWithRamCache.Create(const ADownloader: IDownloader);
begin
  Assert(Adownloader <> nil);
  inherited Create;
  FDownloader := ADownloader;
  FLock := TCriticalSection.Create;
  FCache := TDictionary<string, IDownloadResponse>.Create;
end;

destructor TDownloaderWithRamCache.Destroy;
begin
  FDownloader := nil;
  FreeAndNil(FCache);
  FreeAndNil(FLock);
  inherited;
end;

function TDownloaderWithRamCache.DoGetRequest(
  const AUrl: string;
  const ARawHeaders: string
): IDownloadResponse;
begin
  FLock.Acquire;
  try
    if not FCache.TryGetValue(AUrl, Result) then begin
      Result := FDownloader.DoGetRequest(AUrl, ARawHeaders);
      FCache.Add(AUrl, Result);
    end;
  finally
    FLock.Release;
  end;
end;

function TDownloaderWithRamCache.DoHeadRequest(
  const AUrl: string;
  const ARawHeaders: string
): IDownloadResponse;
begin
  FLock.Acquire;
  try
    if not FCache.TryGetValue(AUrl, Result) then begin
      Result := FDownloader.DoHeadRequest(AUrl, ARawHeaders);
      FCache.Add(AUrl, Result);
    end;
  finally
    FLock.Release;
  end;
end;

end.
