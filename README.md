# Putt & Pixel - Spielrahmen-Prototyp

Spielbarer Godot-4-Prototyp fuer das controllerorientierte 2D-Minigolfspiel mit drei Kursen, insgesamt zweiundzwanzig echten Loechern, vier Spielmodi, Hotseat und Ergebnistabelle.

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
| Menue waehlen | linker Stick / D-Pad | WASD / Pfeile | bewegen |
| Menue bestaetigen | Kreuz | Leertaste / Enter | linke Taste |
| Menue zurueck | Kreis | Escape | rechte Taste |
| Zielen | linker Stick / D-Pad | WASD / Pfeile | bewegen |
| Schlagphasen | Kreuz | Leertaste / Enter | linke Taste |
| Abbrechen | Kreis | Escape | rechte Taste |
| Neustart | Quadrat | R | - |
| Testloch wechseln (Uebung) | Dreieck | F2 | - |
| Pause | Start | P | - |
| Diagnose | - | F3 | - |
| Kalibrierung | - | F4 | - |

Schlagfolge: einmal druecken startet Kraft, erneut druecken startet Genauigkeit, ein drittes Mal druecken und halten bereitet den Schlag vor. Loslassen startet den sichtbaren Abschwung; nach exakt 0,10 Sekunden treffen Schlaeger, Ton und Ball gleichzeitig aufeinander.

Auf grossen Bahnen bewegt das Zielkreuz die Kamera erst am Rand ihres Ruhebereichs. Das haelt besonders das Erkunden mit der Maus ruhig. Beim Rollen und im Kanonenflug folgt die Kamera dem Ball weich und blickt geschwindigkeitsabhaengig bis zu 48 interne Pixel voraus; nur harte Kontakte und der Kanonenabschuss geben einen sehr kleinen Kameraimpuls. Im Uebungsmodus schaltet Dreieck/F2 weiterhin zyklisch durch den gesamten Katalog aus zweiundzwanzig Kurs- und fuenf technischen Bahnen.

Die Controllerachsen werden direkt vom aktiven Geraet gelesen. Nach Menue-, Spieler- und Lochwechseln wartet eine Eingabeschranke auf einen neutralen Stick und losgelassene Tasten. Dadurch bleiben Stick und D-Pad aktiv, ohne einen gehaltenen Impuls in den naechsten Bildschirm zu uebertragen.

## Spielmodi und Runde

- **Einzelner Kurs:** ein Spieler waehlt zwischen **Klassische Neun** (Par 18), **Pfeil-Armageddon** (Par 27) und dem **Prototypkurs** (Par 38).
- **Lokaler Mehrspieler:** zwei bis vier Spieler waehlen ebenfalls einen Kurs, beenden jeweils ein ganzes Loch und reichen danach den Controller weiter.
- **Uebung:** ein frei gewaehltes Loch mit schnellem Neustart; Dreieck/F2 behaelt den Zugriff auf alle technischen Testbahnen.
- **Freies Spiel:** ein bis vier Spieler bauen eine eigene Folge aus bis zu neun echten Loechern; Wiederholungen sind erlaubt.

Spieler geben ueber eine controllerfreundliche Bildschirmtastatur Namen mit bis zu zwoelf Zeichen ein und erhalten eine eindeutige kosmetische Farbe. Nach jedem Loch erscheint die gemeinsame Tabelle. Der achte Schlag ist das Maximum; ein nicht eingelochtes Ergebnis wird als `8*` markiert. Nur vollstaendige offizielle Kursrunden koennen den jeweiligen lokalen Bestwert in `user://progress.cfg` verbessern. Uebung und freies Spiel zeigen die zweiundzwanzig echten Bahnen auf controllerfreundlichen Seiten mit je fuenf Eintraegen.

## Controller

Der angeschlossene Controller `054C:0268` wird unter Windows 10 von Godot/SDL als `PS3 Controller` erkannt. F3 zeigt Name, GUID, Achsen und gedrueckte Tasten. Falls die Belegung nicht stimmt, startet F4 die lokale Kalibrierung; das Ergebnis landet in `user://controller_mappings.cfg`.

Wenn SDL das Geraet auf einem anderen Rechner gar nicht erkennt, ist Steam Input der vorgesehene Fallback. Es werden keine zusaetzlichen Systemtreiber benoetigt.

## Tests

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```

Die Headless-Suite prueft 592 Faelle: Schusszustaende samt verzoegertem Kontakt und Abbruch, Genauigkeitsfehler, Reibung, alle acht Gefaellerichtungen, gedrehte Pfeilflaechen, Rechteck-, Kreis- und Kreisbogenkollisionen, Dreher- und Torimpuls, Triggerverkettung, verriegelte Kanonen, reproduzierbaren Bogenflug und die Referenzrouten aller zweiundzwanzig echten Loecher. Zusaetzlich werden Wasser-Ruecksetzung, Lochgeschwindigkeit, Bahn- und Kurskatalog, kuratierte technische Kursbahnen, paginierte Auswahl, Spieler- und Rundendaten, Hotseat-Wechsel, Schlaglimit, Neun-Loch-Tabelle, getrennte Bestwerte sowie Kamera-, Audio-, Effekt-, Eingabe- und Fokusverhalten geprueft.

Hardware-Erkennung des angeschlossenen PS3-Controllers pruefen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/controller_probe.tscn
```

## Prototypumfang

- der Kurs **Klassische Neun** mit drei Par-1-, drei Par-2- und drei Par-3-Bahnen, Gesamt-Par 18, sechs festen Bildschirmbahnen und drei horizontal scrollenden Bahnen
- der Kurs **Pfeil-Armageddon** mit je drei Par-2-, Par-3- und Par-4-Bahnen, Gesamt-Par 27, fuenf kompakten und vier horizontal scrollenden Pfeilpuzzles
- der neunloecherige **Prototypkurs** mit **S-Kurve an der Muehle**, **Die Diamantenlinie**, **Das Doppeltor**, **Die Kanonenwerkstatt** und allen fuenf technischen Testbahnen, Gesamt-Par 38
- fuenf technische Bahnen: Allround-Testloch, Acht-Richtungs-Labor, U-Flussbahn, Scroll-Testbahn und **Kurven-Labor**; Dreieck/F2 wechselt in der Uebung zyklisch durch alle 27 Bahnen
- typisierte `.tres`-Bahndaten fuer rechteckige Banden, runde Bumper, Kreisbogenwaende, gerade und gedrehte Flaechen, Hindernisse, Trigger, Kanonen, Kamera und Lochregeln; ein gemeinsamer Runtime-Builder erzeugt Darstellung und Kollisionen aller Bahnen
- Gruen, Sand, Gefaelle und Wasser; Pfeil-Armageddon unterscheidet sanfte, starke und fuehrende Pfeilflaechen sichtbar und physikalisch
- gerade und gedrehte Banden, massive Kreis-Bumper, dicke Kreisbogenwaende, rotierende Hindernisse, zwei deterministische Schiebetore sowie zwei automatisch ausloesende Kanonen mit sichtbarem Bogenflug
- reproduzierbare Ballphysik mit festen Physikschritten
- animierter Platzhaltergolfer mit getrennten Posen fuer Zielen, Timing, Abschwung, Beobachten, Wasser, Erfolg und perfekte Treffer
- Schlagzahl, Dezimeter-Entfernung, vertikale Kraft-/Weitenskala, eingerahmte Genauigkeitsanzeige und Ergebnisanzeige
- prozedurale Retro-Sounds fuer Schlagphasen, Treffer, Bande, Windmuehle, Tor, Schalter, Kanone, Wasser und Loch sowie materialabhaengiges Rollfeedback
- kurze codebasierte Splitter-, Staub-, Wasser-, Loch- und Perfekt-Effekte ohne Einfluss auf die Physik
- Controller-, Tastatur- und Mausbedienung
- persistenter Titel- und Menuefluss mit vier vollstaendig spielbaren Modi
- ein bis vier lokale Spieler mit Namen, Farbvariante und Controller-Uebergabe
- Loch- und Endtabellen, gemeinsamer Rang bei Gleichstand und lokaler Kursbestwert
- maximales Lochergebnis von acht Schlaegen

Noch nicht enthalten sind weitere Golferprofile, ein final ausgearbeiteter Produktionskurs, finale Pixel-Art, Musik, Einstellungen, Speichern laufender Runden und Bahneditor.
