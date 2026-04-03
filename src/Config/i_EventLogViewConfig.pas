unit i_EventLogViewConfig;

interface

uses
  System.Types,
  i_ConfigBase;

type
  TTreeColumnState = record
    Name: string;
    Size: Integer;
    Position: Integer;
  end;
  TTreeColumnsState = array of TTreeColumnState;

  TTreeShowOptRec = record
    SortColumn: Integer;
    SortDirection: Integer;
  end;

  IEventLogViewConfig = interface(IConfigBase)
    ['{C4E3918B-7487-444F-972E-5737FDC4ED1B}']

    function GetBounds: TRect;
    procedure SetBounds(const ARect: TRect);
    property Bounds: TRect read GetBounds write SetBounds;

    function GetTreeColumnsState: TTreeColumnsState;
    procedure SetTreeColumnsState(const AValue: TTreeColumnsState);
    property TreeColumnsState: TTreeColumnsState read GetTreeColumnsState write SetTreeColumnsState;

    function GetTreeShowOpt: TTreeShowOptRec;
    procedure SetTreeShowOpt(const AValue: TTreeShowOptRec);
    property TreeShowOpt: TTreeShowOptRec read GetTreeShowOpt write SetTreeShowOpt;
  end;

implementation

end.
