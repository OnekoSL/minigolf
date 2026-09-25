# Übung, Tutorial und Training

**Spiel starten → Übung** öffnet ohne Spieleranlage den Grundkurs, die Lektionsauswahl und das freie Training. Lektionen verwenden Ben. Alle Lerninhalte sind sofort zugänglich; Abschlüsse werden markiert, nicht als Zugangsvoraussetzung verwendet.

## Lernen

Der Grundkurs führt durch den ersten Putt, Kraftdosierung und das Bereithalten eines Schlags vor einem Tor. Weitere Lektionen erklären Banden, Grün/Sand/Beton/Eis, die drei Gefällestärken, Schiebetore/Rotore und Wippen. Insgesamt gibt es acht Lektionen mit vierzehn Abschnitten. Jeder Abschnitt kann einzeln wiederholt oder übersprungen werden. Überspringen vergibt keinen Abschluss.

Vor einer Aufgabe pausiert die Erklärung die Welt. Danach erscheinen Hinweise im oberen Teil der Seitenleiste; im Grundkurs werden Kraft- und Genauigkeitsanzeige passend hervorgehoben. Das grüne Fenster der Genauigkeitsanzeige entspricht dem tatsächlich gewählten Golfer. Die Weitenskala bleibt auf ebenes Grün geeicht.

Die drei Gefälle-Lernbahnen verwenden mittig jeweils ein 128 Pixel breites Pfeilfeld aus acht Spalten. Die längere Passage macht die Wirkung der drei Gefällestärken deutlicher; der Durchgang wird erst hinter dem gesamten Feld gewertet.

Erfolge entstehen durch echtes Einlochen und die jeweilige Voraussetzung, zum Beispiel einen Bandenkontakt, das Befahren eines Belags oder die Passage hinter einem Hindernis. Bei der Kraftübung muss der Ball vollständig im gelben Feld liegen bleiben. Beim Timing muss ein vorbereiteter Schlag mindestens 0,75 Sekunden gehalten werden. Ein verfehlter Versuch beendet die Übung nicht.

## Freies Training

Zuerst einen Kurs, dann eine der neun Bahnminiaturen wählen. **Technik-Labore** enthält die technischen Bahnen auf zwei Seiten. Auswahl und Kategorie bleiben während des Aufenthalts im Übungsbereich erhalten. Eigene Inhalte starten weiterhin über ihre bisherige Bibliothek.

Es gibt kein Schlaglimit und keine Kursbestwerte. Nach dem Einlochen bleibt die Bahn für Wiederholung, Neustart und Auswahl erhalten. Ein Golferwechsel beginnt die Bahn neu; alle fünf Figuren und Dons einstellbare Werte stehen zur Verfügung.

| Aktion | Controller | Tastatur | Maus |
| --- | --- | --- | --- |
| Trainingshilfen | Dreieck | F2 | Schaltfläche oben links |
| Pause/Weiter | Start | P | Trainingshilfen → Weiter |
| Bahn neu starten | Quadrat | R | Trainingshilfen → Loch neu starten |
| Schlag neu versuchen | Trainingshilfen | Trainingshilfen | Trainingshilfen |
| Vorbereitung abbrechen | Kreis | Escape | Rechtsklick |

**Schlag neu versuchen** stellt den Zustand beim Beginn der letzten Kraftauswahl wieder her: Ball, Schlagzahl, Hindernisphasen, Schalter und aufgabenbezogene Voraussetzungen. Man beginnt erneut beim Zielen und kann Richtung, Kraft und Timing ändern. Abgebrochene Vorbereitungen überschreiben den letzten Schlag nicht. Es gibt eine Rücksetzstufe; sie ist auch während des Rollens, eines Transports oder nach dem Einlochen verfügbar.

Die goldene Spur zeichnet die tatsächliche Bewegung auf. Nach Wiederholung bleibt die alte Spur gestrichelt und gedämpft sichtbar. Tunnel, Rohre und Wasserrücksetzungen verbinden räumlich getrennte Abschnitte nicht durch eine Linie. Die Anzeige ist abschaltbar. Pro Spur werden höchstens 12.000 Punkte gehalten.

## Daten und Integration

- `PracticeSession` steuert den Übungsbereich und verwendet dieselbe `PrototypeMain`-Spielszene wie andere Spielmodi. Die Übungsoption schaltet ausschließlich Schlaglimit und automatische Rundenauswertung ab.
- `data/tutorial/catalog.tres` ist ein eigener typisierter Katalog mit Lektionen, Abschnitten, Aufgaben und Bahnreferenzen. Die Bahnen befinden sich ausschließlich dort und verändern weder die offiziellen Kataloge noch deren Bestwertrevisionen.
- Die Zustandssicherung wird mit dem Editor geteilt. Synchronisierte Hindernisse und ausstehende Ballanimationen werden bei der Rücksetzung mit berücksichtigt. Während Wiederherstellung und neutraler Eingabe bleibt die Welt pausiert.
- `user://practice.cfg` enthält nur stabile Abschluss-IDs. Ballspuren, laufende Übung und Physikzustände bleiben im Arbeitsspeicher. Bei Speicherproblemen bleibt Üben möglich; beschädigte Dateien werden erhalten und eine Meldung erscheint im Menüfuß.
- Texte verwenden `PRACTICE_*` und `HOLE_TUTORIAL_*` in den fünf vorhandenen Sprachkatalogen.

## Prüfungen

Die Übungstests sind in der Gesamtsuite registriert. Die separate Szene `res://tests/practice_runner.tscn` prüft Lernrouten mit echten Hindernissen, kleine Winkel-/Kraftabweichungen, Wiederholungen, Eingabeschranken, Auswahl und Speicherung. Speichertests stets mit isoliertem `APPDATA` ausführen; `tools/test_editor.ps1 -FullSuite` übernimmt dies für die Gesamtsuite.

`res://tests/capture_practice.tscn` ohne `--headless` erzeugt die Ansichten in allen fünf Sprachen unter `.godot/practice/`. Für Aufnahmen ebenfalls ein isoliertes `APPDATA` verwenden. Echte Controllerbedienung muss zusätzlich an vorhandener Hardware geprüft werden.
