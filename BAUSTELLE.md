# Die Baustelle

Zehnter Themenkurs mit neun neuen Bahnen, Gesamt-PAR **13** und Bestwertschlüssel
`baustelle_course` (Revision 1). Der Katalog umfasst damit 90 reguläre und 14 technische
Bahnen. Bestehende Kurse, Rekorde und lokale Controllerkalibrierungen bleiben erhalten.

## Spielen

Im aktuellen Godot-Projekt unter **Kursauswahl → Seite 4 → DIE BAUSTELLE** starten.
Übung und freies Spiel enthalten die neuen Löcher ebenfalls; die Baustellenbahnen stehen auf den Bahnseiten 17 und 18; Urban Winter folgt auf 19 und 20.
Der lokale Windows-Build [PuttAndPixel-Baustelle.exe](build/windows/PuttAndPixel-Baustelle.exe)
enthält die Erweiterung und läuft ohne Editor. Das veröffentlichte Release 0.3.0 bleibt unverändert.

| Nr. | Bahn | PAR | Aufgabe |
| --- | --- | ---: | --- |
| 1 | Frisch gegossen | 1 | Breite Gerade mit aufgeweitetem Zielfeld; längeres Rollen kennenlernen. |
| 2 | Um die Schalung | 2 | Bandenschlag in die L-Ecke, anschließend nach oben zum Loch. |
| 3 | Erstes Rohr | 1 | Kurzer gerader Rohranlauf; zwei längere Seitenschleifen. |
| 4 | Die lange Leitung | 1 | Langer senkrechter Anlauf verändert das Eintrittstempo. |
| 5 | Umleitung | 2 | Versetzte Trennwand; Bandenschlag zur Anspielposition vor dem Rohr. |
| 6 | Sandlager | 1 | Ein durchgehender Sandstreifen bremst vor der Rohrmündung. |
| 7 | Baustellentor | 2 | Bewegliches Tor, sichere Zwischenposition und neuer Rohranlauf. |
| 8 | Rohrschleife | 1 | Lange U-Bahn; passendes Tempo überspringt die Rücklauf-Engstelle. |
| 9 | Bauabnahme | 2 | Zwei Pflichtrohre mit großzügiger Zwischenfläche. |

Die PAR-Folge folgt den geprüften Routen. Gerade Rohrbahnen erlauben bei passendem
Tempo ein Ass. Die sicheren Routen sind mit allen vier Figuren und jeweils ±0,3 Grad
Ziel- sowie ±1 Prozent Geschwindigkeitsabweichung beim ersten Schlag geprüft; spätere
Schläge zielen von der tatsächlich erreichten Position. Diese Varianten belegen keine
beliebige Schlagtoleranz. Das Tor bleibt dabei aktiv; die Route startet im Öffnungsfenster.

## Beton und Rohre

Die komplette Grundfläche besteht aus Beton: **80 px/s²** Rollwiderstand gegenüber
120 auf Grün. Bei gleichem Schlag rollt der Ball frei rund 1,5-mal so weit. **Schlagstärke,
Kraftanzeige und Golferprofile bleiben auf ebenes Grün geeicht.** Sand verwendet weiterhin
260 px/s²; Plattenfugen und Dekoration haben keine physische Wirkung.

Jedes Rohrsystem hat einen Eingang und drei reine Ausgänge. Langsam bedeutet weniger
als 140 px/s am Eingang, passend 140 bis unter 260, schnell mindestens 260. Entscheidend
ist die aktuelle Geschwindigkeit nach Sand und Bandenkontakten, nicht die ursprünglich
gewählte Schlagstärke. Nach 0,6 Sekunden tritt der Ball mit gleichem Tempo in Richtung
der ausgewählten Mündung aus. Kein Zufall, kein Zusatzschlag, keine rückwärtige Aufnahme.

Der mittlere Ausgang verkürzt den Weg. Die anderen Ausgänge benötigen in den geprüften
Routen insgesamt drei oder vier Schläge. Alle 16 Fehlwege führen bis zum Ziel. Auf Bahn 9
bleibt das zweite Rohr auch nach beiden Fehlwegen des ersten Pflicht. Auf Bahn 8 trennt
eine kurze Wand die beiden ungünstigen Ausgänge vom direkten Zielweg.

Die bündigen Einlässe und erhöhten Auslassstutzen sind orange. Ihre Zuordnung wird ohne
Nummern, Tempomarkierungen oder Verbindungslinien entdeckt. Pause, Neustart, Bahnwechsel
und Wertung nach dem letzten erlaubten Schlag verwenden den vorhandenen Transportablauf.

## Daten und Prüfung

`HoleDefinition.base_surface` legt den Grundbelag unabhängig von der Themenfarbe fest;
`pipe_systems` enthält typisierte `PipeSystemDefinition`-Ressourcen. `HoleRuntime.configure_ball()`
übergibt Grundbelag, Sonderflächen und Mechanismen an den Ball. Bestehende Bahnressourcen
verwenden standardmäßig weiterhin Grün. Bisherige paarweise Tunnel bleiben unverändert.

`tests/baustelle_test.gd` ist im zentralen Testrunner registriert. Die regulären Routen
stehen in `tests/baustelle_routes.json`, die Fehlwege in `tests/baustelle_recovery_routes.json`.
Zusätzlich werden Grenzwerte, Tempoerhalt, schnelle und verfehlte Aufnahme, Bodenwirkung,
Pause, Reset, Bahnwechsel, letzter Schlag und ungültige Rohrgeometrie geprüft.
Durchgehende Trennwände sichern die Pflichtpassagen; nur Katalogzählungen wären dafür
kein ausreichender Nachweis.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/validate_catalog.gd
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_baustelle.tscn
```

Das Capture-Skript erzeugt unter `.godot/baustelle/` die 3×3-Übersicht, Einzelansichten,
alle Spielansichten, die vierte Kursseite, Kameraenden, Rohrphasen und drei Torstellungen.

## Abnahme am 13.09.2026

- Godot 4.7.2: **104 gültige Katalogdefinitionen**.
- Gesamte Headless-Suite: **4.703 Prüfungen, 0 Fehler**, Exitcode 0.
- Alle neun PAR-Routen mit vier Golfern und den genannten Winkel-/Kraftvarianten;
  beide Fehlwege aller acht Rohrsysteme vollständig bis zum Loch geprüft.
- Gesamtansicht, neun Spielansichten, Kursseite 4, beide Kameraenden, alle Rohrphasen
  und geschlossenes, teilweise geöffnetes und offenes Tor gerendert und angesehen.
- Protokolle liegen unter `tmp/baustelle-*.log`, Bilder unter `.godot/baustelle/`.

Offen bleibt eine Godot-Abschlussmeldung des Capture-Skripts über 11 nicht freigegebene
Skriptressourcen (Exitcode trotzdem 0). Der separate Start-/Beenden-Probelauf mit einer
Baustellenbahn und die Gesamtsuite zeigen diese Meldung nicht.

Windows-Export am 13.09.2026 mit eingebettetem Spielpaket erstellt (Exitcode 0).
Die EXE wurde eigenständig aus dem Build-Verzeichnis gestartet und bei 2560 × 1440 Pixeln
visuell geprüft. Die zusätzliche Prüfung des exportierten Pakets bestand mit
**22 Checks, 0 Fehlern**: Kataloge, vierte Kursseite, alle neun Baustellenbahnen,
Betonphysik und Rohrtransport. Menü, Spielansichten und Rohraustritt wurden gerendert
und angesehen. Protokolle und Aufnahmen liegen lokal unter `tmp/baustelle-exe/`.
Das Exportwerkzeug meldete beim Beenden nicht freigegebene Ressourcen; der eigenständige
EXE-Start und die Paketprüfung beendeten sich ohne diese Meldung mit Exitcode 0.
Keine Hardwareabnahme des Controllers durchgeführt.
