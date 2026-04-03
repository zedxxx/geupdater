unit i_ConfigBase;

interface

uses
  System.IniFiles;

type
  IConfigBase = interface
    ['{45F49EA3-66D7-4BE6-ADFF-6197165DCD60}']

    procedure DoReadConfig(const AIni: TMemIniFile);
    procedure DoWriteConfig(const AIni: TMemIniFile);
  end;

implementation

end.
