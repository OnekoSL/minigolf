# Windows-Release 0.7.0

Spielbare Vorabversion mit Ingame-Bahneditor, eigenen Kursen, elf Themenkursen,
99 regulären Bahnen, vier regulären Golfern und Testgolfer Don.
Der neue Übungsbereich enthält acht Lektionen mit 14 Lernbahnen,
Schlagwiederholung, vergleichbare Ballspuren und unbegrenztes freies Training.
Spiel und Editor sind in fünf Sprachen verfügbar; das Einstellungsmenü bietet
Sprachwahl, Ton, Anzeige und die bestehende Controllerkalibrierung.
Die ZIP-Datei enthält eine eigenständige x64-EXE, Kurzanleitung, Neuerungen,
Editor- und Übungsanleitung, Godot-/Drittanbieter-Lizenzhinweise, Builddaten, Prüfbericht und SHA-256-Prüfsummen.

## Erstellen und prüfen

Alle Befehle aus dem Projektverzeichnis in PowerShell ausführen:

```powershell
& './tools/build_release.ps1'
& './tools/test_editor.ps1' -FullSuite
```

Version in `project.godot`, Windows-Dateiversion in `export_presets.cfg` und
Versionstexte dieser Release-Anleitung gemeinsam pflegen. Die EXE wird mit
`--export-release` und dem lokalen Release-Template gebaut. Controllerprofile
werden ausdrücklich mitgeliefert; Tests, Werkzeuge und lokale Daten sind ausgeschlossen.

Das eigene [Anwendungssymbol](../assets/branding/README.md) ist
in Projekt und Windows-Export hinterlegt. `assets/branding/putt_and_pixel.ico` enthält
sieben Größen von 16 bis 256 Pixeln; PNG und ICO lassen sich mit
`./tools/build_icon.ps1` aus der erhaltenen Bildvorlage neu erstellen. Beim Testexport
auch das eingebettete EXE-Icon und das Fenstersymbol prüfen. Bereits veröffentlichte
EXE-Dateien werden dadurch nicht nachträglich geändert.

`tools/release_smoke.tscn` prüft das exportierte Paket mit der passenden Editor-Engine:
aus dem **Paketordner** starten, `--main-pack <absolute EXE>` und den absoluten Pfad
zur Prüfszene übergeben. Ohne `--headless` und mit `-- <absoluter Aufnahmeordner>`
entstehen zusätzlich Titel-, Kurs- und Spielaufnahmen. Der Paketordner als
Arbeitsverzeichnis verhindert einen unbemerkten Rückgriff auf Quelldateien.

Die echte Release-EXE separat aus ihrem Ordner starten. Das Release-Template
unterstützt keine externen Skript-/Szenenwechsel; diese sind kein Laufzeittest.
Für eine automatisch beendete Renderprüfung unterstützt es
`--write-movie <absoluter PNG-Pfad> --quit-after 8 --log-file <absoluter Logpfad>`.

Alle Paketprüfungen mit einem separaten `APPDATA` unter `tmp/` ausführen,
damit lokale Bahnen, Bestwerte und Controllerkalibrierung unangetastet bleiben.

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
verwendet standardmäßig bis zu 2560 × 1440, begrenzt auf den Bildschirm.
Sprache, Ton und Anzeige werden in `user://settings.cfg` gespeichert.
Die interne Auflösung und Physik bleiben unverändert.

Automatische Prüfungen ersetzen nicht das manuelle Durchspielen aller Varianten
oder Controllerprüfungen auf fremden PCs. Das Release ist daher als spielbare
Vorabversion bezeichnet. Das geprüfte ZIP und seine SHA-256-Prüfsumme gehören zum
[GitHub-Release v0.7.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.7.0).
