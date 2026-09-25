# Release-Abnahme 0.6.0

Windows-x64-Vorabversion mit fünf Sprachen, Einstellungsmenü und Testgolfer Don. Ingame-Bahneditor, eigene Kurse, elf Themenkurse und 99 reguläre Bahnen bleiben enthalten. Abgenommen am 24.09.2026 mit Godot 4.7.2, Compatibility-Renderer.

Die EXE wurde aus dem sauberen Commit `e6b58a1a57e757bc3f44b49b8aa688a68b13da47` gebaut (`source_dirty: false`). Der Release-Tag ergänzt diesen Stand ausschließlich um diesen abschließenden Prüfbericht. Spielquellen, Szenen, Bahndaten und Controllerprofile sind unverändert gegenüber dem zuletzt geprüften Mehrsprachigkeitsstand `7058a6b61879fc313cf69e7ce0efc457dc8b668a`.

| Prüfung | Ergebnis |
| --- | --- |
| Vollständige Spielsuite vor der Releasevorbereitung | 5735 Checks, 0 Fehler, Exitcode 0; keine GDScript-Parserfehler |
| Vorbereitender Windows-Testexport mit Neustart | 11 + 14 Checks, 0 Fehler |
| Vorbereitende reale Anzeigewechsel | 6 Checks, 0 Fehler |
| Lokalisierung | 55 Renderaufnahmen aller fünf Sprachen visuell geprüft |
| Exportiertes Paket, Headless | 113 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Paket, Rendering | 129 Checks, 0 Fehler, Exitcode 0 |
| Windows-Datei- und Produktversion | 0.6.0.0 |
| Echte Release-EXE ohne Editor | Exitcode 0; Titel 0.6.0 bei 2560 × 1440 gerendert und angesehen |
| Frisch entpacktes ZIP | Alle sieben Dateiprüfsummen stimmen; entpackte EXE startet mit Exitcode 0 |

Die Paketprüfung umfasst alle fünf Sprachkataloge mit je 849 Einträgen, Sprachvorschau, Abbrechen und das Speichern/Laden der Einstellungen. Elf Kursvorschauen, alle fünf Golfer einschließlich Don, Kursstarts, Beton, Eis, Rohrtransport und ein kurzer Eisputt wurden geprüft. Hinzu kommen Editorauflösung, Auswahl nach Tunnelplatzierung, einzelnes und gemeinsames Verschieben, Rückgängig, Testspiel der ungespeicherten Bahn, Rückkehr zum Entwurf, Bibliothek und Kurs-Import/Export. 16 Paketaufnahmen wurden erzeugt; Titel, französische Einstellungen und Editor mit Tunnelgriffen wurden zusätzlich visuell kontrolliert.

Die Paketprüfungen verwenden die passende Editor-Engine mit dem exportierten Hauptpaket und einer externen Prüfszene aus dem Paketordner heraus. Die echte EXE und die frisch entpackte EXE wurden separat gestartet. Frühere eigenständige Editorprüfungen decken zusätzlich Neustart und einen tatsächlich gespielten eigenen Kurs samt Bestwert ab. Nach den reinen Versions-/Releaseänderungen wurde die unveränderte Spielsuite nicht erneut ausgeführt.

Export, Paketprüfungen und eigenständige Starts liefen ohne Skript- oder Ressourcenfehler. Sämtliche Releaseprüfungen verwendeten isoliertes `APPDATA` unter `tmp/release-0.6.0/`. Persönliche Inhalte sind nicht im Paket. Die Hardwareprobe fand keinen Controller; echte Controllerbedienung, Hardwarekalibrierung und andere PCs bleiben ungeprüft. Die Veröffentlichung bleibt eine spielbare Vorabversion.

`PuttAndPixel-0.6.0-windows-x64.zip`, **46.927.460 Bytes**, enthält EXE, Kurzanleitung, Neuerungen, Editoranleitung, Godot-Lizenzen, Builddaten, Prüfbericht und Dateiprüfsummen.

- EXE SHA-256: `C3C56633960BECBBB00D8EA6405BC9F88CB42F84CF774889295CA04B11733524`
- ZIP SHA-256: `FEC7A1DEB372F20D79AD406FDC91B0560FD313D628EB1A2CCEB9B8E653A79300`
- [GitHub-Release v0.6.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.6.0)

Historische Prüfstände: [0.5.0](PRUEFSTAND_0.5.0.md), [0.4.0](PRUEFSTAND_0.4.0.md), [0.3.0](PRUEFSTAND_0.3.0.md).
