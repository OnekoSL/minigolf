# Acht Welten – Umsetzung und Prüfstand

Stand: 11.09.2026. Godot 4.7.2 Standard, Compatibility-Renderer.

## Spielbarer Inhalt

Acht Kurse mit je neun regulären Bahnen ersetzen die bisherigen fünf Kurszusammenstellungen. Alle Kurse sind sofort auswählbar. Der Katalog enthält **72 reguläre und 14 technische Bahnen**; offizielle Kurse verwenden keine technischen Bahnen und teilen sich keine Bahnplätze.

| Welt | PAR-Folge | Gesamt-PAR |
| --- | --- | ---: |
| Stadtpark | 1/2/2/1/2/6/3/3/3 | 23 |
| Dünenküste | 1/3/5/1/3/3/4/3/3 | 26 |
| Mühlental | 2/3/2/3/5/3/5/2/3 | 28 |
| Bergpass | 2/3/2/3/3/2/3/1/3 | 22 |
| Schlossgarten | 3/3/3/4/3/5/6/5/3 | 35 |
| Uhrwerkfabrik | 3/2/2/3/4/4/5/2/2 | 27 |
| Tempelruinen | 2/2/3/3/4/3/4/2/4 | 27 |
| Sternwarte | 2/2/4/5/4/4/3/6/2 | 32 |

36 Bahnen sind neu gebaut. Die bisherigen 36 regulären IDs bleiben erhalten: neun Labyrinthgeometrien und das frühere Pfeilfinale wurden neu aufgebaut. Hinzu kommen der rote Pavillon-Kreis und die neue Gartenspirale im Stadtpark; 24 weitere Vorlagen behalten ihre Geometrie und erhalten die neue thematische Einbindung, Namen und gegebenenfalls korrigiertes PAR. Neue Kurs-IDs beginnen mit Bestwertrevision 1; Stadtpark verwendet nach seinen Bahnkorrekturen Revision 3, Mühlental nach dem zweiten Rotor ebenfalls Revision 3, Uhrwerkfabrik nach der Tempoanpassung ebenfalls Revision 3, Tempelruinen Revision 2. Ergebnisse der alten Kursfolgen werden weder übernommen noch gelöscht.

Die Welten verwenden gemeinsame [Themenressourcen](data/themes/stadtpark.tres) und [CourseTheme](src/course_theme.gd). Dekoration wird außerhalb des Spielwegs mit Abstand zu Wänden und Mechanismen gezeichnet. Rasenstreifen folgen auch den tatsächlichen Konturbögen. Bandenfarben ändern sich, die Geometrie für Darstellung und Kollision bleibt gemeinsam. Gefällefarben und Oberflächenwirkung bleiben unverändert.

## Baupläne und Pflege

- [Kursplan](KURSPLAN_8_WELTEN.md): Hauptaufgabe und Risikoidee je Bahn, Lernfolge und Herkunft.
- [Bahnblätter](BAHNBAUPLAENE_8_WELTEN.md): reale Abschläge, Ziele, PAR und geprüfte Schlagfolgen je Bahn.
- [Strukturierte Baupläne](data/world_blueprints.json): Zuordnung, Aufgaben, Zwischenpositionen und Endpunkte aller 72 Bahnen.
- [Generator](tests/build_eight_worlds.gd): neue Geometrien, gemeinsame Mechanikbausteine und Kataloge. Die Ausgaben stehen regulär als `.tres` unter `data/holes/`.
- [Routenfixtures](tests/world_routes.json): reproduzierte Schläge einschließlich beobachteter Torwartezeiten. Abweichende Figurenrouten kommen aus [Golfer-Routen](tests/golfer_routes.json).

Der Generator liest die K1-01–K8-09-Tabellen des Kursplans, die gesicherten ursprünglichen Ressourcen und die geprüften Routen. Geometrieänderungen deshalb im Generator und in den Routen/Bahnblättern mitführen. Bestehende Ressourcenkennungen der übernommenen Geometrien bleiben beim Schreiben erhalten. Erst validierte Ausgaben werden vom Windows-Hilfsskript aus `tmp/worlds/staging/` in `data/` kopiert:

```powershell
& './tests/build_eight_worlds.ps1'
```

Die alten Kursressourcen unter `data/` gehören nicht mehr zum offiziellen Kurskatalog. Historische Geometrie- und Wertungsregressionen laden ausdrücklich die eingefrorenen Ressourcen unter `tests/fixtures/legacy/`. Das bewahrt ihre ursprünglichen Erwartungen, etwa das alte PAR-7-Schlaglimit. Die neuen Kurse besitzen eigene Katalog-, Menü-, Runden- und aktive Routenprüfungen. Der historische Prototypgenerator ist keine Aktualisierungsmethode für die acht Welten.

## Tatsächlich ausgeführte Prüfungen

Die Datenprüfung bestätigt **86 gültige Definitionen**. Die vollständige Headless-Suite meldet **4.108 Checks, 0 Fehler**, Exitcode 0. Sie umfasst auch alle 72 aktuellen Allrounder-Routen, sämtliche Kursseiten, die letzten Übungs-/Freispielseiten, vollständige Neun-Loch-Runden und den Erhalt historischer Bestwerte beim Speichern der neuen Kurse.

Der zusätzliche Weltenaudit der ersten Kursfassung meldete **576 Checks, 0 Fehler**, Exitcode 0: je Bahn die Route mit Allrounder, Mara, Bruno und Nika sowie vier Allrounder-Varianten mit −0,3°/+0,3° oder −1 %/+1 % beim ersten Schlag. Die Kraftvariation wird an der jeweiligen legalen Kraftgrenze begrenzt. Tore, Rotoren, Wippen, Tunnel und Kanonen bleiben aktiv. Der echte Schusscontroller löst jeden Schlag mit sechs Physikticks Abschwung aus. Die Tests prüfen Einlochen innerhalb des aktuellen PAR.

Diese Aussage gilt für die gespeicherten Routen und die genannten Variationen des ersten Schlags. Sie ist kein Nachweis beliebiger Abweichungen an jedem Schlag, aller möglichen Mechanismusphasen oder jeder Risikoabkürzung. PAR berücksichtigt sichere Nachputts und bei Bedarf die geringere Reichweite einzelner Golfer. Keine Ballphysik wurde zum Erreichen der Routen geändert.

```powershell
# Katalog
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/validate_catalog.gd

# Gesamtsuite; feste 60-Hz-Schritte ohne Echtzeit-Warten
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . res://tests/test_runner.tscn

# Alle vier Figuren und Anspieltoleranzen
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . res://tests/audit_eight_worlds.tscn

# Rendering, ausdrücklich ohne --headless
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_eight_worlds.tscn
```

Aufnahmen liegen unter `.godot/eight-worlds/`: acht Kursübersichten, 72 Einzelansichten, drei Kursmenüseiten sowie Spielansichten der ersten und letzten Bahn jedes Kurses einschließlich vorhandener Kameraenden. Prüfprotokolle und der detaillierte Routenbericht liegen lokal unter `tmp/worlds/`.

Der Windows-Debugexport mit Godot 4.7.2 liegt unter [PuttAndPixel-AchtWelten.exe](build/windows/PuttAndPixel-AchtWelten.exe). Export und anschließender kurzer Headless-Start (`--quit-after 20`) endeten mit Exitcode 0. Der eigene Dateiname vermeidet das Überschreiben der noch laufenden bisherigen EXE; diese Prozesse wurden nicht beendet.

Die Umgebung meldet beim Engine-Start einen nicht lesbaren Zertifikatsspeicher. Der lokale Katalog, die Routen und die Tests benötigen keinen Netzwerkzugriff. Die beiden `ConfigFile parse error`-Meldungen der Gesamtsuite sind weiterhin absichtliche Negativtests; GDScript-Parserfehler sind keine erwarteten Meldungen.

## Weitere spielerische Abnahme

### Stadtpark: Pavillon-Kreis und Gartenspirale

Bahn 4 besitzt jetzt über den ganzen Kreis rote Pfeile nach links. Das Feld verwendet reine steile Gefällephysik (150 px/s², Rollwiderstand 30) und bleibt eine PAR-1-Aufgabe. Der Abschlag liegt auf neutralem Grün. Zugeschnittene Randzellen schließen die Fläche bis zum Kreisbogen; Darstellung, Flächenkollision und Abfrage am Ballzentrum verwenden dasselbe Polygon innerhalb des 16-Pixel-Rasters.

Bahn 6 ist als „Gartenspirale“ neu gebaut. Vom äußeren Abschlag führt der Weg zunächst nach oben, dann mit zehn tangentialen Bogenanschlüssen nach innen zum mittigen Loch. Die Arme haben 48 Pixel Wandachsenabstand und 44 Pixel lichte Breite. Vier geometrische Schnittprüfungen belegen die aufeinanderfolgenden Pflichtpassagen ohne direkte Außenabkürzung. Die sichere Route benötigt sechs Schläge, daher PAR 6 und Gesamt-PAR 23 für Stadtpark. Der Kurs verwendet einschließlich der nachfolgenden Parkbank-Korrektur Bestwertrevision 3; bisherige Rekorde bleiben gespeichert.

`tests/park_tuning_test.gd` ergänzt 38 Prüfungen: vollständige Kreisbelegung mit über 7.000 Abtastpunkten, kein Gefälle in abgeschnittenen Zellbereichen, Rastervalidierung, Spiralführung, kollidierende Parkbank-Diagonalen und die drei PAR-Routen mit Ben, Mara, Bruno und Nika sowie jeweils ±0,3° und ±1 % beim ersten Schlag. Die ursprüngliche Engstelle bleibt als historischer Geometriefall in den Legacy-Fixtures erhalten. Bahnansichten und die aktualisierte Kursvorschau wurden visuell geprüft. Aktuelle Protokolle und die Doppelansicht liegen unter `tmp/park-tuning/`.

### Diagonalen an der Parkbank

Die beiden äußeren Umlenkecken von Stadtpark-Bahn 7 „An der Parkbank“ besitzen nun je eine 32 × 32 Pixel große 45°-Abschrägung. Das gemeinsame Wandnetz zeichnet und kollidiert die Diagonalen. Anspielpunkte, Abschlag, Ziel und PAR 3 bleiben erhalten. Der Generator begrenzt diese Änderung auf Stadtpark; andere L-Bahnen werden nicht verändert. Bahnansicht, PAR-Routen mit allen vier Golfern sowie ±0,3°/±1 % beim ersten Schlag sind geprüft. Die aktuellen Protokolle und die Ansicht liegen unter `tmp/park-corners/`.

### Mühlental: Rotoren auf Bahn 1, 8 und 9

Die drei zuvor 128 × 8 Pixel großen Flügel bei y=200 sind auf 40 × 8 Pixel verkürzt und nach y=188 versetzt. Die Achsen liegen auf Bahn 1 und 9 bei x=360, auf Bahn 8 bei x=568. Der komplette Drehkreis hält mindestens fünf Pixel Abstand zur inneren Bande; Abschlag und Ziel bleiben auch vom Weckbereich getrennt. Der Rotor beeinflusst weiterhin die direkte Spiellinie. Seine versetzte Achse lässt ein zeitlich begrenztes gerades Durchfahrtsfenster frei.

Bahn 8 erhält eine dosierte Ziellinie nach der Wippe. Die sichere Route auf Bahn 9 führt mit drei Schlägen über eine Ablage hinter dem Rotor und eine Ablage hinter der Schleuse zum Loch. Daher PAR 3, Gesamt-PAR 28 und zunächst Bestwertrevision 2 für Mühlental. Vorherige Bestwerte bleiben gespeichert.

`tests/mill_rotors_test.gd` umfasst einschließlich des zweiten Rotors 47 bestandene Prüfungen: vollständige Drehkreise, Abstand zu Abschlag und Loch, zwei volle Umdrehungen mit ruhendem Abschlagball und aktive PAR-Routen mit allen vier Golfern sowie ±0,3°, ±1 % und ±5 Physikticks am jeweiligen Rotor-Anspiel. Zwei Rotorstellungen je Bahn und die Kursvorschau wurden visuell geprüft. Protokolle und Aufnahmen liegen unter `tmp/mill-rotors/`. Die Prüfungen decken die genannten Routen und Abweichungen ab, keine beliebigen Schläge oder Hindernisphasen.

Bahn 1 besitzt zusätzlich einen zweiten, oben versetzten Rotor bei (456, 160), entsprechend der markierten Cursorposition. Sein Blatt misst 32 × 8 Pixel; die Umlaufzeit beträgt 8 Sekunden für ein nutzbares Durchfahrtsfenster. Der erste Rotor bleibt bei (360, 188). Die sichere Zwischenablage bei (408, 176) bleibt über zwei volle Umdrehungen auch physikalisch ruhig. Beide vollständigen Drehkreise und beide Anspielfenster sind geprüft, einschließlich ±5 Ticks beim zweiten Schlag und einer zusätzlichen vollen Umdrehung Wartezeit. PAR 2 und Gesamt-PAR 28 bleiben bestehen. Mühlental verwendet nun Bestwertrevision 3. Aktuelle Protokolle tragen das Präfix `second-` unter `tmp/mill-rotors/`.

### Uhrwerkfabrik: verborgenes Tunnelzahnrad

Das Finale „Das große Uhrwerk“ ist jetzt eine kompakte Kreuzung mit vier Armen. Ein flach liegendes Zahnrad dreht sich in der Mitte: acht Zähne und acht gleich aussehende, unmarkierte Löcher zwischen den Zähnen. Vier feste gegenseitige Paarverbindungen sind absichtlich verborgen. Keine Farben oder Nummern verraten den richtigen Eingang. Je nach gewähltem Eingang und Zahnradphase sind alle vier Bereiche erreichbar.

Der Ball wird am Eingang eingezogen, wartet unsichtbar im Zahnrad und tritt am Partnerloch aus, sobald dieses einem Kreuzarm gegenüberliegt. Die Ausgangsrichtung zeigt nach außen, die Geschwindigkeit bleibt erhalten. Die Ausgabe endet bei Radius 104 außerhalb des Zahnkreises mit Radius 88; das vermeidet einen unmittelbaren zweiten Kontakt oder erneuten Einzug. Der Abschlag liegt außerhalb der Mechanik. Zahnkontakt kann ruhende Bälle im Drehbereich wieder bewegen. Neustart setzt Phase und Transport zurück. Die Kursvorschau hält das Zahnrad an.

`src/tunnel_gear.gd` verwendet dieselben Zahnpolygone für Zeichnung, Kollision und die Kontaktprüfung ruhender Bälle. `ObstacleDefinition.TUNNEL_GEAR` speichert die festen Lochpaare und die Umlaufzeit von 16 Sekunden (25 % langsamer als die erste Fassung mit 12 Sekunden). `PrototypeBall.start_directed_tunnel()` erweitert die gemeinsame Tunnelanimation um Ausgangsrichtung und Wartezeit; bisherige Tunnel behalten ihre Richtung und kurze Transportdauer. Die Bahndefinition enthält Kreuzkontur, Zahnradposition, Abschlag und Ziel.

Die überlangen Rotoren auf Uhrwerkfabrik 2, 5, 7 und 8 sind auf 40 × 8 Pixel bei y=188 korrigiert. Das neue Finale hat eine sichere PAR-2-Route mit Nachputt; der bekannte richtige Eingang erlaubt auch den direkten Treffer. Gesamt-PAR ist 27, Bestwertrevision 3 nach der Tempoanpassung. Frühere Bestwerte bleiben gespeichert.

`tests/factory_gear_test.gd` umfasst 79 bestandene Prüfungen: alle acht real angefahrenen Eingänge, vier Ausgangsbereiche, Ausgabe außerhalb des Zahnkreises, ungültige Paarverbindungen, Neustart während des Transports, ruhender Abschlag über zwei volle Umdrehungen, bewegter Ball nach Zahnkontakt sowie alle fünf geänderten PAR-Routen mit vier Figuren, ±0,3°, ±1 % und ±5 Physikticks. Zwei Zahnradstellungen und die Kursvorschau wurden visuell geprüft. Protokolle und Aufnahmen liegen unter `tmp/factory-gears/`; die aktuelle Tempoanpassung verwendet das Präfix `slower-`. Die Prüfung deckt diese konkreten Routen und Mechanikzustände ab; menschliches Ausprobieren der verborgenen Verbindungen bleibt Teil der spielerischen Abnahme.

Die aktuelle Spielversion mit 16 Sekunden Zahnrad-Umlaufzeit liegt unter [PuttAndPixel-AchtWelten-Zahnrad16s.exe](build/windows/PuttAndPixel-AchtWelten-Zahnrad16s.exe). Der separate Dateiname erhält die bereits laufende Vorgängerversion. Export und kurzer Start sind geprüft.

### Kursvorschau vor dem Start

Die Kursauswahl zeigt links drei Kurskarten und rechts alle neun Bahnen des markierten Kurses als 3×3-Bild mit Bahnnummer und PAR. Die Bilder entstehen direkt aus den aktuellen Bahndefinitionen; lange Bahnen werden vollständig eingepasst. Maus, Tastatur und Controller verwenden dieselbe Auswahl. Die Seitennavigation erhält das zuletzt gezeigte Bild, ein Seitenwechsel zeigt den ersten Kurs der neuen Seite. Bestätigen startet den Kurs wie bisher.

`src/course_preview.gd` verwendet die gemeinsame Bahndarstellung in einem einmal gerenderten, isolierten Viewport. Mechanismen stehen still und beeinflussen die Spielphysik nicht. `tests/course_preview_test.gd` ergänzt 60 bestandene Checks für alle acht Kurse, Reihenfolge, Bildausschnitte, ruhende Mechanismen, Kartenabstände, Maus-/Controller-Navigation, veraltete Signale, Eingabesperre und Kursstart. Renderaufnahmen aller acht Auswahlen wurden visuell geprüft.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_course_preview.tscn
```

Die Aufnahmen liegen unter `.godot/course-preview/`, die aktuellen Prüf- und Exportprotokolle unter `tmp/course-preview/`.

### Feinabstimmung: Wächterkammer

Der bisherige Rotor (128 × 8 Pixel bei 280/200) konnte den wartenden Ball vom Abschlag schieben und durch die untere Bande drehen. Das Blatt ist jetzt 40 × 8 Pixel groß und liegt bei 280/188. Der ganze Drehkreis einschließlich Weckbereich bleibt vom Abschlag getrennt; die sichtbare Mechanik bleibt innerhalb der Banden. Abschlag, Tunnel, Ziel und PAR 2 bleiben erhalten. Tempelruinen verwendet Bestwertrevision 2; bisherige Ergebnisse bleiben gespeichert.

Der neue Regressionstest `tests/guardian_tee_test.gd` prüft die Abstände und den unbewegten Abschlag über zwei volle Rotorumdrehungen, einschließlich Neustart. Elf aktive Routenvarianten prüfen alle vier Golfer, Winkel ±0,3°, Kraft ±1 %, Timing ±5 Physikticks und eine zusätzliche volle Umdrehung Wartezeit. Alle 15 zusätzlichen Checks und die vollständige Suite sind bestanden. Drei Rotorstellungen wurden gerendert und visuell geprüft (`tmp/guardian/rotor-phasen.png`); aktuelle Protokolle liegen unter `tmp/guardian/`.

Die Kursfassung ist technisch spielbar und automatisiert geprüft. Manuelles Durchspielen aller 72 Bahnen, echte Controllerhardware, jede Risikoalternative und eine vollständige topologische Prüfung aller denkbaren Umgehungen sind damit noch nicht abgedeckt. Die Themenzeichnung ist eine erste gemeinsame Pixelgestaltung; individuelle größere Abschlussmotive und menschliches Balancing können darauf aufbauen.

Die Lernfolgen enthalten bewusst Ruhebahnen und unterschiedlich lange Aufgaben. Das Planbudget von höchstens drei scrollenden Bahnen pro Welt wird in Mühlental, Uhrwerkfabrik und Sternwarte noch überschritten. Dort wurden Mechanikketten bereits deutlich verkürzt; weitere Verdichtung sollte anhand echter Rundenzeiten erfolgen, ohne die sicheren Zwischenräume zu verlieren.
