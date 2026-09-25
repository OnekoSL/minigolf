# Release-Abnahme 0.7.0

Windows-x64-Vorabversion mit Übungsmodus, Tutorial, Schlagwiederholung und vergleichbaren Ballspuren. Acht Lektionen mit 14 Lernbahnen, elf Themenkurse, fünf Sprachen, Bahneditor und eigene Kurse. Abgenommen am 25.09.2026 mit Godot 4.7.2, Compatibility-Renderer.

Die EXE stammt aus dem sauberen Commit `24927f63756c6d3e506baababc3719ebc4e5a99c` (`source_dirty: false`). Der Release-Tag ergänzt diesen Stand ausschließlich um diesen Prüfbericht. Seit dem vollständig geprüften Übungsstand `7eb6278` wurden nur Versionsdaten, Releaseanleitungen und die Paketprüfung geändert; Spielquellen und Bahndaten sind unverändert.

| Prüfung | Ergebnis |
| --- | --- |
| Letzte vollständige Spielsuite mit Betonkorrektur und breiten Gefällefeldern | 5970 Checks, 0 Fehler, Exitcode 0; keine GDScript-Parserfehler |
| Lernrouten | Alle 14 Abschnitte mit Produktionsphysik, zusätzlich ±0,3° Ziel- und ±1 % Kraftabweichung |
| Übungsoberfläche | 95 Ansichten in fünf Sprachen visuell geprüft; Beton und breitere Pfeilfelder danach separat geprüft |
| Exportiertes Paket, Headless | 125 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Paket, Rendering | 148 Checks, 0 Fehler, Exitcode 0; 23 Aufnahmen visuell geprüft |
| Windows-Datei- und Produktversion | 0.7.0.0 |
| Eigenständige Release-EXE | Exitcode 0; Titel 0.7.0 bei 2560 × 1440 gerendert und angesehen |
| Frisch entpacktes ZIP | Alle acht Dateiprüfsummen stimmen; entpackte EXE startet mit Exitcode 0 |

Die Paketprüfung umfasst alle fünf Sprachkataloge mit je 926 Einträgen, Sprache und Einstellungen, elf Kursvorschauen, fünf Golfer, Beton, Eis und Rohrtransport. Neu geprüft sind der direkte Übungseinstieg, Tutorialkatalog, pausierende Erklärung, neutrale Eingabe, Produktionsschlag, Ballspur, Wiederholung, sichtbarer Betonbelag, drei verbreiterte Gefällefelder und separate Lernspeicherung. Editor, Tunnelgriffe, Undo, Testspiel, Bibliothek und Kurs-Import/Export bleiben Teil der Prüfung.

Paketprüfungen verwenden die passende Editor-Engine mit `--main-pack` und einer externen Prüfszene aus dem Paketordner. Die echte EXE und die frisch entpackte EXE wurden separat gestartet. Export, Prüfungen und Starts liefen ohne Skript- oder Ressourcenfehler. Alle Schreibtests verwenden isoliertes `APPDATA` unter `tmp/release-0.7.0/`. Nach den reinen Versions-/Releaseänderungen wurde die unveränderte Spielsuite nicht erneut ausgeführt.

Die Hardwareprobe des Übungsstands fand keinen Controller. Echte Controllerbedienung, Hardwarekalibrierung und andere PCs bleiben ungeprüft; die Veröffentlichung bleibt eine spielbare Vorabversion.

`PuttAndPixel-0.7.0-windows-x64.zip`, **46.973.262 Bytes**, enthält EXE, Kurzanleitung, Neuerungen, Editor- und Übungsanleitung, Godot-Lizenzen, Builddaten, Prüfbericht und Dateiprüfsummen.

- EXE SHA-256: `BA1ECC40D6082D5D27890315B93E7F20FAD1A9A7B46B8589A52FF467BB152546`
- ZIP SHA-256: `E2068831A2224BFAA125EC58DAF63FB96868A5337AA1397979C88B03A36B751D`
- [GitHub-Release v0.7.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.7.0)

Historische Prüfstände: [0.6.0](PRUEFSTAND_0.6.0.md), [0.5.0](PRUEFSTAND_0.5.0.md), [0.4.0](PRUEFSTAND_0.4.0.md), [0.3.0](PRUEFSTAND_0.3.0.md).
