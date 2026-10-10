# Pochodzenie i licencje

LoriiTorrent korzysta z kodu qBittorrenta 5.2.4 i libtorrent 2.0.15.
Zachowuje nagłówki praw autorskich i informacje o autorach. Jest niezależnym
forkiem, a nie wydaniem zespołu qBittorrenta. Dokładne rewizje i sumy poprawek
są w [PROVENANCE.json](PROVENANCE.json).

## Licencja projektu

Kod qBittorrenta jest na GPLv2 lub nowszej. Jego dystrybuowane binaria i część
zasobów są na GPLv3 lub nowszej. [COPYING](COPYING) zachowuje oryginalny opis
licencji i wyjątku dotyczącego OpenSSL.

Nowe skrypty i dokumentacja LoriiTorrent są na GPLv3 lub nowszej.
Pełne teksty są w [COPYING.GPLv2](COPYING.GPLv2),
[COPYING.GPLv3](COPYING.GPLv3) i [LICENSE](LICENSE).
[AUTHORS](AUTHORS) zachowuje listę autorów qBittorrenta. Oryginalne ikony
i pozostałe zasoby również zachowują swoje licencje.

## Komponenty wydania

| Komponent | Wersja | Licencja i informacje o autorach |
| --- | --- | --- |
| libtorrent-rasterbar i poprawki silnika | 2.0.15 | BSD-3-Clause; [LICENSE](dependencies/libtorrent/LICENSE) |
| asio-gnutls, try_signal, libsimulator | Rewizje w manifeście silnika | Oryginalne licencje w [źródłach silnika](dependencies/libtorrent/) |
| Qt w Windows | 6.10.3 | LGPLv3 / GPLv3 i licencje komponentów; [teksty licencji](LICENSES/third-party/qt-6.10.3/) |
| Qt w Linux i Docker | 6.8.2 z poprawkami Debiana | [Noty pakietów Debiana](LICENSES/debian-runtime/) oraz źródła pakietów |
| Boost | Windows: 1.92.0; Linux: 1.83.0 | [Boost Software License 1.0](LICENSES/Boost-LICENSE-1.0.txt) |
| OpenSSL | Windows: 3.6.5; Linux: według manifestu | Apache-2.0 i noty komponentów; [copyright](LICENSES/openssl-copyright.txt) |
| zlib | Windows: 1.3.2; Linux: według manifestu | [Licencja zlib](LICENSES/zlib-copyright.txt) |
| NSIS | Kompilator instalatora 3.11 | [Licencje NSIS i jego komponentów](LICENSES/nsis-build/) |
| Microsoft Visual C++ Runtime | MSVC 2022 x64 | Warunki redystrybucji Microsoft; nie jest objęty GPL projektu |

## Źródła bibliotek

Wydanie R3 zawiera `LoriiTorrent-5.2.4-r3-Source.zip` i
`LoriiTorrent-5.2.4-r3-Dependency-Sources.tar.gz`. Druga paczka dostarcza
źródła modułów Qt użytych w Windows, archiwa zależności vcpkg i dokładne paczki
źródłowe Debiana wraz z poprawkami. Manifesty w [dependencies](dependencies/)
opisują ich wersje i sumy kontrolne.

Qt jest linkowane dynamicznie. Można zastąpić jego biblioteki zgodną
zmodyfikowaną wersją i ponownie zbudować aplikację. Archiwa źródeł są częścią
wydania; sam odnośnik do strony producenta nie zastępuje ich udostępnienia.
Opis pakowania znajduje się w [packaging/SOURCE.md](packaging/SOURCE.md).

MSVC Runtime jest zastrzeżonym komponentem Microsoft. Jego źródła nie są
częścią forka. ICU i Direct3D są używane z instalacji Windows; aktualna paczka
nie zawiera kopii tych bibliotek z katalogu systemowego.

## Dane geolokalizacyjne

qBittorrent może pobierać bazę IP-to-Country Lite od DB-IP, udostępnianą na
CC BY 4.0. Informację o źródle danych zachowano w
[oryginalnym README](upstream/README.md). Profil użytkownika i jego lokalna
kopia bazy nie są częścią paczki portable.

Ten dokument jest opisem komponentów. Oryginalne teksty licencji i informacje
o prawach autorskich pozostają przy ich źródłach oraz w [LICENSES](LICENSES/).
