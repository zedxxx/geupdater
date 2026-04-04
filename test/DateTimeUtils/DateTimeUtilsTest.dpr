program DateTimeUtilsTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.DateUtils,
  u_DateTimeUtils in '..\..\src\u_DateTimeUtils.pas';

procedure DoTest;
var
  VDate,VDate2: TDateTime;
  VDateUtc, VDateUtc2: TDateTime;
  VHttpDate: string;
begin
  VDate := RecodeMilliSecond(Now, 0);
  VDateUtc := LocalTimeToUtc(VDate);
  VHttpDate := DateTimeToHttpDate(VDateUtc);

  Writeln('Local : ', DateTimeToStr(VDate));
  Writeln('UTC   : ', DateTimeToStr(VDateUtc));
  Writeln('HTTP  : ', VHttpDate);

  VDateUtc2 := HttpDateToDateTime(VHttpDate);
  VDate2 := UtcToLocalTime(VDateUtc2);

  if not SameDateTime(VDate, VDate2) then begin
    raise Exception.Create('Date conversion error!');
  end;
end;

procedure DoDayOfWeekTest;
var
  I: Integer;
  VDate: TDateTime;
  Year, Month, Day, DOW: Word;
begin
  VDate := RecodeMilliSecond(Now, 0);

  for I := 0 to 3 do begin
    Writeln;

    DOW := System.DateUtils.DayOfTheWeek(VDate);   // ISO 8601: Mon, Tue, ..., Sun
    Writeln('DayOfTheWeek    : ', DOW);

    DOW := System.SysUtils.DayOfWeek(VDate);       // Sun, Mon, ..., Sat
    Writeln('DayOfWeek       : ', DOW);

    DecodeDateFully(VDate, Year, Month, Day, DOW); // Sun, Mon, ..., Sat
    Writeln('DecodeDateFully : ', DOW);

    VDate := IncDay(VDate);
  end;
end;

begin
  try
    DoTest;
    DoDayOfWeekTest;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Writeln(#13#10, 'Press ENTER to exit...');
  Readln;
end.
