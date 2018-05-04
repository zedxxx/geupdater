unit i_TaskInfoListener;

interface

uses
  t_TaskInfo;

type
  ITaskInfoListener = interface
    ['{5DAD386E-C197-4A28-A05C-BCC786A1D83D}']
    procedure Update(const AInfo: TTaskInfo);
  end;

implementation

end.
