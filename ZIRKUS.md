# Zirkus: neunter Themenkurs

Neun neue Kursbahnen, PAR 29, Bestwertschluessel `zirkus_course_v4`.
Der Gesamtbestand umfasst 81 regulaere und 14 technische Bahnen. Die acht
bisherigen Kurse, ihre Revisionen und das GitHub-Release 0.3.0 bleiben erhalten.

| Bahn | Name | PAR | Aufgabe |
| --- | --- | ---: | --- |
| 1 | Manege frei | 2 | Trichter und sanfter Pfeilhuegel |
| 2 | Kleine Akrobaten | 2 | Einzelne obligatorische Wippe |
| 3 | Zirkusschleife | 3 | S-Form mit drei breiten blauen Hoch-/Runter-Pfeilfeldern |
| 4 | Balanceakt | 3 | Zwei versetzte Wippen mit Zwischenplattform |
| 5 | Elefantenpups | 5 | U-Bahn, Ruessel und Schwanz; optionale Ass-Abkuerzung |
| 6 | Jonglierweg | 3 | Drei versetzte Links-/Rechts-Pfeilpassagen mit je zwei Gegenreihen |
| 7 | Hoch hinaus | 3 | Anstieg, Kuppe und Abfahrt mit ruhigem Zielfeld |
| 8 | Doppelte Zugabe | 4 | Wippe im Hin- und Rueckweg, rechte Kehre |
| 9 | Grosse Vorstellung | 4 | Wippe, Pfeilkurve und Abschlussputt |

Die Wippen auf 4 und 8 reagieren in 0,10 Sekunden, damit ihre Kombination
mit laengeren Schlaegen gutmuetig bleibt. Alle Pfeile verwenden bestehende
Gefaellefarben und reine Gefaellephysik. Das Feld an der neunten Bahn ist an
der schraegen Kontur zugeschnitten und schliesst die gesamte Passage.

## Elefant

Die eigene U-Kontur basiert auf Rueckweg zum Schloss: unten links starten,
rechts wenden, oben links einlochen. Der Elefant steht bei (400,168).
Sein Ruessel sperrt die untere Gerade; sein schmaler Schwanz sperrt die obere.
Beide senken sich eine Sekunde, bleiben zwei Sekunden unten, heben sich eine
Sekunde und bleiben zwei Sekunden offen. Der Schwanz ist drei Sekunden versetzt.

Die Oeffnung sitzt am unteren Ende des Ruessels. Ein Ball zwischen dieser
Spitze und der unteren Bande wird sofort aufgenommen, auch waehrend er rollt.
Die Aufnahme erfolgt vor Bewegung und Kollisionsimpuls des Ruessels; Ballradius
und innere Bandenkante begrenzen den Spalt. Der vollstaendig gehobene Ruessel
laesst rollende Baelle fuer die normale Umrundung passieren. Ein darunter
abgelegter Ball wird auch bei gehobenem Ruessel aufgenommen.

Die Animation dauert 1,2 Sekunden. Der Ball wird bei (372,56) mit 205 Pixeln
pro Sekunde nach links ausgeblasen. Seitlicher Versatz quer zur Ruesselspitze
ergibt bis zu acht Grad Richtungsabweichung; eine mittige Aufnahme erlaubt ein
Ass. Die Ruesselkorrektur fuehrte Kursrevision 2 ein; die erweiterten blauen
Pfeilfelder auf Bahn 3 erhoehen sie auf 3. Aeltere Bestwerte bleiben gespeichert.

Der Schwanz haelt vor einem Ball an der oberen Bande an. Weder Schwanz noch
Ruessel erteilen zusaetzliche Tor-Kickimpulse. Waehrend eines Balltransports
werden nachlaufende Hindernisimpulse abgewehrt.

Aufnahme und Transport kosten keinen Schlag. Pause friert beide ein;
Neustart und Bahn-/Spielerwechsel verwerfen alte Transporte. Auch am Schlaglimit
wartet die Wertung auf das Ende des automatisch fortgesetzten Balls.
Ansaugton, Pups, Bauchreaktion und Staubwolke beeinflussen die Physik nicht.

## Pruefen und spielen

Die Bahnen sind im dritten Bildschirm der Kursauswahl als ZIRKUS erreichbar.
Die Vorschau zeigt alle neun Bahnen. Uebung und freie Bahnfolgen enthalten
alle 81 regulaeren Bahnen auf 17 Seiten.

`tests/circus_routes.json` enthaelt die aktiven PAR-Routen. `tests/circus_test.gd`
prueft sie mit allen vier Golfern sowie +/-0,3 Grad Ziel- und +/-1 Prozent
Kraftabweichung beim ersten Schlag. Zusaetzlich: regulaere Elefantenumrundung,
Aufnahme ruhender und rollender Baelle im Spalt, seitlicher Ausstoss, Schlagvorbereitung, Pause,
Neustart, Bahnwechsel und regulaeres Einlochen beim letzten erlaubten Schlag.
Diese begrenzten Varianten sind kein Nachweis beliebiger Schlagtoleranz.

Die vollstaendige Headless-Suite laeuft wie in README.md beschrieben.
`tests/capture_circus.tscn` erzeugt Gesamtansichten, alle neun Spielansichten,
Kameraenden und Elefantenphasen unter `.godot/circus/`.

Dieser Ausbau veroeffentlicht kein neues GitHub-Release. Reale Controller-
und Langzeitspieltests bleiben zusaetzlich zu den automatisierten Pruefungen sinnvoll.

## Abnahme am 13.09.2026

- Godot 4.7.2: Katalog mit 95 Bahnen gueltig.
- Gesamte Headless-Suite: **4.263 Checks, 0 Fehler**, Exitcode 0.
- Alle neun aktiven PAR-Routen mit vier Golfern und den genannten
  Winkel-/Kraftvarianten bestaetigt.
- 3x3-Gesamtansicht, Kursmenue, Spielansichten, Kameraenden und
  Elefantenphasen gerendert und visuell kontrolliert.
- Separater Windows-Debugexport nach `build/windows/PuttAndPixel-Zirkus.exe`;
  EXE eigenstaendig mit OpenGL gestartet und Titelbild gerendert, Exitcode 0.
- Protokolle: `tmp/circus/`; Aufnahmen: `.godot/circus/`.

Keine neue Hardwarepruefung des Controllers oder Abnahme auf einem anderen PC.

## Korrektur der Ruesselaufnahme

Der gemeldete Fehler wurde mit einem ruhenden Ball bei (400,300) reproduziert:
der Ruessel schob ihn durch die untere Bande bis y=1003. Auch der Schwanz
konnte einen Ball bei (400,36) nach oben aus der Bahn schieben. Beide Faelle
werden jetzt in `tests/elephant_gap_test.gd` mit echten Physikframes geprueft,
ergaenzt um seitliche Aufnahme, hohe Geschwindigkeiten und Zyklusphasen.
Der korrigierte Entwicklungsbuild bleibt bei 2560 x 1440 Pixeln.

Abnahme der Korrektur: **4.293 Checks, 0 Fehler**, Exitcode 0. Darin sind
124 Zirkuspruefungen einschliesslich Aufnahme-, Einklemmschutz-, Ass- und
PAR-Routen enthalten. Ruesselspitze, Ansaugen und Ausstoss wurden gerendert
und visuell kontrolliert. Der korrigierte Build
`build/windows/PuttAndPixel-Zirkus-Ruessel.exe` wurde eigenstaendig gestartet
und mit 2560 x 1440 Pixeln gerendert, Exitcode 0. Protokolle stehen unter
`tmp/circus/` in `suite-ruessel.log`, `gap-tests.log` und
`standalone-ruessel.log`.

## Blaue Pfeilfelder auf der Zirkusschleife

Bahn 3 besitzt drei breite Felder mit insgesamt 81 blauen Rasterzellen.
Jedes Feld hat zwei Reihen in Hauptrichtung und direkt dahinter zwei
entgegengesetzte Reihen: oben/unten, unten/oben und oben/unten. Die Felder reichen ohne seitliche Umgehung bis an die
schraegen Banden; schmale ebene Zwischenstreifen sowie grosse Abschlag-
und Zielflaechen bleiben erhalten. Blau verwendet die vorhandene mittlere
Gefaellestaerke. Die aktive Route in `tests/circus_routes.json` wurde auf
drei Schlaege abgestimmt; PAR 3 und Kurs-PAR 29 bleiben bestehen.

Abnahme der Pfeilpaare: Katalog mit 95 gueltigen Definitionen; gesamte
Headless-Suite **4.293 Checks, 0 Fehler**, Exitcode 0. Die geaenderte Bahn
besteht die aktive PAR-Route mit allen vier Golfern, +/-0,3 Grad und
+/-1 Prozent Kraft. Spielansicht und Vorschau gerendert; Windows-Build
`build/windows/PuttAndPixel-Zirkus-Pfeile.exe` eigenstaendig gestartet und
mit 2560 x 1440 Pixeln visuell kontrolliert, Exitcode 0.
Protokolle: `tmp/circus/suite-pfeilpaare.log`, `capture-pfeilpaare.log`
und `standalone-pfeile.log`.

## Gegenreihen auf Jonglierweg (Bahn 6)

Die drei bisherigen gruenen Pfeilpassagen bleiben erhalten. Direkt rechts
dahinter folgen jeweils zwei weitere Rasterspalten ueber die gesamte
Bahnhoehe, entgegengesetzt gerichtet. Jede Passage ist jetzt vier statt
zwei Spalten breit: links/rechts, rechts/links, links/rechts. Insgesamt
60 Pfeilzellen. Staerke und Farbe bleiben gruen; PAR 3 bleibt bestehen.
Die Kursrevision steigt auf 4, damit alte Bestwerte getrennt bleiben.

Abnahme: 95 gueltige Katalogdefinitionen, vollstaendige Headless-Suite
**4.293 Checks, 0 Fehler**, Exitcode 0 (`tmp/circus/suite-jonglier.log`).
Alle vier Golfer und die Ziel-/Kraftvarianten bestehen die aktualisierte
PAR-Route mit einem kurzen dritten Abschlussputt. Gesamtansicht und beide
Kameraenden wurden gerendert und visuell geprueft. Der Windows-Build
`build/windows/PuttAndPixel-Zirkus-Jonglierweg.exe` wurde eigenstaendig
in 2560 x 1440 gestartet, Exitcode 0 (`tmp/circus/standalone-jonglier.log`).
