# Recherche: reale Minigolfbahnen als Grundlage fuer den Generator

Stand: 04.09.2026

## Kurzfazit

Der groesste Unterschied zwischen den aktuellen Spielbahnen und realen Minigolfbahnen ist nicht die Art einzelner Hindernisse, sondern die Grundform der bespielbaren Flaeche.

Reale Sportbahnen bestehen fast immer aus einem schmalen, durchgehend eingefassten Bahnkorridor. Am Ende sitzt ein vergroessertes rundes oder polygonales Zielfeld. Hindernisse gliedern oder unterbrechen diesen Korridor. Die aktuelle Implementierung verwendet dagegen meist die gesamte rechteckige `course_rect` als bespielbare Gruenflaeche und stellt einzelne Waende, Kreise und Boegen frei hinein. Dadurch lesen sich die Loecher eher als Billardtisch oder offene Arena als als Minigolfbahn.

Die kuenftige Vereinfachung sollte deshalb reale Topologie statt reale Zentimeter kopieren:

1. schmaler Startkorridor,
2. durchgehende, der Bahnform folgende Banden,
3. eine klar erkennbare Hauptaufgabe,
4. ein abgesetzter Zielbereich,
5. wenige absichtliche Spielwege statt grosser freier Flaechen.

## 1. Die relevanten realen Bahnsysteme

| System | Normform | Typische Wirkung | Nutzen fuer unser Spiel |
| --- | --- | --- | --- |
| Beton | 12,00 m lang, 1,25 m breit, Zielkreis 2,50 m; 18 Bahnen in fester Reihenfolge | lange, schmale Betonrinnen; grosse runde Zielkreise; viel Banden- und Tempospiel | Vorbild fuer lange geometrische Bahnen und klare Zielkreise |
| Miniaturgolf | 6,25 m lang, 0,90 m breit, Zielkreis 1,40 m; 18 aus 30 Normbahnen | sehr kompakte Faserzementbahnen; pro Bahn meist genau ein markantes Hindernis | bestes Vorbild fuer kompakte Bildschirmbahnen und einen modularen Generator |
| Filzgolf | 6-18 m lang, 0,90 m breit, Zielfeld 1,80 oder 2,40 m | lange gruene Korridore mit Holzbanden, polygonalen Zielfeldern und deutlichen Hoehenprofilen | Vorbild fuer lange Bahnen, Winkel, Tore, Rampen und Zielkaesten |
| Adventuregolf | 3-40 m lang, mindestens 1,00 m breit | organische Kunstrasenbahnen, Steine, Rough, Wasser, Sand und Landschaft | Vorbild fuer Themenwelten und natuerlichere Konturen |
| Minigolf Open Standard (MOS) | 3-40 m lang, mindestens 0,50 m breit | freies Material und freie Formen; berechenbare bewegliche Hindernisse erlaubt | regeltechnisch passendstes Vorbild fuer unsere Tore, Windmuehlen und Fantasiemechanik |

Die vollstaendigen Systemdaten stehen in `data/reference/minigolf_systems.csv`.

## 2. Was reale Bahnen visuell und spielerisch gemeinsam haben

### 2.1 Korridor plus Zielfeld

Das wiederkehrende Grundmotiv ist eine 0,90-1,25 m breite Rinne, die am Ende in ein groesseres Zielfeld uebergeht. Das reale Laengen-Breiten-Verhaeltnis des schmalen Bahnteils liegt grob bei 7:1 fuer Miniaturgolf, 9,6:1 fuer Beton und bis etwa 20:1 fuer lange Filzbahnen. Das bedeutet nicht, dass unser Spiel dieselben extremen Verhaeltnisse verwenden muss. Die Silhouette sollte aber klar laenger und schmaler als ein Zimmer sein.

Der Uebergang zum Zielfeld ist selbst ein wichtiges Designelement: Verengung, Trichter, kurzer Hals, Fenster, Rampe oder Kurve bestimmen, wie viel Tempo im Zielbereich ankommt.

### 2.2 Eine dominante Idee pro Bahn

Die Normkataloge benennen Bahnen nach genau der Aufgabe, die man sofort erkennt: `Pyramiden`, `Rohr`, `Doppelwellen`, `Bruecke`, `Blitz`, `Labyrinth`, `Einfachtor`, `Graben`, `Hufeisen`. Weitere Elemente unterstuetzen diese Aufgabe, konkurrieren aber nicht mit ihr.

Fuer den Generator ist die sinnvolle Einheit deshalb kein zufaelliges Hindernis, sondern ein vollstaendiges Bahn-Archetyp:

- Grundkorridor und Zieltyp,
- ein Primaerhindernis,
- erlaubte oder erzwungene Route,
- Hoehenprofil,
- sichere Linie und optionale Risiko-Linie.

### 2.3 Enge werden relativ zum Ball lesbar

Ein echter Minigolfball hat 37-43 mm Durchmesser. Viele Miniaturgolf-Durchgaenge sind nur 10-25 cm breit; ein Rohr hat 4,5-6,5 cm Durchmesser. Die Herausforderung entsteht also oft durch eine klar sichtbare Engstelle von wenigen Ballbreiten, nicht durch einen weit entfernten kleinen Gegenstand in einer grossen Flaeche.

Fuer unsere vereinfachte Darstellung sollten Engstellen in Ballradien beschrieben werden. Erste brauchbare Zielwerte fuer Prototypen:

- grosszuegiges Tor: 5-7 Balldurchmesser,
- normales Praezisionstor: 3-5 Balldurchmesser,
- schweres Tor oder Rohr: 1,5-3 Balldurchmesser,
- freier Korridor: eher 8-14 Balldurchmesser als eine fast bildschirmhohe Flaeche.

Diese Pixelwerte sind eine Designhypothese und noch kein getesteter Balancingstandard.

### 2.4 Banden gehoeren zur Bahnform

Bei realen Bahnen sind Banden nicht nur Hindernisse im Inneren. Sie definieren die gesamte spielbare Kontur und erzeugen reproduzierbare Abpraller. Selbst Adventuregolf verlangt in taktisch genutzten Bereichen glatte und berechenbare Begrenzungen. Organische Stein- oder Rough-Raender bleiben optisch eindeutig.

Konsequenz fuer die Datendarstellung: `course_rect` sollte langfristig nur Welt- oder Kameragrenze sein. Die eigentliche Spielflaeche braucht eine eigene Kontur, aus der Bodenzeichnung, Kollision und Aussenbanden gemeinsam erzeugt werden.

### 2.5 Ziele sind nicht immer nur Loecher

Die realen Kataloge verwenden neben einem Loch auch Zielbereiche, Schuesseln, Mulden, Netze, Auffangkaesten, Plateaus und V- oder Vulkanflaechen. Das erweitert das Design, ohne zwangslaeufig bewegliche Mechanik einzufuehren.

Besonders gut fuer ein 2D-Spiel lesbar sind:

- klassischer Zielkreis mit Loch,
- erhoehtes Plateau mit Fangbereich,
- Mulde oder Schuessel,
- Netz oder Kasten nach einer Sprungschanze,
- Ziel hinter einem Rohr,
- definierter Bereich in einem V, Hufeisen oder Labyrinth.

### 2.6 Hoehe erzeugt Aufgaben, nicht Dekoration

Bruecken, Wellen, Steigungen und Rampen bestimmen erforderliches Tempo und Ruecklaufgefahr. Im Top-down-Spiel muss Hoehe durch klare Flaechenzeichen, Schatten, Pfeile oder Profil-Symbole vermittelt werden. Ein Gefaelle sollte eine erkennbare zusammenhaengende Form besitzen und an eine Bahnidee gebunden sein, nicht als beliebiges Rechteck auf einer offenen Flaeche liegen.

## 3. Wiederkehrende Archetyp-Familien

Die 80 offiziellen Beton-, Miniaturgolf- und Filzgolfbahnen lassen sich fuer einen Generator auf wenige kombinierbare Familien reduzieren. `data/reference/minigolf_lane_archetypes.csv` enthaelt den vollstaendigen Katalog und zusaetzliche Generator-Tags. Die Tags sind unsere Interpretation, nicht Teil der offiziellen Regeln.

| Familie | Reale Beispiele | Primaere Entscheidung |
| --- | --- | --- |
| Reine Linie | Gerade Bahn, Einfachtor, Doppeltor, Zielkreisfenster | exaktes Zielen und passende Geschwindigkeit |
| Bandenwinkel | Winkel, Halbwinkel, Blitz, besonderer Winkel | direkter Weg gegen ein- oder mehrfache Bandenlinie |
| Slalom | Pyramiden, Staebe, Kaesten, Fischgraete, Celler Staebe | Seite waehlen und mehrere Engstellen ausrichten |
| Welle und Huegel | Doppelwellen, Mittelhuegel, drei Huegel | Tempo ueber Kuppen und Ruecklauf kontrollieren |
| Rampe und Sprung | Sprungschanze mit Netz, Bunker, Graben, Auflaufkeil | Mindesttempo treffen und Lande- oder Fangzone erreichen |
| Tunnel und Kanal | Rohr, Bruecke mit Tor, Rinne, Passage | Eingang treffen; Ausgangstempo und -richtung beherrschen |
| Fangziel | Vulkan, V-Hindernis, Doppelkeile, Ass-Box, Mulde | mit genug Tempo in einen Zielbereich gelangen, ohne zurueckzurollen |
| Mehrweg | Raute, Passagen, Seitentore, besonderer Winkel | sichere und riskante Route gegeneinander abwaegen |
| Zielraum-Hindernis | Steine, Niere, Hufeisen, Kegel | Anspielpunkt und Resttempo fuer den Zielbereich planen |

## 4. Vergleich mit dem aktuellen Projekt

### 4.1 Aktueller Stand

- `HoleRuntime._draw()` fuellt die gesamte `course_rect` als Gruenflaeche.
- Viele Kursbahnen besitzen nur die vier rechteckigen Aussenwaende des kompletten Bildschirmbereichs.
- Typische feste Bildschirmbahn: 448 x 328 px, Seitenverhaeltnis 1,37:1.
- Selbst die langen 832 x 328 px grossen Bahnen erreichen nur 2,54:1.
- Die neun aktuellen klassischen Bahnen platzieren Bumper oder Boegen in diesem offenen Raum, statt einen eigenen Bahnkorridor zu formen.
- `WallDefinition` kann Rechtecke, Kreise und Boegen darstellen, aber noch keine zusammenhaengende frei geformte Aussenkontur erzeugen.
- `SurfaceDefinition` beschreibt rechteckige, optional gedrehte Zonen. Organische oder der Bahnkontur folgende Steigungen und Risikoflaechen fehlen.
- Alternative Zieltypen fehlen; jede regulaere Bahn endet aktuell in `hole_position`.

### 4.2 Was bereits gut zu realen Vorbildern passt

- Rechteck-, Kreis- und Bogenkollisionen reichen fuer viele erste Miniaturgolf-Archetypen aus.
- Tore, Rampenideen, Roehren/Kanonen und klare Trigger koennen reale Einzelideen erweitern.
- Reproduzierbare Physik und berechenbare bewegliche Hindernisse passen zum MOS-Gedanken.
- Die Forderung nach einer schnell erkennbaren Hauptidee im Grunddokument stimmt mit den realen Normbahnen ueberein.

### 4.3 Wichtigste Luecken fuer die spaetere Umsetzung

1. Eigene spielbare Bahnkontur statt vollstaendig bespielbarer `course_rect`.
2. Kontinuierliche Aussenbanden entlang dieser Kontur.
3. Explizite Startzone, schmaler Bahnhals und Zielzone.
4. Hoehenprofile oder Rampen als zusammenhaengende Geometrie.
5. Zieltypen neben dem Standardloch.
6. Generatorregeln fuer minimale Korridorbreite, Torbreite in Ballradien und freie Auslaufzonen.
7. Trennung von statischer Sportbahn-Grundform und optionaler MOS-/Fantasie-Mechanik.

## 5. Empfohlenes vereinfachtes Zielmodell

Eine generierte Bahn sollte spaeter mindestens diese Bausteine besitzen:

```text
Startzone -> schmaler Anlauf -> Hauptaufgabe -> Auslauf -> Zielzone
```

Nicht jede Stufe braucht sichtbare Laenge. Sie sollte aber in den Daten vorkommen, damit Validierung und automatische Loesungstests sinnvolle Aussagen treffen koennen.

Empfohlene Generatorhierarchie:

1. Systemprofil waehlen: `sport_compact`, `sport_long`, `adventure` oder `fantasy_mos`.
2. Archetyp waehlen: zum Beispiel `gate`, `bank_angle`, `slalom`, `wave`, `jump`, `tunnel`, `capture`.
3. Zusammenhaengende Bahnkontur und Zielzone erzeugen.
4. Primaerhindernis in diese Kontur einsetzen.
5. Sichere Referenzroute konstruieren.
6. Optional genau eine schwierigere Alternativroute hinzufuegen.
7. Erst danach Dekoration, Thema und optionale Mechanik aufsetzen.

## 6. Naechster sinnvoller Arbeitsschritt

Vor einer Umstellung aller 22 Kursloecher sollten drei Referenzbahnen gebaut werden:

1. eine gerade Miniaturgolfbahn mit Tor und rundem Zielfeld,
2. eine Winkel- oder Blitzbahn mit echten Korridorbanden,
3. eine Adventure-/MOS-Bahn mit organischer Kontur und einer berechenbaren Mechanik.

An diesen drei Bahnen koennen wir die benoetigten Datenstrukturen, Pixelbreiten, Kamerafuehrung und Physik validieren. Erst danach sollte entschieden werden, welche vorhandenen Bahnen angepasst und welche komplett ersetzt werden.

## Quellen

- Deutscher Minigolfsport Verband, Regelwerk-Download (Stand 01/2026): https://www.minigolfsport.de/download.php?subpage=11&title=DMV-Regelwerk
- Normungsbestimmungen Beton S11 (01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/s11_normungsbestimmungen_beton-2026-01_rot.pdf
- Normungsbestimmungen Miniaturgolf S12 (01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/s12_normungsbestimmungen_miniaturgolf-2026-01_rot.pdf
- Normungsbestimmungen Filzgolf S13 (01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/s13_Normungsbestimmungen_filzgolf-2026-01_rot.pdf
- Normungsbestimmungen Adventuregolf S14 (01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/s14_normungsbestimmungen_adventure_2026-01_neu.pdf
- Normungsbestimmungen Minigolf Open Standard S14b (01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/S14b_normungsbestimmungen_mos_2026-01_neu.pdf
- Internationale Spielregeln S1 (Ballmasse, 01/2026): https://www.minigolfsport.de/pdf/Download/Regelwerk/s1_internationale_spielregeln-2026-01_rot.pdf
- Fotoreferenz einer realen Filz- und Miniaturgolf-Wettkampfanlage mit allen 18 Bahnen: https://minigolf2023-badmuender.de/informationen.php?l=de&subpage=2&t=Die+Wettkampfanlagen

## Hinweise zur Datennutzung

- Offizielle Namen, Nummern und Systemmasse stammen aus den oben verlinkten Normungsbestimmungen.
- Die Felder `geometry_family`, `elevation_family`, `route_constraint`, `target_family` und `generator_tags` in der Archetyp-CSV sind fuer dieses Projekt abgeleitete Klassifizierungen.
- Die Beton-Norm verwendet Bahnnummern statt allgemein verbindlicher deutscher Bahnnamen. Die Beschreibungen in der CSV sind daher bewusst deskriptive Kurzbezeichnungen der offiziellen Diagramme.
- Die Normzeichnungen duerfen als Analysegrundlage dienen. Fuer das Spiel sollten keine kompletten existierenden Anlagen oder deren exakte Zusammenstellung kopiert werden; wir uebernehmen allgemeine Geometrie- und Designprinzipien.
