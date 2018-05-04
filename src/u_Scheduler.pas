unit u_Scheduler;

interface

type
  TScheduler = class
  public
    class function AppCanStart: Boolean;
  end;

implementation

{ TScheduler }

class function TScheduler.AppCanStart: Boolean;
begin
  // ToDo
  Result := True;
end;

end.
