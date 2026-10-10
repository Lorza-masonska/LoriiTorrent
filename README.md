# LoriiTorrent

Klient BitTorrent oparty na qBittorrencie 5.2.4, z poprawkami pobierania z webseedów HTTP i HTTPS.

Webseed to serwer HTTP udostępniający dane torrenta obok zwykłych partnerów P2P.
LoriiTorrent powstał, żeby takie pobieranie mogło wrócić do pracy po przejściowym
błędzie serwera albo wygaśnięciu adresu po przekierowaniu. Zachowuje GUI i WebUI
qBittorrenta. Wspólny silnik libtorrent obsługuje poprawki we wszystkich wariantach.

Inspiracją był SuperSeedTorrent. To własna implementacja, bez kodu tamtego
programu. LoriiTorrent jest niezależnym forkiem qBittorrenta.

## Co zmienia fork

- Webseed zachowuje informację o dostępności pliku po HTTP 408, 429, 500, 502,
  503 i 504. Silnik może ponowić transfer bez ponownego dodawania torrenta.
- Nieaktywne źródła pozostałe po przekierowaniu nie zajmują limitu kandydatów
  na połączenia.
- HTTP 401 z tymczasowego adresu po przekierowaniu pozwala ponownie zapytać
  pierwotne źródło o aktualny adres. Każdy plik ma osobno śledzone przekierowania.
- Dziennik podaje więcej szczegółów, gdy źródło zwróci nieprawidłowy zakres bajtów.

Ponowienia zachowują odstęp silnika, zwykle 30 sekund, i rozpoznany `Retry-After`.
Bezpośrednie HTTP 401 ze skonfigurowanego źródła oraz HTTP 403 i 404 nie uruchamiają
odświeżenia adresu. Sprawdzanie hashy i ograniczenia autoryzacji pozostają aktywne.
Fork nie zapewni transferu, jeśli serwer przestanie udostępniać plik.

Sekwencyjne pobieranie i priorytet pierwszego oraz ostatniego fragmentu pochodzą
z qBittorrenta. LoriiTorrent nie dodaje odtwarzacza wideo do WebUI.

## Pobieranie i instalacja

Gotowe paczki są w zakładce **Releases** tego repozytorium. Wydanie forka to
`5.2.4-r3`; aplikacja nadal pokazuje wersję `5.2.4`.

| Wariant | System | Interfejs |
| --- | --- | --- |
| Windows | Windows 10 od 1809 lub Windows 11, x64 | GUI i opcjonalne WebUI |
| Linux | Debian 13, amd64 | GUI i opcjonalne WebUI |
| Docker | Linux, amd64 | WebUI |

### Windows

Uruchom `LoriiTorrent-5.2.4-r3-Windows-x64-Setup.exe` i przejdź przez polski
kreator. Instalacja jest dla bieżącego użytkownika, domyślnie w
`%LOCALAPPDATA%\Programs\LoriiTorrent`. Program ma osobny profil
`%APPDATA%\LoriiTorrent`. Deinstalacja zachowuje profil i pobrane pliki.

Jeśli wolisz wersję portable, rozpakuj całe
`LoriiTorrent-5.2.4-r3-Windows-x64-Portable.zip` i uruchom `Launch-LoriiTorrent.cmd`.
Jej profil powstaje w folderze `profile` obok programu.

Instalator nie ma podpisu Authenticode, więc Windows może wyświetlić ostrzeżenie.
Sumy plików znajdziesz w `SHA256SUMS.txt` dołączonym do wydania.

### Linux

Na Debianie 13 amd64 pobierz paczkę `.deb` i uruchom w jej katalogu:

```sh
sudo apt install ./loriitorrent_5.2.4+loriitorrent.3-1_amd64.deb
loriitorrent
```

Program pojawi się też w menu aplikacji. Korzysta z profilu
`${XDG_CONFIG_HOME:-$HOME/.config}/LoriiTorrent` i może działać obok zwykłego
qBittorrenta. Usuniesz go poleceniem `sudo apt remove loriitorrent`.

Paczka wymaga bibliotek Debiana 13. Dla innej dystrybucji wybierz Docker lub
[budowanie ze źródeł](docs/BUILDING.md). Linuxowe `.tar.gz` zawiera drzewo
instalacyjne, a nie samodzielny AppImage.

### Docker

Wymagania: Docker z Compose. Pobierz obraz
`LoriiTorrent-5.2.4-r3-Docker-amd64.tar.gz` i `compose.yaml` z tego samego wydania.
W katalogu z tymi plikami uruchom:

```sh
docker load --input LoriiTorrent-5.2.4-r3-Docker-amd64.tar.gz
docker compose up -d
docker compose logs loriitorrent
```

Otwórz [http://localhost:8080](http://localhost:8080). Login to `admin`;
tymczasowe hasło pojawi się w logach pierwszego uruchomienia. Po zalogowaniu
ustaw własne hasło. Konfiguracja i pobrane pliki pozostają w nazwanych wolumenach.
Kontener działa jako UID/GID `1000:1000`.

WebUI nasłuchuje domyślnie tylko na hoście Dockera. `docker compose down`
zachowuje wolumeny; opcja `--volumes` je usuwa.

## WebUI, profil i VPN

W wersjach desktopowych włącz WebUI w **Narzędzia → Opcje → Interfejs WWW**.
Ustaw login i hasło. Kilka klientów na jednym komputerze potrzebuje osobnych
portów WebUI i BitTorrent.

Nowa instalacja nie przenosi poprzedniego profilu. Jeśli chcesz go skopiować,
zamknij klientów i przenieś cały profil do osobnego katalogu. Uruchom aplikację
z `--profile=/ścieżka/do/profilu`; ścieżkę ze spacjami ujmij w cudzysłowy.
Nie używaj jednego profilu równocześnie w dwóch procesach.

Jeżeli torrent czeka na 0% po zmianie VPN, sprawdź **Opcje → Zaawansowane →
Interfejs sieciowy**. Połącz VPN i wybierz jego aktualny interfejs. Klient
zachowuje przypisanie nawet wtedy, gdy interfejs zniknie.

## Kod i dokumentacja

- [Budowanie](docs/BUILDING.md): Windows, Linux GUI i Docker.
- [Pakowanie](packaging/README.md): instalator Windows, `.deb` i archiwa źródeł.
- [Pochodzenie i licencje](NOTICE.md): komponenty użyte w wydaniu.
- [Zmiany](CHANGELOG.md) i [zasady współpracy](CONTRIBUTING.md).

Kod aplikacji jest w `upstream/`, baza silnika w `dependencies/libtorrent/`,
a jawne poprawki w `packaging/patches/`. [PROVENANCE.json](PROVENANCE.json)
zawiera rewizje, sumy poprawek i identyfikatory przetestowanych binariów.
Wydanie dostarcza osobne archiwa źródeł aplikacji i zależności.

## Licencja

Dystrybuowane binaria są na GPLv3 lub nowszej. Kod qBittorrenta zachowuje
GPLv2 lub nowszą z wyjątkiem OpenSSL opisanym w [COPYING](COPYING).
Nowe skrypty i dokumentacja są na GPLv3 lub nowszej, a biblioteki zachowują
własne licencje. Szczegóły znajdziesz w [NOTICE.md](NOTICE.md) i [LICENSE](LICENSE).
