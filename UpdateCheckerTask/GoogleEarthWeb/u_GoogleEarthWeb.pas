unit u_GoogleEarthWeb;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_UpdateCheckerStoredInfo,
  u_UpdateCheckerTaskBase;

type
  TGoogleEarthWebCheckType = (gewctEarth, gewctClient);

  TGoogleEarthWeb = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleEarthWebCheckType;
    function GetUrl: string;
    function GetHeaders: string;
  protected
    function GetGUID: TGUID; override;
    function GetName: string; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleEarthWebCheckType;
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
  planetoid_metadata;

const
  cUrl: array [TGoogleEarthWebCheckType] of string = (
    'https://kh.google.com/rt/earth/PlanetoidMetadata',
    'https://earth.google.com/static/'
  );
  cName: array [TGoogleEarthWebCheckType] of string = (
    'Earth',
    'Client'
  );
  cGUID: array [TGoogleEarthWebCheckType] of string = (
    '{CABC52B6-A855-43D8-88CB-718A04ECF82F}',
    '{E36D2679-DEA2-4E05-93D0-777DF1E9F913}'
  );

{ TGoogleEarthWeb }

constructor TGoogleEarthWeb.Create(
  const ACheckType: TGoogleEarthWebCheckType;
  const ADownloader: IDownloader;
  const AStoredInfo: IUpdateCheckerStoredInfo;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AStoredInfo, AListener);
  FCheckType := ACheckType;
end;

function TGoogleEarthWeb.GetGUID: TGUID;
begin
  Result := StringToGUID(cGUID[FCheckType]);
end;

function TGoogleEarthWeb.GetName: string;
begin
  Result := cName[FCheckType];
end;

function TGoogleEarthWeb.GetUrl: string;
begin
  Result := cUrl[FCheckType];
end;

function TGoogleEarthWeb.GetHeaders: string;
begin
  Result :=
    'User-Agent: ' + cBrowserUserAgent + #13#10 +
    'Accept: */*' + #13#10 +
    'Accept-Encoding: gzip,deflate' + #13#10 +
    'Accept-Language: en-us,en,*';
end;

function GetClientVersion(const AText: string): string;
var
  VPattern: string;
  VMatch: TMatch;
begin
  Result := '';
  if AText <> '' then begin
    VPattern := '\"app_min(.*?)\.html\":"(.*?)/app_min(.*?)\.html"';
    VMatch := TRegEx.Match(AText, VPattern, [roIgnoreCase, roMultiLine]);
    if VMatch.Success then begin
      Result := VMatch.Groups.Item[2].Value;
    end;
  end;
end;

procedure SaveDump(const AData: Pointer; const ASize: Int64);
var
  VStream: TFileStream;
begin
  VStream := TFileStream.Create('pb_dump.bin', fmCreate);
  try
    VStream.Write(AData^, ASize + 4);
  finally
    VStream.Free;
  end;
end;

function GetVersion(const AData: Pointer; const ASize: Int64): string;
var
  f02, f05: Integer;
  VPlanetoidMetadata: TPlanetoidMetadata;
begin
  Result := '';
  if ASize > 0 then begin
    try
      VPlanetoidMetadata := TPlanetoidMetadata.Create;
      try
        VPlanetoidMetadata.LoadFromMem(AData, ASize);
        f02 := VPlanetoidMetadata.epoch.f02;
        f05 := VPlanetoidMetadata.epoch.f05;
        if f02 = f05 then begin
          Result := IntToStr(f02);
        end else begin
          Result := IntToStr(f02) + ',' + IntToStr(f05);
        end;
      finally
        VPlanetoidMetadata.Free;
      end;
    except
      SaveDump(AData, ASize);
      raise;
    end;
  end;
end;

procedure TGoogleEarthWeb.DoExecute;
var
  VUrl: string;
  VRawHeaders: string;
  VResponse: IDownloadResponse;
begin
  VUrl := GetUrl;
  VRawHeaders := GetHeaders;
  VResponse := FDownloader.DoGetRequest(VUrl, VRawHeaders);
  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;
    case FCheckType of
      gewctEarth:  FInfo.Version := GetVersion(VResponse.Body, VResponse.BodySize);
      gewctClient: FInfo.Version := GetClientVersion(VResponse.GetBodyAsText);
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
