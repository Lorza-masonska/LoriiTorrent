# Przygotowanie wydania

Wydanie składa się z kodu oznaczonego tagiem, paczek aplikacji i odpowiadających
im źródeł. Publikację wykonuje człowiek po przeglądzie kodu i plików.

## Pliki wydania R3

| Wariant | Pliki |
| --- | --- |
| Windows | `LoriiTorrent-5.2.4-r3-Windows-x64-Setup.exe`, `LoriiTorrent-5.2.4-r3-Windows-x64-Portable.zip` |
| Debian 13 | `loriitorrent_5.2.4+loriitorrent.3-1_amd64.deb`, `loriitorrent_5.2.4+loriitorrent.3-1_amd64.tar.gz`, `Install-LoriiTorrent.sh` |
| Docker | `LoriiTorrent-5.2.4-r3-Docker-amd64.tar.gz`, `compose.yaml` |
| Źródła | `LoriiTorrent-5.2.4-r3-Source.zip`, `LoriiTorrent-5.2.4-r3-Dependency-Sources.tar.gz` |
| Integralność | `SHA256SUMS.txt` i sumy poszczególnych paczek |

Do repozytorium trafia kod z dokumentacją, licencjami i manifestami.
Binaria oraz duże archiwa zależności dodaj jako załączniki release.
`Legacy`, `build`, profile i notatki robocze nie należą do publikowanego kodu.

## Przed publikacją

Sprawdź instalację i deinstalację Windows oraz Debiana w osobnym środowisku.
Potwierdź, że deinstalator zachowuje profil i pobrane dane. Wczytaj eksport
obrazu Docker i sprawdź WebUI oraz zapis wolumenów pod UID 1000.

Przy zmianach silnika uruchom scenariusze pobierania na własnym serwerze HTTP
i porównaj końcowe hashe. Sprawdź również zachowanie po zatrzymaniu ręcznym.
Zachowaj manifesty zależności użytych do kompilacji.

Paczki muszą zawierać licencje i informacje o autorach. Archiwa źródeł powinny
odpowiadać wydawanym binariom. Przejrzyj zawartość pod kątem profili, logów,
prywatnych torrentów, kluczy i tokenów.

## Tag i załączniki

Tag R3 to `v5.2.4-r3`. Wskaż commit odpowiadający opublikowanemu kodowi.
W opisie podaj bazę qBittorrent 5.2.4, zakres poprawek i wymagania platform.
Instalator Windows nie jest podpisany Authenticode.

Załączniki GitHuba są pojedynczymi plikami. Plik `SHA256SUMS.txt` do release
powinien używać samych nazw plików, bez lokalnych podfolderów. Użytkownik może
wtedy pobrać paczki do jednego katalogu i wykonać:

```sh
sha256sum --check SHA256SUMS.txt
```

Na Windows porównaj wybraną sumę wyniku `Get-FileHash -Algorithm SHA256`.
Przy zmianie już wydanych paczek utwórz nową rewizję zamiast zastępować R3.
