# Linux-Abnahme 0.7.0

Zusätzliches Linux-x64-Paket zu Release 0.7.0, geprüft am 25.09.2026 unter
Ubuntu 22.04 mit Godot 4.7.2, Xvfb und Mesa 23.2.1/llvmpipe.

Gebaut aus dem sauberen Commit `1604083fa3591fd66ce7d57995cf5b21f2ad045c`.
Spielquellen, Szenen, Bahndaten und Projektversion entsprechen dem bestehenden
Windows-Release. Ergänzt wurden Linux-Export, Paketierung, Anleitungen und
Plattformprüfungen. Der Routentest legt seinen Ausgabeordner jetzt auch auf
frischen Checkouts selbst an. Der bestehende Release-Tag und die Windows-Assets
bleiben unverändert; `BUILD.json` dokumentiert den Linux-Quellstand.

[Erfolgreicher Ubuntu-Prüflauf](https://github.com/OnekoSL/minigolf/actions/runs/36124889495)

| Prüfung | Ergebnis |
| --- | --- |
| Offizielle Godot-Engine und Exportvorlagen | SHA-512 gegen offizielle Prüfsummen bestätigt |
| Vollständige Spielsuite unter Linux | 5970 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Linux-Paket, Headless | 125 Checks, 0 Fehler, Exitcode 0 |
| Exportiertes Linux-Paket, OpenGL | 148 Checks, 0 Fehler, Exitcode 0 |
| Darstellung | 23 Paketaufnahmen und nativer Start visuell geprüft |
| Native Release-Binary | OpenGL-Start unter Xvfb/Mesa, Exitcode 0 |
| Frisch entpacktes Archiv | Acht Dateiprüfsummen bestätigt, Binary ausführbar (0755), Start mit Exitcode 0 |
| Lokale Kontrolle des heruntergeladenen CI-Artefakts | Archivhash, Dateiprüfsummen und Dateimodus bestätigt |

Keine GDScript- oder Ressourcenfehler. Absichtlich beschädigte Config-Dateien
erzeugen in Negativtests die erwarteten ConfigFile-Meldungen. Xvfb/Mesa meldet,
dass der VSync-Modus nicht umgeschaltet werden kann. Hardware-VSync ist damit
nicht abgenommen; Rendering und Spielstart funktionieren.

Alle Schreibtests liefen mit isoliertem `XDG_DATA_HOME`. Reale Audioausgabe,
Controller, Hardwarekalibrierung, Wayland und andere Distributionen wurden nicht
geprüft. Das Paket ist weiterhin eine spielbare Vorabversion für Linux x86_64.

`PuttAndPixel-0.7.0-linux-x64.tar.gz`, **35.989.251 Bytes**, enthält Binary,
Linux-Kurzanleitung, Neuerungen, Editor- und Übungsanleitung, Lizenzen,
Builddaten, Prüfbericht und Dateiprüfsummen.

- ELF SHA-256: `D43BFF31F55E53DC590B121175E12CBA9F3555EA791DD6D5131DC4DD0C263061`
- Archiv SHA-256: `2597B8FF1EFEE0414D3D2FA979C7E02E658E14F863D6BE72ECF6C26467D5CC43`
- [Release 0.7.0](https://github.com/OnekoSL/minigolf/releases/tag/v0.7.0)
