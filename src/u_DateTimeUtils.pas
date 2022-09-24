unit u_DateTimeUtils;

interface

function LocalTimeToUTC(const ALocalTime: TDateTime): TDateTime;
function UTCToLocalTime(const AUTC: TDateTime): TDateTime;

function DateTimeToRFC1123(const ADate: TDateTime): string;
function RFC1123ToDateTime(const AStr: string): TDateTime;

implementation

uses
  Windows,
  SysUtils,
  IdGlobalProtocols; // for GMTToLocalDateTime

function LocalTimeToUTC(const ALocalTime: TDateTime): TDateTime;
var
  ST1, ST2: TSystemTime;
  TZ: TTimeZoneInformation;
begin
  GetTimeZoneInformation(TZ);

  TZ.Bias := -TZ.Bias;
  TZ.StandardBias := -TZ.StandardBias;
  TZ.DaylightBias := -TZ.DaylightBias;

  DateTimeToSystemTime(ALocalTime, ST1);
  SystemTimeToTzSpecificLocalTime(@TZ, ST1, ST2);
  Result := SystemTimeToDateTime(ST2);
end;

function UTCToLocalTime(const AUTC: TDateTime): TDateTime;
var
  ST1, ST2: TSystemTime;
  TZ:TTimeZoneInformation;
begin
  GetTimeZoneInformation(TZ);
  DateTimeToSystemTime(AUTC, ST1);
  SystemTimeToTzSpecificLocalTime(@TZ, ST1, ST2);
  Result := SystemTimeToDateTime(ST2);
end;

function DateTimeToRFC1123(const ADate: TDateTime): string;
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

function RFC1123ToDateTime(const AStr: string): TDateTime;
begin
  Result := GMTToLocalDateTime(AStr);
  if Result <> 0 then begin
    Result := LocalTimeToUTC(Result);
  end;
end;

end.
