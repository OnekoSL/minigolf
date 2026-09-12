# Windows-Release 0.3.0

Spielbare Vorabversion mit acht Themenkursen, 72 regulären Bahnen und vier Golfern.
Die ZIP-Datei enthält eine eigenständige x64-EXE, Kurzanleitung, Neuerungen,
Godot-/Drittanbieter-Lizenzhinweise, Builddaten, Prüfbericht und SHA-256-Prüfsummen.

## Erstellen und prüfen

Alle Befehle aus dem Projektverzeichnis in PowerShell ausführen:

```powershell
& './tools/build_release.ps1'
& './.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . res://tests/test_runner.tscn
```

Version in `project.godot`, Windows-Dateiversion in `export_presets.cfg` und
Versionstexte dieser Release-Anleitung gemeinsam pflegen. Die EXE wird mit
`--export-release` und dem lokalen Release-Template gebaut. Controllerprofile
werden ausdrücklich mitgeliefert; Tests, Werkzeuge und lokale Daten sind ausgeschlossen.

`tools/release_smoke.tscn` prüft das exportierte Paket mit der passenden Editor-Engine:
aus dem **Paketordner** starten, `--main-pack <absolute EXE>` und den absoluten Pfad
zur Prüfszene übergeben. Ohne `--headless` und mit `-- <absoluter Aufnahmeordner>`
entstehen zusätzlich Titel-, Kurs- und Spielaufnahmen. Der Paketordner als
Arbeitsverzeichnis verhindert einen unbemerkten Rückgriff auf Quelldateien.

Die echte Release-EXE separat aus ihrem Ordner starten. Das Release-Template
unterstützt keine externen Skript-/Szenenwechsel; diese sind kein Laufzeittest.
Für eine automatisch beendete Renderprüfung unterstützt es
`--write-movie <absoluter PNG-Pfad> --quit-after 8 --log-file <absoluter Logpfad>`.

Nach erfolgreicher Prüfung `PRUEFBERICHT.txt` im Paketordner schreiben, einschließlich
der SHA-256-Prüfsumme der geprüften EXE. Anschließend:

```powershell
& './tools/package_release.ps1'
```

Das Skript verweigert fehlende Dateien, unerwartete Paketbeigaben und einen
Prüfbericht mit abweichendem EXE-Hash. Abschließend das ZIP frisch entpacken,
alle enthaltenen Prüfsummen vergleichen und die entpackte EXE starten.

## Speicherstände und Abnahme

Der interne Anwendungsname bleibt für bestehende Spielstände stabil.
Fenstertitel und Titelbildschirm zeigen Produktname und Version. Das Startfenster
ist 1280 × 720 groß; die interne Auflösung und Physik bleiben unverändert.

Automatische Prüfungen ersetzen nicht das manuelle Durchspielen aller Varianten
oder Controllerprüfungen auf fremden PCs. Das Release ist daher als spielbare
Vorabversion bezeichnet. Das geprüfte ZIP und seine SHA-256-Prüfsumme gehören zum
[GitHub-Release v0.3.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.3.0).
