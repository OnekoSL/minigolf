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

## Mara, Bruno und Nika (10.09.2026)

Mit dem eingebauten Imagegen-Werkzeug erzeugt, kein CLI/API-Fallback. Die neuen Dateien sind `mara_atlas.png`, `bruno_atlas.png` und `nika_atlas.png`, jeweils 1024 x 1536 Pixel. Als Stil- und Rasterreferenz diente der vorhandene Allrounder. Echte Alpha-Transparenz war angefordert; geliefert wurde der explizit erlaubte Magenta-Ersatz. Die vorhandene Shaderpipeline entfernt ihn beim Rendern und faerbt nur Polo beziehungsweise Weste. Quellbilder wurden unveraendert kopiert; Spritekorrekturen erfolgten ebenfalls mit Imagegen.

Finale Quelldateien im Imagegen-Ausgabeverzeichnis:
- Mara: `exec-e08f4ec6-331e-4d0d-b2bf-5a926da45513.png`
- Bruno: `exec-a34697a9-f758-4ee6-a1b3-6ca4f2bee475.png`
- Nika: `exec-1a95c7c0-a216-4686-9c91-46ed96496e83.png`

### Gemeinsamer Generierungsprompt

Use case: stylized-concept. Production pixel sprite atlas for Putt & Pixel. Reference image is STYLE AND EXACT POSE/GRID REGISTRATION reference, not target identity. Generate ONE new character across precisely 4 columns x4 rows, 1024x1536 canvas, equal256x384 cells, no margins between cells. Classic coarse 16-bit pixel art, dark outlines, limited flat shading. Match reference body size, feet anchors, putter locations and all16 poses exactly; adult proportions, both hands gripping the putter in every putting frame. No text, labels, grid, ground, shadow or ball. Real transparent alpha background; if alpha cannot be produced, use uniformly pure RGB255,0,255 including enclosed gaps, never checkerboard or gradients. All nontransparent contents remain inside own cell with 12px safety margins. Feet planted at same position in every frame. Row1: address, same blinking, same breathing, watch right. Row2: short left backswing, medium left backswing, larger left controlled PUTT backswing, concentrated hold. Row3: central contact same as address, short right followthrough, medium right followthrough, larger right followthrough. Row4: two success poses, two frustration poses. Pure turquoise family only on recolorable garment, never elsewhere. Silver putter, navy trousers, cream/dark golf shoes.

### Figuren-Prompts (an den gemeinsamen Prompt angehaengt)

**Mara:** Character MARA: adult woman, slim-average mature build, warm light skin, brown ponytail visible to side, cream visor (open top showing brown hair), turquoise collared short sleeve polo, straight navy trousers. Distinct female face, no beard. Calm careful posture. Success frames12,13: satisfied warm smile and small fist near chest with a subtle nod. Frustration14,15: sigh, lowered shoulders and head, refocus, grounded putter. Maintain same identity in all16 cells.

**Bruno:** Character BRUNO: broad stocky muscular adult male, visibly wider torso and thick arms than reference, cream sporty cap, warm light tanned skin, short brown stubble, turquoise polo with rolled sleeves exposing strong arms, wide navy golf trousers and broad golf shoes. Confident grounded stance. Success12,13: exuberant grin with clenched fist raised progressively, fully inside cell. Frustration14,15: look right with raised brows and incredulous expression, then perplexed head tilt, grounded putter. Distinct broad build across ALL16 cells, feet anchors unchanged.

**Nika:** Character NIKA: slender adult woman with short dark pixie haircut, no cap or hat, warm medium skin, turquoise sleeveless sporty V-neck vest over cream short-sleeve collared shirt, slim navy trousers and cream/dark shoes. Analytical attentive expression, precise controlled movements. CRITICAL row4 differs from reference: success12 and13 small determined clenched fist held at chest level below shoulder, modest closed-mouth smile and nod, NEVER fist overhead. Frustration14 and15 holds putter upright in one hand at torso height and skeptically examines silver head turned toward her, furrowed eyebrows then puzzled head tilt. All poses same woman, same narrow build. Front view feet stay planted.

### Gezielte Korrekturen

Mara: In den beiden Jubelzellen Faust auf Brusthoehe unterhalb der Schulter absenken, geschlossener zufriedener Mund, zweite Pose als kleines Nicken; restliches Raster erhalten.

Bruno: Zellenuebergreifende Putter- und Faustfragmente beseitigen. Die erste Korrektur wurde wegen eines verbleibenden Fragments erneut bearbeitet; zwischenzeitliche Bilder mit falsch gerichtetem Schlaeger wurden verworfen. Finaler Korrekturprompt:

Fix ONLY second row third cell: club is on WRONG side. Put silver head over the trouser knee on the VIEWER'S LEFT (the man's anatomical RIGHT knee). Club shaft slants like / not like backslash. Head at VIEWER LEFT of hands, hands above and to VIEWER RIGHT of club head. Club head overlaps navy pants of VIEWER LEFT leg, remaining inside silhouette. This is a leftward backswing as seen on the screen. Keep all other15 frames and all other elements identical. No character flip. Pure magenta background. Pixel art 1024x1536.

Alle finalen Kontaktboegen und Farbvarianten wurden im Godot-Renderer angesehen. Brunos hoher Ausholpunkt bleibt nun vollstaendig in der Zelle. Ausgabepfade der erweiterten Aufnahmen sind in `GOLFER.md` beschrieben.

