# Urban Winter

Elfter Themenkurs, Bestwertrevision 1, neun eigene Bahnen und Gesamt-PAR **14**.
Im Spiel unter **Kursauswahl → Seite 4 → URBAN WINTER** erreichbar.
Übung und freies Spiel enthalten die Bahnen ebenfalls; der aktuelle Katalog umfasst
99 reguläre und 14 technische Bahnen, die reguläre Einzelauswahl hat 20 Seiten.

## Beläge und Gestaltung

Alle Abschläge liegen auf Beton mit **80 px/s²** Bremsung. Eis ist eine feste,
befahrbare Sonderfläche mit **20 px/s²**, ohne Beschleunigung oder Lenkhilfe.
Es bricht nicht ein und verursacht keine Strafschläge oder Rücksetzungen.
Der Ball kann auf Eis anhalten und erneut geschlagen werden. Sieben Ziele liegen
auf Beton; die Ziele der Bahnen 7 und 9 liegen auf Eis.

Die Abschlaggeschwindigkeit, Golferprofile und Kraft-/Weitenanzeige bleiben auf
ebenes Grün mit 120 px/s² geeicht. Frei rollt der Ball auf Eis ungefähr viermal so
weit wie auf Beton und sechsmal so weit wie auf Grün. Bei 240 px/s wurden mit den
festen Physikschritten rund **242 / 362 / 1442 px** auf Grün / Beton / Eis gemessen.
Die kleinen Abweichungen vom kontinuierlichen Modell entstehen durch die vorhandene
Integration in 60 Schritten pro Sekunde.

Graue Betonplatten, hellblaue Eisflächen und weiße Kratzer trennen die Beläge sichtbar.
Die geschlossenen Rissmuster beeinflussen die Bewegung nicht. Schnee auf Bänken,
Laternen und kleinen Stadtsilhouetten bleibt außerhalb der Spielfläche. Die vorhandenen
Schiebetore und Dreher behalten ihre Mechanik; neue Rohre oder Wasserflächen gibt es
in diesem Kurs nicht. Frühere Kurse behalten ihre bisherigen Beläge und Regeln.

## Bahnen und sichere Routen

| Nr. | Name | PAR | Nachgewiesener Spielweg |
| --- | --- | ---: | --- |
| 1 | Erster Frost | 1 | Über den Eisstreifen auf das großzügige Betonzielfeld. |
| 2 | Um den Häuserblock | 2 | Gerade auf die rechte Bande der Eiskurve; von dort zum Betonziel. |
| 3 | Zebrastreifen | 1 | Drei vollbreite Eisstreifen mit Beton dazwischen. |
| 4 | Lieferzufahrt | 1 | Öffnung des Schiebetors abwarten, dann über Eis zum Ziel. |
| 5 | Winterkreisel | 1 | Im passenden Zeitfenster seitlich am aktiven Dreher durch die Eispassage. |
| 6 | Kanalpromenade | 1 | Gemeinsamen Eisstreifen und geraden Eisweg nehmen. Der längere Betonbogen ist in drei Schlägen spielbar. |
| 7 | Am Stadtbrunnen | 1 | Vom Betonabschlag dosiert zum Loch auf dem breiten Eisplatz. |
| 8 | Unter der Hochbahn | 3 | Vereiste Hinfahrt, Betonwende, Rücklauf durch das Schiebetor zum Ziel. |
| 9 | Mitternachtsplatz | 3 | Durch das Tor auf die Betonzwischenfläche, am Dreher vorbei auf Eis, abschließend Eisputt. |

Bahnen 1–7 passen in die kompakte Spielansicht, Bahnen 8 und 9 scrollen horizontal.
Die Tore haben einen Achtsekundenzyklus mit vier Sekunden vollständig offener Phase
und je einer halben Sekunde Übergang. Die Dreher benötigen acht Sekunden pro Umdrehung.
Jede Bahn besitzt eine unvermeidbare Eispassage. Die Geometrie erlaubt nach Fehlschlägen
weitere Versuche; bewegliche Hindernisse werden bei der Routenprüfung nicht eingefroren.

Die reproduzierbaren Schläge einschließlich Zielpunkten, Geschwindigkeiten und Wartezeiten
stehen in `tests/urban_winter_routes.json`. Der Betonbogen sowie Korrekturrouten nach
Tor- und Dreherkontakt stehen in `tests/urban_winter_extra_routes.json`.

## Prüfung

`tests/urban_winter_test.gd` prüft die freie Rollweite, schnelle und schräge Belagwechsel,
die Eisvalidierung, kurze Eisputts mit allen vier Golfern, Pause, Neustart sowie Bahn-
und Spielerwechsel. Die Grundrouten werden mit allen vier Golfern gefahren; zusätzlich
wird **jeder einzelne Schlag** unabhängig um ±0,3° beziehungsweise ±1 % Kraft variiert.
Die Folgeputts behalten dabei ihre festgelegten Zielpunkte und Geschwindigkeiten.

Konturschnitte belegen die Pflichtpassagen und die Torwirkung. Abschlag, Ziel und
Endlagen nach falschem Timing werden gegen die gemeinsame Wandgeometrie einschließlich
Ballradius geprüft. Geschlossene, öffnende, offene und schließende Torstellungen sowie
mehrere reale Fehlzeiten prüfen freie Durchgänge und das Ausrollen nach Kontakten.
Die bestehenden Wasser-, Beton- und Kraftanzeigetests bleiben Teil der Gesamtsuite.

`res://tests/capture_urban_winter.tscn` erzeugt Gesamtansichten, alle neun Spielansichten,
Hindernisphasen, beide Eisziele, Kameraenden und die vierte Kursseite unter
`.godot/urban_winter/`. Das Capture-Skript zeigt wie die Baustellenaufnahme beim Beenden
eine Godot-Meldung über 11 noch verwendete Skriptressourcen; die Bilder werden erstellt.
Eine Controller-Hardwareabnahme ist nicht Bestandteil dieser Prüfung.

## Abnahme und Windows-Build vom 13.09.2026

- Katalogprüfung: **113 gültige Definitionen**, Exitcode 0 (`tmp/winter-validation.log`).
- Vollständige Headless-Suite: **5.183 Checks, 0 Fehler**, Exitcode 0, ohne Parser- oder Laufzeitfehler (`tmp/winter-suite.log`).
- Gesamtansichten, alle neun Spielansichten, Tor- und Dreherphasen, Eisziele, Kameraenden und Kursseite 4 gerendert und angesehen.
- [PuttAndPixel-UrbanWinter.exe](build/windows/PuttAndPixel-UrbanWinter.exe) als lokalen Windows-Release-Build mit eingebettetem Spielpaket exportiert.
- EXE eigenständig aus dem Build-Verzeichnis gestartet, Startansicht bei 2560 × 1440 geprüft, Exitcode 0.
- Exportiertes Paket aus dem Build-Verzeichnis mit **32 Checks, 0 Fehlern**, Exitcode 0 geprüft: elf Kurse, Wintervorschau, alle neun Bahnen, Beton, Eisgleiten, Neustart und kurzer Eisputt. Keine Quellprojekt-Tests oder Werkzeuge im Paket.

Export-, Paket- und Startprotokolle sowie weitere Aufnahmen liegen unter `tmp/winter-exe/`.
Das Exportwerkzeug meldet beim Beenden 25 noch verwendete Ressourcen (Exitcode 0),
wie bereits beim Baustellenexport. Eigenständiger EXE-Start, Paketprüfung und Gesamtsuite
zeigen diese Abschlussmeldung nicht. Es wurde kein öffentliches Release erstellt;
die bisherige angezeigte Programmversion 0.3.0 bleibt erhalten.

SHA-256 der EXE: `3E9CE25A243A02F1AD095FB70AA677BFBB5CCFE56E04C2B219EBA957C155DD4E`.
