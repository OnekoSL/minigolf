# Putt & Pixel - Grundprototyp

Spielbarer Godot-4-Prototyp fuer das controllerorientierte 2D-Minigolfspiel.

## Starten

Die portable Godot-Version liegt lokal unter `.tools/godot-4.7.2/` und wird nicht versioniert.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --editor --path .
```

Direkt spielen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --path .
```

## Steuerung

| Funktion | Controller | Tastatur | Maus |
|---|---|---|---|
| Zielen | linker Stick / D-Pad | WASD / Pfeile | bewegen |
| Schlagphasen | Kreuz | Leertaste / Enter | linke Taste |
| Abbrechen | Kreis | Escape | rechte Taste |
| Neustart | Quadrat | R | - |
| Testloch wechseln | Dreieck | F2 | - |
| Pause | Start | P | - |
| Diagnose | - | F3 | - |
| Kalibrierung | - | F4 | - |

Schlagfolge: einmal druecken startet Kraft, erneut druecken startet Genauigkeit, ein drittes Mal druecken und halten bereitet den Schlag vor. Loslassen startet den sichtbaren Abschwung; nach exakt 0,10 Sekunden treffen Schlaeger, Ton und Ball gleichzeitig aufeinander.

Auf grossen Bahnen bewegt das Zielkreuz die Kamera erst am Rand ihres Ruhebereichs. Das haelt besonders das Erkunden mit der Maus ruhig. Beim Rollen folgt die Kamera dem Ball weich und blickt geschwindigkeitsabhaengig bis zu 48 interne Pixel voraus; nur harte Banden-, Windmuehlen- oder Torkontakte geben einen sehr kleinen Kameraimpuls. Beim Start wird das Referenzloch **S-Kurve an der Muehle** geladen. Dreieck/F2 schaltet danach durch **Die Diamantenlinie**, **Das Doppeltor**, die vier technischen Testbahnen und zurueck.

Die Controllerachsen werden direkt vom aktiven Geraet gelesen. Dadurch bleiben Stick und D-Pad auch nach wiederholtem Wechsel der Testbahn aktiv; eine kurze Wechsel-Sperre verhindert doppelte Dreieck-Impulse.

## Controller

Der angeschlossene Controller `054C:0268` wird unter Windows 10 von Godot/SDL als `PS3 Controller` erkannt. F3 zeigt Name, GUID, Achsen und gedrueckte Tasten. Falls die Belegung nicht stimmt, startet F4 die lokale Kalibrierung; das Ergebnis landet in `user://controller_mappings.cfg`.

Wenn SDL das Geraet auf einem anderen Rechner gar nicht erkennt, ist Steam Input der vorgesehene Fallback. Es werden keine zusaetzlichen Systemtreiber benoetigt.

## Tests

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```

Die Headless-Suite prueft 198 Faelle: Schusszustaende samt verzoegertem Kontakt und Abbruch, Genauigkeitsfehler, Reibung, alle acht Gefaellerichtungen, Bandenreflexion, Dreher- und Torimpuls, reproduzierbare Routen aller echten Loecher, Wasser-Ruecksetzung, Lochgeschwindigkeit, Bahnkatalog sowie Kamera-, Audio-, Effekt-, Eingabe- und Fokusverhalten.

Hardware-Erkennung des angeschlossenen PS3-Controllers pruefen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/controller_probe.tscn
```

## Prototypumfang

- drei echte Loecher: **S-Kurve an der Muehle**, das geometrische Par 3 **Die Diamantenlinie** und das mechanische Par 4 **Das Doppeltor**
- ein Par-4-Allround-Testloch, ein Acht-Richtungs-Labor, eine U-foermige Flussbahn und eine grosse Scroll-Testbahn; Dreieck/F2 wechselt zyklisch durch alle sieben Bahnen
- typisierte `.tres`-Bahndaten fuer Banden, Flaechen, Hindernisse, Kamera und Lochregeln; ein gemeinsamer Runtime-Builder erzeugt alle Bahnen
- Gruen, Sand, Gefaelle und Wasser
- Banden, rotierende Hindernisse und zwei deterministische Schiebetore mit gemeinsamem Timingfenster
- reproduzierbare Ballphysik mit festen Physikschritten
- animierter Platzhaltergolfer mit getrennten Posen fuer Zielen, Timing, Abschwung, Beobachten, Wasser, Erfolg und perfekte Treffer
- Schlagzahl, Dezimeter-Entfernung, vertikale Kraft-/Weitenskala, eingerahmte Genauigkeitsanzeige und Ergebnisanzeige
- prozedurale Retro-Sounds fuer Schlagphasen, Treffer, Bande, Windmuehle, Tor, Wasser und Loch sowie materialabhaengiges Rollfeedback
- kurze codebasierte Splitter-, Staub-, Wasser-, Loch- und Perfekt-Effekte ohne Einfluss auf die Physik
- Controller-, Tastatur- und Mausbedienung

Noch nicht enthalten sind Hotseat, weitere Golfer, ein kompletter Kurs, finale Pixel-Art, Musik, Speichern und Bahneditor.
