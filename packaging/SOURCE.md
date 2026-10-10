# Źródła wydania

Binariom towarzyszą dwa archiwa. Udostępniaj je razem z paczkami aplikacji
i sumami kontrolnymi.

| Archiwum R3 | Zawartość |
| --- | --- |
| `LoriiTorrent-5.2.4-r3-Source.zip` | Kod aplikacji i silnika, poprawki, skrypty, instalator, dokumentacja i licencje |
| `LoriiTorrent-5.2.4-r3-Dependency-Sources.tar.gz` | Archiwa źródeł bibliotek, poprawki pakietów Debiana, przepisy vcpkg i manifesty |

`SOURCE-MANIFEST.json` wewnątrz każdego archiwum podaje SHA256 jego plików.
[PROVENANCE.json](../PROVENANCE.json) opisuje bazę kodu oraz sumy poprawek
i przetestowanych binariów.

## Kod aplikacji i silnika

`upstream/` zawiera zmodyfikowany qBittorrent 5.2.4.
`packaging/qbittorrent-working-tree.patch` pokazuje jego diff względem
oficjalnej bazy. Ten diff jest do wglądu, nie do ponownego nakładania.

`dependencies/libtorrent/` zawiera bazę silnika i przypięte podmoduły.
Skrypt przygotowania sprawdza manifest, kopiuje źródła do `build/` i tam
nakłada poprawki z `packaging/patches/`. Rozpakowane źródła nie potrzebują
metadanych `.git`; Git pozostaje narzędziem do nakładania poprawek.

Archiwum R3 przygotowane do wydania zawiera także sterowniki testów webseedów.
Obecne repozytorium nie ma katalogu `tests/`, więc nowe archiwum utworzone z jego
zawartości nie dołączy tych sterowników.

## Biblioteki

Duże archiwa w `dependencies/archives/` są ignorowane w Git. Źródła generowane
automatycznie przez GitHub nie zawierają tych plików i nie zastępują paczki
zależności. Udostępnij odpowiadające binariom archiwa na tym samym serwerze co
wydanie, z zachowaniem licencji i informacji o autorach.

Zmiana dokumentacji lub skryptów nie aktualizuje już istniejących archiwów.
Przy kolejnym pakowaniu zapisz nowy zestaw źródeł i sum. Nie zastępuj po cichu
plików opublikowanego wydania.
