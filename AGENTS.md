# Arbeitsanweisungen für Putt & Pixel

Diese Datei gilt für das gesamte Projekt. Konkrete Nutzeraufträge haben Vorrang vor diesen Projektkonventionen.

## Schnell orientieren

- Antworte auf Deutsch, knapp und mit konkretem Ergebnis sowie tatsächlich ausgeführten Prüfungen.
- Prüfe zuerst `git status --short`; erhalte vorhandene Änderungen. Suche gezielt mit `rg` in den betroffenen Quell-, Daten- und Testdateien. Generierte Verzeichnisse nicht breit durchsuchen.
- Lies `README.md` für Start, Steuerung und aktuellen Funktionsumfang. Für Gestaltungsentscheidungen gilt `GAME_DESIGN_GRUNDDOKUMENT.md`; bei Bahnänderungen zusätzlich die relevanten Abschnitte von `BAHNGESTALTUNG_REGELN.md` lesen.
- `PROTOTYPKURS.md` enthält kursbezogene Details und Aufnahmen. `MINIGOLF_BAHNEN_RECHERCHE.md` ist Hintergrundmaterial. Datierte Bestandszahlen und frühere Umbauaufträge können überholt sein: tatsächliche Kataloge und aktuellen Code prüfen, historische Einschränkungen nicht ungeprüft übernehmen.
- Führe überschaubare, reversible Arbeiten im beauftragten Umfang selbstständig bis zur Prüfung aus. Halte Änderungen auf das Problem begrenzt; keine beiläufigen Architekturumbauten oder neuen Abhängigkeiten.

## Technik und Einstiegspunkte

Godot 4.7.2 Standard mit typisiertem GDScript, Windows und Compatibility-Renderer. Interne Auflösung: 640 × 360; Physik: 60 feste Schritte pro Sekunde. Controllerbedienung ist zentral, Tastatur und Maus sind ebenfalls unterstützt.

| Bereich | Einstieg |
| --- | --- |
| Start, Menüs und Spielmodi | `scenes/game_app.tscn`, `src/game_app.gd` |
| Ablauf eines Lochs | `scenes/prototype_main.tscn`, `src/prototype_main.gd` |
| Ball, Schuss und Oberflächen | `src/ball.gd`, `src/shot_controller.gd`, `src/surface_zone.gd` |
| Bahnbau und Darstellung | `src/hole_runtime.gd`, `src/hole_overlay.gd`, `src/wall_join_geometry.gd` |
| Typisierte Bahndaten | `src/*_definition.gd`, `data/holes/*.tres` |
| Loch- und Kurskatalog | `data/holes/hole_catalog.tres`, `data/course_catalog.tres`, `data/*_course.tres` |
| Runden, Spieler und Bestwerte | `src/round_session.gd`, `src/round_config.gd`, `src/player_profile.gd`, `src/best_score_store.gd` |
| Eingabe und Kalibrierung | Autoload `src/controller_support.gd`, `config/controller_mappings.cfg` |
| HUD, Kamera und Feedback | `src/hud.gd`, `src/course_camera.gd`, `src/prototype_audio.gd`, `src/feedback_effects.gd` |
| Tests | `tests/run_tests.gd`, `tests/*_test.gd`, `tests/test_runner.tscn` |
| Windows-Release | `tools/build_release.ps1`, `tools/package_release.ps1`, `release/README.md` |

## Änderungen umsetzen

- Bestehenden GDScript-Stil übernehmen: Tabs, typisierte Schnittstellen, `snake_case` für Funktionen und Variablen, `class_name` für wiederverwendbare Klassen. Vorhandene Ressourcen und gemeinsame Builder erweitern.
- Bahnspezifische Geometrie und Parameter gehören in die `.tres`-Definitionen. Gemeinsam verwendete Mechanik gehört in `src/`; keine Sonderfälle je Loch in der Ballphysik einbauen.
- Neue Bahnen und Kurse in den passenden Katalogen registrieren und Referenzen sowie `validate()`-Ergebnisse prüfen. Ressourcen-IDs und vorhandene `.gd.uid`-Dateien erhalten.
- Bei Änderungen, die Kursbestwerte unvergleichbar machen, `best_score_revision` der betroffenen Kursressource anpassen. Rein optische Änderungen brauchen keine neue Bestwertrevision. Lokale Spielstände und Controllerkalibrierung unter `user://` erhalten.
- Feste Physikschritte und reproduzierbare Schläge bewahren. Audio, Partikel und Kamera dürfen das physikalische Ergebnis nicht verändern. Beim Schlag müssen Abschwung, Ton und Ballkontakt synchron bleiben.
- Eingabeschranken nach Menü-, Spieler- und Lochwechseln erhalten. Gehaltene Tasten oder ausgelenkte Sticks dürfen keine Folgeaktion im nächsten Bildschirm auslösen.
- Bei Bahnänderungen zuerst Hauptaufgabe und spielbaren Weg festlegen. Gemeinsame sichtbare und physische Wandgeometrie verwenden; Normwände und atomare Pfeile folgen dem 16-Pixel-Raster. Details, Bogenanschlüsse und Legacy-Ausnahmen stehen in `BAHNGESTALTUNG_REGELN.md`.
- Pflichtpassagen, freie Durchgänge mit Ballradius und bewegliche Hindernisse in ihren Zwischenstellungen prüfen. Eine erfolgreiche Datenvalidierung allein belegt keine spielbare PAR-Route.
- Bei verändertem Verhalten betroffene Tests und Dokumentation mitführen. Veränderliche Bahnanzahlen, PAR-Summen und Revisionsstände nicht zusätzlich in dieser Datei pflegen.

## Starten und prüfen

Alle Befehle in PowerShell aus dem Projektverzeichnis ausführen. Die portable Engine liegt unter `.tools/godot-4.7.2/` und ist nicht versioniert. Fehlt sie, zuerst verfügbare lokale Godot-Installation prüfen und die verwendete Version nennen.

```powershell
# Spielen
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --path .

# Editor
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --editor --path .

# Bei frischem Checkout oder fehlendem Klassen-/Importcache
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path . --quit

# Schnelle Prüfung der Lochdefinitionen
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/validate_catalog.gd

# Gesamte Headless-Testsuite
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```

- Bei Änderungen an Spielcode oder Bahndaten die Headless-Suite ausführen. Erfolg erfordert Exitcode 0 und die Abschlussmeldung mit `0 Fehler`; Parserfehler ebenfalls beachten.
- Neue Regressionstests sollen beobachtbares Fehlverhalten prüfen. Zusätzliche `RefCounted`-Testmodule nach dem vorhandenen Muster über `tests/run_tests.gd` einbinden; sie sind keine eigenständig startbaren `SceneTree`-Skripte.
- Bei reinen Dokumentationsänderungen genügen Prüfung von Inhalt, Pfaden und Diff; dafür die Spielsuite nicht starten.
- Darstellung, Kamera und UI zusätzlich visuell prüfen. Passende vorhandene `tests/capture_*.gd`-Skripte bzw. `.tscn`-Szenen verwenden und erzeugte Bilder ansehen. Rendering-Aufnahmen ohne `--headless` starten; Ausgabeorte im jeweiligen Skript nachlesen.
- Beispiel für Gesamtansichten: `& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_classic_harmony.gd`. Weitere Kursskripte: `capture_arrow_harmony.gd`, `capture_prototype_course.gd`.
- Echte Controllererkennung separat über `res://tests/controller_probe.tscn` ohne `--headless` prüfen. Headless-Tests ersetzen keine Hardwareprüfung; F3 zeigt Diagnose, F4 startet Kalibrierung.
- Nach bestandenen relevanten Prüfungen nicht ohne neue Änderung oder konkreten Verdacht erneut testen. Im Abschluss Ergebnis, Prüfungen und verbleibende Einschränkungen nennen.

## Dateien und lokale Umgebung

- `.godot/`, `.tools/`, `build/`, `logs/`, `tmp/`, `user_data/`, `*.log` und `*.import` sind laut `.gitignore` lokale oder generierte Inhalte. Nicht als Quelländerungen aufnehmen. Temporäre Hilfsskripte unter `tmp/` ablegen.
- Godot und andere interaktive Programme nur bei Bedarf öffnen. Hintergrundhilfen unter Windows ohne zusätzliches sichtbares Fenster starten.
- Bei Git-Fehler `detected dubious ownership` für dieses bekannte Projekt eine befehlsbezogene Ausnahme verwenden: `git -c safe.directory='J:/Projekte/mini putt' status --short`. Für weitere Git-Befehle denselben Schalter verwenden; keine globale Git-Konfiguration ändern.
- Vor Abschluss Diff und Arbeitsbaum prüfen. Diese Datei kompakt halten und bei geänderten Einstiegspunkten oder Werkzeugpfaden aktualisieren.
