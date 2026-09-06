# Putt & Pixel - Spielrahmen-Prototyp

Spielbarer Godot-4-Prototyp fuer das controllerorientierte 2D-Minigolfspiel mit fuenf Kursen, insgesamt einunddreissig echten Loechern, neun Referenzbahnen, vier Spielmodi, Hotseat und Ergebnistabelle.

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

Auf grossen Bahnen bewegt das Zielkreuz die Kamera erst am Rand ihres Ruhebereichs. Das haelt besonders das Erkunden mit der Maus ruhig. Beim Rollen und im Kanonenflug folgt die Kamera dem Ball weich und blickt geschwindigkeitsabhaengig bis zu 48 interne Pixel voraus; nur harte Kontakte und der Kanonenabschuss geben einen sehr kleinen Kameraimpuls. Im Uebungsmodus schaltet Dreieck/F2 weiterhin zyklisch durch den gesamten Katalog aus einunddreissig Kurs- und vierzehn technischen Bahnen.

Die Controllerachsen werden direkt vom aktiven Geraet gelesen. Nach Menue-, Spieler- und Lochwechseln wartet eine Eingabeschranke auf einen neutralen Stick und losgelassene Tasten. Dadurch bleiben Stick und D-Pad aktiv, ohne einen gehaltenen Impuls in den naechsten Bildschirm zu uebertragen.

## Spielmodi und Runde

- **Einzelner Kurs:** ein Spieler waehlt zwischen **Klassische Neun** (Par 18), **Pfeil-Armageddon** (Par 27), dem **Referenzkurs** (Par 18), **Labyrinth-Neun** (Par 50) und dem **Prototypkurs** (Par 38).
- **Lokaler Mehrspieler:** zwei bis vier Spieler waehlen ebenfalls einen Kurs, beenden jeweils ein ganzes Loch und reichen danach den Controller weiter.
- **Uebung:** ein frei gewaehltes Loch mit schnellem Neustart; Dreieck/F2 behaelt den Zugriff auf alle technischen Testbahnen.
- **Freies Spiel:** ein bis vier Spieler bauen eine eigene Folge aus bis zu neun echten Loechern; Wiederholungen sind erlaubt.

Spieler geben ueber eine controllerfreundliche Bildschirmtastatur Namen mit bis zu zwoelf Zeichen ein und erhalten eine eindeutige kosmetische Farbe. Nach jedem Loch erscheint die gemeinsame Tabelle. Das Schlagmaximum betraegt mindestens 8 und steigt bei langen Bahnen auf `PAR + 3`; ein nicht eingelochtes Maximalergebnis wird mit `*` markiert. Nur vollstaendige offizielle Kursrunden koennen den jeweiligen lokalen Bestwert in `user://progress.cfg` verbessern. Uebung und freies Spiel zeigen die einunddreissig echten Bahnen auf controllerfreundlichen Seiten mit je fuenf Eintraegen.

## Controller

Der angeschlossene Controller `054C:0268` wird unter Windows 10 von Godot/SDL als `PS3 Controller` erkannt. F3 zeigt Name, GUID, Achsen und gedrueckte Tasten. Falls die Belegung nicht stimmt, startet F4 die lokale Kalibrierung; das Ergebnis landet in `user://controller_mappings.cfg`.

Wenn SDL das Geraet auf einem anderen Rechner gar nicht erkennt, ist Steam Input der vorgesehene Fallback. Es werden keine zusaetzlichen Systemtreiber benoetigt.

## Tests

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```

Die Headless-Suite prueft Schusszustaende samt verzoegertem Kontakt und Abbruch, Genauigkeitsfehler, Reibung, alle acht Gefaellerichtungen, atomare 16-Pixel-Pfeilzellen mit drei Steigungsstufen sowie abgestufter Bergab-Beschleunigung und Bergauf-Bremsung, alle zwoelf atomaren Wandbausteine einschliesslich vier T-Stuecken, das gemeinsame Wandnetz fuer Innen- und Aussenwaende, lueckenlose Anschluesse diagonaler Innenwaende, verborgene paarweise Tunnelloecher mit Geschwindigkeits- und Richtungserhalt, um 90 Grad gedrehte Hindernisse, gemischte gerade und diagonale Aussenkonturen, die Symmetrieachsen und Proportionen der neun Referenzbahnen, das sichere Ausrollen nach wiederholtem Gefaelle-Wandkontakt, freie Bahnkonturen, aus Normwand-Kaestchen erzeugte Aussenbanden, Rechteck-, Kreis- und Kreisbogenkollisionen, Dreher- und Torimpuls, die gewichtsgesteuerte Wippenneigung samt Vorzugsstellung, perspektivisch eindeutiger Hoehendarstellung, dynamischer Sperrkante, mitkippenden Seitenbanden und ausschliesslichem Einstieg ueber die abgesenkte Vorderseite, die um 90 Grad gedrehte und beidseitig an Normwaende angeschlossene Labyrinth-Wippe, Triggerverkettung, verriegelte Kanonen und reproduzierbaren Bogenflug. Fuer die Klassischen Neun werden neun eigene geschlossene Silhouetten, exakt acht Kreisbumper, sieben Kreisboegen, drei flache atomare Pfeilfelder sowie sichere PAR- und riskante Abkuerzungsrouten geprueft. Fuer Pfeil-Armageddon werden zusaetzlich neun unterschiedliche Normwandkonturen, 761 reine Gefaellezellen, unvermeidbare Kernfelder, alle acht Richtungen, die exakte Sand- und Wasserverteilung, die mit L- und T-Stuecken geschlossene Pfeilspirale, ihr verborgenes Tunnelpaar, schwacher und starker Gegenstrom sowie neun PAR-Routen geprueft. Weitere Tests decken Wasser-Ruecksetzung, Lochgeschwindigkeit, Bahn- und Kurskatalog, kuratierte technische Kursbahnen, paginierte Auswahl, Spieler- und Rundendaten, Hotseat-Wechsel, das dynamische Schlaglimit `max(8, PAR + 3)`, Neun-Loch-Tabelle, kursweise revisionierte Bestwerte sowie Kamera-, Audio-, Effekt-, Eingabe- und Fokusverhalten ab.

Hardware-Erkennung des angeschlossenen PS3-Controllers pruefen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/controller_probe.tscn
```

## Prototypumfang

- der vollstaendig neu aufgebaute Kurs **Klassische Neun** mit drei Par-1-, drei Par-2- und drei Par-3-Bahnen, Gesamt-Par 18, neun eigenen geschlossenen Normwand-Silhouetten, acht Kreisbumpern, sieben angeschlossenen Kreisboegen und drei kleinen flachen Pfeilfeldern; Loch 1 bis 3 besitzen reproduzierbare Ein-Schlag-Linien, Loch 4 bis 9 sichere PAR-Routen und schwierigere Abkuerzungen
- der vollstaendig neu aufgebaute Kurs **Pfeil-Armageddon** mit je drei Par-2-, Par-3- und Par-4-Bahnen, Gesamt-Par 27, fuenf kompakten und vier horizontal scrollenden Pfeilpuzzles; alle neun besitzen eine eigene Normwandkontur und ein unvermeidbares Pfeil-Kernfeld
- der sichtbare **Referenzkurs** mit neun Konturbahnen und Gesamt-Par 18
- der Kurs **Labyrinth-Neun** mit neun langen Irrgaerten, Gesamt-Par 50, 26 in Zwangspassagen eingebundenen Rotoren, Schiebetoren und Wippen sowie zwei Bahnen mit diagonalen Normwaenden
- der neunloecherige **Prototypkurs** mit **S-Kurve an der Muehle**, **Die Diamantenlinie**, **Das Doppeltor**, **Die Kanonenwerkstatt** und den fuenf fuer diesen Kurs kuratierten technischen Testbahnen, Gesamt-Par 38
- vierzehn technische Bahnen: Allround-Testloch, Acht-Richtungs-Labor, U-Flussbahn, Scroll-Testbahn, **Kurven-Labor** sowie **Referenz: Tor-Gerade**, **Basis 1: Dreifach-Bumper**, **Basis 1: Rotor**, **Basis 1: Schiebetor**, **Basis 1: Wippe**, **Basis 1: Huegelpass**, **Referenz: Winkel**, **Referenz: MOS-Kurve** und **Basis 1: Huegelloch**; Dreieck/F2 wechselt in der Uebung zyklisch durch alle 45 Bahnen
- typisierte `.tres`-Bahndaten fuer freie Bahnkonturen, bei den klassischen, Referenz-, Labyrinth- und Pfeil-Armageddon-Bahnen aus 4-Pixel-Normwaenden erzeugte Aussenkonturen und gerade beziehungsweise diagonale Innenwaende samt L- und T-Anschluessen, atomare achsenparallele 16-x-16-Pixel-Pfeilzellen, zwoelf normierte Wandbausteine im 16-Pixel-Raster, unmarkierte paarweise Tunnelloecher, rechteckige Legacy-Banden fuer aeltere Testbahnen, runde Bumper, Kreisbogenwaende, freie Flaechen, Hindernisse, Trigger, Kanonen, Kamera und Lochregeln; ein gemeinsamer Runtime-Builder erzeugt Darstellung und Kollisionen aller Bahnen
- Gruen, Sand, Gefaelle und Wasser; atomare Pfeilflaechen verwenden 30 px/s2 Rollwiderstand und unterscheiden flaches Gefaelle in Dunkelgruen, mittleres in Dunkelblau und steiles in Dunkelrot
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
