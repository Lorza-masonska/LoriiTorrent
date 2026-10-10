# Współpraca

Zmiana powinna rozwiązywać konkretny problem i dać się sprawdzić bez dostępu
do prywatnego webseeda. Przed pracą przeczytaj [README](README.md),
[opis budowania](docs/BUILDING.md) i [licencje](NOTICE.md).

## Zgłoszenie błędu

Podaj wersję forka, system, sposób instalacji i kroki potrzebne do odtworzenia
problemu. Przy błędzie webseeda pomocny jest status HTTP oraz krótki fragment
dziennika. Usuń z niego tokeny, hasła, prywatne adresy i dane torrenta.

Problem dotyczący LoriiTorrent zgłaszaj w repozytorium tego forka.
Jeśli podejrzewasz błąd oryginalnego qBittorrenta, najpierw sprawdź go na
oficjalnej wersji.

## Gdzie zmieniać kod

| Katalog | Przeznaczenie |
| --- | --- |
| `upstream/` | Kod qBittorrenta ze zmianami forka |
| `dependencies/libtorrent/` | Baza silnika z manifestem źródeł |
| `packaging/patches/` | Poprawki nakładane na kopię silnika przy budowaniu |
| `packaging/` | Skrypty budowania, instalatory i paczki |
| `docs/` | Dokumentacja dla osób budujących projekt |

Poprawki silnika dodawaj jako pliki `.patch`. Skrypt przygotowuje osobną kopię
libtorrent, sprawdza źródła i nakłada zmiany. Bezpośrednia edycja jego bazy
spowoduje błąd weryfikacji manifestu. Zmiany aplikacji są już w `upstream/`;
nie nakładaj na nie ponownie `qbittorrent-working-tree.patch`.

Zachowuj informacje o autorach i stosuj
[styl kodu qBittorrenta](upstream/CODING_GUIDELINES.md). Dokumentację forka
pisz po polsku. Oddzielaj poprawkę zachowania od porządkowania niezwiązanych
fragmentów kodu.

## Sprawdzenie zmiany

Skrypty budowania domyślnie uruchamiają wewnętrzne testy z `upstream/test/`.
Zmianę webseeda sprawdź również na własnym serwerze HTTP, z osobnym profilem
klienta. Końcowy hash i komplet danych są ważniejsze niż sam rosnący procent.

Uwzględnij błędne dane, zatrzymanie ręczne, usunięcie źródła i autoryzację.
Przy zmianach przekierowań sprawdź także torrent z wieloma plikami.
Dodatkowe sterowniki testów R3 znajdują się w archiwum źródeł tego wydania;
obecne repozytorium nie zawiera katalogu `tests/`.

W opisie zmiany wyjaśnij problem, nowe zachowanie i sposób sprawdzenia.
Jeśli nie testowałeś któregoś wariantu, zaznacz to wprost.

## Odpowiedzialność za wkład

Zgłoszenia i pull requesty tworzy oraz wysyła człowiek po przeglądzie zmian.
Narzędzia AI mogą pomagać w pracy lokalnej, ale nie zastępują tego przeglądu.
Autor odpowiada za kod, jego licencję i wyniki testów, które podaje.
