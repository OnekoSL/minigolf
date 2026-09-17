# Release-Abnahme 0.5.0

Windows-x64-Vorabversion mit Ingame-Bahneditor, eigenen Kursen und korrigierter Tunnelbedienung. Elf Themenkurse und 99 reguläre Bahnen bleiben enthalten. Abgenommen am 17.09.2026 mit Godot 4.7.2, Compatibility-Renderer.

Die EXE wurde aus dem sauberen Commit `7ff38de747e7e5be723d094f79faaaf48129515c` gebaut (`source_dirty: false`). Der Release-Tag ergänzt diesen Stand ausschließlich um den abschließenden Prüfbericht und den Downloadverweis. Spielquellen, Szenen, Bahndaten und Controllerprofile sind unverändert gegenüber dem zuletzt geprüften Editorstand.

| Prüfung | Ergebnis |
| --- | --- |
| Vollständige Spielsuite vor der Releasevorbereitung | 5462 Checks, 0 Fehler, Exitcode 0; davon 279 Editorprüfungen |
| Exportiertes Paket, Headless | 98 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Paket, Rendering | 109 Checks, 0 Fehler, Exitcode 0 |
| Windows-Datei- und Produktversion | 0.5.0.0 |
| Echte Release-EXE ohne Editor | Exitcode 0; Titel 0.5.0 bei 2560 × 1440 gerendert und angesehen |
| Frisch entpacktes ZIP | Alle sieben Dateiprüfsummen stimmen; entpackte EXE startet mit Exitcode 0 |

Die Paketprüfung umfasst elf Kursvorschauen, alle vier Golfer, Kursstarts, Beton, Eis, Rohrtransport und einen kurzen Eisputt. Hinzu kommen Editorauflösung, Auswahl nach Tunnelplatzierung, einzelnes und gemeinsames Verschieben, Rückgängig, Testspiel der ungespeicherten Bahn, Rückkehr zum Entwurf, Speichern und Laden der Bibliothek sowie Kurs-Import/Export. Titel, Editor mit Tunnelgriffen, Testspiel und Bibliothek wurden visuell geprüft.

Die Paketprüfungen verwenden die passende Editor-Engine mit dem exportierten Hauptpaket und einer externen Prüfszene. Die echte EXE und die frisch entpackte EXE wurden separat gestartet. Frühere eigenständige Editorprüfungen decken zusätzlich Neustart und einen tatsächlich gespielten eigenen Kurs samt Bestwert ab. Nach den reinen Versions-/Releaseänderungen wurde die unveränderte Spielsuite nicht erneut ausgeführt.

Export, Paketprüfungen und eigenständige Starts liefen ohne Skript- oder Ressourcenfehler. Sämtliche Releaseprüfungen verwendeten isoliertes `APPDATA` unter `tmp/release-0.5.0/`. Persönliche Inhalte sind nicht im Paket. Reale Controllerhardware und andere PCs wurden nicht erneut geprüft; die Veröffentlichung bleibt eine spielbare Vorabversion.

`PuttAndPixel-0.5.0-windows-x64.zip`, **45.278.712 Bytes**, enthält EXE, Kurzanleitung, Neuerungen, Editoranleitung, Godot-Lizenzen, Builddaten, Prüfbericht und Dateiprüfsummen.

- EXE SHA-256: `DF85B7DCE5B7DB7588FB27B0D0FA8C2597D77524FD1D25D105B5AE54DDE46684`
- ZIP SHA-256: `19F6A2589938F571176BA51C6F0338A266E601E315BDF3EFD0F3D0D5B86D3638`
- [GitHub-Release v0.5.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.5.0)

Historische Prüfstände: [0.4.0](PRUEFSTAND_0.4.0.md), [0.3.0](PRUEFSTAND_0.3.0.md).
