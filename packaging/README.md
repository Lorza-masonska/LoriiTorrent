# Przygotowanie paczek

Najpierw [zbuduj aplikację](../docs/BUILDING.md). Polecenia poniżej wykonuj
z głównego katalogu repozytorium. Gotowe pliki zapisujemy obok niego w `Release/`.
Skrypty odmawiają nadpisania istniejących paczek.

## Windows: portable i instalator

Po kompilacji odczytaj nazwę wariantu z manifestu. Przykład zakłada Qt 6.10.3,
Visual Studio 2022 Community z runtime MSVC 14.44.35112 i NSIS w standardowym
katalogu instalacji. Ścieżki SDK i runtime dopasuj do swojego środowiska.

```powershell
$native = Get-Content .\build\libtorrent-result-windows-ON.json -Raw | ConvertFrom-Json
$stage = Join-Path $PWD "build\packages\qbt-gui-$($native.variant)"
$crt = 'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT'

.\packaging\create-release.ps1 `
  -StageDirectory $stage `
  -QtRoot C:\Qt\6.10.3\msvc2022_64 `
  -VcpkgPrefix .\build\deps\vcpkg\installed\x64-windows-static-md-release `
  -CrtDirectory $crt `
  -OutputDirectory ..\Release\Windows `
  -ReleaseName LoriiTorrent-5.2.4-r3-Windows-x64-Portable

python packaging/windows/build-installer.py `
  --payload ..\Release\Windows\LoriiTorrent-5.2.4-r3-Windows-x64-Portable `
  --output ..\Release\Windows\LoriiTorrent-5.2.4-r3-Windows-x64-Setup.exe `
  --makensis "C:\Program Files (x86)\NSIS\makensis.exe"
```

Paczka wymaga pasujących tłumaczeń Qt, w tym `qtbase_pl.qm`. Jeśli są w innym
SDK, wskaż je przez `-TranslationsRoot`. Zachowaj katalogi licencji i SBOM Qt.
Nie kopiuj bibliotek ICU ani Direct3D z systemowego katalogu Windows.

Instalator używa NSIS 3.x Unicode. Jego źródła są w `packaging/windows/`.
Można go skompilować także na Linuxie, wskazując `makensis` z pakietu `nsis`.
Instaluje dla bieżącego użytkownika i zachowuje profil przy odinstalowaniu.

## Linux: paczka Debian

Na Debianie 13 amd64, z etapem instalacji w `build/linux-gui`:

```sh
sh packaging/package-linux.sh build/linux-gui ../Release/Linux
```

Powstaną `.deb`, `.tar.gz` i sumy kontrolne dla wersji `5.2.4+loriitorrent.3-1`.
Inną wersję wskaż przez `PACKAGE_VERSION`. Własny launcher, katalog programu
i wpis menu pozwalają zainstalować paczkę obok zwykłego qBittorrenta.

## Docker i źródła

Eksport obrazu opisuje [instrukcja budowania](../docs/BUILDING.md#docker-nox-i-webui).
Wydanie udostępnia go razem z `compose.yaml`, który uruchamia gotowy obraz.

Archiwa aplikacji i zależności przygotujesz tak:

```sh
python3 packaging/package-source.py --output ../Release/Source/LoriiTorrent-5.2.4-r3-Source.zip
python3 packaging/package-source.py --dependencies \
  --output ../Release/Source/LoriiTorrent-5.2.4-r3-Dependency-Sources.tar.gz
```

W Windows użyj `python` zamiast `python3`. Archiwa bibliotek muszą być wcześniej
przygotowane w `dependencies/archives/`. Skrypt pakuje dostępne pliki; nie pobiera
ich i nie potwierdza sam, że zestaw odpowiada wszystkim wydawanym bibliotekom.
Manifesty wersji i sum pomagają to sprawdzić. Źródła Qt dla Windows można pobrać
przez `python3 packaging/fetch-qt-sources.py`.

[SOURCE.md](SOURCE.md) opisuje zawartość archiwów,
a [RELEASE.md](RELEASE.md) listę plików i sprawdzenie przed publikacją.
