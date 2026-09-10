# Allrounder: Pixelatlas

- Erzeugt am 10.09.2026 mit dem eingebauten Imagegen-Werkzeug; kein CLI/API-Fallback.
- Quelle: `allrounder_atlas.png`, 1024 x 1536 Pixel, 4 x 4 gleich grosse Zellen.
- Jede Zelle wird in Godot auf 88 x 144 interne Pixel abgebildet. Der Shader tastet pro internem Pixel einmal ab; ganzzahlige Vergroesserung bleibt scharf.
- Die angeforderte Alpha-Freistellung wurde vom Bildwerkzeug nicht geliefert. Deshalb verwendet die finale Quelle Magenta als Schluesselfarbe. `palette.gdshader` entfernt Hintergrund und Farbraender beim Rendern vollstaendig und ersetzt ausschliesslich die Tuerkistoene des Polos durch die Spielerpalette. Keine neue Abhaengigkeit.
- Posen in Zeilenreihenfolge: Ansprechen, Blinzeln, Atmen, Beobachten; kurz/mittel/weit ausholen, Konzentrationsvariante; Kontakt, kurz/mittel/weit durchschwingen; zwei Jubel- und zwei Aergerposen.
- Die Konzentrationsvariante ist im Kontaktbogen enthalten; im Spiel wird beim Genauigkeitswechsel die zuvor gewaehlte Ausholpose gehalten, damit der Schlaeger nicht springt.
- Die Spritekomponente behaelt ihren bestehenden Klassennamen und ihre UID. Der Einblendungsball wird separat gezeichnet, damit kein generierter Ball vor dem echten Kontakt losrollt.
- Aufnahmen: `godot --path . res://tests/capture_golfer.tscn` -> `.godot/golfer/poses.png`, `colors.png`, `sequences.png`. Die drei Sequenzzeilen zeigen minimale, mittlere und maximale Kraft.

## Urspruenglicher Generierungsprompt

Create a production sprite atlas for a retro 2D minigolf game, with TRANSPARENT background (real alpha), no text, no grid lines, no labels, no ground, no ball. A precisely aligned 4-column by 4-row grid of 16 equal cells, canvas 1024x1536 pixels, each cell 256x384. Every cell contains the SAME full-body adult male golfer, facing the viewer, same scale and clothing and face. Handcrafted classic 16-bit pixel art, intentionally coarse pixel clusters, crisp hard edges, restricted palette, tasteful dark outline, 3-tone shading. Adult proportions (head about one sixth total height), friendly face, cream cap, turquoise short sleeve collared polo, dark navy trousers, cream and dark golf shoes, brown skin, silver putter. Both hands grip one putter whenever putting. Strong readable anatomy, bent elbows, slight forward lean and flexed knees, genuine controlled putting, NOT a full golf drive. Character occupies about 70% cell height, cap near y=54, feet at y=330, center x=128. Entire silhouette and putter within x=15..240, y=25..360. Feet remain identically planted and body scale IDENTICAL across all cells. Putter head at address near (128,352); no ball. Treat as exact animation keyframes, no separate character designs.
Read row-major, 16 cells:
row 1: (0) address at imaginary central ball, eyes down, both hands center, putter vertical down; (1) same address blinking eyes shut; (2) same address with subtle breathing shoulders lifted; (3) watching ball toward screen right, head slightly turned, putter calmly grounded to right.
row 2: (4) short backswing putter head 25 pixels left of address; (5) medium backswing putter head 55 pixels left of address; (6) maximum controlled PUTTING backswing head 85 pixels left and 50 pixels up, shoulders subtly turned, feet stationary; (7) same maximum backswing concentrating, eyebrows lowered.
row 3: (8) precise contact pose same putter endpoint as address, eyes down; (9) short followthrough putter head 25 pixels right of address; (10) medium followthrough putter head 55 pixels right; (11) large putting followthrough putter head 85 pixels right and 50 pixels up, eyes follow ball, feet stationary.
row 4: (12) quick happy clenched left fist at shoulder, right hand holds putter, broad smile; (13) delighted modest celebration fist raised, putter in other hand, body same place; (14) disappointed head lowered, shoulders slumped, hands rest on grounded putter; (15) sighing and a little head shake, disappointed face.
Keep polo pure turquoise family distinct from every other material for palette replacement. No turquoise anywhere except shirt. No shadows outside sprite, no translucent antialiasing. EXACT 4x4 cell grid and consistent pose registration are essential.

## Nachbearbeitung mit Imagegen

1. Hintergrundextraktion mit echter Transparenz angefordert; Ergebnis weiterhin mit Verlauf, verworfen.
2. Gesamten Hintergrund einschliesslich Arm-/Beinzwischenraeumen durch reines RGB(255,0,255) ersetzen lassen. Alle Figuren, Posen, Farben, Zellpositionen und Abmessungen erhalten.
3. Technische Korrektur: Putter in Zeile 2, Spalte 3 vollstaendig in seine eigene Zelle verlegen; ueberstehendes Fragment in Nachbarzelle entfernen. In Zeile 1, Spalte 2 geschlossene Augen, in Spalte 3 leicht angehobene Schultern fuer die Atmung. Fuesse, Raster und Magentahintergrund erhalten.

Das finale Quellbild stammt aus `exec-4335e874-124b-4f9b-9210-9024d4ca3e4d.png` im Imagegen-Ausgabeverzeichnis und ist vollstaendig in das Projekt kopiert.

