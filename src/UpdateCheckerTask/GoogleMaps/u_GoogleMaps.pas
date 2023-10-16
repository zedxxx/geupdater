unit u_GoogleMaps;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_EventLogStorage,
  u_UpdateCheckerTaskBase;

type
  TGoogleMapsCheckType = (gmctEarth, gmctMars, gmctMoon, gmctSat, gmctApi);

const
  cGoogleMapsClassicSet: set of TGoogleMapsCheckType = [gmctSat, gmctApi];

type
  TGoogleMaps = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleMapsCheckType;
    function GetHeaders: string;
  protected
    function GetConf: TTaskConf; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleMapsCheckType;
      const ADownloader: IDownloader;
      const AEventLog: IEventLogStorage;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  RegularExpressions,
  c_UserAgent,
  c_UpdateCheckerTask,
  i_DownloadResponse,
  u_PlanetoidMetadata;

const
  cTaskConf: array [TGoogleMapsCheckType] of TTaskConf = (
    (GUID:        cGoogleMapsEarthGUID;
     RequestUrl:  'https://kh.google.com/rt/earth/PlanetoidMetadata';
     DisplayName: 'Earth'),

    (GUID:        cGoogleMapsMarsGUID;
     RequestUrl:  'https://khms.google.com/dm/Epoch?db=mars';
     DisplayName: 'Mars'),

    (GUID:        cGoogleMapsMoonGUID;
     RequestUrl:  'https://khms.google.com/dm/Epoch?db=moon';
     DisplayName: 'Moon'),

    (GUID:        cGoogleMapsClassicEarthGUID;
     RequestUrl:  'https://maps.googleapis.com/maps/api/js';
     DisplayName: 'Earth'),

    (GUID:        cGoogleMapsClassicJSAPIGUID;
     RequestUrl:  'https://maps.googleapis.com/maps/api/js';
     DisplayName: 'JS API')
  );

{ TGoogleMaps }

constructor TGoogleMaps.Create(
  const ACheckType: TGoogleMapsCheckType;
  const ADownloader: IDownloader;
  const AEventLog: IEventLogStorage;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AEventLog, AListener);
  FCheckType := ACheckType;
end;

function TGoogleMaps.GetConf: TTaskConf;
begin
  Result := cTaskConf[FCheckType];
end;

function TGoogleMaps.GetHeaders: string;
begin
  Result :=
    'User-Agent: ' + cBrowserUserAgent + #13#10 +
    'Accept: text/html, */*' + #13#10 +
    'Accept-Language: en-us,en,*';
end;

function GetSatVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := 'https://khms\d+.googleapis\.com/kh\?v=(\d+)';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

function GetApiVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '\[\"https://maps\.googleapis\.com/maps-api-(.*?)",\"(.*?)\"\]';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[2].Value;
    end;
  end;
end;

function GetDbVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '(\d+)';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[1].Value;
    end;
  end;
end;

function GetVersion(const AData: Pointer; const ASize: Int64): string;
var
  VMetadata: TPlanetoidMetadataRec;
begin
  Result := '';
  if ASize > 0 then begin
    if ParseMetadata(AData, ASize, VMetadata) then begin
      if VMetadata.Epoch_02 = VMetadata.Epoch_05 then begin
        Result := IntToStr(VMetadata.Epoch_02);
      end else begin
        Result := Format('%d,%d', [VMetadata.Epoch_02, VMetadata.Epoch_05]);
      end;
    end;
  end;
end;

procedure TGoogleMaps.DoExecute;
var
  VRawHeaders: string;
  VResponse: IDownloadResponse;
begin
  VRawHeaders := GetHeaders;
  VResponse := FDownloader.DoGetRequest(FInfo.Conf.RequestUrl, VRawHeaders);
  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;
    case FCheckType of
      gmctSat: FInfo.Version := GetSatVersion(VResponse.GetBodyAsText);
      gmctApi: FInfo.Version := GetApiVersion(VResponse.GetBodyAsText);
      gmctEarth: FInfo.Version := GetVersion(VResponse.Body, VResponse.BodySize);
      gmctMars, gmctMoon: FInfo.Version := GetDbVersion(VResponse.GetBodyAsText);
    else
      Assert(False);
    end;
    FInfo.IsUpdatesFound := not FPrevInfoExists or (FPrevInfo.Version <> FInfo.Version);
  end else begin
    FInfo.State := tsFailed;
  end;
end;

end.
