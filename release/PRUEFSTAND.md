# Release-Abnahme 0.4.0

Windows-x64-Vorabversion mit elf Kursen und 99 regulären Bahnen, Godot 4.7.2,
Compatibility-Renderer. Veröffentlichung unter `v0.4.0`.

Abgenommen am 13.09.2026. Die EXE wurde aus dem sauberen Commit
`e3d8ad4a224ded93966e66797d1fea706893f8df` gebaut (`source_dirty: false`).
Der Release-Tag ergänzt diesen Stand ausschließlich um dieses Prüfprotokoll.

## Automatische und visuelle Prüfung

| Prüfung | Ergebnis |
| --- | --- |
| Katalogvalidierung | 113 gültige Bahndefinitionen |
| Vollständige Headless-Suite | 5183 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Paket, Headless | 86 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Paket, Rendering | 94 Checks, 0 Fehler, Exitcode 0 |
| Windows-Datei- und Produktversion | 0.4.0.0 |
| Eingebettetes Anwendungssymbol | Sechs Größen (16–256 px), bytegenau mit der ICO-Vorlage verglichen |
| Eigenständiger EXE-Start | Exitcode 0, Titel 0.4.0 bei 2560 × 1440 gerendert |
| Frisch entpacktes ZIP | Alle sechs Dateiprüfsummen stimmen; entpackte EXE startet mit Exitcode 0 |

Die Paketprüfung umfasst alle elf Kursvorschauen, Starts mit allen vier Golfern,
Zahnradtempo, alle 27 Bahnen von Zirkus, Baustelle und Urban Winter sowie Beton,
Eis, Rohrtransport und einen kurzen Eisputt. Titel, Kursseiten 2–4, Spielansicht,
Rohraustritt und Eisgleiten wurden gerendert und angesehen.

Die zwei ConfigFile-Parsermeldungen der Gesamtsuite gehören zu absichtlich
beschädigten Testdateien. Export, Paketprüfungen und eigenständige Starts liefen
ohne GDScript- oder Ressourcenfehler. Die Paketprüfungen verwenden die passende
Editor-Engine mit dem exportierten Hauptpaket; der echte EXE-Start wurde separat
ohne Editor ausgeführt. Protokolle und Aufnahmen liegen lokal unter
`tmp/release-0.4.0/` und sind nicht Bestandteil des Downloads.

## Auslieferung

`PuttAndPixel-0.4.0-windows-x64.zip`, 45.182.327 Bytes, enthält EXE, Kurzanleitung,
Neuerungen, Godot-Lizenzen, Builddaten, Prüfbericht und Dateiprüfsummen.
Persönliche Bestwerte und Controllerkalibrierungen sind nicht enthalten.

- EXE SHA-256: `F5694981E71897FC2ED99DB69B66BE6BB319FB33B2E84F150F9A4C30FD760E5F`
- ZIP SHA-256: `CE5CEF670BD5A8BE0935AE512672373429AB506DCAC23EF8CCB88BA14A8AAD06`

Reale Controllerhardware und Betrieb auf anderen PCs wurden nicht erneut geprüft.
Automatisierte Routen decken nicht jede mögliche Schlag- oder Timingvariante ab.
Die Veröffentlichung bleibt eine spielbare Vorabversion.

Der [Prüfstand von 0.3.0](PRUEFSTAND_0.3.0.md) bleibt als historische Referenz erhalten.
