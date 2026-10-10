; SPDX-License-Identifier: GPL-3.0-or-later
Unicode true
!include MUI2.nsh
!include LogicLib.nsh
!include x64.nsh
!include WinVer.nsh

!ifndef PAYLOAD_DIR
  !error "Wymagany parametr PAYLOAD_DIR."
!endif
!ifndef OUTPUT_FILE
  !error "Wymagany parametr OUTPUT_FILE."
!endif
!ifndef UNINSTALL_LIST
  !error "Wymagany parametr UNINSTALL_LIST."
!endif
!ifndef APP_ID
  !define APP_ID "LoriiTorrent"
!endif

Name "LoriiTorrent 5.2.4-r3"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\LoriiTorrent"
InstallDirRegKey HKCU "Software\${APP_ID}" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 32
ShowInstDetails show
ShowUninstDetails show
VIProductVersion "5.2.4.3"
VIAddVersionKey /LANG=1045 "ProductName" "LoriiTorrent"
VIAddVersionKey /LANG=1045 "FileDescription" "Instalator LoriiTorrent 5.2.4-r3"
VIAddVersionKey /LANG=1045 "FileVersion" "5.2.4.3"
VIAddVersionKey /LANG=1045 "ProductVersion" "5.2.4-r3"
VIAddVersionKey /LANG=1045 "LegalCopyright" "Autorzy qBittorrent i LoriiTorrent; GPLv3 lub nowsza"
!define MUI_ICON "${__FILEDIR__}\..\..\upstream\src\icons\qbittorrent.ico"
!define MUI_UNICON "${__FILEDIR__}\..\..\upstream\src\icons\qbittorrent.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Witaj w instalatorze LoriiTorrent"
!define MUI_WELCOMEPAGE_TEXT "LoriiTorrent to otwarty fork qBittorrenta 5.2.4 z poprawkami pobierania z webseedów.$\r$\n$\r$\nProgram zostanie zainstalowany dla bieżącego użytkownika. Korzysta z osobnego profilu i nie przejmuje ustawień zwykłego qBittorrenta."
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_RUN_TEXT "Uruchom LoriiTorrent"
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchApplication
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${__FILEDIR__}\license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!insertmacro MUI_LANGUAGE "Polish"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "Ta wersja wymaga 64-bitowego Windows."
    Abort
  ${EndIf}
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_ICONSTOP "Ta wersja wymaga Windows 10 lub nowszego."
    Abort
  ${EndIf}
  SetRegView 64
  SetShellVarContext current
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuildNumber"
  IntCmp $0 17763 SupportedWindows OlderWindows SupportedWindows
  OlderWindows:
    MessageBox MB_ICONSTOP "Ta wersja wymaga Windows 10 od wersji 1809 lub Windows 11."
    Abort
  SupportedWindows:
FunctionEnd

Function LaunchApplication
  Exec '$\"$INSTDIR\bin\qbittorrent.exe$\" $\"--profile=$APPDATA\LoriiTorrent$\"'
FunctionEnd

Section "Program i skrót w menu Start" Main
  SectionIn RO
  IfFileExists "$INSTDIR\bin\qbittorrent.exe" 0 ApplicationClosed
  ClearErrors
  FileOpen $0 "$INSTDIR\bin\qbittorrent.exe" a
  IfErrors ApplicationInUse 0
  FileClose $0
  Goto ApplicationClosed
  ApplicationInUse:
    MessageBox MB_ICONSTOP "Zamknij LoriiTorrent z tego katalogu przed aktualizacją."
    SetErrorLevel 2
    Quit
  ApplicationClosed:
  SetOutPath "$INSTDIR"
  File /r "${PAYLOAD_DIR}\*"
  WriteUninstaller "$INSTDIR\Uninstall-LoriiTorrent.exe"
  CreateDirectory "$SMPROGRAMS\${APP_ID}"
  CreateShortcut "$SMPROGRAMS\${APP_ID}\LoriiTorrent.lnk" "$INSTDIR\bin\qbittorrent.exe" '$\"--profile=$APPDATA\LoriiTorrent$\"'
  CreateShortcut "$SMPROGRAMS\${APP_ID}\Odinstaluj.lnk" "$INSTDIR\Uninstall-LoriiTorrent.exe"
  WriteRegStr HKCU "Software\${APP_ID}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "LoriiTorrent"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "5.2.4-r3"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "Projekt LoriiTorrent"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayIcon" "$INSTDIR\bin\qbittorrent.exe,0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" '$\"$INSTDIR\Uninstall-LoriiTorrent.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "QuietUninstallString" '$\"$INSTDIR\Uninstall-LoriiTorrent.exe$\" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1
SectionEnd

Section /o "Skrót na pulpicie" Desktop
  CreateShortcut "$DESKTOP\${APP_ID}.lnk" "$INSTDIR\bin\qbittorrent.exe" '$\"--profile=$APPDATA\LoriiTorrent$\"'
SectionEnd

Section /o "Zarejestruj obsługę torrentów i magnetów" Associations
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Torrent" "" "Plik torrent LoriiTorrent"
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Torrent\DefaultIcon" "" "$INSTDIR\bin\qbittorrent.exe,0"
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Torrent\shell\open\command" "" '$\"$INSTDIR\bin\qbittorrent.exe$\" $\"--profile=$APPDATA\LoriiTorrent$\" $\"%1$\"'
  WriteRegStr HKCU "Software\Classes\.torrent\OpenWithProgids" "${APP_ID}.Torrent" ""
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Magnet" "" "Odnośnik magnet LoriiTorrent"
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Magnet" "URL Protocol" ""
  WriteRegStr HKCU "Software\Classes\${APP_ID}.Magnet\shell\open\command" "" '$\"$INSTDIR\bin\qbittorrent.exe$\" $\"--profile=$APPDATA\LoriiTorrent$\" $\"%1$\"'
  WriteRegStr HKCU "Software\${APP_ID}\Capabilities" "ApplicationName" "LoriiTorrent"
  WriteRegStr HKCU "Software\${APP_ID}\Capabilities" "ApplicationDescription" "Klient BitTorrent z automatycznym wznawianiem webseedów"
  WriteRegStr HKCU "Software\${APP_ID}\Capabilities\FileAssociations" ".torrent" "${APP_ID}.Torrent"
  WriteRegStr HKCU "Software\${APP_ID}\Capabilities\URLAssociations" "magnet" "${APP_ID}.Magnet"
  WriteRegStr HKCU "Software\RegisteredApplications" "${APP_ID}" "Software\${APP_ID}\Capabilities"
SectionEnd

Section "Uninstall"
  SetRegView 64
  SetShellVarContext current
  IfFileExists "$INSTDIR\bin\qbittorrent.exe" 0 ApplicationStopped
  ClearErrors
  FileOpen $0 "$INSTDIR\bin\qbittorrent.exe" a
  IfErrors StillRunning 0
  FileClose $0
  Goto ApplicationStopped
  StillRunning:
    MessageBox MB_ICONSTOP "Zamknij LoriiTorrent przed odinstalowaniem."
    SetErrorLevel 2
    Quit
  ApplicationStopped:
  !include "${UNINSTALL_LIST}"
  Delete "$INSTDIR\Uninstall-LoriiTorrent.exe"
  Delete "$SMPROGRAMS\${APP_ID}\LoriiTorrent.lnk"
  Delete "$SMPROGRAMS\${APP_ID}\Odinstaluj.lnk"
  RMDir "$SMPROGRAMS\${APP_ID}"
  Delete "$DESKTOP\${APP_ID}.lnk"
  DeleteRegValue HKCU "Software\Classes\.torrent\OpenWithProgids" "${APP_ID}.Torrent"
  DeleteRegKey HKCU "Software\Classes\${APP_ID}.Torrent"
  DeleteRegKey HKCU "Software\Classes\${APP_ID}.Magnet"
  DeleteRegValue HKCU "Software\RegisteredApplications" "${APP_ID}"
  DeleteRegKey HKCU "Software\${APP_ID}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"
  ; Nie usuwaj profilu, plików użytkownika ani pobranych danych.
  RMDir "$INSTDIR"
SectionEnd
