# Putt & Pixel - Spielrahmen-Prototyp

Spielbarer Godot-4-Prototyp fuer das controllerorientierte 2D-Minigolfspiel mit acht Themenkursen, 72 regulaeren Bahnen, 14 technischen Referenzen und Laboren, vier Spielmodi, Hotseat und Ergebnistabelle.

Die [Regeln fuer die Bahngestaltung](BAHNGESTALTUNG_REGELN.md) beschreiben den aktuellen Wand- und Pfeilstandard, spielerische Abnahmekriterien und den datierten Bestandscheck und die Kursaktualisierungen einschliesslich offener Design- und Testluecken.

Die acht Welten ersetzen die fuenf bisherigen Kurszusammenstellungen. [Kursplan](KURSPLAN_8_WELTEN.md) und [Umsetzungsbericht](ACHT_WELTEN_UMSETZUNG.md) dokumentieren Bahnideen, Herkunft, Bauplaene und Pruefstand.

| Kurs | PAR | Schwerpunkt |
| --- | ---: | --- |
| Stadtpark | 23 | Zielen, roter Pavillon-Kreis und Gartenspirale |
| Duenenkueste | 26 | Sand, Wasser und Dosierung |
| Muehlental | 28 | Rotoren, Schleusen und Wippen |
| Bergpass | 22 | Gefaelle und Kuppen |
| Schlossgarten | 35 | Wegwahl und geometrische Praezision |
| Uhrwerkfabrik | 27 | Mechanikketten und verborgenes Tunnelzahnrad |
| Tempelruinen | 27 | Tunnel und getrennte Kammern |
| Sternwarte | 32 | Schalter, Kanonen und Landungen |

Jeder Kurs umfasst neun eigene Bahnplaetze und einen neuen Bestwertschluessel. Alte Bestwerte und technische Testbahnen bleiben erhalten. Gemeinsame Themenressourcen steuern Umgebung, Rasen, Banden und Dekoration ohne Einfluss auf die Ballphysik.

## Starten

Der lokal erstellte [Windows-Build mit acht Welten und langsamerem Zahnrad](build/windows/PuttAndPixel-AchtWelten-Zahnrad16s.exe) kann direkt gestartet werden. Export und kurzer Headless-Start wurden mit Godot 4.7.2 erfolgreich geprueft.

Die portable Godot-Version liegt lokal unter `.tools/godot-4.7.2/` und wird nicht versioniert.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --editor --path .
```

Direkt spielen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' --path .
```

## Steuerung

Das Golferfenster zeigt Figur und beide Anzeigen ohne Phasentext, Anzeigenueberschriften oder dauerhafte Steuerungshinweise. Die verlaengerte Kraftskala erlaubt kurze Schlaege ab etwa 1 dm; bis 10 dm besitzt sie einzelne Dezimeterstriche, darueber 10-dm-Striche. Die erwartete Weite gilt fuer ebenes Gruen.

Vier erwachsene Pixelgolfer sind sofort verfuegbar: Ben (Allrounder), Mara, Bruno und Nika. Jeder besitzt einen eigenen Atlas und ein festes Spielprofil. Die Spieleranlage fuehrt vom Namen ueber die Figur zur kosmetischen Farbe; mehrere Spieler duerfen dieselbe Figur waehlen. Fuenf Vergleichsbalken zeigen ihre Staerken und Schwaechen direkt in der Auswahl; ein heller Strich markiert Ben. Details und Werte stehen in [GOLFER.md](GOLFER.md). Ihre Spriteposen zeigen Atmen/Blinzeln, kraftabhaengiges Ausholen, Halten, kontrolliertes Putten, Beobachten, Jubel und Aerger. Vier Spielerfarben faerben nur Polo beziehungsweise Weste um. Abschwung und Kontakt folgen dem Schlagsystem; der Einblendungsball und Perfektglanz starten erst am echten Ballkontakt. Abbruch, Neustart und Spielerwechsel setzen die Darstellung zurueck, Pause friert sie ein. Bildquelle und Aufbereitung sind in [assets/golfer/README.md](assets/golfer/README.md) dokumentiert.

`godot --path . res://tests/capture_golfer.tscn` rendert alle Posen, Spielerfarben und Schlagfolgen nach `.godot/golfer/`. `tests/golfer_animation_test.gd` prueft die Verbindung zum echten Schlagsystem einschliesslich des sichtbaren Kontaktframes.

Brunos maximale Richtungsabweichung betraegt 10 Grad. Die Themenkurse verwenden Bestwertrevision 1; Stadtpark verwendet nach den Bahnkorrekturen einschliesslich der Parkbank-Diagonalen Revision 3, Muehlental nach dem zweiten Rotor auf Bahn 1 ebenfalls Revision 3, Uhrwerkfabrik nach der Zahnrad-Tempoanpassung ebenfalls Revision 3, Tempelruinen nach der Rotor-Korrektur Revision 2. Historisch galten nach dem Figurenbalancing: Klassische Neun 10, Pfeil-Armageddon 8, Referenzbahnen 4, Labyrinth-Neun 4 und Prototypkurs 6. Diese alten Bestwerte bleiben gespeichert; die unten beschriebenen Geometrie-Revisionen dokumentieren den vorherigen Bahnstand.

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

Auf grossen Bahnen bewegt das Zielkreuz die Kamera erst am Rand ihres Ruhebereichs. Das haelt besonders das Erkunden mit der Maus ruhig. Beim Rollen und im Kanonenflug folgt die Kamera dem Ball weich und blickt geschwindigkeitsabhaengig bis zu 48 interne Pixel voraus; nur harte Kontakte und der Kanonenabschuss geben einen sehr kleinen Kameraimpuls. Im Uebungsmodus schaltet Dreieck/F2 weiterhin zyklisch durch den gesamten Katalog aus 72 Kurs- und 14 technischen Bahnen.

Die Controllerachsen werden direkt vom aktiven Geraet gelesen. Nach Menue-, Spieler- und Lochwechseln wartet eine Eingabeschranke auf einen neutralen Stick und losgelassene Tasten. Dadurch bleiben Stick und D-Pad aktiv, ohne einen gehaltenen Impuls in den naechsten Bildschirm zu uebertragen.

## Spielmodi und Runde

- **Einzelner Kurs:** ein Spieler waehlt einen der acht Themenkurse auf drei Seiten mit 3/3/2 Eintraegen.
- **Lokaler Mehrspieler:** zwei bis vier Spieler waehlen ebenfalls einen Kurs, beenden jeweils ein ganzes Loch und reichen danach den Controller weiter.
- **Uebung:** ein frei gewaehltes Loch mit schnellem Neustart; Dreieck/F2 behaelt den Zugriff auf alle technischen Testbahnen.
- **Freies Spiel:** ein bis vier Spieler bauen eine eigene Folge aus bis zu neun echten Loechern; Wiederholungen sind erlaubt.

Beim Markieren eines Kurses erscheint rechts eine **3×3-Vorschau aller neun Bahnen** mit Bahnnummer und PAR. Controller, Tastatur und Maus aktualisieren dieselbe Uebersicht; Bestaetigen startet den angezeigten Kurs. Auch lange Bahnen sind vollstaendig abgebildet.

Spieler geben ueber eine controllerfreundliche Bildschirmtastatur Namen mit bis zu zwoelf Zeichen ein und erhalten eine eindeutige kosmetische Farbe. Nach jedem Loch erscheint die gemeinsame Tabelle. Das Schlagmaximum betraegt mindestens 8 und steigt bei langen Bahnen auf `PAR + 3`; ein nicht eingelochtes Maximalergebnis wird mit `*` markiert. Nur vollstaendige offizielle Kursrunden koennen den jeweiligen lokalen Bestwert in `user://progress.cfg` verbessern. Uebung und freies Spiel zeigen die 72 regulaeren Bahnen auf controllerfreundlichen Seiten mit je fuenf Eintraegen.

Die Kursfreigabe wird aus Kurs-ID und exakter vollständiger Lochfolge abgeleitet. Beschädigte Bestwertdateien werden nicht überschrieben; fehlgeschlagenes Speichern wird in der Endtabelle angezeigt. Menüaktionen beachten Eingabesperre, Fokus, Diagnose und Kalibrierung auch bei Mausklicks und verspäteten Signalen alter Bildschirme.

## Controller

Der angeschlossene Controller `054C:0268` wird unter Windows 10 von Godot/SDL als `PS3 Controller` erkannt. F3 zeigt Name, GUID, Achsen und gedrueckte Tasten. Falls die Belegung nicht stimmt, startet F4 die lokale Kalibrierung; das Ergebnis landet in `user://controller_mappings.cfg`.

Scheitert das Speichern einer Kalibrierung, bleibt das neue Profil für diese Sitzung aktiv. Die Diagnose zeigt den Fehler dauerhaft an; eine Erfolgsmeldung erfolgt nur nach erfolgreichem Schreiben. Vorhandene beschädigte Kalibrierdateien bleiben erhalten.

Wenn SDL das Geraet auf einem anderen Rechner gar nicht erkennt, ist Steam Input der vorgesehene Fallback. Es werden keine zusaetzlichen Systemtreiber benoetigt.

## Tests

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```

Die Headless-Suite prueft Schusszustaende samt verzoegertem Kontakt und Abbruch, Genauigkeitsfehler, Reibung, alle acht Gefaellerichtungen, atomare 16-Pixel-Pfeilzellen mit drei Steigungsstufen sowie abgestufter Bergab-Beschleunigung und Bergauf-Bremsung, alle zwoelf atomaren Wandbausteine einschliesslich vier T-Stuecken, das gemeinsame Wandnetz fuer Innen- und Aussenwaende, lueckenlose Anschluesse diagonaler Innenwaende, verborgene paarweise Tunnelloecher mit Geschwindigkeits- und Richtungserhalt, um 90 Grad gedrehte Hindernisse, gemischte gerade und diagonale Aussenkonturen, die Symmetrieachsen und Proportionen der neun Referenzbahnen, das sichere Ausrollen nach wiederholtem Gefaelle-Wandkontakt, freie Bahnkonturen, aus Normwand-Kaestchen erzeugte Aussenbanden, Rechteck-, Kreis- und Kreisbogenkollisionen, Dreher- und Torimpuls, die gewichtsgesteuerte Wippenneigung samt Vorzugsstellung, perspektivisch eindeutiger Hoehendarstellung, dynamischer Sperrkante, mitkippenden Seitenbanden und ausschliesslichem Einstieg ueber die abgesenkte Vorderseite, die um 90 Grad gedrehte und beidseitig an Normwaende angeschlossene Labyrinth-Wippe, Triggerverkettung, verriegelte Kanonen und reproduzierbaren Bogenflug. Fuer die Klassischen Neun werden neun eigene geschlossene Silhouetten, exakt acht Kreisbumper, sieben Kreisboegen, drei flache atomare Pfeilfelder sowie sichere PAR- und riskante Abkuerzungsrouten geprueft. Fuer Pfeil-Armageddon werden zusaetzlich neun unterschiedliche Normwandkonturen, 834 reine Gefaellezellen, kontinuierlich abgesicherte Pflichtquerschnitte, alle acht Richtungen, die exakte Sand- und Wasserverteilung, die mit L- und T-Stuecken geschlossene Pfeilspirale, ihr verborgenes Tunnelpaar, das zur Mitte und in den inneren Reihen diagonal nach links gerichtete rote Wasserfeld, dessen Festhaengeschutz sowie neun PAR-Routen geprueft. Weitere Tests decken Wasser-Ruecksetzung, Lochgeschwindigkeit, Bahn- und Kurskatalog, kuratierte technische Kursbahnen, paginierte Auswahl, Spieler- und Rundendaten, Hotseat-Wechsel, das dynamische Schlaglimit `max(8, PAR + 3)`, Neun-Loch-Tabelle, kursweise revisionierte Bestwerte sowie Kamera-, Audio-, Effekt-, Eingabe- und Fokusverhalten ab.

Der zentrale Testrunner registriert Fachmodule für Ball/Oberflächen, Mechanik, Spielrahmen und Kursgruppen. Gemeinsame Szenen- und Geometrieroutenhilfen liegen in `tests/test_support.gd`; `tests/cleanup_regression_test.gd` prüft Menü- und Speicherfehler mit isolierten Testdateien. Bei den absichtlich beschädigten Testdateien sind zwei `ConfigFile parse error`-Meldungen erwartete Negativfälle; GDScript-Parserfehler sind weiterhin Fehler.

Die Labyrinth-Geometrierouten setzen Hinderniskollisionen teilweise aus. Zusätzlich ist die Diagonalfalle mit aktiven Mechanismen in vier Schlägen innerhalb PAR 5 zweimal reproduziert. Für die übrigen acht Bahnen fehlt nach 54 untersuchten Startvarianten weiterhin ein vollständiger Live-Nachweis. Ergebnisse, genaue Grenzen und der separate Auditor stehen in [LABYRINTH_LIVE_PRUEFUNG.md](LABYRINTH_LIVE_PRUEFUNG.md).

`ScorecardView` zeichnet die Ergebnistabelle, `MenuWidgets` bündelt gemeinsame UI-Bausteine. `GameApp` behält Navigation und Rundenaktionen. `SurfaceSample` verbindet Ball, Oberflächen und dynamische Wippen mit typisierten Physikdaten.

Die Ergebnistabelle begrenzt Kurskopf und Tabellenbeschriftungen auf ihre vorgesehenen Felder und richtet sie vertikal mittig aus. Kursname und Loch-/PAR-Angabe behalten getrennte Bereiche mit Innenabstand; lange Texte werden bei Bedarf mit Auslassungspunkten begrenzt. Die Begriffe `TOTAL` und `E` bleiben erhalten.

Hardware-Erkennung des angeschlossenen PS3-Controllers pruefen:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/controller_probe.tscn
```

Wippen-Regressionsfaelle pruefen ausserdem echten Rueckprall bei 420/520 px/s, beide Fahrtrichtungen, vier rechtwinklige Orientierungen, dosiertes Ueberqueren sowie geschlossene Zwischenstellungen. Live-Physiktests sichern Kippwechsel und Reset gegen einen um einen Frame verspaeteten Kollisionsschluss ab.

## Historischer Prototypumfang vor den acht Welten

Die folgenden Kursnamen, PAR-Werte und Revisionen dokumentieren den abgeloesten Entwicklungsstand. Fuer den aktuellen Spielbestand gelten die Tabelle oben und [ACHT_WELTEN_UMSETZUNG.md](ACHT_WELTEN_UMSETZUNG.md). Geometrie-Regressionsfaelle dieses Standes liegen getrennt unter `tests/fixtures/legacy/` und werden nicht exportiert.

Der **Prototypkurs** verwendet Bestwertrevision 3 (`prototype_course_03_v3`) und neun echte Kursbahnen mit PAR `4/3/4/3/3/3/5/4/4` (33). Fuenf eigenstaendige Kursfassungen ersetzen die Labore in der gewerteten Runde; die urspruenglichen Labore bleiben ueber F2 in der Uebung erhalten. Normkonturen, wandbuendige reine Pfeilfelder und zwei echte Konturboegen bringen die Bahnen auf den aktuellen Stand. Dezente Rasenstreifen und Pflanzbeete verbinden alle neun Bahnen optisch. Die Endtabelle zeigt Kursdaten, farbige PAR-Wertungen, nach Ergebnis sortierte Spieler und eine Solo-Auswertung. Details und reproduzierbare Aufnahmen stehen in [PROTOTYPKURS.md](PROTOTYPKURS.md).


**Pfeil-Armageddon** verwendet nach der Wegepruefung Bestwertrevision 5 (`arrow_armageddon_course_v5`). Alle neun Bahnen haben wandbuendige Pflichtpassagen; beim Gegenstrom ist die Wasserumgehung geschlossen. Die Schlussbahn fuehrt durch acht Pfeilabschnitte statt um ungenutzte Pfeilinseln. PAR27, Start-/Lochpositionen und reine Gefaellephysik bleiben erhalten. `tests/capture_arrow_harmony.gd` erzeugt die Gesamtansichten nach `.godot/arrow-harmony/`.

Die **Klassischen Neun** verwenden inzwischen Bestwertrevision 7 (`classic_nine_course_v7`). Die PAR-Folge bleibt unveraendert. Gemeinsame Gehrungen beseitigen Wandnaehte; echte Konturboegen ersetzen doppelte Rahmen bei Bogenschuss, Hufeisen, Engstelle und Heimkehr. Kreisallee besitzt freigestellte Pfeile und einen gleichmaessigen Zielkanal. Dauerhafte Bahn-, Spieler- und Rundeninfos stehen in der Seitenleiste statt ueber dem Spielfeld.

Zusaetzliche Tests sichern gebogene Konturen samt Ankern, gemeinsame sichtbare und physische Wandkanten, legale Schlagstaerken sowie kleine Routenabweichungen. `godot --path . --script res://tests/capture_classic_harmony.gd` rendert alle neun Gesamtansichten nach `.godot/classic-harmony/`; `tests/capture_classic_nine.tscn` prueft die Spielansichten und Kameraenden.

- der vollstaendig neu aufgebaute Kurs **Klassische Neun** mit der Par-Folge `1/2/2/1/1/2/3/3/4`, Gesamt-Par 19, neun eigenen geschlossenen Normwand-Silhouetten, acht Kreisbumpern, sieben angeschlossenen Kreisboegen und drei kleinen flachen Pfeilfeldern; alle neun Bahnen besitzen reproduzierbare PAR-Routen
- der vollstaendig neu aufgebaute Kurs **Pfeil-Armageddon** mit je drei Par-2-, Par-3- und Par-4-Bahnen, Gesamt-Par 27, fuenf kompakten und vier horizontal scrollenden Pfeilpuzzles; alle neun besitzen eine eigene Normwandkontur und ein unvermeidbares Pfeil-Kernfeld
- der sichtbare **Referenzkurs** mit neun Konturbahnen und Gesamt-Par 18
- der Kurs **Labyrinth-Neun** mit neun langen Irrgaerten, Gesamt-Par 50, 26 in Zwangspassagen eingebundenen Rotoren, Schiebetoren und Wippen sowie zwei Bahnen mit diagonalen Normwaenden
- der neunloecherige **Prototypkurs** mit **S-Kurve an der Muehle**, **Die Diamantenlinie**, **Das Doppeltor**, **Die Kanonenwerkstatt** sowie **Sandufer**, **Doppelhuegel**, **Uferkehre**, **Panoramaweg** und **Bogenpromenade**, Gesamt-Par 33
- vierzehn technische Bahnen: Allround-Testloch, Acht-Richtungs-Labor, U-Flussbahn, Scroll-Testbahn, **Kurven-Labor** sowie **Referenz: Tor-Gerade**, **Basis 1: Dreifach-Bumper**, **Basis 1: Rotor**, **Basis 1: Schiebetor**, **Basis 1: Wippe**, **Basis 1: Huegelpass**, **Referenz: Winkel**, **Referenz: MOS-Kurve** und **Basis 1: Huegelloch**; Dreieck/F2 wechselt in der Uebung zyklisch durch alle 50 Bahnen
- typisierte `.tres`-Bahndaten fuer freie Bahnkonturen, bei den klassischen, Referenz-, Labyrinth- und Pfeil-Armageddon-Bahnen aus 4-Pixel-Normwaenden erzeugte Aussenkonturen und gerade beziehungsweise diagonale Innenwaende samt L- und T-Anschluessen, atomare achsenparallele 16-x-16-Pixel-Pfeilzellen, zwoelf normierte Wandbausteine im 16-Pixel-Raster, unmarkierte paarweise Tunnelloecher, rechteckige Legacy-Banden fuer aeltere Testbahnen, runde Bumper, Kreisbogenwaende, freie Flaechen, Hindernisse, Trigger, Kanonen, Kamera und Lochregeln; ein gemeinsamer Runtime-Builder erzeugt Darstellung und Kollisionen aller Bahnen
- Gruen, Sand, Gefaelle und Wasser; atomare Pfeilflaechen verwenden 30 px/s2 Rollwiderstand und unterscheiden flaches Gefaelle in Dunkelgruen, mittleres in Dunkelblau und steiles in Dunkelrot
- gerade und gedrehte Banden, massive Kreis-Bumper, dicke Kreisbogenwaende, rotierende Hindernisse, zwei deterministische Schiebetore sowie zwei automatisch ausloesende Kanonen mit sichtbarem Bogenflug
- reproduzierbare Ballphysik mit festen Physikschritten
- vier animierte Pixelgolfer mit eigenen Spielprofilen und getrennten Posen fuer Zielen, Timing, Abschwung, Beobachten, Wasser, Erfolg und perfekte Treffer
- Schlagzahl, Dezimeter-Entfernung, vertikale Kraft-/Weitenskala, eingerahmte Genauigkeitsanzeige und Ergebnisanzeige
- prozedurale Retro-Sounds fuer Schlagphasen, Treffer, Bande, Windmuehle, Tor, Schalter, Kanone, Wasser und Loch sowie materialabhaengiges Rollfeedback
- kurze codebasierte Splitter-, Staub-, Wasser-, Loch- und Perfekt-Effekte ohne Einfluss auf die Physik
- Controller-, Tastatur- und Mausbedienung
- persistenter Titel- und Menuefluss mit vier vollstaendig spielbaren Modi
- ein bis vier lokale Spieler mit Namen, Farbvariante und Controller-Uebergabe
- Loch- und Endtabellen, gemeinsamer Rang bei Gleichstand und lokaler Kursbestwert
- dynamisches Schlagmaximum `max(8, PAR + 3)`

Weiterhin offen sind Turniersieg-Reaktionen, finale Pixel-Art, Musik, Einstellungen, Speichern laufender Runden und Bahneditor. Die acht Themenkurse sind als spielbare Kursfassung umgesetzt; menschliche Langzeit- und Controller-Spieltests bleiben Teil des weiteren Balancings.
