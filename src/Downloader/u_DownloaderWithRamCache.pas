unit u_DownloaderWithRamCache;

interface

uses
  System.SyncObjs,
  System.Generics.Collections,
  i_Downloader,
  i_DownloadRequest,
  i_DownloadResponse;

type
  TDownloaderWithRamCache = class(TInterfacedObject, IDownloader)
  private
    FDownloader: IDownloader;
    FLock: TCriticalSection;
    FCache: TDictionary<string, IDownloadResponse>;
  private
    function DoHeadRequest(const ARequest: IDownloadRequest): IDownloadResponse;
    function DoGetRequest(const ARequest: IDownloadRequest): IDownloadResponse;
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

function TDownloaderWithRamCache.DoGetRequest(const ARequest: IDownloadRequest): IDownloadResponse;
begin
  FLock.Acquire;
  try
    if not FCache.TryGetValue(ARequest.Url, Result) then begin
      Result := FDownloader.DoGetRequest(ARequest);
      FCache.Add(ARequest.Url, Result);
    end;
  finally
    FLock.Release;
  end;
end;

function TDownloaderWithRamCache.DoHeadRequest(const ARequest: IDownloadRequest): IDownloadResponse;
begin
  FLock.Acquire;
  try
    if not FCache.TryGetValue(ARequest.Url, Result) then begin
      Result := FDownloader.DoHeadRequest(ARequest);
      FCache.Add(ARequest.Url, Result);
    end;
  finally
    FLock.Release;
  end;
end;

end.
