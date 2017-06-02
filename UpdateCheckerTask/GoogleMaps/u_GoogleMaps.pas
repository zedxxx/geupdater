unit u_GoogleMaps;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_UpdateCheckerStoredInfo,
  u_UpdateCheckerTaskBase;

type
  TGoogleMapsCheckType = (gmctEarth, gmctMars, gmctMoon, gmctSat, gmctApi);

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
      const AStoredInfo: IUpdateCheckerStoredInfo;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  RegularExpressions,
  c_UserAget,
  i_DownloadResponse,
  u_PlanetoidMetadata;

const
  cTaskConf: array [TGoogleMapsCheckType] of TTaskConf = (
    (GUID:        '{34D0C112-755B-4D4F-B9A4-9F4961E5FA84}';
     RequestUrl:  'https://kh.google.com/rt/earth/PlanetoidMetadata';
     DisplayName: 'Earth'),

    (GUID:        '{A6359894-6FA9-4717-801A-4D011DC8AAAD}';
     RequestUrl:  'https://khms.google.com/dm/Epoch?db=mars';
     DisplayName: 'Mars'),

    (GUID:        '{42F97AF2-D938-4056-9F7B-738BDADA6CF8}';
     RequestUrl:  'https://khms.google.com/dm/Epoch?db=moon';
     DisplayName: 'Moon'),

    (GUID:        '{D732DF07-37C4-4773-9C88-AA95C1A7AAFF}';
     RequestUrl:  'https://maps.googleapis.com/maps/api/js';
     DisplayName: 'Flat Earth'),

    (GUID:        '{45B30A7C-F81D-4E85-9E7D-52DE35E25173}';
     RequestUrl:  'https://maps.googleapis.com/maps/api/js';
     DisplayName: 'JS API')
  );

{ TGoogleMaps }

constructor TGoogleMaps.Create(
  const ACheckType: TGoogleMapsCheckType;
  const ADownloader: IDownloader;
  const AStoredInfo: IUpdateCheckerStoredInfo;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AStoredInfo, AListener);
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
    'Accept-Encoding: gzip,deflate' + #13#10 +
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
    VPattern := '\[\"https://maps\.googleapis\.com/maps-api-(.*?)/api/js/\d+/\d+\",\"(.*?)\"\]';
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
    FInfo.IsUpdatesFound :=
      not FHasStoredInfo or
      (FStoredInfoRec.Version <> FInfo.Version);
  end else begin
    FInfo.State := tsFailed;
  end;
end;

end.
