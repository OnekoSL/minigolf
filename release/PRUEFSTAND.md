# Release-Abnahme 0.3.0

Stand: 11.09.2026. Spielbare Windows-x64-Vorabversion, Godot 4.7.2,
Compatibility-Renderer. Veröffentlichung als GitHub-Vorabversion `v0.3.0`.

- Release-Export (`--export-release`): Exitcode 0. Eingebettete Spieldaten,
  Windows-Datei-/Produktversion 0.3.0.0, keine Debug-Konsolenbeigabe.
- Gesamte Headless-Suite: **4.108 Checks, 0 Fehler**, Exitcode 0.
- Exportierte Daten/Szenen mit passender Prüfengine aus dem Paketordner:
  **23 Headless-Checks**, zusätzlich **26 Checks mit Renderaufnahmen**, jeweils 0 Fehler.
- Alle acht Kursvorschauen mit insgesamt 72 Bahnen aufgebaut; Spielstart mit
  allen vier Figuren; Zahnrad mit 16 Sekunden Umlaufzeit.
- Controllerprofile vorhanden; Entwicklertests und Buildwerkzeuge ausgeschlossen.
- Der bisherige Benutzer-Speicherordner wird weiterverwendet.
- Echte Release-EXE eigenständig mit OpenGL gestartet und Titel gerendert, Exitcode 0.
  Titel-, Kurs- und Spielansichten visuell kontrolliert.
- ZIP frisch nach `build/release-check/0.3.0/` entpackt, alle sechs enthaltenen
  Dateiprüfsummen identisch. Die entpackte EXE erneut eigenständig gestartet und
  gerendert, Exitcode 0.

Paket: `build/releases/PuttAndPixel-0.3.0-windows-x64.zip` (44.843.454 Bytes).
SHA-256: `821596BBEE11DA30D74B715E2CDB90CE576D08117CC8B978C4CD85B6202E9125`.
Protokolle und Aufnahmen liegen lokal unter `tmp/release-0.3.0/`.

Das veröffentlichte ZIP bleibt gegenüber dieser Abnahme unverändert. Seine
`BUILD.json` nennt den damaligen Basiscommit `f7bb38c` und `source_dirty: true`,
weil die Release-Anpassungen beim Export noch nicht eingecheckt waren.
Der Tag `v0.3.0` enthält diese Anpassungen und die Veröffentlichungsdokumentation.

Die Release-Laufzeit unterstützt keine externen Skript-/Szenenwechsel.
Der Daten-/Szenenaudit verwendet deshalb die Editor-Engine mit dem exportierten
Paket und ist getrennt vom eigenständigen EXE-Start ausgewiesen.

Die zwei ConfigFile-Parsermeldungen der Gesamtsuite sind beabsichtigte Negativtests.
Die lokale Umgebung meldet einen nicht lesbaren Zertifikatsspeicher; das Spiel
benötigt keinen Netzwerkzugriff. Die erfolgreichen Prüfläufe enthalten keine
GDScript-Parserfehler.

Nicht erneut geprüft: reale Controllerhardware und Betrieb auf anderen PCs.
Die automatisierten Routen decken nicht jede mögliche Schlag- oder Timingvariante
ab. Weitere manuelle Spieltests gehören zur Abnahme dieser Vorabversion.
