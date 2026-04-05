unit u_LanguageManager;

interface

type
  TLanguageManager = record
    class procedure LoadLocalization(const ALangName: string = ''); static;
  end;

implementation

uses
  SysUtils,
  UITypes,
  Dialogs,
  amLanguageInfo,
  amVersionInfo;

{ TLanguageManager }

class procedure TLanguageManager.LoadLocalization(const ALangName: string);
const
  cDefaultLocaleName = 'en-US';
var
  VLanguage: TLanguageItem;
  VExeName, VModuleName: string;
  VExeVersion, VModuleVersion: string;
begin
  VExeName := ParamStr(0);

  if DirectoryExists(ExtractFilePath(VExeName) + 'res') then begin
    amLanguageInfo.ResourceModulePaths := 'res';
  end;

  if ALangName = '' then begin
    VLanguage := LanguageInfo.FindLCID(GetSystemDefaultUILanguage);
  end else begin
    VLanguage := LanguageInfo.FindLocaleName(ALangName);
  end;

  if VLanguage = nil then begin
    VLanguage := LanguageInfo.FindLocaleName(cDefaultLocaleName);
  end;

  if (LoadNewResourceModule(VLanguage, VModuleName) <> 0) and (VModuleName <> '') then begin

    VExeVersion := TVersionInfo.FileVersionString(VExeName);
    VModuleVersion := TVersionInfo.FileVersionString(VModuleName);

    if VExeVersion <> VModuleVersion then begin

      // fallback to default
      amLanguageInfo.SetResourceHInstance(HInstance);
      {$IF RTLVersion >= 34}
      ResStringCleanupCache;
      {$ENDIF}

      MessageDlg(Format(
        'Version Mismatch Error!' + #13#10 + #13#10 +
        'The language module "%s" (v%s) is incompatible with the current application version (v%s).' + #13#10 + #13#10 +
        'Module: %s' + #13#10 + #13#10 +
        'Please update or reinstall the application.',
        [VLanguage.EnglishLanguageName, VModuleVersion, VExeVersion, ExtractFileName(VModuleName)]),
        mtError, [mbOk], 0
      );
    end;
  end;
end;

end.
