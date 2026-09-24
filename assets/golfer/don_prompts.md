# Don: Imagegen-Promptset

Eingebautes Imagegen-Werkzeug, 24.09.2026. Referenz: `bruno_atlas.png`.

## Generierung

Use case: stylized-concept. Generate a production pixel sprite atlas for Putt & Pixel. The reference image is STYLE, EXACT POSE and GRID REGISTRATION reference only; change identity and clothes. Create DON, an immediately recognizable satirical Donald Trump golfer caricature: elderly stocky man with broad orange face, small eyes with pale surrounding areas, pursed mouth, extravagantly swept bright golden-yellow comb-over hair, NO HAT, no beard. Dark navy open suit jacket and trousers, white shirt and exceptionally LONG BRIGHT RED NECKTIE reaching well below waist. Keep tie red in every pose. Small pure turquoise pocket square only on jacket for player color replacement. Self-important expression, believes he is the best golfer. Full-body, adult proportions, same scale as reference. Strong crisp pixel art edges with limited palette. Exactly 4 columns x4 rows, canvas 1024x1536, equal256x384 cells, same body sizes and feet anchors as reference. Do not enlarge heads to chibi proportions.
Transparent alpha background. If alpha cannot be produced use uniformly pure RGB255,0,255 including enclosed gaps, never checkerboard, shadows or gradients. No text, no labels, no grid, no ground or ball. Silver putter. Both hands on putter during putting frames. Every sprite and its club must fit entirely within its cell with 12px safety margins. Feet remain planted and central.
Read row-major:
row1: (0) address at imaginary central ball, FRONT facing head readable, both hands center, putter vertical down; (1) same address eyes blinking shut; (2) same address breathing slightly raised shoulders; (3) watch ball screen right, club grounded.
row2: (4) short backswing club LEFT of center; (5) medium backswing further LEFT; (6) larger controlled putting backswing LEFT, club head by left knee; (7) concentrating hold same pose. No full drive.
row3: (8) central contact exactly same putter endpoint as address; (9) short followthrough RIGHT; (10) medium followthrough RIGHT; (11) larger followthrough RIGHT, eyes follow ball. No full drive.
row4: (12) smug celebratory thumbs up, other hand on putter; (13) boastful grin chin raised and fist raised, fully inside cell; (14) indignant pursed lips hands on grounded club; (15) incredulous sideways glance shoulders hunched.
Yellow comb-over, orange face and long red tie consistently clearly visible in every frame. Maintain 4x4 registration and silhouettes inside own cell.

## Hintergrundkorrektur

Edit only background of this production sprite atlas. Replace ALL background, glow, ground, shadows and empty gaps between arms and legs by perfectly uniform solid PURE MAGENTA RGB(255,0,255). No glow, no gradients, no checkerboard. Preserve all 16 golfers, every colored pixel of suit/hair/skin/red tie/putters, all poses, exact 4x4 registration, image size1024x1536 unchanged. Magenta is mandatory for game-engine chromakey. Do not alter sprites, only background.

