# Vier Golfer

Stand: 10.09.2026. Alle Figuren sind direkt verfuegbar, ohne Ausruestungsboni oder Freischaltungen. Die Auswahl folgt auf den Spielernamen; danach wird eine eindeutige Spielerfarbe vergeben. Mehrere Spieler duerfen dieselbe Figur waehlen. Die Figur gilt fuer die gesamte Runde.

| Figur | Aussehen und Reaktion | Weite auf ebenem Gruen | Kraftzyklus | Genauigkeitszyklus | Perfektfenster | Max. Fehler |
|---|---|---:|---:|---:|---:|---:|
| Allrounder | Cap, Polo; freundlicher Jubel | 100 %, 230 dm | 4,0 s | 2,4 s | +/-0,05 | 8 Grad |
| Mara | Visor, brauner Zopf, gerade Hose; kleines Faustzeichen und Nicken, bei Fehlern Schultern senken | 85 %, 195 dm | 5,2 s | 2,4 s | +/-0,05 | 8 Grad |
| Bruno | Breite Statur, Cap, hochgekrempelte Aermel; erhobene Faust, unglaeubiger Blick | 125 %, 287 dm | 3,2 s | 2,4 s | +/-0,05 | 8 Grad |
| Nika | Kurze dunkle Haare, Weste ueber hellem Shirt; kleine Faustbewegung, skeptische Putterpruefung | 95 %, 218 dm | 4,0 s | 1,8 s | +/-0,025 | 4 Grad |

Zykluszeiten gelten fuer hin und zurueck. Alle Figuren beginnen bei etwa 1 dm. Maximale Ballgeschwindigkeit: `420 * sqrt(range_factor)`. Die Weiten sind gerundet und gelten ausschliesslich fuer ebenes Gruen. Die bestehende nichtlineare Winkel-Fehlerkurve bleibt bestehen; keine Zufallsfehler. Allrounder-Werte sind unveraendert.

## Ressourcen und Ablauf

`data/golfers/*.tres` verwenden `GolferDefinition`. Diese Ressourcen enthalten ID, Anzeigename, Beschreibung, Atlas und Spielwerte. `PlayerProfile.golfer_id` ist standardmaessig `allrounder`; der vierte Parameter von `PlayerProfile.create` ist optional. Unbekannte IDs werden in der Rundenvalidierung abgelehnt, die isolierte Darstellung faellt auf den Allrounder zurueck.

Die Schlagsteuerung uebernimmt das Profil beim Erstellen des Spieler-Versuchs. HUD, Sprite und Kraftskala beziehen dieselbe Definition. Wiederholte HUD-Aktualisierungen setzen die Animation nicht zurueck. Ein echter Figuren- oder Farbwechsel entfernt Reaktion, Kontakt und Perfektglanz. Jede Spriteinstanz besitzt ein eigenes Palettenmaterial.

Alle Atlanten verwenden dieselben 16 Posen in 4 x 4 Zellen, intern 88 x 144 Pixel. Die Genauigkeits- und Haltephase bewahren die erreichte Ausholpose. Der Abschwung liest den Fortschritt des Schlagsystems. Kontaktpose, Schlagton und echter Ballstart erfolgen bei 0,10 Sekunden; Animationen starten keine Physik. Jubel beginnt sofort, die zweite Pose nach 0,16 Sekunden; Aerger wechselt nach 0,30 Sekunden. Pause friert ein. Quelle und Promptset: [assets/golfer/README.md](assets/golfer/README.md).

Gemeinsame Kursbestwerte bleiben bestehen. Neue Revisionen: Klassische Neun 9, Pfeil-Armageddon 7, Prototypkurs 5, Referenzbahnen 3, Labyrinth-Neun 3. Alte Eintraege und Controllerkalibrierungen werden nicht geloescht.

## Pruefung

Abschliessende Headless-Suite: **3405 Checks, 0 Fehler**, Exitcode 0. Windows-Releaseexport und Starttest ebenfalls Exitcode 0; der exportierte Build wurde anschliessend als Spiel gestartet. Darstellung bei 640 x 360 und zweifacher Vergroesserung wurde anhand der gerenderten Aufnahmen geprueft.

- `tests/golfer_profiles_test.gd`: Profildaten, 1-dm-Untergrenze, Skalenstriche, tatsaechliche Startgeschwindigkeiten, Zykluszeiten, Perfektgrenzen, Menuefolge, Eingabesperren und Mehrfachwahl.
- `tests/golfer_animation_test.gd`: alle vier Figuren mit minimaler, mittlerer und maximaler Kraft, langem Halten, exaktem Kontakt, Abbruch, externer Bewegung, Reaktionen, Pause und Ruecksetzen.
- `tests/golfer_routes_test.gd` und `tests/golfer_routes.json`: dauerhaft reproduzierbare Routen fuer die von geringerer Reichweite betroffenen Loecher sowie Mara auf Diagonalfalle mit aktiven Hindernissen. Gezaehlt werden echte Kontakte nach sechs Physikticks; Einlochen innerhalb des Schlaglimits ist das Kriterium, kein pauschaler PAR-Nachweis.
- `tests/capture_golfer.tscn`: Kontaktboegen, vier Farben und drei Kraftsequenzen pro Figur nach `.godot/golfer/<id>-poses.png`, `-colors.png`, `-sequences.png`; Spielbilder als `-game-native.png` und `-game-2x.png`, Auswahl als `selection.png`. Ohne `--headless` starten.

Zusaetzlicher Live-Audit: 69 erfolgreiche Laeufe (alle drei neuen Figuren auf den neun klassischen, neun Pfeil- und fuenf neu gestalteten Prototypbahnen). Mara schaffte ausserdem alle neun Referenzbahnen, die vier weiteren Prototypbahnen und Diagonalfalle mit aktiven Mechanismen. Nachputts wurden als regulaere, legale Schlaege ausgefuehrt. Keine Bahngeometrie wurde veraendert.

**Bestehende Pruefluecke:** Fuer die acht anderen Labyrinthbahnen liefern die bisherigen Geometrierouten auch mit dem Allrounder keinen erfolgreichen Live-Nachweis. Der Kontrolllauf mit Mara scheitert an denselben Routenproblemen; alle urspruenglichen Schlagstaerken liegen bereits in Maras Bereich. Daraus folgt weder ein Nachweis der Unspielbarkeit noch eine Freigabe dieser acht Bahnen. Ihre Live-Routen und PAR-Abnahme bleiben offen; der Golfer-Build ist keine vollstaendige Kursfreigabe.

Turniersieg-Reaktionen und weitere Figuren sind nicht Bestandteil dieser Erweiterung. Eine echte Controller-Hardwarepruefung wird durch die automatisierten Menuepruefungen nicht ersetzt.
