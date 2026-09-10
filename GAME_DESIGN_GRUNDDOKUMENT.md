# Game-Design-Grunddokument

## Putt & Pixel (vorlaeufiger Arbeitstitel)

**Dokumentversion:** 0.4
**Stand:** 6. September 2026
**Engine:** Godot 4.7.2 Standard, GDScript, Compatibility-Renderer  
**Darstellung:** reine 2D-Pixel-Art  
**Primaere Plattform:** Windows-PC  
**Primaere Eingabe:** Controller/Joystick  

> Dieses Dokument beschreibt die verbindliche kreative und spielerische Grundlage. Angaben, die noch getestet oder entschieden werden muessen, sind ausdruecklich als vorlaeufig oder offen gekennzeichnet.

---

## 1. Vision

Ein eigenstaendiges, leicht zugaengliches und langfristig anspruchsvolles 2D-Minigolfspiel im Stil klassischer Heimcomputer-Spiele. Das Spiel verbindet ein praezises, mehrstufiges Schlagsystem mit ausdrucksstarken animierten Golferfiguren, abwechslungsreichen mechanischen Bahnen und einer deutlich groesseren Auswahl eigener Loecher.

Das Spiel soll sich retro anfuehlen, ohne wie eine technische Beschraenkung aus den 1980er-Jahren zu wirken. Die Grafik nutzt bewusst sichtbare Pixel, arbeitet aber mit hoeherer Aufloesung, fluessigen Animationen, klarer Lesbarkeit und moderner Bedienbarkeit.

### Kurzbeschreibung

> Zielen, Kraft bestimmen, Genauigkeit treffen und den vorbereiteten Schlag im richtigen Moment ausloesen. Unterschiedliche Golfer, bewegliche Hindernisse und viele kompakte Bahnen sorgen dafuer, dass die einfache Grundidee immer wieder neue Entscheidungen erzeugt.

---

## 2. Eigenstaendigkeit und Abgrenzung

Das Projekt wird kein originalgetreues Remake und keine Neuveroeffentlichung eines bestehenden Spiels.

### Wir uebernehmen als Inspiration

- ein leicht verstaendliches, timingbasiertes Schlagsystem
- einen sichtbar animierten Golfer in einer Bildschirmecke
- kompakte, auf einen Blick lesbare Minigolfbahnen
- lokale Mehrspielerpartien an einem Geraet
- die Mischung aus praezisem Golf und verspielten Hindernissen

### Wir entwickeln eigenstaendig

- Spielname und Logo
- Figuren, Namen und Persoenlichkeiten
- Grafik, Benutzeroberflaeche und Animationen
- Musik und Soundeffekte
- alle Bahnen und Themenwelten
- konkrete Regeln, Werte und Spielmodi
- Hindernisdesigns und visuelle Inszenierung

Namen, Figuren, Grafiken, Musik und exakte Bahnlayouts bestehender Spiele werden nicht uebernommen. Referenzmaterial dient nur zur Analyse von Spielgefuehl und Designprinzipien.

---

## 3. Zielgruppe und Spielerlebnis

### Zielgruppe

- Spielerinnen und Spieler mit Interesse an Retro- und Pixel-Art-Spielen
- Freunde lokaler Mehrspielerpartien
- Gelegenheitsspieler, die sofort beginnen moechten
- erfahrene Spieler, die Bestwerte und praezise Schlaege meistern wollen
- Familien und kleine Gruppen, sofern Schwierigkeits- und Hilfsoptionen aktiviert werden

### Gewuenschtes Gefuehl

- innerhalb weniger Sekunden verstanden
- ruhig und kontrolliert statt hektisch
- jeder Fehlschlag ist nachvollziehbar
- gute Schlaege fuehlen sich verdient an
- bewegliche Hindernisse erzeugen Spannung beim Warten auf den richtigen Moment
- die Golferfiguren geben dem Spiel Waerme, Humor und Wiedererkennungswert
- lokale Partien erzeugen freundlichen Wettbewerb und gemeinsames Mitfiebern

---

## 4. Designsaeulen

### 4.1 Praezision statt Zufall

Der Ball folgt klaren, erlernbaren Regeln. Abweichungen entstehen durch die Eingabe des Spielers und erkennbare Bahneffekte, nicht durch versteckte Zufallswerte.

### 4.2 Persoenlichkeit in jeder Aktion

Die sichtbare Golferfigur reagiert auf Zielen, Warten, gute Schlaege, Fehler, Wasser, knappe Situationen und Ergebnisse. Sie ist ein zentraler Teil des Spielerlebnisses und kein dekoratives Extra.

### 4.3 Auf einen Blick verstaendliche Bahnen

Eine Bahn soll ihre wichtigste Idee schnell vermitteln. Der Spieler soll eine moegliche Linie erkennen koennen, ohne Menues oder Statistiken studieren zu muessen.

### 4.4 Wenige Regeln, viele Kombinationen

Wiederverwendbare Flaechen, Bewegungen, Hindernisse und Trigger werden zu vielen unterschiedlichen Bahnen kombiniert. Neue Inhalte sollen vor allem Leveldesign und nicht staendig neue Programmierung erfordern.

### 4.5 Gemeinsam auf dem Sofa

Lokaler Mehrspieler ist ein Kernmodus. Runden muessen zuegig ablaufen, Eingaben klar zugeordnet und Zwischenstaende jederzeit verstaendlich sein.

---

## 5. Kernspielschleife

1. Bahn ueberblicken und Hindernisse beobachten.
2. Zielpunkt mit Stick, D-Pad, Maus oder Tastatur bestimmen.
3. Kraftanzeige starten und Schlagstaerke festlegen.
4. Genauigkeitsanzeige beobachten und Abweichung festlegen.
5. Schlag vorbereitet halten und auf den richtigen Moment warten.
6. Taste loslassen und Ball spielen.
7. Ballbewegung, Kollisionen und Reaktion der Figur beobachten.
8. Vom neuen Ballstand weiterspielen oder Bahn abschliessen.
9. Schlagzahl, Par und persoenliche Bestleistung vergleichen.

---

## 6. Schlagsystem

Das Schlagsystem ist das Herz des Spiels. Es muss mit einer Aktionstaste bedienbar sein und auf dem Controller am natuerlichsten wirken.

### 6.1 Ablauf mit Controller

1. **Zielen:** Linker Stick oder D-Pad bewegt das Zielkreuz.
2. **Kraft starten:** Ein Druck auf die Aktionstaste startet den Kraftbalken.
3. **Kraft fixieren:** Ein zweiter Druck fixiert die Kraft und startet die Genauigkeitsanzeige.
4. **Genauigkeit fixieren:** Ein dritter Druck wird gehalten und fixiert die Genauigkeit. Die Figur bereitet den Schlag vor.
5. **Abschwung starten:** Das Loslassen der gehaltenen Taste startet die sichtbare Schlagbewegung.
6. **Kontakt:** Nach exakt 0,10 Sekunden treffen Schlaeger, Trefferton und Ball gleichzeitig aufeinander. Erst jetzt wird der Schlag gezaehlt und der Ball bewegt.

Dadurch kann ein fertiger Schlag vor einer Windmuehle, einem Tor oder einem Pendel bewusst zurueckgehalten werden.

### 6.2 Abbrechen

Eine separate Abbruchtaste beendet die Schlagvorbereitung, solange der Ball noch nicht gespielt wurde. Das gilt auch fuer die 0,10 Sekunden zwischen Loslassen und Kontakt. Fokusverlust, Controllertrennung oder Bahnwechsel brechen diesen Abschwung ebenfalls ohne Schlag und ohne Strafe ab.

### 6.3 Genauigkeit

- Ein perfekter Treffer erzeugt keine Winkelabweichung.
- Zu fruehes Fixieren lenkt den Ball in eine Richtung ab.
- Zu spaetes Fixieren lenkt ihn in die Gegenrichtung ab.
- Die Staerke der Abweichung ist visuell vorhersehbar.
- Figuren duerfen unterschiedliche Timingprofile besitzen, aber keine versteckten Zufallsfehler.

### 6.4 Noch zu testen

- Aktueller Prototyp-Ausgangspunkt: Kraftzyklus 4,0 Sekunden, Genauigkeitszyklus 2,4 Sekunden. Beide Anzeigen laufen damit halb so schnell wie im ersten Prototypstand.
- linearer oder hin- und herlaufender Kraftbalken
- Feintuning der nun verlangsamten Anzeigen
- Groesse des perfekten Genauigkeitsfensters
- maximale Winkelabweichung
- ob der dritte Tastendruck sofort gehalten werden muss oder ein eigener Status vor dem Halten sinnvoller ist

Diese Werte werden im spielbaren Prototyp festgelegt und nicht allein auf dem Papier entschieden.

---

## 7. Eingabekonzept

Alle Menues und Spielsituationen muessen vollstaendig mit Controller, Tastatur und Maus bedienbar sein.

| Funktion | Controller | Tastatur | Maus |
|---|---|---|---|
| Zielpunkt bewegen | linker Stick / D-Pad | WASD / Pfeiltasten | Maus bewegen |
| Schlag steuern | untere Aktionstaste | Leertaste / Enter | linke Maustaste |
| Abbrechen / zurueck | rechte Aktionstaste | Escape | rechte Maustaste |
| Kamera bewegen | rechter Stick | zusaetzliche Richtungstasten | Mitteltaste / Bildschirmrand |
| Ansicht zentrieren | Schulter- oder Sticktaste | definierbare Taste | mittlere Maustaste |
| Pause | Start / Menu | Escape | Pause-Schaltflaeche |

### Eingabeprinzipien

- Controller ist die Referenz fuer Bedienfluss und Menuefokus.
- D-Pad ermoeglicht feinere Zielkorrekturen als der Analogstick.
- Tastenbelegung ist frei konfigurierbar.
- Beim Wechsel des Eingabegeraets aktualisieren sich Hilfesymbole automatisch.
- Im lokalen Mehrspieler kann wahlweise ein Controller weitergereicht oder je Spieler ein eigenes Geraet verwendet werden.
- Der Begriff "Joystick" bezeichnet im Design primaer modernen Controllerstick und D-Pad; Unterstuetzung klassischer USB-Joysticks wird technisch geprueft.

---

## 8. Ballphysik und Bahnregeln

Die Physik ist eine kontrollierte 2D-Simulation. Realismus ist weniger wichtig als Lesbarkeit, Konsistenz und ein gutes Gefuehl.

### Kernwerte des Balls

- Position
- Bewegungsrichtung
- Geschwindigkeit
- Radius
- aktueller Untergrund
- Status, zum Beispiel spielbar, in Bewegung, im Wasser oder im Hindernis

### Grundregeln

- Der Ball wird als Kreis behandelt.
- Banden reflektieren den Bewegungsvektor nachvollziehbar.
- Ein kraeftiger erster Bandentreffer auf einem Gefaelle prallt normal ab. Trifft der Ball dieselbe Begrenzung nach dem Ruecklauf erneut mit geringer bis mittlerer Geschwindigkeit, wird nur noch seine Bewegung in die Wand entfernt; dadurch kann er an der tiefsten Stelle zur Ruhe kommen, statt zwischen Gefaelle und Wand endlos zu pendeln.
- Bewegliche Hindernisse uebertragen ihre Geschwindigkeit am Kontaktpunkt auf den Ball und koennen auch einen ruhenden Ball wieder in Bewegung setzen.
- Reibung reduziert die Geschwindigkeit kontinuierlich.
- Gefaelle erzeugt eine konstante Kraft in die sichtbare Pfeilrichtung. Der normale Prototypwert wurde auf 90 Pixel pro Quadratsekunde verdoppelt. Unterstuetzt werden oben, unten, links, rechts und alle vier Diagonalen; diagonale Kraefte werden normalisiert und sind daher nicht staerker.
- Ein eigenes Gefaelle-Labor ordnet alle acht Richtungen um einen zentralen Abschlag an und ist im Prototyp per Dreieck beziehungsweise F2 erreichbar.
- Eine zusaetzliche U-Flussbahn kombiniert fuenf Gefaellesegmente mit Leitbanden, Mindesttempo und sanfter Richtungsausrichtung. Gegenlaeufige Schlaege werden nicht ueberschrieben und hohe Einfahrtgeschwindigkeiten nur allmaehlich reguliert. Ein passend in die Bahn gespielter Ball rollt weiterhin selbsttaetig bis zum Ausgang.
- Eine vierte, 1088 x 688 Pixel grosse Scroll-Testbahn prueft horizontale und vertikale Kamerafahrten. Beim Zielen folgt die Kamera dem Zielkreuz; nach dem Schlag folgt sie automatisch dem Ball. Sie bleibt an den Bahnraendern stehen und laesst HUD sowie Golferfenster unbewegt.
- Die feste linke HUD-Kante besitzt eine eigene 8-Pixel-Rahmenleiste. Am maximalen Scrollrand werden rechte und untere Aussenwand jeweils vollstaendig bis zur aeusseren Kante gezeigt.
- Controllerachsen werden direkt und geraetegebunden gelesen. Jeder Bahnwechsel setzt das Schlagsystem auf Zielen zurueck; eine kurze Eingabesperre verhindert versehentliche doppelte Wechsel durch denselben Tastendruck.
- Der Ball gilt erst nach 0,25 Sekunden unter 3 Pixeln pro Sekunde als ruhend; Kontakte mit beweglichen Hindernissen setzen diese Ruhepruefung sofort zurueck.
- Bewegliche Hindernisse uebertragen ihre Oberflaechengeschwindigkeit relativ zur Ballbewegung und geben bei einem gueltigen Kontakt einen sichtbaren Mindestimpuls weiter.
- Das Loch akzeptiert den Ball bei eindeutigem Eintritt bis zu einer Geschwindigkeit von 120 Pixeln pro Sekunde, damit auch etwas schnellere Baelle sichtbar hineinplumpsen.
- Physikwerte sind unabhaengig von der Bildrate.
- Gleiche Ausgangswerte sollen dasselbe Ergebnis erzeugen.

### Flaechentypen fuer Version 1

- normales Gruen
- Rough oder Sand mit hoher Reibung
- Eis oder glatte Flaeche mit niedriger Reibung
- Gefaellezone
- Wasser mit Strafschlag und Ruecksetzen
- Aus-Zone
- Foerderband oder Stroemung

---

## 9. Golferfiguren

Vier Golfer bieten unterschiedliche Spielweisen, ohne Fortschrittsboni oder bessere Ausruestung zu benoetigen. Allrounder, Mara (ruhig), Bruno (kraftvoll) und Nika (technisch) sind als animierte Pixelgolfer umgesetzt; feste Startwerte und Pruefstand stehen in `GOLFER.md`.

| Rolle | Maximale Weite auf ebenem Gruen | Kraft-Timing | Genauigkeitsprofil | Spielgefuehl |
|---|---:|---|---|---|
| Allrounder | 100 % Reichweite | 4,0 s | 2,4-s-Zyklus, Perfektfenster +/-0,05, maximal 8 Grad | verlaessliche Referenzfigur |
| Mara | 85 % Reichweite | 5,2 s | normal, gut dosierbare Kraft | stark auf kurzen technischen Bahnen |
| Bruno | 125 % Reichweite | 3,2 s | normal | hohe Reichweite, schwerer zu dosieren |
| Nika | 95 % Reichweite | 4,0 s | 1,8-s-Zyklus, halbes Perfektfenster, halbe Fehlerwirkung | reaktionssicheres Timing belohnt Richtungstreue |

### Verbindliche Regeln fuer Figurenunterschiede

- Keine Figur ist eine freischaltbare Verbesserung einer anderen.
- Keine Bahn darf mit einer Figur grundsaetzlich unspielbar sein.
- Unterschiedliche optimale Wege sind erwuenscht.
- Werte werden im Prototyp getestet und spaeter exakt festgelegt.
- Jede Figur erhaelt eigene Animationen und eine erkennbare Persoenlichkeit.
- Kosmetische Varianten duerfen keine Spielwerte veraendern.
- Im Golferfenster blickt die Figur beim Ansprechen frontal zum Spieler. Der Ball liegt mittig vor ihren Fuessen. Der Schlaeger holt links aus, trifft den Ball in der Mitte und schwingt nach rechts zur direkt angrenzenden Bahn durch; der Einblendungsball verlaesst das Fenster ebenfalls nach rechts.

### Benoetigte Animationsgruppen

Aktueller Allrounder: Ein zusammengehoeriger Pixelatlas ersetzt die Linienfigur in einem 88 x 144 Pixel grossen Fenster links neben der Kraftskala. Spriteposen decken Ruhe, Blinzeln, Atmen, drei Ausholweiten, Kontakt, drei Durchschwungweiten, Beobachten, Jubel und Aerger ab. Die Kraft bestimmt das Ausholen, Genauigkeit und Bereithalten frieren es ein. Der Abschwung liest den Fortschritt des Schlagsystems; Kontaktpose, Einblendungsball und Perfektglanz starten erst bei dessen Ballkontakt. Mindestens ein Renderframe zeigt die Kontaktpose. Vier kosmetische Polofarben erhalten Haut, Hose, Schuhe und Putter. Pause, Abbruch und Neustart sind angebunden. Mara, Bruno und Nika verwenden dieselbe Animationssteuerung mit eigenen Atlanten und Profilen. Die gemeinsame Kurswertung beginnt wegen der neuen Spielprofile mit neuen Revisionen; alte Rekorde bleiben gespeichert. Differenzierte Turnierreaktionen bleiben eine spaetere Erweiterung.

- Idle
- Zielen
- Kraft aufbauen
- Genauigkeit konzentrieren
- Schlag vorbereitet halten
- Schlag ausfuehren
- Ball beobachten
- perfekter Schlag
- knapper Fehlschlag
- Wasser oder Aus
- Loch geschafft
- Unter Par, Par und ueber Par
- Runden- oder Turniersieg

---

## 10. Bahndesign

### Bahnklassen

1. **Golfbahnen:** Geometrie, Banden, Winkel, Kraft, Gefaelle und Untergrund stehen im Mittelpunkt.
2. **Mechanische Bahnen:** Tore, Windmuehlen, Pendel, Bruecken und bewegliche Plattformen ergaenzen das Timing.
3. **Abenteuerbahnen:** Kanonen, Roehren, Schalter, Aufzuege oder kleine Ballmaschinen erzeugen besondere Ablaufe.

Ein Kurs darf alle drei Klassen mischen oder ein klares Thema verfolgen.

### Grundsaetze fuer jedes Loch

Die konkreten Gestaltungs- und Abnahmeregeln stehen in [BAHNGESTALTUNG_REGELN.md](BAHNGESTALTUNG_REGELN.md). Der dortige Bestandscheck vom 08.09.2026 umfasst alle 45 Bahnen und unterscheidet Datenvalidierung, Idealrouten und noch offene Spielpruefungen. Historische Kursbeschreibungen und bestandene Einzeltests sind keine pauschale Designfreigabe.

- eine schnell erkennbare Hauptidee
- mindestens ein plausibler Weg zum Loch
- klare visuelle Trennung von Spielflaeche und Dekoration
- keine versteckten Sofortstrafen ohne Vorwarnung
- kurze Wartezeiten zwischen Schlaegen
- faire Startposition nach Wasser oder Aus
- mit allen vier Golfern erreichbar
- fuer geuebte Spieler Raum fuer Abkuerzungen oder riskante Linien

### Bahn-Baukasten V1

- Gruenflaeche
- Bande
- Gefaelle
- Rough/Sand
- Eis/glatte Flaeche
- Wasser
- Loch
- Rampe
- Bruecke
- Tor
- Windmuehle
- Pendel
- beweglicher Block
- Foerderband/Stroemung
- Teleporter oder Roehre
- Kanone
- Schalter
- Trigger
- bewegliche Plattform
- definierter Ruecksetzpunkt

### Bewegungsmodule

- Rotation
- Pendelbewegung
- Bewegung zwischen zwei Punkten
- Kreisbahn
- Auf und zu
- Ein und aus
- zeitgesteuerte Zustandsfolge

### Triggerprinzip

Trigger verbinden Ereignis und Aktion, zum Beispiel:

> Ball beruehrt Schalter -> Tor oeffnet -> Bruecke faehrt aus -> Windmuehle wird langsamer.

Bahnlogik und Dekoration bleiben getrennt. Dieselbe mechanische Bahn kann dadurch in unterschiedlichen Themenwelten anders aussehen.

Der erste Bahn-Baukasten ist als typisiertes Godot-Resource-Modell umgesetzt. `HoleDefinition` verbindet Metadaten, Kameragrenzen, Banden, Flaechen und Hindernisse; ein gemeinsamer Runtime-Builder erzeugt daraus Darstellung und Kollisionen. `WallDefinition` unterstuetzt gerade und gedrehte Rechteckbanden, massive Kreis-Bumper sowie dicke Kreisboegen mit frei waehlbarem Radius, Startwinkel, Bogenlaenge und Segmentzahl. Darstellung und Kollision werden aus derselben Geometrie erzeugt, damit sichtbare und physische Wand uebereinstimmen. Alle bisherigen Flaechenwerte, rotierende Hindernisse, gewichtsgesteuerte Wippen und deterministische Schiebetore werden ebenfalls ohne bahnspezifischen Programmcode beschrieben. Einunddreissig echte Loecher und vierzehn technische Testbahnen verwenden denselben Katalog.

Das technische **Kurven-Labor** isoliert die neue Geometrie in einer festen Bildschirmbahn. Drei runde Bumper und vier verschieden grosse Kreisboegen erlauben Tests von frontalen, streifenden und mehrfachen Abprallern, ohne dass Flaechen oder bewegliche Hindernisse das Ergebnis verfremden.

Schiebetore besitzen Groesse, Oeffnungsweg, Zyklus, Uebergangszeit, Offenhaltezeit und Phasenversatz. Bewegliche Hindernisse melden Kontaktgeschwindigkeit, Normale und Typ ueber eine gemeinsame Schnittstelle. Ein Lochneustart setzt ihre Bewegungsphase zurueck, sodass derselbe zeitlich definierte Ablauf reproduzierbar bleibt.

---

## 11. Umfang und Inhalte

### Langfristiges Ziel fuer Version 1.0

- Ausbau von derzeit 45 Bahnen auf den vorgesehenen Produktionsumfang
- vorlaeufiges Produktionsziel: **6 Kurse mit je 9 Loechern, insgesamt 54 Bahnen**
- vier spielerisch unterschiedliche Golfer
- mehrere klar unterscheidbare Themenwelten
- lokale Partien fuer bis zu vier Personen
- Uebungsmodus fuer einzelne Loecher
- Bestwerte und Kursrekorde

Die Zahl 54 ist ein Planungsziel und wird nach dem Vertical Slice anhand des tatsaechlichen Produktionsaufwands bestaetigt oder angepasst. Qualitaet und Abwechslung haben Vorrang vor einer kuenstlich aufgefuellten Zahl.

### Moegliche Kursstruktur

- zwei ueberwiegend klassische Golfkurse
- zwei mechanische Kurse
- zwei Abenteuer- oder Themenkurse

Konkrete Themen, Namen und Reihenfolge sind noch offen.

---

## 12. Spielmodi

### Verbindlich fuer Version 1.0

- **Einzelner Kurs:** neun Loecher mit Gesamtwertung
- **Uebung:** frei waehlbares einzelnes Loch
- **Lokaler Mehrspieler:** zwei bis vier Spieler spielen nacheinander
- **Freies Spiel:** Figur und verfuegbare Bahn frei waehlen

### Spaeter zu pruefen

- Turnier ueber mehrere Kurse
- taegliche oder feste Herausforderungen ohne Onlinepflicht
- Zeit- oder Trickvarianten
- Zufallskurs aus vorhandenen Loechern
- vom Spieler erstellte Kurse

Online-Multiplayer ist fuer die erste Version nicht vorgesehen.

### Umgesetzter Prototyp-Spielrahmen

- **Einzelner Kurs:** ein Spieler waehlt zwischen **Klassische Neun**, **Pfeil-Armageddon**, dem **Referenzkurs**, **Labyrinth-Neun** und dem neunloecherigen Prototypkurs.
- **Lokaler Mehrspieler:** zwei bis vier Spieler spielen lochweise nacheinander; jeder beendet sein Loch, bevor der Controller weitergereicht wird.
- **Uebung:** ein Spieler waehlt ein einzelnes Loch und darf es sofort neu starten. Die technischen Testbahnen bleiben hier ueber Dreieck/F2 erreichbar.
- **Freies Spiel:** ein bis vier Spieler stellen eine Folge aus einem bis neun echten Loechern zusammen; Reihenfolge und Wiederholungen sind frei.

Der Ablauf ist Titelbild, Moduswahl, Spieleranlage, Kurs- oder Lochauswahl, Partie, Lochtabelle und Endtabelle. Die Kursauswahl wird vollstaendig aus dem Kurskatalog aufgebaut, zeigt drei Kurse pro Seite und speichert getrennte, bei grundlegenden Kursumbauten revisionierbare Bestwerte. Uebung und freies Spiel paginieren die einunddreissig echten Bahnen in Seiten mit je fuenf Eintraegen. Nach jedem Bildschirm-, Spieler- und Lochwechsel muss die Eingabe neutral sein, bevor der naechste Zustand Controllerbefehle annimmt.

---

## 13. Wertung und Fortschritt

### Wertung

- jedes Loch besitzt einen Par-Wert
- angezeigt werden Schlaege am Loch, Differenz zu Par und Kursgesamtwert
- persoenliche Bestwerte werden lokal gespeichert
- Gleichstand im lokalen Mehrspieler bleibt zunaechst ein gemeinsamer Rang
- ein Loch endet spaetestens bei `max(8, PAR + 3)` Schlaegen; ein nicht eingelochter Maximalwert wird in der Tabelle mit `*` gekennzeichnet
- nach jedem vollstaendig von allen Spielern beendeten Loch erscheint die gemeinsame Tabelle
- Gleichstaende verwenden gemeinsame Wettbewerbsraenge, zum Beispiel `1, 1, 3`
- der Prototyp speichert je Kurs genau den besten Gesamtwert unter `user://`; nur vollstaendige Einzel- und Mehrspielerkurse sind bestwertberechtigt

### Fortschritt

Das Spiel bleibt ein Geschicklichkeitsspiel. Es gibt keine staerker werdenden Schlaeger, kaufbaren Werte oder permanenten Kraftverbesserungen.

Moegliche Fortschrittsformen:

- neue Kurse
- kosmetische Farbvarianten
- neue Figuren mit anderem, aber nicht besserem Spielstil
- Medaillen und persoenliche Bestleistungen
- optionale Herausforderungen

**Offene Entscheidung:** Ob alle Kurse sofort spielbar sind oder schrittweise freigeschaltet werden. Eine Freischaltung darf lokale Gruppen nicht unnoetig vom gewuenschten Kurs aussperren.

---

## 14. Bildschirm und Kamera

### Technische Bildbasis

- internes Seitenverhaeltnis: 16:9
- interne Aufloesung: 640 x 360 Pixel
- ganzzahlige Skalierung auf 1280 x 720 und 1920 x 1080
- keine Filterung, die Pixel unscharf macht
- Physik und Spiellogik sind von der Ausgabeaufloesung unabhaengig

Der Grundprototyp bestaetigt 640 x 360 als gut lesbare Basis. Die Darstellung wird ganzzahlig und ohne weichzeichnende Texturfilter skaliert.

### Bildschirmaufteilung

- die Bahn nimmt den groessten Teil des Bildes ein
- ein klar abgegrenztes, fuer die Bahn reserviertes Golferfenster befindet sich unten links
- Kraft und Genauigkeit liegen optisch nahe an der Figur; beide Anzeigen sind schmal und behalten ihre volle Ableselaenge
- die Kraftanzeige steht rechts neben dem Golfer, die Genauigkeitsanzeige darunter; gemeinsam rahmen beide die Figur ein und sind jeweils 5 Pixel breit
- das Golferfenster nutzt die Flaeche ab y=168 bis y=352; Phasentext, Anzeigenueberschriften und die dauerhaften Steuerungshinweise entfallen
- die Kraftanzeige hat 150 Pixel Ableselaenge und traegt eine Dezimeter-Skala fuer die erwartete Ausrollweite auf ebenem Gruen: Teilstriche von 1 bis 10 dm einzeln, darueber alle 10 dm; beschriftet sind 1, 5, 10, 50, 100, 150, 200 und die maximale Weite. Die Abstaende folgen der Weitenberechnung. Schlaege beginnen bei etwa 1 dm (27,713 px/s) und reichen weiterhin bis etwa 230 dm (420 px/s)
- die aktuelle Entfernung zwischen Ball und Zielcursor wird ebenfalls in ganzen Dezimetern angezeigt
- Schlagzahl, Par und aktiver Spieler bleiben sichtbar, dominieren aber nicht
- wichtige Bahnobjekte werden nie dauerhaft durch das Golferfenster verdeckt

### Kamera

- kleine Bahnen passen moeglichst vollstaendig auf den Bildschirm
- groessere Bahnen koennen vor dem Schlag erkundet werden
- das Zielkreuz besitzt beim Erkunden einen grossen Ruhebereich; erst nahe am Bildschirmrand wird die Kamera nachgefuehrt
- waehrend der Ballbewegung folgt die Kamera ruhig und mit einem geschwindigkeitsabhaengigen Vorlauf von hoechstens 48 internen Pixeln
- nur harte Banden- und Windmuehlenkontakte erzeugen einen gerichteten Impuls bis 2 interne Pixel, der nach 0,12 Sekunden verschwunden ist
- eine Taste zentriert die Ansicht auf Ball oder Loch
- Kamerabewegung darf das Timing des Schlags nicht unbeabsichtigt beeinflussen

---

## 15. Grafikstil

### Ziel

Hochaufloesende Pixel-Art mit klaren Silhouetten, gut lesbaren Flaechen und ausdrucksstarken Charakteranimationen.

### Stilregeln

- sichtbare, konsistente Pixelgroesse
- begrenzte Farbpaletten pro Themenwelt
- klare Konturen fuer spielrelevante Objekte
- Dekoration darf Kollisionsgrenzen nicht verschleiern
- starke, gut lesbare Charakterposen
- fluessige Animationen ohne den Pixel-Art-Charakter zu verlieren
- moderne Breitbildkomposition statt Nachbildung eines alten Bildschirmformats
- Effekte wie Partikel, Licht oder Bildschirmbewegung nur sparsam und abschaltbar

Spielrelevante Zustaende muessen auch ohne Farbe erkennbar sein, zum Beispiel durch Form, Bewegung oder Symbolik.

---

## 16. Audio

### Musik

- moderne Chiptune- oder Retro-inspirierte Musik
- eigene Kompositionen
- Themenvariation zwischen Kurswelten
- Musik tritt waehrend konzentrierter Schlagmomente nicht stoerend in den Vordergrund

### Soundeffekte

- unterschiedliche Trefferstaerken
- klar unterscheidbare Materialien und Banden
- Ball rollt auf verschiedenen Untergruenden
- Loch, Wasser, Kanone, Schalter und bewegliche Hindernisse
- kurze charakterbezogene Reaktionen
- eindeutige Signale fuer Kraft, Genauigkeit und vorbereiteten Schlag

Audiofeedback darf wichtige Informationen unterstuetzen, aber nicht die einzige Informationsquelle sein.

Der Grundprototyp erzeugt seine lizenzfreien Retro-Sounds vollstaendig im Code. Schlaglautstaerke und Klangfarbe folgen der Ballgeschwindigkeit; Bande und Windmuehle sind unterscheidbar. Leise Rollschleifen wechseln zwischen Gruen, Sand und Gefaelle und verstummen unterhalb der Stillstandsgrenze. Perfekte Treffer erhalten eine kurze helle Zusatznote. Die zugehoerigen Splitter, Sandpixel, Wasserringe und Lochringe sind rein visuell und greifen nicht in die reproduzierbare Physik ein.

---

## 17. Zugaenglichkeit und Komfort

- frei belegbare Tasten
- getrennte Lautstaerkeregler
- einstellbare Geschwindigkeit von Kraft- und Genauigkeitsanzeige als Assistenzoption
- hoher UI-Kontrast
- Symbole zusaetzlich zu Farben
- reduzierte Bildschirmbewegung
- abschaltbares Controller-Rumpeln
- Pause jederzeit ausser waehrend eindeutig abgeschlossener Physikschritte
- schnelle Wiederholung eines Uebungslochs
- optionaler Ziel- oder Linienassistent fuer Einsteiger

Assistenzoptionen werden bei lokalen Bestwerten sichtbar vermerkt, sollen aber das freie Spielen nicht verhindern.

---

## 18. Technische Leitlinien

- Godot 4 und reine 2D-Nodes
- feste Physikschritte
- Bahndaten und allgemeiner Programmcode bleiben getrennt
- wiederverwendbare Szenen fuer Flaechen, Hindernisse, Bewegungen und Trigger
- Eingaben verwenden Godots Aktionssystem und keine fest codierten Tasten
- Spielregeln funktionieren unabhaengig vom verwendeten Eingabegeraet
- Bahnobjekte besitzen klar definierte Zustaende und Signale
- Speicherstaende enthalten Einstellungen, Freischaltungen und Bestwerte
- Debugansichten zeigen Kollisionen, Geschwindigkeiten, Zonen und Ruecksetzpunkte

Ein vollstaendiger Ingame-Bahneditor ist kein Bestandteil des ersten Prototyps. Die interne Datenstruktur wird aber von Anfang an so angelegt, dass ein spaeterer Editor moeglich bleibt.

---

## 19. Minimaler Vertical Slice

Der Vertical Slice ist die erste kleine Fassung, die bereits das beabsichtigte Spielgefuehl zeigt.

### Inhalt

- eine neutrale Testumgebung
- drei vollstaendige Loecher
  - eine geometrische Golfbahn
  - eine mechanische Bahn mit zeitgesteuertem Hindernis
  - eine Abenteuerbahn mit Trigger oder Kanone
- zunaechst Allrounder, danach alle vier Figuren als Testprofile
- komplettes Schlagsystem
- Ballphysik, Banden, Reibung, Gefaelle, Wasser und Loch
- animiertes Golferfenster mit mindestens Idle, Zielen, Schlag und Reaktion
- Controller-, Tastatur- und Mausbedienung
- Einzelspieler und Hotseat fuer zwei bis vier Spieler
- Schlagzahl, Par und Abschlussanzeige
- Platzhaltergrafik und einfacher Testsound sind zulaessig

### Abnahmekriterien

- Ein neuer Spieler versteht den grundlegenden Schlag ohne lange Erklaerung.
- Derselbe Schlag fuehrt reproduzierbar zum selben Ergebnis.
- Das vorbereitete Warten vor einem Hindernis fuehlt sich sinnvoll an.
- Alle drei Bahnen sind mit allen Figuren erreichbar.
- Controllerbedienung funktioniert ohne Maus oder Tastatur.
- Die Golferreaktionen werden als Teil des Spielcharakters wahrgenommen.
- Eine komplette kleine Mehrspielerrunde kann ohne technische Unterbrechung beendet werden.

---

## 20. Produktionsroadmap

### Phase 1: Fundament

- Godot-Projektstruktur
- Eingabeaktionen
- Ball, Kamera und Testbahn
- Kollision, Reibung und Loch

### Phase 2: Kerngefuehl

- Zielcursor
- Kraft- und Genauigkeitsanzeige
- vorbereiteter Schlag
- erster Platzhaltergolfer
- Soundfeedback

### Phase 3: Vertical Slice

- drei Testbahnen
- Grundbausteine und ein Trigger
- vier Figurenprofile
- Hotseat
- erste visuelle Stilprobe

### Phase 4: Bahn-Baukasten

- Flaechen und Zonen
- Bewegungsmodule
- Hindernisse
- Triggerverkettung
- interne Bahnpruefung und Debugwerkzeuge

### Phase 5: Erster Kurs

- neun eigene Loecher
- finale Grundoptik einer Themenwelt
- Tutorial und Uebungsmodus
- Speichern und Bestwerte
- ausfuehrliche Spieltests

### Phase 6: Inhaltsproduktion

- weitere Themenwelten
- Ausbau von derzeit 45 auf das bestaetigte Ziel von 54 Bahnen
- vollstaendige Charakteranimationen
- Musik, Sound und Polishing

### Phase 7: Veroeffentlichungsvorbereitung

- Optionen und Zugaenglichkeit
- Controller- und Hardwaretests
- Performance und Fehlerbehebung
- Store-Material, Trailer und Demo
- rechtliche und lizenzbezogene Abschlusspruefung

---

## 21. Bewusst nicht Teil des ersten Prototyps

- Online-Multiplayer
- veroeffentlichungsfertiger Bahneditor
- Teilen von Benutzerkursen
- komplexe Kampagne oder Geschichte
- Ausruestungs- und RPG-System
- Mikrotransaktionen
- prozedural generierte Bahnen
- finale Anzahl aller Kurse
- aufwendige Sprachaufnahmen

---

## 22. Offene Entscheidungen

Diese Punkte blockieren den Physik-Prototyp nicht, muessen aber vor dem Vertical Slice geklaert werden:

1. finaler Spielname und Logo
2. Namen, Aussehen und Persoenlichkeit der vier Figuren
3. erste Themenwelt und visueller Stiltest
4. finales Balancing des Kraft- und Genauigkeitssystems
5. Regel fuer maximale Schlagzahl an einem Loch
6. Freischaltungsmodell fuer Kurse
7. Unterstuetzung weiterer klassischer USB-Joysticks
8. finales Inhaltsziel fuer Version 1.0 nach Auswertung des Vertical Slice

---

## 23. Status des Grundprototyps

Der spielbare Godot-Grundprototyp umfasst einunddreissig echte Loecher in vier regulaeren Kursen, einen sichtbaren Referenzkurs mit neun Konturbahnen und insgesamt vierzehn weiterhin erreichbare technische Testbahnen. Hinzu kommen reproduzierbare Ballphysik, das dreiphasige Ein-Tasten-Schlagsystem, eine animierte Platzhalterfigur und Controllerdiagnose. Der Schlag besitzt einen sichtbaren, exakt 0,10 Sekunden langen Abschwung vor dem Kontakt. Der angeschlossene PlayStation-3-Controller wird von Godot/SDL nativ erkannt.

Der neue Spielrahmen startet auf einem Titelbild und fuehrt vollstaendig durch Einzelkurs, lokalen Mehrspieler, Uebung und freies Spiel. Bis zu vier Spieler erhalten Namen und eindeutige kosmetische Farbvarianten. Eine typisierte Rundensitzung verwaltet lochweise Spielerwechsel, das dynamische Schlagmaximum `max(8, PAR + 3)`, Zwischen- und Endtabellen, gemeinsame Raenge sowie den lokalen Kursbestwert. Eingaben werden bei jedem Zustandswechsel bis zur neutralen Controllerstellung gesperrt, um haengende oder doppelt ausgeloeste Joystickbefehle zu verhindern.

Der **Prototypkurs** verbindet seine vier regulaeren Kursloecher mit Allround-Testloch, Gefaelle-Labor, U-Flussbahn, Scroll-Testbahn und Kurven-Labor zu einer neunloecherigen Runde mit Gesamt-Par 38. Die fuenf Labore behalten ihre technische Kategorie und bleiben aus normaler Uebungs- und Freispielauswahl ausgeblendet. Eine ausdrueckliche Kursfreigabe erlaubt sie nur innerhalb dieses kuratierten Prototypkurses; beliebige Rundendaten duerfen technische Bahnen weiterhin nicht als normalen Kursinhalt einschleusen.

Das Referenzloch besitzt einen breiten Sicherheitsweg durch Sand und Gefaelle sowie eine kuerzere obere Linie an Wasser und Windmuehle. Ein festgelegter Sicherheitsablauf beendet es reproduzierbar in vier Schlaegen; bei offener Windmuehle ist die Risikolinie in zwei Schlaegen erreichbar. Horizontales Scrolling zeigt Start und Loch samt vollstaendiger Aussenwaende.

**Die Diamantenlinie** ist ein kompaktes Par 3 ohne Flaecheneffekte oder Mechanik. Vier schräge Banden bilden einen geschlossenen Diamanten; ein breiter unterer Weg ist in drei, eine praezise obere Linie in zwei Schlaegen reproduzierbar.

**Das Doppeltor** ist ein horizontal scrollendes Par 4 mit Anspielzone, Wartebucht, zwei phasenversetzten Schiebetoren und ansteigendem Schlussabschnitt. Beide Tore sind pro Zyklus 0,75 Sekunden gleichzeitig offen. Geschlossene Treffer prallen ohne Zusatzstrafe zurueck, schliessende Tore koennen ruhende Baelle kontrolliert aus dem Kontakt bewegen.

**Die Kanonenwerkstatt** ist eine horizontal scrollende Par-4-Abenteuerbahn. Ein dauerhaft aktivierter Bodenschalter entriegelt zwei zwingend zu benutzende Kanonen: Eine breite Einfahrt fuehrt auf einen sicheren Vier-Schlag-Weg, eine halb so breite Einfahrt auf einen reproduzierbaren Drei-Schlag-Weg. Aufnahme, Zuendpause und sichtbarer Bogenflug laufen automatisch im festen Physiktakt. Der Ball ignoriert waehrend des Fluges Boden und Banden, landet mit definierter Restgeschwindigkeit und behaelt die Schlagzahl sowie die urspruengliche Wasser-Ruecksetzposition bei.

**Klassische Neun** besitzt Gesamt-Par 19 mit der Folge `1/2/2/1/1/2/3/3/4`; sechs Bahnen sind kompakt, drei scrollen horizontal. Revision 7 harmonisiert die bestehenden Aufgaben: Der Auftakt richtet Start und Ziel auf y176 aus. Am runden Stein, Zwei Kreise und der Zickzack-Weg behalten ihre Grundrisse. Bogenschuss und Engstelle verwenden tangential angeschlossene Viertelboegen als wirkliche Aussenkontur; in der Engstelle deckt das 3-x-4-Pfeilfeld den gesamten 64 Pixel hohen Hals ab. Das Hufeisen bildet eine symmetrische runde Zielkammer ohne lose Wandarme und doppelten Rahmen. Kreisallee trennt Bumper und Pfeilfeld raeumlich, setzt den letzten Bumper in die Schlusskurve und richtet den Zielkanal gleichmaessig aus. Die Heimkehr bildet einen echten U-Kanal mit 64 Pixel Mittellinienabstand in Geraden und Kurve; Abschlag `(220,280)` und Ziel `(220,56)` liegen am jeweils linken Ende. Die Mittelinsel und Flaechen ausserhalb der Kurve sind kein Spielboden.

Alle neun Silhouetten verwenden vier Pixel starke Normgeraden und -diagonalen. Die sieben Kreisboegen liegen in `LaneOutlineDefinition.boundary_arcs` und ersetzen dort jeweils genau eine Ankerkante einschliesslich Spielboden und Kollision; eine unsichtbare gerade Sehne wird nicht erzeugt. Insgesamt bleiben acht Kreisbumper und 36 atomare, flache dunkelgruene 16-x-16-Pfeile erhalten, je zwoelf in Bogenschuss, Engstelle und Kreisallee. Die Pfeile haben `30 px/s²` Rollwiderstand ohne Flow-Unterstuetzung. Legacy-Flaechen, Sand, Wasser und bewegliche Mechanismen bleiben ausgeschlossen. Legale PAR-Routen sind fuer alle neun Bahnen getestet; fuer 03, 06, 08 und 09 sichern kleine Winkel-/Kraftabweichungen zusaetzliche Spielreserve. Die Heimkehr erlaubt vier sichere beziehungsweise drei riskante Schlaege. Alte Rekorde bleiben gespeichert, die neue Fassung verwendet `classic_nine_course_v7`.

Der gemeinsame Wandverbund erzeugt nahtlose Gehrungen an geraden, diagonalen und gebogenen Anschluessen. Gezeichnet und kollidiert werden nur die aeusseren Kanten, keine verdeckten Stirnnaehte. Diese technische Korrektur gilt fuer alle Normwandkurse; deren sonstige Bahndaten bleiben unveraendert. Dauerhafte Bahn-, Schlag-, Spieler- und Rundeninformationen stehen jetzt in der Seitenleiste, damit insbesondere obere Ruecklaufkanaele unverdeckt sichtbar sind.

**Pfeil-Armageddon** ist ein vollstaendiger Neun-Loch-Gefaellekurs mit Gesamt-Par 27. Je drei Bahnen sind als Par 2, Par 3 und Par 4 ausgelegt; fuenf bleiben kompakt, vier scrollen horizontal. Alle neun Loecher wurden als eigene geschlossene Minigolf-Silhouetten aus 4-Pixel-Normwaenden neu aufgebaut. Jede Bahn unterbricht den neutralen Spielweg mit mindestens einem nicht seitlich umgehbaren Pfeil-Kernfeld. Die Progression lehrt in Loch 1 bis 3 flache dunkelgruene Felder, praegt Loch 4 bis 6 durch mittlere dunkelblaue Felder und macht ab Loch 7 steile dunkelrote Gegen- und Querpassagen zur Hauptgefahr. Insgesamt 834 Zellen verwenden alle acht Richtungen. Jede Zelle ist ein einzelnes, exakt 16 x 16 Pixel grosses achsenparalleles Quadrat; groessere Felder bestehen ausschliesslich aus solchen Rasterzellen. Drei feste Steigungsstufen steuern Farbe und Physik gemeinsam: flach mit `60 px/s²` in Dunkelgruen, mittel mit `90 px/s²` in Dunkelblau und steil mit `150 px/s²` in Dunkelrot. Alle Zellen besitzen `30 px/s²` Rollwiderstand und keinerlei Mindesttempo, Maximaltempo, automatische Ausrichtung oder Zentrierung. Dadurch beschleunigen sie bergab netto mit `30`, `60` und `120 px/s²`; gegen den Pfeil bremsen sie mit `90`, `120` und `180 px/s²`, sodass ein zu langsamer Ball stoppt und anschliessend in Pfeilrichtung zurueckrollt. Die Pfeilspirale ist ein geschlossener Rechteckspiral-Korridor aus Normwaenden, L- und T-Anschluessen. Ihr inneres schwarzes Loch ist ohne Markierung mit einem zweiten Loch in der abgetrennten Zielkammer verbunden. Der Ball wird kurz eingezogen, erscheint am Partnerloch und behaelt Richtung sowie Geschwindigkeit; die Verbindung muss spielerisch entdeckt werden. Ihre Sand-Auffangzone liegt als seitliche Tasche im mittleren Ruecklauf. Im Gegenstrom flankieren zwei Wasserbecken das rote Kernfeld: Die aeusseren roten Reihen zeigen senkrecht vom jeweiligen Wasser weg. Die beiden inneren Reihen zeigen diagonal nach links-unten beziehungsweise links-oben. Dadurch bleibt die Zentrierung erhalten, waehrend die gemeinsame Linkskomponente einen Ball von der Mittellinie loest und den Gegenstrom lesbar macht. Bewegliche Hindernisse werden nicht verwendet. Jede Bahn besitzt eine automatisiert bestaetigte Idealloesung innerhalb ihres Pars. Revision 5 schliesst neutrale Randstreifen durch wandbuendige Felder und passende Konturen. Anschub, Seitenzug, Wechselstrom und Staffel erhalten einheitlich gefasste Pflichtpassagen. Im Kompasskreuz zeigen Fehlwegpfeile zurueck. Die Pfeilspirale entfernt unbespielbare Restflaechen und setzt ihren inneren Tunneleingang in die Auslauflinie bei (808,100). Beim Gegenstrom reichen die Wasserbecken bis an die Kontur; der neutrale Unterweg entfällt. Armageddon ersetzt den weiten Diamantraum durch einen gefuehrten Zickzack mit acht aufeinanderfolgenden Vollbreitenfeldern und allen acht Richtungen. Kontinuierliche Querschnittsnachweise, legale PAR-Routen und ausgewaehlte Ziel-/Kraftabweichungen sichern die Korrekturen. Alte Ergebnisse bleiben gespeichert; die neue Fassung verwendet arrow_armageddon_course_v5.

**Labyrinth-Neun** ist der naechste vollstaendige Neun-Loch-Kurs mit Gesamt-Par 50. Alle Bahnen verwenden dieselbe lange, horizontal scrollende Grundflaeche, unterscheiden sich aber durch eigene Kammer-, Zickzack-, Kreuzweg- und Diagonallabyrinthe. Die Aussenkontur und saemtliche inneren Mauern bestehen aus den atomaren 16-Pixel-Normwaenden mit 4 Pixel Staerke. Jede Bahn kombiniert zwei oder drei bewegliche Mechanismen; ueber den Kurs verteilt sind es 26 Rotoren, deterministische Schiebetore und gewichtsgesteuerte Wippen. Diese Mechanismen stehen in den notwendigen Wandoeffnungen: Rotoren bestreichen Engstellen, Tore ersetzen Wandabschnitte und verbreiterte Wippen fuellen ihre Passage bis auf weniger als einen Balldurchmesser aus. Die trapezfoermigen Wippenseiten sind echte, mitkippende Banden: Seitliche Treffer prallen ab, sodass der Ball nur ueber die abgesenkte vordere Stirnseite auffahren kann. Im Wippen-Labyrinth steht die Wippe um 90 Grad gedreht in Laufrichtung; waagerechte Normwaende mit T-Anschluessen schliessen beide Seiten und machen die Wippe zum einzigen Durchgang in die obere Kammer. Zwei Irrgaerten setzen die diagonalen Wandvarianten auch innerhalb der Spielflaeche ein. Die bisherigen automatisierten Routen bestätigen für alle neun Bahnen nur einen vereinfachten Grundweg mit ausgesetzter Hinderniswirkung. Die Live-Prüfung vom 10.09.2026 bestätigt die Diagonalfalle mit aktiven Mechanismen in vier Schlägen innerhalb PAR 5; für die übrigen acht Bahnen bleibt dieser Nachweis offen. Details stehen in [LABYRINTH_LIVE_PRUEFUNG.md](LABYRINTH_LIVE_PRUEFUNG.md).

Alle Bahnen liegen als typisierte Datenressourcen in einem validierten Katalog. Neue Loecher benoetigen keine eigene Skriptklasse mehr; der gemeinsame Runtime-Builder erzeugt gerade und gedrehte Flaechen, normierte Wandbausteine, freie Legacy-Banden, Kreise, Kreisboegen, Hindernisse, Trigger und Kanonen. Ein Wandbaustein belegt genau ein 16 x 16 Pixel grosses Kaestchen bei 4 Pixel Wandstaerke. Der Baukasten umfasst vier rechtwinklige Ecken, zwei Diagonalen, eine Waagerechte, eine Senkrechte und vier T-Stuecke fuer lueckenlose dreifache Anschluesse. Gedrehte Flaechen werden anhand ihrer transformierten Ecken gegen die Bahnbegrenzung validiert. Rotoren, Schiebetore und Wippen koennen frei, insbesondere um 90 Grad, platziert werden; Darstellung, Kollision, Bewegungsweg, Gefaelleachse und Sperrkanten folgen der Drehung gemeinsam. Trigger- und Mechanismus-IDs werden vor dem Laden auf Eindeutigkeit und vollstaendige Verknuepfung geprueft.

Die Bahnpruefung bewertet jedes Kursloch nach vier Regeln: Hindernisse muessen die beabsichtigte Linie beeinflussen, Anschluesse duerfen keine unbeabsichtigten Ballluecken besitzen, die Orientierung beweglicher Mechanismen muss zum Anspielweg passen und eine sichere Route muss innerhalb des Pars liegen. Ein Weg innerhalb des dynamischen Schlaglimits allein ist kein PAR-Nachweis. Die Bestandsaufnahme mit noch offenen Fragen fuer andere Kurse steht in `BAHNGESTALTUNG_REGELN.md`; sie ist keine pauschale spielerische Freigabe. Fuer die Klassischen Neun prueft die Automatisierung neun unterschiedliche Konturen, 4-Pixel-Waende, acht Kreise, sieben Konturboegen, drei flache atomare Pfeilfelder, legale PAR-Routen, Abkuerzungen und ausgewaehlte Schlagtoleranzen. Pfeil-Armageddon steht nach der Wegepruefung auf Bestwertrevision 5, die Klassischen Neun stehen nach der Harmonisierung auf Revision 7.

Die neun technischen Kontur-Referenzen **Tor-Gerade**, **Basis 1: Dreifach-Bumper**, **Basis 1: Rotor**, **Basis 1: Schiebetor**, **Basis 1: Wippe**, **Basis 1: Huegelpass**, **Winkel**, **MOS-Kurve** und **Basis 1: Huegelloch** erproben eigene spielbare Bahnkonturen innerhalb der weiterhin rechteckigen Welt- und Kameragrenze. Waagerechte und senkrechte Konturen liegen in den Zentren des 16-Pixel-Rasters; gemischte Konturen duerfen diese Geraden mit 45-Grad-Kanten verbinden. Der Runtime-Builder zeichnet das geschlossene Konturpolygon als Spielboden und zerlegt seine gesamte Aussenkante in atomare Normwaende. Gerade, Senkrechte, vier Eckvarianten und beide Diagonalen erzeugen sowohl Darstellung als auch Kollision mit 4 Pixel Wandstaerke. Tor-Gerade besitzt am Ziel vier echte diagonale Aussenschultern und spiegelt zwei entgegengesetzte diagonale Torstuecke an ihrer horizontalen Spielachse. Fuenf weitere Bahnen verwenden exakt denselben Grundriss, Abschlag und Zielpunkt. Die befahrbare Wippe besteht in der Draufsicht aus zwei trapezfoermigen Flaechen um eine gemeinsame Querachse. Das Ballgewicht senkt jeweils die belegte Seite; dadurch bremst das Gefaelle den Ball vor dem Drehpunkt und beschleunigt ihn nach dessen Ueberquerung wieder. Die abgesenkte Seite wird perspektivisch schmaler, die angehobene Seite breiter dargestellt; Flaechenfarbe, Groessenwirkung, Seitenkollision und Stirnkante vermitteln damit dieselbe Hoehenlage. Die gegenueberliegende hohe Stirnkante wird dabei sichtbar angehoben und blockiert einen zu schnellen Ball. Erst wenn das Gewicht die Ausgangsseite ausreichend abgesenkt hat, verschwindet diese Sperre und gibt den Weg frei. Ohne Belastung kehrt sie in ihre sichtbare Vorzugsposition mit abgesenkter linker Einstiegsseite und angehobener rechter Stirnkante zurueck. Der Huegelpass besteht aus einem 12 x 4 grossen Feld mit 48 atomaren 16-x-16-Pixel-Pfeilbloecken. Er beginnt an beiden Aussenseiten steil in Dunkelrot, geht ueber mittleres Dunkelblau in eine flache dunkelgruene Kuppe ueber und ist in Farbe und Pfeilrichtung an seiner Mittelachse gespiegelt. Das abschliessende Huegelloch behaelt Abschlag und Zielpunkt, vergroessert aber seinen Zielraum symmetrisch fuer ein 7-x-7-Feld aus 49 Pfeilzellen. Das Feld verwendet einen gemeinsamen Halbrasterversatz, bleibt dabei vollstaendig achsenparallel und setzt das Loch exakt in sein mittleres Quadrat. Sein Gefaelle zeigt radial von der Kuppe weg: Der aeussere Ring beginnt steil in Dunkelrot, darauf folgt Mittel in Dunkelblau und der innere 3-x-3-Bereich wird zum Loch hin flach und dunkelgruen. Die Winkelbahn ist einschliesslich Abschlag und Loch punktsymmetrisch aufgebaut; ihr Mittelteil ist auf 144 Pixel Breite reduziert. Die doppelt facettierte MOS-Kurve besitzt horizontale und vertikale Spiegelsymmetrie; ihr 4 x 4 grosses Pfeilfeld liegt mittig, waehrend beide Diagonalvarianten die Aussenwand bilden. Dessen sechzehn Zellen sind jeweils eigenstaendige, ungedrehte 16-x-16-Pixel-Quadrate mit genau einem diagonalen Pfeil und zeigen gemeinsam alle drei Steigungsstufen. Alle neun Referenzrouten sind reproduzierbar getestet; der Referenzkurs besitzt insgesamt Par 18.

Fuer die Wippe gilt ausdruecklich: Ein zu schneller Ball prallt an der noch gesperrten Stirnkante zurueck. Blosses Abbremsen an der Kante ersetzt das notwendige Kippen nicht. Beide Enden bleiben waehrend der waagerechten Zwischenstellung geschlossen; nur das ausreichend abgesenkte Ende wird freigegeben. Diese Regel gilt auch bei gedrehten Wippen und hohen Kontaktimpulsen anderer Hindernisse.

Der erste Spielgefuehl-Polish verbindet den Abschwung mit Kontaktton und Ballstart, unterscheidet die Golferposen klarer und ergaenzt prozedurales Materialaudio sowie kurze Pixel-Effekte. Die Ballkamera verwendet einen weichen Vorlauf; harte Kontakte erhalten einen begrenzten Impuls. Diese Rueckmeldungen lesen nur Physikereignisse und veraendern weder Bahnverlauf noch Reproduzierbarkeit.

Die erste Spieltest-Runde beantwortet nun drei Fragen:

1. Fuehlt sich die Ballbewegung kontrollierbar und nachvollziehbar an?
2. Funktioniert das mehrstufige Schlagsystem mit einer einzigen Aktionstaste?
3. Erzeugt das bewusste Zurueckhalten eines vorbereiteten Schlags tatsaechlich Spannung und Freude?

Erst wenn diese drei Punkte im manuellen Spieltest funktionieren, beginnt die umfangreiche Produktion von Bahnen, Figuren und finaler Pixel-Art.
