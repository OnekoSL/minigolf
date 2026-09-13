# Putt & Pixel – Anwendungssymbol

Eigenes Pixel-Art-Motiv: heller Golfball, goldene Zielfahne und türkisfarbene
Puttingfläche auf dunkelblauem Abzeichen. Der Außenbereich ist transparent.
Das Symbol gilt für das ganze Spiel und bleibt unabhängig vom gewählten Kurs.

- `putt_and_pixel_source.png`: unveränderte Bildvorlage, mit dem eingebauten Imagegen-Werkzeug am 13.09.2026 erzeugt.
- `putt_and_pixel.png`: 256 × 256 Pixel für das Godot-Anwendungssymbol.
- `putt_and_pixel.ico`: Windows-Icon mit 16, 24, 32, 48, 64, 128 und 256 Pixeln, jeweils mit 32-Bit-Farbe und Alpha.

`project.godot` verwendet PNG und natives Windows-Icon für das Fenster.
`export_presets.cfg` bindet die ICO-Datei in die EXE und gegebenenfalls einen
Konsolen-Wrapper ein. Die große Bildvorlage ist vom Spielpaket ausgeschlossen.

Die Größen werden ohne zusätzliche Abhängigkeit unter Windows erzeugt:

```powershell
& './tools/build_icon.ps1'
```

Das Skript verwendet System.Drawing ausschließlich zur Größen- und Formatkonvertierung.
Die Bildvorlage bleibt unverändert. Bei einer neuen Gestaltung eine neue Vorlage
erstellen und anschließend PNG/ICO gemeinsam neu erzeugen.

## Prüfung

Godot 4.7.2 übernimmt beim Windows-Export die sechs Größen 16, 32, 48, 64, 128 und
256 Pixel aus der ICO-Datei; die zusätzliche 24-Pixel-Stufe bleibt in der ICO-Vorlage.
Alle sechs eingebetteten PNG-Bilder wurden am 13.09.2026 direkt in den PE-Ressourcen
des [Testbuilds](../../build/windows/PuttAndPixel-UrbanWinter-Icon.exe) bytegenau
mit der Vorlage verglichen. Die normale Windows-Icon-Extraktion liefert das eigene
Symbol mit transparenter Außenkante. Kleine und große Größen wurden visuell geprüft.

Import, Export und eigenständiger EXE-Start liefen mit Exitcode 0. Das Startprotokoll
enthält keine Icon-Ladefehler. Protokolle und extrahierte Vorschauen liegen unter
`tmp/icon/`. Spielcode und Bahndaten wurden für das Icon nicht geändert; die Spielsuite
wurde deshalb nicht erneut ausgeführt.

## Gestaltungsprompt

Modus: eingebautes `image_gen`, keine CLI und kein eigener API-Schlüssel.

```text
Create a finished Windows application icon for a retro 2D minigolf game named Putt & Pixel. No text or letters. Square 1:1 canvas, 1024x1024 PNG with genuine transparent alpha outside the icon. Design as extremely clean deliberate pixel art with large blocky shapes and hard staircase edges, essentially a carefully drawn 32x32 sprite enlarged with nearest-neighbor pixels. A compact dark navy chamfered square badge (palette #09131b and #203f50), inside it one warm golden triangular golf flag at the upper right on a short ivory flagpole, a small dark golf cup below the flag, and a prominent large ivory golf ball in the lower left on a restrained teal putting-green wedge. The golf ball should be an unmistakable chunky round silhouette, with only two or three square cool-gray dimple/shadow details. Strong simple composition: cream ball lower left, golden flag upper right, teal course below. Restrict palette to 7 flat solid colors: deep navy, blue gray, dark teal, muted cyan-teal, warm cream, gold, ball shadow. Broad contrasting silhouettes readable at 16px and 32px. Fill nearly all the square with a thin transparent outside margin, centered, no excessive padding. No gradients, no blur, no glow, no photorealism, no 3D extrusion, no extra decorative pixels, no outer drop shadow, no lettering, no watermark, no mockup or grid of variants. This is the actual app icon asset, exactly one icon.
```
