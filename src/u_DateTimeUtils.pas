unit u_DateTimeUtils;

interface

{$DEFINE USE_RTL_HTTP_DATE_PARSER}

function LocalTimeToUtc(const ALocalTime: TDateTime): TDateTime;
function UtcToLocalTime(const AUtc: TDateTime): TDateTime;

function DateTimeToHttpDate(const AUtc: TDateTime): string;
function HttpDateToDateTime(const AStr: string): TDateTime;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  {$IFDEF USE_RTL_HTTP_DATE_PARSER}
  Web.HTTPApp
  {$ELSE}
  IdGlobalProtocols
  {$ENDIF USE_RTL_HTTP_DATE_PARSER};

function LocalTimeToUtc(const ALocalTime: TDateTime): TDateTime;
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

function UtcToLocalTime(const AUtc: TDateTime): TDateTime;
var
  ST1, ST2: TSystemTime;
  TZ:TTimeZoneInformation;
begin
  GetTimeZoneInformation(TZ);
  DateTimeToSystemTime(AUtc, ST1);
  SystemTimeToTzSpecificLocalTime(@TZ, ST1, ST2);
  Result := SystemTimeToDateTime(ST2);
end;

function DateTimeToHttpDate(const AUtc: TDateTime): string;
const
  cWeekDays: array[1..7] of string = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
  cMonths: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  Year, Month, Day, DOW: Word;
  Hour, Min, Sec, MSec: Word;
begin
  DecodeDateFully(AUtc, Year, Month, Day, DOW);
  DecodeTime(AUtc, Hour, Min, Sec, MSec);

  Result := Format('%s, %2.2d %s %4.4d %2.2d:%2.2d:%2.2d GMT',
    [cWeekDays[DOW], Day, cMonths[Month], Year, Hour, Min, Sec]);
end;

{$IFDEF USE_RTL_HTTP_DATE_PARSER}
function HttpDateToDateTime(const AStr: string): TDateTime;
begin
  Result := Web.HTTPApp.ParseDate(AStr);
end;
{$ELSE}
function HttpDateToDateTime(const AStr: string): TDateTime;
begin
  Result := IdGlobalProtocols.GMTToLocalDateTime(AStr);
  if Result <> 0 then begin
    Result := LocalTimeToUtc(Result);
  end;
end;
{$ENDIF USE_RTL_HTTP_DATE_PARSER}

end.
