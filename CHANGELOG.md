# Historia zmian

## 5.2.4-r3

Wydanie oparte na qBittorrencie 5.2.4 i statycznie linkowanym libtorrent 2.0.15.

### Pobieranie z webseedów

- Dostępność pliku jest zachowywana po przejściowych błędach HTTP 408, 429,
  500, 502, 503 i 504, żeby silnik mógł ponowić transfer.
- Nieaktywne delegacje po przekierowaniu nie zajmują limitu kandydatów na połączenia.
- HTTP 401 z tymczasowego adresu po przekierowaniu może odświeżyć adres przez
  pierwotne źródło. Mechanizm śledzi każdy plik i generację żądania osobno.
- Ostrzeżenia o nieprawidłowym zakresie bajtów HTTP zawierają adres końcówki
  sieciowej i szczegóły błędu silnika.

### Paczki

- Polski instalator i wersja portable dla Windows x64.
- Paczka `.deb` z GUI i WebUI dla Debiana 13 amd64.
- Obraz Docker amd64 z WebUI, uruchamiany jako UID/GID `1000:1000`.
- Własne profile instalowanych klientów desktopowych.
- Archiwa źródeł aplikacji i zależności, licencje oraz sumy SHA256.

Rewizje kodu i sumy poprawek są w [PROVENANCE.json](PROVENANCE.json).
Historię oryginalnego projektu zachowano w [upstream/Changelog](upstream/Changelog).
