unit u_GoogleEarthClassic;

interface

uses
  t_TaskInfo,
  i_Downloader,
  i_TaskInfoListener,
  i_UpdateCheckerStoredInfo,
  u_UpdateCheckerTaskBase;

type
  TGoogleEarthClassicCheckType = (
    gecctEarth,
    gecctHistory,
    gecctSky,
    gecctMars,
    gecctMoon,
    gecctClient
  );

  TGoogleEarthClassic = class(TUpdateCheckerTaskBase)
  private
    FCheckType: TGoogleEarthClassicCheckType;
    function GetUrl: string;
    function GetHeaders: string;
    function IsClientCheck: Boolean; inline;
  protected
    function GetGUID: TGUID; override;
    function GetName: string; override;
    procedure DoExecute; override;
  public
    constructor Create(
      const ACheckType: TGoogleEarthClassicCheckType;
      const ADownloader: IDownloader;
      const AStoredInfo: IUpdateCheckerStoredInfo;
      const AListener: TArray<ITaskInfoListener>
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  c_UserAget,
  i_DownloadResponse;

const
  cUrl: array [TGoogleEarthClassicCheckType] of string = (
    'http://kh.google.com/dbRoot.v5?',
    'http://khmdb.google.com/dbRoot.v5?db=tm&',
    'http://khmdb.google.com/dbRoot.v5?db=sky&',
    'http://khmdb.google.com/dbRoot.v5?db=mars&',
    'http://khmdb.google.com/dbRoot.v5?db=moon&',
    'http://dl.google.com/earth/client/advanced/current/GoogleEarthProWin.exe'
  );

  cName: array [TGoogleEarthClassicCheckType] of string = (
    'Earth',
    'History',
    'Sky',
    'Mars',
    'Moon',
    'Client'
  );

  cGUID: array [TGoogleEarthClassicCheckType] of string = (
    '{2736BF1B-C010-4262-91DD-BFA152DAB1E1}',
    '{FC49C486-B6CD-4FF2-B7A8-413EA1402695}',
    '{9D7D345D-F3F1-4287-8A3D-EE6AA3099BE8}',
    '{F5872C50-7F68-4B43-AED3-DB34A71B5FA4}',
    '{AC2DAEA2-8F2A-42FC-87E1-397DA2C203F3}',
    '{146E4984-C081-4DA0-9F79-5855F271923C}'
  );

function DateTimeToRFC1123(ADate: TDateTime): string;
const
  cStrWeekDay: string = 'MonTueWedThuFriSatSun';
  cStrMonth: string = 'JanFebMarAprMayJunJulAugSepOctNovDec';
var
  VYear, VMonth, VDay: Word;
  VHour, VMin, VSec, VMSec: Word;
  VDayOfWeek: Word;
begin
  DecodeDate(ADate, VYear, VMonth, VDay);
  DecodeTime(ADate, VHour, VMin, VSec, VMSec);
  VDayOfWeek := (Trunc(ADate) - 2) mod 7;
  Result :=
    Copy(cStrWeekDay, 1 + VDayOfWeek * 3, 3) + ', ' +
    Format(
      '%2.2d %s %4.4d %2.2d:%2.2d:%2.2d',
      [VDay, Copy(cStrMonth, 1 + 3 * (VMonth - 1), 3), VYear, VHour, VMin, VSec]
    ) + ' GMT';
end;

{ TGoogleEarthClassic }

constructor TGoogleEarthClassic.Create(
  const ACheckType: TGoogleEarthClassicCheckType;
  const ADownloader: IDownloader;
  const AStoredInfo: IUpdateCheckerStoredInfo;
  const AListener: TArray<ITaskInfoListener>
);
begin
  inherited Create(ADownloader, AStoredInfo, AListener);
  FCheckType := ACheckType;
end;

function TGoogleEarthClassic.GetGUID: TGUID;
begin
  Result := StringToGUID(cGUID[FCheckType]);
end;

function TGoogleEarthClassic.GetName: string;
begin
  Result := cName[FCheckType];
end;

function TGoogleEarthClassic.IsClientCheck: Boolean;
begin
  Result := FCheckType = gecctClient;
end;

function TGoogleEarthClassic.GetUrl: string;
begin
  Result := cUrl[FCheckType];
  if not IsClientCheck then begin
    Result := Result + 'hl=en-GB&gl=us';
  end;
end;

function TGoogleEarthClassic.GetHeaders: string;
var
  VIfModifiedSince: string;
begin
  if IsClientCheck then begin
    Result :=
      'User-Agent: ' + cBrowserUserAgent + #13#10 +
      'Accept: */*' + #13#10 +
      'Accept-Encoding: gzip,deflate' + #13#10 +
      'Accept-Language: en-us,en,*';
  end else begin
    if FHasStoredInfo then begin
      VIfModifiedSince :=
        'If-Modified-Since: ' + DateTimeToRFC1123(FStoredInfoRec.LastCheck) + #13#10;
    end else begin
      VIfModifiedSince := '';
    end;
    Result :=
      'User-Agent: ' + cClientClassicUserAgent + #13#10 +
      VIfModifiedSince +
      'Accept: application/vnd.google-earth.kml+xml, application/vnd.google-earth.kmz, image/*, */*' + #13#10 +
      'Accept-Encoding: gzip,deflate' + #13#10 +
      'Accept-Language: en-us,en,*' + #13#10 +
      'Accept-Charset: iso-8859-1,*,utf-8';
  end;
end;

function GetDbRootVersion(const AData: Pointer; const ASize: Int64): string;
var
  VPtr: PByte;
  VVersion: PWord;
begin
  Result := '';
  VPtr := AData;
  Assert(VPtr <> nil);
  if ASize > 8 then begin
    Inc(VPtr, 6);
    VVersion := PWord(VPtr);
    Result := IntToStr(VVersion^ xor $4200);
  end;
end;

procedure TGoogleEarthClassic.DoExecute;
var
  VUrl: string;
  VRawHeaders: string;
  VResponse: IDownloadResponse;
begin
  VUrl := GetUrl;
  VRawHeaders := GetHeaders;

  if IsClientCheck then begin
    VResponse := FDownloader.DoHeadRequest(VUrl, VRawHeaders);
  end else begin
    VResponse := FDownloader.DoGetRequest(VUrl, VRawHeaders);
  end;

  if VResponse.Code = 200 then begin
    FInfo.State := tsFinished;
    FInfo.LastModified := VResponse.LastModified;

    if IsClientCheck then begin
      FInfo.Version := '-';
      FInfo.IsUpdatesFound :=
        not FHasStoredInfo or
        (FStoredInfoRec.LastModified <> FInfo.LastModified);
    end else begin
      FInfo.Version := GetDbRootVersion(VResponse.Body, VResponse.BodySize);
      FInfo.IsUpdatesFound :=
        not FHasStoredInfo or
        (FStoredInfoRec.Version <> FInfo.Version);
    end;
  end else if VResponse.Code = 304 then begin // Not Modified
    Assert(FHasStoredInfo);
    FInfo.State := tsFinished;
    FInfo.LastModified := FStoredInfoRec.LastModified;
    FInfo.Version := FStoredInfoRec.Version;
  end else begin
    FInfo.State := tsFailed;
  end;
end;

end.
