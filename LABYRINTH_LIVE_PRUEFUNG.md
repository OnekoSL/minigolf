# Labyrinth-Neun: Prüfung mit aktiven Hindernissen

Stand: 10. September 2026. Godot 4.7.2 Standard, Windows, 60 feste Physikschritte pro Sekunde.

## Ergebnis und Grenze

Alle neun Bahnen wurden mit je sechs Startwartezeiten untersucht: 0, 30, 60, 90, 120 und 150 Physikticks. Danach beginnt jeder weitere Schlag nach dem Stillstand ohne zusätzliche Wartezeit. Die Diagonalfalle (05) endet mit 150 Ticks Startwartezeit reproduzierbar in vier Schlägen innerhalb PAR 5. Der erfolgreiche Versuch wurde nach frischem Reset wiederholt und ist als Regression eingebunden.

Für die übrigen acht Bahnen erreichen diese konkreten Schlagfolgen das Loch nicht. Das ist weder ein Nachweis der Unlösbarkeit noch eine vollständige Suche nach sicheren PAR-Routen. Bahndaten, PAR, Physikparameter und Bestwertrevisionen wurden nicht geändert. Die alten Prüfungen bleiben ausdrücklich vereinfachte Geometrierouten mit ausgesetzten Hinderniskollisionen.

## Ablauf und Wiederholung

Die Zielpunkte und Geschwindigkeiten stehen in `LabyrinthRoutes.geometry_routes()`, die legalen Live-Schritte in `LabyrinthRoutes.live_route()` ([Routendaten](tests/labyrinth_routes.gd)). Bei Bahn 09 wird der alte Zielpunkt `(1064,20)` für die Live-Prüfung auf `(1064,23)` angehoben: Erst dort liegt er im erreichbaren Cursorbereich. Alle Live-Schläge liegen zwischen 78 und 420 px/s.

Der [Live-Routenhelfer](tests/live_route_runner.gd) verwendet die produktiven Ball-, Hindernis- und Kollisionsknoten. Er setzt die Mechanismen einmal zurück, lässt einen Synchronisierungsschritt vergehen und zählt danach die angegebenen Wartezeiten. Der Testtreiber ersetzt nur die manuelle Schlagvorbereitung: Er durchläuft die echten Schlagzustände und taktet den Abschwung mit sechs Physikschritten bis zum Kontakt. Rotoren, Tore, Wippengewicht und Aufweckkontakte werden durch den normalen SceneTree verarbeitet. Auch während des Wartens bleibt die Welt aktiv.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . res://tests/audit_labyrinth_routes.tscn
```

`--fixed-fps 60` beschleunigt die Ausführung ohne Echtzeitwartezeiten; die Simulation verwendet weiterhin echte Physikframes mit 1/60 s. Der Auditor schreibt alle 54 Ergebnisse einschließlich Zwischenpositionen, Kontaktzeitpunkten und letzten Wandkontakten nach `.godot/labyrinth-live/audit.json`. Ein gefundener Erfolg wird zusätzlich wiederholt. Die vollständige reguläre Headless-Suite prüft die bestätigte Diagonalfallenroute zweimal ohne diesen Beschleunigungsparameter.

## Konkrete Befunde

Die Tabelle zeigt pro Bahn den Versuch ohne Startwartezeit, bei 05 den bestätigten Erfolg mit 150 Ticks. Alle nicht eingelochten Versuche endeten nach der angegebenen Schlagfolge; ihre Endposition ist ein konkreter Scheiterpunkt dieses Ablaufs. Der letzte Kontakt ist eine Beobachtung, keine alleinige Ursachenbestimmung.

| Bahn | PAR | Startwartezeit | Schläge | Endposition | Ergebnis / letzter Kontakt |
| --- | ---: | ---: | ---: | --- | --- |
| 01 Die erste Schleuse | 5 | 0 | 5 | (562.97, 198.14) | Nicht eingelocht; wall bei (582.00, 198.77) |
| 02 Zickzack-Kammern | 5 | 0 | 5 | (514.56, 69.21) | Nicht eingelocht; wall bei (598.00, 49.10) |
| 03 Wippen-Labyrinth | 5 | 0 | 8 | (478.28, 107.98) | Nicht eingelocht; gate bei (541.72, 99.05) |
| 04 Dreifachtor | 6 | 0 | 6 | (253.28, 228.80) | Nicht eingelocht; wall bei (288.27, 26.00) |
| 05 Diagonalfalle | 5 | 150 | 4 | (1088.00, 176.00) | Eingelocht; Wiederholung bestätigt |
| 06 Drei Kammern | 5 | 0 | 6 | (645.20, 184.84) | Nicht eingelocht; kein Kontakt im letzten Schlag |
| 07 Kreuzwege | 5 | 0 | 6 | (228.54, 199.54) | Nicht eingelocht; wall bei (374.00, 205.25) |
| 08 Das Getriebe | 7 | 0 | 7 | (326.33, 127.20) | Nicht eingelocht; wall bei (342.00, 126.50) |
| 09 Der grosse Irrgarten | 7 | 0 | 7 | (296.46, 157.04) | Nicht eingelocht; kein Kontakt im letzten Schlag |

Die Listen für 03, 06 und 07 überschreiten bereits ihre PAR-Vorgabe. Deren Ausführung dient der Fehleranalyse und ist auch bei einem künftigen Erfolg kein PAR-Nachweis. Die Regression `labyrinth_live_test.gd` sichert für 05 Einlochen, PAR, Schlaglimit, vier Ballkontakte, den Kontaktabstand von sechs Physikticks und gleiche Zwischenpositionen mit 0,01 px Toleranz ab. Sie behauptet keine Toleranz gegenüber ungenauen Schlägen.

## Endpositionen aller untersuchten Startwartezeiten

| Bahn | 0 Ticks | 30 Ticks | 60 Ticks | 90 Ticks | 120 Ticks | 150 Ticks |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | (563.0, 198.1) | (506.7, 192.8) | (785.4, 132.5) | (1088.7, 152.8) | (759.6, 130.3) | (324.4, 165.9) |
| 02 | (514.6, 69.2) | (790.7, 156.5) | (379.5, 74.0) | (575.2, 68.7) | (380.5, 197.9) | (379.4, 175.7) |
| 03 | (478.3, 108.0) | (472.2, 85.3) | (480.3, 107.7) | (478.6, 107.6) | (478.6, 107.6) | (476.2, 108.2) |
| 04 | (253.3, 228.8) | (286.1, 191.1) | (607.3, 196.8) | (602.2, 191.2) | (520.4, 159.0) | (296.4, 189.7) |
| 05 | (694.5, 184.7) | (839.0, 192.4) | (837.4, 193.8) | (663.3, 213.3) | (857.1, 170.1) | eingelocht |
| 06 | (645.2, 184.8) | (645.2, 184.8) | (578.2, 185.1) | (796.0, 192.1) | (809.1, 241.1) | (775.6, 243.8) |
| 07 | (228.5, 199.5) | (411.9, 187.7) | (232.5, 191.4) | (228.5, 195.4) | (238.5, 209.6) | (234.9, 188.8) |
| 08 | (326.3, 127.2) | (326.3, 125.8) | (485.6, 152.8) | (767.8, 218.8) | (1051.0, 139.9) | (327.7, 132.7) |
| 09 | (296.5, 157.0) | (439.1, 136.9) | (590.4, 106.9) | (595.4, 103.2) | (408.7, 84.7) | (300.8, 113.3) |

## Verbleibende Arbeit

Für 01–04 und 06–09 fehlen bestätigte vollständige Live-Routen. Ein nächster Spielbarkeitsauftrag kann gezielt Wartezeiten vor einzelnen Hindernissen, andere Zwischenziele und dosierte Geschwindigkeiten untersuchen. Änderungen an Bahnen oder PAR sind daraus nicht automatisch freigegeben.
