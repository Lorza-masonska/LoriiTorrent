# Budowanie LoriiTorrent

Polecenia wykonuj z głównego katalogu repozytorium, obok `README.md` i `packaging/`.
Po rozpakowaniu archiwum źródeł przejdź do katalogu `LoriiTorrent-5.2.4-r3`.

Skrypty budują własną, statyczną kopię libtorrent 2.0.15 z poprawkami forka.
Nie wybierają systemowego silnika. Źródła są dołączone do repozytorium, a Git
służy do sprawdzania i nakładania poprawek w katalogu `build/`.

## Windows: GUI i WebUI

Potrzebujesz Windows x64, Visual Studio 2022 lub Build Tools ze składnikami C++
i Windows SDK, CMake 3.20+, Ninja, Git i Python 3.11+. Przygotuj Qt 6.10.3 dla
`msvc2022_64`: QtBase, QtTools/LinguistTools, QtSvg i nagłówki CorePrivate.
Qt instalujesz osobno z dystrybucji open source.

Otwórz Developer PowerShell for VS 2022 z narzędziami x64. W przykładzie SDK Qt
jest w `C:\Qt\6.10.3\msvc2022_64`; zmień tę ścieżkę, jeśli masz inną instalację.

```powershell
.\packaging\bootstrap-windows-deps.ps1
.\packaging\build-windows.ps1 `
  -QtRoot C:\Qt\6.10.3\msvc2022_64 `
  -CMakeToolchainFile .\build\deps\vcpkg\scripts\buildsystems\vcpkg.cmake `
  -VcpkgTriplet x64-windows-static-md-release `
  -CMakeArguments "-DVCPKG_OVERLAY_TRIPLETS=$PWD\packaging\triplets" `
  -BuildJobs 4
```

Bootstrap pobiera przypiętą wersję vcpkg i korzysta z dołączonych przepisów
`dependencies/vcpkg-ports`. Wydanie używa Boost 1.92.0, OpenSSL 3.6.5 i zlib 1.3.2,
ze statycznymi bibliotekami i dynamicznym runtime MSVC. Lokalne archiwa możesz
umieścić w `build/deps/vcpkg/downloads`; brakujące pobierze vcpkg.

Skrypt uruchamia wewnętrzne testy i `windeployqt`, a na końcu wypisuje katalog
etapu instalacji `build/packages/qbt-gui-windows-...`. Pełną paczkę z licencjami
i instalator przygotujesz według [packaging/README.md](../packaging/README.md).
NSIS jest potrzebny do stworzenia instalatora, nie do samej kompilacji aplikacji.

## Linux: GUI i WebUI

Na Debianie 13 amd64 zainstaluj zależności, zbuduj aplikację i utwórz paczkę:

```sh
sudo sh packaging/install-debian-deps.sh
INSTALL_DIR="$PWD/build/linux-gui" BUILD_JOBS=4 sh packaging/build-linux.sh
sh packaging/package-linux.sh build/linux-gui ../Release/Linux
```

Instalator zależności dobiera Qt 6.8.2 z poprawkami Debiana i Boost 1.83.0.
Potrzebuje uprawnień administratora. Kompilację i pakowanie wykonuj zwykłym
użytkownikiem. Narzędzia do paczek, w tym `dpkg-dev`, dostarcza środowisko Debiana.
Archiwum etapu instalacji i `.deb` wymagają bibliotek tego systemu.

Wariant GUI można też zbudować przez Docker, bez instalowania kompilatora na hoście:

```sh
docker build -f packaging/Dockerfile.build \
  --build-arg BUILD_JOBS=4 --output type=local,dest=build/linux-gui .
```

Wynik trafi do `build/linux-gui`. Aby utworzyć `.deb`, uruchom powyższe polecenie
`package-linux.sh` w Debianie 13 amd64 z wymaganymi bibliotekami i `dpkg-dev`.

## Docker: nox i WebUI

Ten wariant kompiluje `qbittorrent-nox` z `GUI=OFF` i `WEBUI=ON`.
Potrzebujesz Dockera z Compose. Zbuduj obraz, a następnie uruchom go:

```sh
docker build -f packaging/Dockerfile --build-arg BUILD_JOBS=4 \
  -t loriitorrent:5.2.4-r3 .
docker compose -f packaging/docker-compose.yml up -d --no-build
docker compose -f packaging/docker-compose.yml logs loriitorrent
```

Otwórz [http://localhost:8080](http://localhost:8080). Login to `admin`, a tymczasowe
hasło jest w logach pierwszego uruchomienia. Ustaw własne hasło po zalogowaniu.
Konfiguracja i dane pozostają w nazwanych wolumenach. Kontener działa jako
UID/GID `1000:1000`, z zapisem w wolumenach i `/tmp`.

Eksport obrazu do pliku:

```sh
mkdir -p ../Release/Docker
docker save loriitorrent:5.2.4-r3 | gzip > ../Release/Docker/LoriiTorrent-5.2.4-r3-Docker-amd64.tar.gz
```

Dockerfile używa Debiana 13, ma osobny etap kompilacji i uruchamiania.
Pakiety Qt i Boost mają przypięte wersje. Bazowy obraz i pozostałe pakiety mogą
otrzymywać aktualizacje, więc kolejna kompilacja nie musi mieć identycznej sumy
jak wydane binarium. Wersje konkretnego wydania opisują manifesty zależności.

## Testy i porównanie z bazą

Skrypty Windows i Linux oraz Dockerfile domyślnie włączają wewnętrzne testy
qBittorrenta z `upstream/test/`. Ich niepowodzenie przerywa budowanie.

Sterowniki dodatkowych testów webseedów R3 są w
`LoriiTorrent-5.2.4-r3-Source.zip`, dołączonym do wydania. Obecna wersja
repozytorium nie zawiera `tests/`. Po rozpakowaniu tamtego archiwum instrukcja
testów jest w jego `tests/README.md`; nie uruchamiaj ich na swoim aktywnym profilu.

Do porównania z silnikiem bez poprawek użyj `LIBTORRENT_PATCHES=OFF` w Linux/Docker
lub `-LibtorrentPatches OFF` w Windows. Przy zmianie zależności lub opcji kompilacji
korzystaj z osobnego katalogu budowania.
