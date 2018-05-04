unit i_UpdateCheckerStoredInfo;

interface

type
  TStoredInfoRec = record
    Version: string;
    LastModified: TDateTime;
    LastCheck: TDateTime;
  end;

  IUpdateCheckerStoredInfo = interface
    ['{F3BB0A7F-5CF0-450B-98A0-32438DA0010C}']
    function Read(const AGUID: TGUID; out AInfo: TStoredInfoRec): Boolean;
    procedure Write(const AGUID: TGUID; const AInfo: TStoredInfoRec);
  end;

implementation

end.
