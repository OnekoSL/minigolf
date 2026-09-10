# Regeln für die Bahngestaltung

Stand: 08.09.2026. Grundlage: Prüfung aller 45 registrierten Bahnen, der vorhandenen Recherche, des Grunddokuments, der Mechaniken und Tests sowie der bisherigen Spielrückmeldungen.

Dieses Dokument beschreibt die Gestaltungs- und Abnahmeregeln für neue und überarbeitete Bahnen von **Putt & Pixel**. Es enthält außerdem einen datierten Bestandscheck. Eine vorhandene Bahn ist ein Beispiel oder Testfall, aber nicht automatisch eine fehlerfreie Vorlage.

**MUSS** bezeichnet ein Abnahmekriterium. **SOLL** bezeichnet den Regelfall; eine Abweichung braucht einen nachvollziehbaren spielerischen Zweck. Zahlen einzelner Kurse, frühere Umbaupläne und technische Versuchsanordnungen sind keine allgemeinen Designvorgaben.

## 1. Geltung und wichtigste Leitlinie

**Zuerst den tatsächlich spielbaren Weg entwerfen, danach seine Hindernisse.** Eine Bahn soll eine erkennbare Aufgabe stellen: eine Linie treffen, eine Bande nutzen, einen Hügel überwinden, eine Kurve durchspielen oder einen Mechanismus im passenden Moment passieren.

Der aktuelle Katalog enthält:

| Gruppe | Umfang | Bedeutung für diese Regeln |
| --- | ---: | --- |
| Echte Kurslöcher | 31 | 9 klassische, 9 Pfeil-, 9 Labyrinth- und 4 Prototypbahnen. Neue und überarbeitete Fassungen müssen die Regeln erfüllen. |
| Moderne Referenzbahnen | 9 | Bewusst vergleichbare Lern- und Mechanikvarianten; im Datenmodell ebenfalls `TECHNICAL`. Keine pauschale Legacy-Ausnahme. |
| Ältere technische Labore | 5 | `allround_test`, `slope_lab`, `flow_test`, `scroll_test`, `curve_lab`. Ihr alter Aufbau bleibt für gezielte Mechanikregressionen zulässig. |

Die fünf Labore dürfen Rechteckbanden, alte Gefälleflächen und im Fall der U-Flussbahn Flow-Unterstützung behalten. Diese Ausnahme gilt für die genannten Versuchsanordnungen, nicht für beliebige neue Bahnen mit der Kategorie `TECHNICAL`.

Die Recherche vom 04.09.2026 beschreibt teilweise einen inzwischen abgelösten Projektstand. Frühere Festlegungen wie „Abschlag, Loch und PAR unverändert lassen“ begrenzten einen konkreten Umbau. Bei einer neuen Gestaltungsentscheidung dürfen diese Werte geändert werden, wenn der Spielweg dies verlangt. Die späteren Korrekturen an Zickzack-Weg und Heimkehr sind dafür maßgebliche Beispiele.

## 2. Spielweg, Kontur und Hindernisfunktion

### R01 – Eine lesbare Hauptaufgabe

Jede Bahn MUSS ihre Hauptaufgabe in einem Satz beschreiben lassen. Kontur, Gefälle und Mechanismen sollen diese Aufgabe unterstützen. Eine einfache Einführungsbahn darf ohne Hindernis auskommen. Eine komplexe Bahn SOLL bereits eingeführte Aufgaben kombinieren; zwei bis drei Mechanismen sind der bisher festgelegte Ansatz für Labyrinthe, keine allgemeine Mindestanzahl.

Jeder spielrelevante Gegenstand MUSS eine nachvollziehbare Funktion haben: Anspiel verändern, eine Linie blockieren, Tempo verlangen, einen Zeitpunkt bestimmen, einen Fehler auffangen oder eine bewusst riskante Alternative eröffnen. Ein Rotor abseits aller sinnvollen Wege erfüllt diese Anforderung nicht.

### R02 – Die Kontur bildet die Bahn

Reguläre Bahnen MÜSSEN eine geschlossene `LaneOutlineDefinition` mit normierten Außenwänden besitzen. `course_rect` beschreibt den Welt- und Kamerarahmen; es ersetzt nicht den Entwurf der bespielbaren Fläche.

Anlauf, Aufgabe, Übergang und Zielbereich SOLLEN als zusammenhängende Form lesbar sein. Kleine diagonale Schultern sind stufigen Scheinrundungen vorzuziehen, wenn eine schräge Bande gemeint ist. Große freie Flächen brauchen einen Zweck, etwa eine Anspiel- oder Wendekammer.

Eine rechteckige Außenkontur ist zulässig, wenn ihre Innengeometrie einen sinnvollen Weg bildet. Individuelle Silhouette bedeutet nicht, dass jedes Loch zwanghaft eine andere Polygonform braucht. Die Referenzfamilie darf dieselbe Grundform für den Vergleich verschiedener Hindernisse wiederverwenden. Reguläre Kursfolgen sollen sich jedoch durch echte Spielentscheidungen unterscheiden.

### R03 – Pflichtaufgaben dürfen nicht vollständig umgangen werden

Für jede Bahn MUSS feststehen, welche Passage Pflicht ist und welche nur Unterstützung oder Risikooption bietet. Ein als Pflichtfeld bezeichnetes Pfeilfeld muss den neutralen Weg unterbrechen; eine Zusatzreihe neben dem tatsächlich gespielten Weg genügt nicht.

Die Prüfung MUSS alle befahrbaren Seiten einbeziehen: Randstreifen, Außenbanden, Lücken an Wandenden, den Platz hinter Hindernissen und sämtliche relevanten Mechanismusstellungen. Eine Risikoabkürzung darf eine Teilaufgabe verkürzen, aber nicht die erklärte Kernaufgabe bedeutungslos machen.

Ein brauchbarer geometrischer Nachweis sperrt das Pflichtfeld gedanklich oder in einer Wegprüfung und untersucht, ob Start und Ziel auf neutralem Boden noch verbunden sind. Der Ballradius und die tatsächliche Flächenauslösung müssen dabei berücksichtigt werden. Eine gefundene neutrale Verbindung widerlegt die Wegepflicht; eine erfolglose grobe Rastersuche beweist sie noch nicht.

### R04 – Zickzack, Spiralen und Inseln müssen als Wege funktionieren

- Beim Zickzack MÜSSEN wechselnde Wandanschlüsse und Durchgänge wirkliche Seitenwechsel erzeugen. Abschlag und Loch gehören so auf die Bahn, dass diese Wechsel auch gespielt werden.
- Eine Pflichtspirale MUSS am Ziel oder an einem funktionierenden Übergang, etwa einem Tunnel, enden. Eine innere Sackgasse neben einer leichteren Außenroute trägt keine Spiralaufgabe.
- Eine massive Dreiecks- oder Diamantinsel MUSS geschlossen sein. Sie wird umspielt; ein Rotor gehört daher in den Weg um ihre Spitze oder Flanke.
- Sackgassen dürfen bewusste Fehlwege sein, wenn man sie wieder verlassen kann. Sie dürfen keine unbeabsichtigte Endlage erzeugen, aus der nur Neustart hilft.

### R05 – Symmetrie wird bewusst gewählt

Bei symmetrischen Aufgaben MÜSSEN die vorgesehenen Achsen oder die Punktsymmetrie benannt werden. Schultern, Durchgangsbreiten, Hindernisse, Start und Ziel sind daran zu prüfen. Ein symmetrischer Hügel verlangt auch passende gespiegelte Pfeilrichtungen und Steigungsstufen.

Asymmetrische Wege und Gefälle sind zulässig. Die Symmetrie einer Kontur bedeutet nicht automatisch, dass ihre Kräfte oder Mechanismen ebenfalls symmetrisch sein müssen.

### R06 – Der Kurs führt seine Aufgaben schrittweise ein

Ein Kurs SOLL ein erkennbares Profil und eine nachvollziehbare Lernfolge besitzen. Neue Mechaniken werden zunächst einzeln und mit Platz zum Anspielen eingeführt; spätere Bahnen verbinden sie mit engeren Wegen, stärkeren Gefällen oder weiteren Entscheidungen.

Die bisherigen Profile bleiben Orientierung: klassische Bahnen überwiegend statisch mit Kreisen und Bögen, Pfeil-Armageddon mit reiner Gefällephysik und zunehmender Stärke, Referenzen als vergleichbare Einzelaufgaben und Labyrinthe mit mehreren Mechanismen. Die Reihenfolge Grün–Blau–Rot vermittelt die Stärke der Pfeile; die genaue Verteilung auf drei Dreiergruppen ist eine Kursentscheidung. Ein Baukasten muss nicht auf jeder Bahn vollständig vertreten sein.

## 3. Wände, Raster und freie Breiten

### W01 – Ein gemeinsamer Wandbaukasten

Innen- und Außenwände MÜSSEN nach denselben Geometrie- und Kollisionsregeln entstehen. Die Außenwand kommt aus `LaneOutlineDefinition` mit `use_normalized_walls = true`; gerade und diagonale Innenwände werden aus `WallTileDefinition` aufgebaut.

| Eigenschaft | Aktueller Standard |
| --- | --- |
| Wandbaustein | 16 × 16 interne Pixel |
| Physische und helle sichtbare Wandstärke | 4 Pixel; die dunkle Zeichenkontur ist zusätzliches Rendering |
| Gerade Varianten | waagerecht und senkrecht |
| Diagonalvarianten | zwei Richtungen mit 45° |
| L-Stücke | vier rechtwinklige Ecken |
| T-Stücke | vier Orientierungen für dreifache Anschlüsse |
| Gesamt | 12 Varianten |

Die ursprünglich diskutierten acht Varianten einschließlich 2:1-Neigungen entsprechen **nicht** dem aktuellen Baukasten. Neue 2:1-Wände oder andere Winkel würden eine ausdrückliche Erweiterung von Datenmodell, Zeichnung und Kollision erfordern.

Normkonturen müssen die Rasterregeln von `LaneOutlineDefinition.validate()` erfüllen: orthogonale und gemischte Konturen verwenden Zellmitten, reine Diagonalkonturen Rasterecken. Frei gewählte Koordinaten dürfen nicht durch optisch ähnliche Stücke kaschiert werden.

### W02 – Anschlüsse müssen tatsächlich geschlossen sein

Trennwände MÜSSEN bis an die zugehörige Kontur oder Anschlusswand reichen. Rechtwinklige Umlenkungen verwenden L-Stücke, dreifache Verbindungen T-Stücke; das gilt auch an der Außenwand. Überdeckungen dürfen keine zusätzlichen Fangtaschen oder unsichtbaren Kanten erzeugen.

Bei Diagonalen und gemischten Konturen sind die Endpunkte ausdrücklich zu kontrollieren. `WallJoinGeometry` verbindet Normsegmente mit echten Gehrungen und begrenzt spitze Anschlüsse durch eine kurze Abschrägung. Nur die äußeren Kanten des Verbunds werden gezeichnet und kollidieren; interne Stirnnähte dürfen weder dunkel erscheinen noch den Ball fangen. Darstellung und Kollision teilen dieselbe beim Bahnaufbau berechnete Geometrie. Ein gemeinsames Wandnetz ersetzt dennoch keine Anschlussprüfung.

Kollision und Darstellung MÜSSEN dieselbe Wandlage vermitteln. Ein optisch geschlossenes Ende mit einer befahrbaren Lücke ist ebenso fehlerhaft wie eine freie Fläche mit unsichtbarer Sperre.

### W03 – Breiten werden für den Ball gemessen

Der aktuelle Ball hat Radius 5 und Durchmesser 10 interne Pixel. Maßgeblich ist die **lichte Breite zwischen den Kollisionsflächen**, nicht der Abstand ihrer Mittellinien und nicht die Zahl gezeichneter Kästchen.

Für einen Durchgang MUSS nach Abzug des Balldurchmessers noch eine sinnvolle Spielreserve bleiben. Bei parallelen 4-Pixel-Wänden mit 48 Pixel Mittellinienabstand bleiben beispielsweise 44 Pixel lichte Breite und 34 Pixel seitlicher Bewegungsraum für das Ballzentrum.

Die sichere Route SOLL kleine Ziel- und Kraftabweichungen vertragen. Sehr enge Durchgänge gehören zu ausdrücklich schwierigen Aufgaben oder Risikoalternativen. Die in der Recherche vorgeschlagenen Breiten von wenigen Balldurchmessern sind Startwerte für Versuche, keine bereits bewiesenen universellen Grenzwerte.

Soll ein Bereich gesperrt sein, ist ein durchgehender Anschluss zu bauen. „Die Restlücke ist wahrscheinlich zu klein“ ist keine Gestaltungsregel. Bei beweglichen Teilen müssen die Anschlüsse in beiden Endlagen und den Zwischenstellungen funktionieren.

## 4. Kreise und Kreisbögen

`WallDefinition.CIRCLE` und `WallDefinition.ARC` bleiben zulässige Spezialgeometrien. Freie rechteckige `WallDefinition`-Banden sind auf die benannten Legacy-Labore beschränkt.

Soll ein Bogen die **Außenbegrenzung** bilden, wird er in `LaneOutlineDefinition.boundary_arcs` genau einer Konturkante zwischen zwei definierten Ankern zugeordnet. Er ersetzt diese Kante vollständig: Spielboden, Punktprüfung, Zeichnung und Kollision folgen dem Bogen, nicht seiner geraden Sehne. Ein zusätzlicher rechteckiger Rahmen hinter der Kurve ist kein Ersatz für eine passende Silhouette. Außenbogen und Normwand müssen dieselbe 4-Pixel-Stärke besitzen; tangentiale Anschlüsse sind für fließende Ein- und Ausläufe zu verwenden. Die tatsächliche Auswölbung muss innerhalb der Kameragrenzen liegen. Diese Erweiterung erlaubt keine frei gewinkelten geraden Legacy-Wände.

**K01:** Ein freier Kreisbumper ist erlaubt, wenn er eine relevante Direkt-, Banden- oder Durchgangslinie beeinflusst. Er muss nicht an einer Wand kleben. Sein Radius und die angrenzenden Freiräume werden gemeinsam gestaltet.

**K02:** Ein Bogen, der einen Kanal oder eine Trennung bilden soll, MUSS an definierten Wandankern enden. Eine bewusst freie Öffnung muss als Einfahrt, Ausfahrt oder Risikooption erkennbar und spielbar sein. Ein sauber verankerter Bogen außerhalb des tatsächlich befahrenen Bereichs erfüllt die Aufgabe trotzdem nicht.

**K03:** Bei konzentrischen Bögen MÜSSEN Einlauf, Wendebereich und Auslauf zusammenpassen. Die lichte Kanalbreite ergibt sich aus Radien und Wandstärken. Das Loch liegt hinter der beabsichtigten Rückkehrlinie, nicht auf der Bogenwand oder vor dem Wendemanöver.

**K04:** Die gesamte Bogen- beziehungsweise Kreisfläche ist auf Wandüberschneidungen, Bodendarstellung und freie Ballwege zu prüfen. Die Lage des Mittelpunkts allein genügt nicht. Bögen verwenden für neue Spielbahnen ebenfalls 4 Pixel Wandstärke; ein massiver Kreis wird dagegen über seinen Radius beschrieben.

Die acht Kreise und sieben Bögen der Klassischen Neun sind deren konkrete Zusammenstellung, keine Mengenpflicht für andere Kurse.

## 5. Pfeilflächen und Höhenprofile

### P01 – Eine Zelle ist ein Quadrat mit einem Pfeil

Pfeilflächen MÜSSEN aus eigenständigen `ArrowTileDefinition`-Zellen von exakt **16 × 16 Pixeln** bestehen. Jede Zelle enthält genau eine der acht Richtungen. Die Quadrate bleiben immer achsenparallel; ein diagonaler Weg wird mit Rasterzellen ausgelegt, nicht durch Drehung eines großen Feldes.

Zusammenhängende Felder verwenden ein konsistentes Raster. Ein bewusst gemeinsamer Halbrasterversatz ist erlaubt: `grid_offset` darf je Achse 0 oder 8 sein. Das Hügelloch nutzt dies, um das Ziel exakt in die mittlere Zelle zu setzen. Beliebige Versätze und überlappende Zellen sind unzulässig.

### P02 – Farbe bezeichnet die Stärke des Gefälles

| Stufe | Farbe | Beschleunigung in Pfeilrichtung | Netto bergab bei 30 Rollwiderstand | Bremsung genau gegen den Pfeil |
| --- | --- | ---: | ---: | ---: |
| Flach | Dunkelgrün `#245537` | 60 px/s² | 30 px/s² | 90 px/s² |
| Mittel | Dunkelblau `#244c70` | 90 px/s² | 60 px/s² | 120 px/s² |
| Steil | Dunkelrot `#71343a` | 150 px/s² | 120 px/s² | 180 px/s² |

Der Pfeil zeigt **bergab**, nicht zwangsläufig zum Loch oder in die gewünschte Spielrichtung. „Flach“ bezeichnet die schwächste Steigung, keine waagerechte Fläche ohne Wirkung. Diagonale Kräfte sind normalisiert und nicht stärker als waagerechte oder senkrechte Kräfte derselben Farbe.

Neue Spielfelder MÜSSEN `deceleration = 30` und alle vier Flow-Werte auf `0` verwenden: `minimum_flow_speed`, `maximum_flow_speed`, `flow_alignment_rate`, `flow_centering_strength`. Der Ball wird durch Gefälle beschleunigt oder gebremst; seine Geschwindigkeit und Ausrichtung werden nicht automatisch festgelegt. Große Legacy-`SLOPE`-Flächen werden nicht neu verwendet.

### P03 – Ein Höhenprofil ist eine zusammenhängende Aufgabe

Bei einem Hügel zeigen Pfeile von der Kuppe weg; beim Spielen bergauf arbeitet der Ball gegen sie. Für die bisher entwickelten Hügel ist außen Rot, danach Blau und zur Kuppe Grün vorgesehen. Der Hügelpass verwendet dieses Profil beidseitig gespiegelt. Beim Hügelloch liegt das Ziel mittig auf der Kuppe.

Das 12 × 4-Feld des Hügelpasses und das 7 × 7-Feld des Hügellochs sind Referenzgrößen, keine Pflichtmaße aller zukünftigen Hügel. Das Profil und seine spielbare Wirkung sind entscheidend.

Ein Pflichtfeld MUSS den relevanten Weg abdecken. Ein unterstützendes Feld darf umgehbar sein, muss dann aber als solche Unterstützung entworfen und geprüft werden. Kraft, Länge und Einfahrttempo sind gemeinsam abzustimmen.

### P04 – Keine unbeabsichtigten Dauerbewegungen oder Fanglinien

Feldübergänge MÜSSEN mit schwachen, starken, schrägen und entgegen gerichteten Bällen geprüft werden. Besonders wichtig sind Pfeil-Pfeil-Grenzen, Pfeil-Wand-Kontakte, Kuppen, Wassergrenzen und Enden langer Felder.

Gegenläufige Pfeile dürfen den Ball nicht dauerhaft auf einer Grenzlinie festhalten oder zwischen Wand und Gefälle pendeln lassen. Eine beabsichtigte Ruheposition muss wieder spielbar werden. Ein fortlaufender Kanal braucht eine Ausroll- oder Rücklaufmöglichkeit.

Das korrigierte Gegenstromfeld ist ein Beispiel: Die äußeren roten Reihen zeigen vom Wasser zur Mitte; die beiden inneren zeigen zusätzlich diagonal nach links. Diese gemeinsame Komponente löst den Ball von der Mittellinie. Das ist ein spezielles Profil, keine allgemeine Pflicht für alle Wasserbahnen.

### P05 – Flächenwirkung muss eindeutig bleiben

Pfeile, Wasser, Sand und Wippe dürfen sich nicht unbeabsichtigt überlagern. Die aktuelle Physik nimmt die erste passende Zone und addiert die Kräfte nicht einfach. Die Wirkung darf deshalb nicht zufällig von der Ressourcenreihenfolge abhängen.

Pfeilzonen werden am Ballzentrum ausgewählt. Ein sichtbarer Ballrand über einer Pfeilzelle beweist noch keine Gefällewirkung. Randstreifen und Kernfeldbreiten müssen anhand dieser tatsächlichen Auslösung geprüft werden.

## 6. Bewegliche Hindernisse, Wippen und Übergänge

### M01 – Orientierung folgt dem Anspielweg

Rotoren, Tore und Wippen MÜSSEN in der tatsächlich gespielten Passage stehen. Eine Drehung um 90° muss Fläche, Kollision, Bewegung, Gefälle und Sperrkanten gemeinsam drehen. Maßgeblich ist die lokale Funktionsachse des Mechanismus.

Rotoren sollen eine Engstelle oder Bandenlinie beeinflussen. Tore müssen im geschlossenen Zustand den vorgesehenen Durchgang sperren und im offenen Zustand ausreichend Platz geben. Vor einer zeitabhängigen Passage SOLL eine sichere Warte- beziehungsweise Anspielzone liegen. Bewegung und Kontaktimpulse müssen berechenbar sein.

### M02 – Eine Wippe wird über ihre niedrige Stirnseite befahren

Die Wippe MUSS längs ihrer lokalen X-Achse zum Anspielweg ausgerichtet werden. Ihre abgesenkte Stirnseite ist der Einstieg. Die beiden Längsseiten reflektieren den Ball; die hohe Stirnkante blockiert ihn, bis diese Seite durch das Ballgewicht ausreichend abgesenkt wurde.

Erreicht der Ball das noch nicht abgesenkte Ende zu schnell, MUSS er dort sichtbar zurückprallen. Die Kante darf ihn weder hindurchlassen noch lediglich abbremsen, damit er auf ihre Freigabe wartet. Tempo darf das notwendige Kippen nicht überspringen. Auch um die waagerechte Zwischenstellung bleiben beide Stirnkanten gesperrt; freigegeben wird nur das ausreichend niedrige Ende.

Sperrzustand und Kollisionsform MÜSSEN vor der Ballbewegung desselben Physikschritts übereinstimmen. Weder ein Kippwechsel noch ein Reset darf ein kurzzeitig offenes Ende hinterlassen. Dies muss mit echten Physikframes und auch nach einem Bahnwechsel geprüft werden; nur manuell synchronisierte Kollisionsproben decken verzögerte Updates nicht auf.

Die Abnahme MUSS schnelle Durchfahrversuche mit aktiver Kippbewegung prüfen: reguläres Maximaltempo (aktuell 420 px/s), mögliche Hindernisimpulse (bis 520 px/s), beide Anspielrichtungen und alle vier rechtwinkligen Orientierungen. Entscheidend sind der Rückprall beim Kontakt und das Ausbleiben einer Überquerung der noch gesperrten Kante während der gesamten Fahrt, nicht allein die Endposition. Ergänzend muss ein passend dosierter Ball die Wippe nach dem Absenken regulär verlassen können. Diese Geschwindigkeiten sind Testfälle, keine zusätzliche Förder- oder Bremsautomatik.

Die unbelastete Vorzugsstellung MUSS erkennbar sein. Das hohe Ende erscheint perspektivisch breiter und heller, das niedrige schmaler und dunkler. Fläche, Pfeile, Seitenbanden und Sperrkante müssen dieselbe Höhenlage vermitteln.

Ist die Wippe eine Pflichtpassage, MÜSSEN ihre Seiten an die angrenzenden Wände anschließen. Dabei zählt die beim Kippen veränderliche Kontur, nicht nur ihr nominelles Rechteck. Einstieg und Auslauf brauchen Platz zum Anspielen und Weiterrollen. Ein seitlich erreichbares Brett oder eine bequem umfahrbare Wippe erfüllt keine Pflichtaufgabe.

### M03 – Tunnel verbinden echte Wegabschnitte

Tunnel werden als paarweise verbundene, unmarkierte schwarze Löcher dargestellt. Es gibt keine Paarfarbe, Beschriftung oder sichtbare Verbindungslinie. Der Spieler entdeckt die Zuordnung selbst; das eigentliche Zielloch bleibt durch die Fahne unterscheidbar.

Beide Enden MÜSSEN erreichbar sein und eine funktionierende Fortsetzung ermöglichen. Richtung und Geschwindigkeit bleiben beim Transfer erhalten. Deshalb ist der Ausgang für die möglichen Einfahrtrichtungen freizuhalten: Der Ball erscheint aktuell 13 Pixel in Bewegungsrichtung neben dem Ausgang und braucht anschließend weiteren Auslauf.

Ein Tunnel darf eine Spirale mit einer getrennten Zielkammer verbinden. Er darf nicht unmittelbar in Wand, Wasser, eine erneute Dauerschleife oder einen unerreichbaren Restweg führen. Transfer und Rückkehr müssen beim Neustart sauber zurückgesetzt werden.

### M04 – Schalter und Kanonen brauchen vollständige Spielketten

Ein Pflichtschalter MUSS auf einem erreichbaren notwendigen Weg liegen. Verknüpfte Mechanismen brauchen eindeutige IDs, nachvollziehbare Zustände und einen funktionierenden Reset.

Bei Kanonen MÜSSEN Einfahrtrichtung, Einfangbreite, Freischaltung, Flug, Landung und Restrollweg zusammenpassen. Eine sichere und eine riskante Kanone sollen sich durch erkennbare Anforderungen unterscheiden. Soll die Kanone die einzige Verbindung zum Ziel sein, müssen Bodenwege neben oder zwischen den Maschinen geschlossen sein.

Der Flug selbst zählt keinen zusätzlichen Schlag. Ein erfolgreicher isolierter Kanonenflug beweist jedoch noch keine spielbare Anfahrt oder sichere Landung im gesamten Loch.

## 7. Start, Ziel, PAR und Fehlertoleranz

### S01 – Start und Ziel gehören an die Enden der Aufgabe

Der Abschlag MUSS kontrolliert anspielbar sein und darf nicht in einer Wand, Gefahrenfläche oder unbeabsichtigten Gefälle-Endlage liegen. Das Loch MUSS nach der beabsichtigten Aufgabe erreicht werden. Beide Positionen werden am gesamten Spielweg geprüft, nicht nur am aktuell sichtbaren Kameraausschnitt.

Die Lage eines Mittelpunkts innerhalb der Kontur genügt nicht. Ball- und Lochradius, Anrollraum und Fahne brauchen Abstand. Der Ziellochradius beträgt aktuell 7 Pixel; eingefangen werden Bälle bis 120 px/s. Ein Ziel, das nur mit sofortigem Wandkontakt oder unkontrolliertem Hochgeschwindigkeitstreffer erreicht wird, braucht einen anderen Auslauf.

Die Heimkehr demonstriert ein Ziel am Ende des Rücklaufs. Der Zickzack-Weg demonstriert die bewusste Kombination aus Start oben und Ziel unten, damit die gesamte Wegführung gespielt wird.

### S02 – PAR folgt der spielbaren sicheren Route

PAR MUSS anhand einer nachvollziehbaren, regulär spielbaren Route festgelegt werden. Weglänge, notwendige Richtungswechsel, Anspielpositionen, Tempoverluste und Mechanismen gehören in diese Bewertung. Lochindex oder eine alte gleichmäßige Zahlenfolge sind keine Begründung.

Die sichere Route SOLL mit kleinen Abweichungen von Winkel, Stärke und bei Mechanismen vom Zeitpunkt funktionieren. Eine einzelne mathematisch exakt kalibrierte Ideallinie ist ein Reproduzierbarkeitsnachweis, aber noch keine sichere Route. Die erlaubte Toleranz muss je Bahn benannt und erprobt werden; ein universeller bereits bewiesener Grenzwert liegt noch nicht vor.

Eine Risikoalternative soll einen nachvollziehbaren Vorteil haben, etwa weniger Schläge, und dafür Präzision, Tempo oder Timing verlangen. Bei PAR 1 ist eine zusätzliche kürzere Route nicht sinnvoll; es genügt eine faire Ass-Aufgabe.

Aktuelle Klassikfolge: `1, 2, 2, 1, 1, 2, 3, 3, 4`, Gesamt-PAR 19. Das ist das Ergebnis der bisherigen Anpassungen, kein Schema für andere Kurse.

### S03 – Nur erreichbare Eingaben zählen als Spielnachweis

Abnahmerouten MÜSSEN mit dem tatsächlichen Schlagsystem spielbar sein. Der aktuelle Standardcontroller erreicht 78 bis 420 px/s; Zielrichtung und Zeitpunkt müssen über die echte Eingabe erreichbar sein. Sondergeschwindigkeiten in isolierten Physiktests sind zulässig, dürfen aber nicht als reguläre PAR-Lösung gelten.

Für Mechanikbahnen müssen die Hindernisse bei der abschließenden Spielprüfung aktiv sein. Ein offenes, eingefrorenes Tor oder ein deaktivierter Rotor kann die Grundgeometrie prüfen, beweist aber kein spielbares Zeitfenster. Die 0,10 Sekunden zwischen Loslassen und Ballkontakt sind beim Timing zu berücksichtigen.

### S04 – Schlaglimit ist Fehlerreserve

Das Schlagmaximum ist `max(8, PAR + 3)`. Es verhindert endlose Runden und ist kein Ersatz für angemessenes PAR. Eine Route mit acht Schlägen auf PAR 5 erfüllt allein dadurch noch nicht die PAR-Abnahme.

Nach Wasser, Fehlfahrt oder Mechanikkontakt MUSS ein sinnvoller weiterer Versuch möglich bleiben. Rücksetzpositionen dürfen keinen sofortigen erneuten Wasserkontakt oder unvermeidlichen Folgeschaden erzeugen.

## 8. Lesbarkeit, Kamera und Rücksetzen

**V01:** Spielboden, Banden, Gefälle, Wasser, Mechanismen und Zielloch müssen unterscheidbar sein. Richtung und Funktionszustand dürfen nicht allein aus versteckten Daten hervorgehen. Die absichtlich unmarkierte Tunnelzuordnung ist eine bewusste Ausnahme; die Tunnelöffnungen selbst bleiben sichtbar.

**V02:** Jede neue oder veränderte Bahn MUSS als Gesamtansicht und im tatsächlichen Spielbild geprüft werden. Lange Bahnen benötigen zusätzlich beide Kameraenden und relevante Zwischenansichten. Kleine Gesamtansichten ersetzen keine Kontrolle von Pfeilen, Anschlüssen oder Engstellen in Spielgröße.

**V03:** HUD, Fahne und Golferfenster dürfen die entscheidende Passage nicht verdecken. Bei der internen Ansicht von 640 × 360 bleiben die dauerhaften Informationen vollständig in der linken Seitenleiste; über dem Spielfeld liegen keine Bahn-, Spieler- oder Rundentexte mehr. Auch lange Namen und hohe Schlagzahlen müssen in ihre reservierten Textfelder passen. Der Fahnenmast reicht 29 Pixel über das Loch. Es sind die Bildschirmpositionen nach Kameraverschiebung zu prüfen, nicht nur Weltkoordinaten.

**V04:** Kameragrenzen müssen Außenwände vollständig zeigen und das Erkunden der nächsten Passage zulassen. Die rechnerische Katalogprüfung ist durch Sichtprüfung zu ergänzen. Ein erfolgreich gespeichertes, aber leeres oder veraltetes PNG zählt nicht als Nachweis.

**V05:** Lochneustart und erneuter Eintritt in eine Bahn müssen Ball, Mechanismen, Wippenstellung, Torphasen, Trigger, Tunneltransfer und Kanonenflug in einen definierten Ausgangszustand bringen.

## 9. Arbeitsablauf und Abnahme

Vor dem Bau werden Hauptaufgabe, Pflichtpassage, sichere Route, optionale Risikoalternative, Start, Ziel und gewünschtes PAR notiert. Danach werden Kontur und geschlossene Wandverbindungen gebaut, erst anschließend Flächen und Mechanismen eingebunden.

| Prüfung | Erforderlicher Nachweis |
| --- | --- |
| Daten | Gültiger Katalog, eindeutige IDs, Normkontur, zulässige Bausteine, korrekte Raster- und Flow-Werte. |
| Wege | Start–Ziel-Verbindung, sinnvolle Rolle jedes Hindernisses, keine neutrale Umgehung einer Pflichtaufgabe, geschlossene Inseln und Wandanschlüsse. |
| Kollision | Tatsächliche Ballbreite, schräge und streifende Treffer, aktive und bewegte Anschlussstellen, freie Tunnel- und Kanonenausgänge. |
| Physik | Mit und gegen Pfeile, schwaches und starkes Tempo, keine Fanglinien oder Endlosschwingungen, sichere Rücksetzung. |
| Spielbarkeit | Eine innerhalb PAR eingelochte Route mit erreichbaren Eingaben und aktiven Mechanismen; dokumentierte Toleranz. Risikoalternative nur dort, wo vorgesehen. |
| Darstellung | Aktuelle vollständige Bahn, relevante Kameraansichten, erkennbare Pfeile/Höhenlagen, keine verdeckte Kernpassage. |
| Auslieferung nach Bahnänderung | Relevante Regressionen, vollständige Headless-Suite, aktualisierter Windows-Export und Startprüfung der tatsächlich ausgelieferten EXE. |

Bei einer reinen Dokumentationsänderung wird kein neuer Spielbuild benötigt. Bei einer Änderung des Wegs, der Schwierigkeit, von Start/Ziel oder PAR ist zu prüfen, ob Bestwerte noch vergleichbar sind. Falls nicht, wird nur die `best_score_revision` des betroffenen Kurses erhöht; alte Schlüssel bleiben gespeichert. Der Schlüssel lautet ab Revision 2 `<course_id>_v<revision>`.

Ein Prüfbericht MUSS unterscheiden zwischen Datenprüfung, geometrischem Wegnachweis, isoliertem Mechaniktest, präziser Idealroute und tatsächlich mit Fehlertoleranz gespielter Abnahme. Ein grüner Gesamtlauf macht diese Nachweise nicht austauschbar.

### Kurzer Freigabecheck

- [ ] Hauptaufgabe und Pflichtpassage sind benannt und im Bild erkennbar.
- [ ] Start und Ziel erzwingen die beabsichtigte Wegfolge.
- [ ] Kontur, L-/T-Anschlüsse, Diagonalen und Bögen sind physisch geschlossen, wo sie sperren sollen.
- [ ] Jedes Hindernis beeinflusst eine sinnvolle Spielentscheidung.
- [ ] Pflichtfelder und Pflichtmechanismen können nicht vollständig neutral umgangen werden.
- [ ] Pfeilraster, Farben, Richtung und reine Gefällephysik entsprechen dem Standard.
- [ ] Wippen, Tore, Rotoren, Tunnel und Kanonen haben spielbare Ein- und Ausgänge.
- [ ] Fehlversuche erlauben Weiterkommen; kein Ball bleibt unbeabsichtigt dauerhaft gefangen.
- [ ] Sichere Route innerhalb PAR mit legalen Eingaben und aktiven Mechanismen nachgewiesen.
- [ ] Sichtprüfung in Gesamt- und Spielansicht, Revision und gegebenenfalls Export abgeschlossen.

## 10. Bestandsprüfung vom 08.09.2026

Die Prüfung umfasst alle 45 Ressourcen aus `data/holes/hole_catalog.tres`. Geprüft wurden Daten, zugehörige Tests und frisch aus `HoleRuntime` gerenderte Gesamtansichten aller fünf Kurse. Die Ansichten zeigen den Ausgangszustand der Mechanismen. Das ist keine erneute manuelle Vollspielprüfung aller Bahnen und keine vollständige HUD-/Timingabnahme.

**Ergebnis der vorhandenen Automatik:** 45 gültige Lochdefinitionen; vollständige Headless-Suite mit **2024 Prüfungen, 0 Fehlern**. Beim Start meldete Godot in der isolierten Prüfumgebung einen nicht lesbaren Zertifikatsspeicher; die lokalen Prüfungen und Renderläufe wurden erfolgreich beendet.

40 Bahnen besitzen Normkonturen und keine freien Rechteckbanden oder Legacy-Gefälleflächen. Die verbleibenden fünf sind genau die benannten älteren Labore. Technische Modernisierung und gute Spielgestaltung sind dennoch getrennt zu bewerten.

### 10.1 Klassische Neun

Alle folgenden IDs haben den Präfix `classic_nine_`. Hinweise auf Testlinien beschreiben die aktuelle Testabdeckung, keine zusätzliche Qualitätsfreigabe.

| ID | Name / PAR | Geprüfter Aufbau und maßgebliche Lehre |
| --- | --- | --- |
| 01 | Der Auftakt / 1 | Freie Mittellinie, symmetrische Schultern. Eine klare Einführung braucht kein zusätzliches Hindernis. |
| 02 | Am runden Stein / 2 | Kreis auf der diagonalen Direktlinie. Freier Bumper zulässig; Test besitzt eine präzise Ass-Linie, noch keine breit abgesicherte Zweischlagroute. |
| 03 | Bogenschuss / 2 | Zwei angeschlossene Viertelbögen und 4 × 3 flache Pfeile. Kanalwirkung und Toleranz der bisher präzisen Testlinie prüfen. |
| 04 | Das Hufeisen / 1 | Schutzbogen mit angeschlossenen Armen. Einfahrt muss zur Anspielrichtung passen; sichere und riskante Testlinie sind aktuell identisch. |
| 05 | Zwei Kreise / 1 | Zwei versetzte Bumper. Lage und Durchgangsbreiten bestimmen die Aufgabe; sichere und riskante Testlinie sind aktuell identisch. |
| 06 | Die Engstelle / 2 | Zwei angeschlossene Bögen und 3 × 4 flache Pfeile. Enge anhand von Ball und Kollisionsflächen prüfen. |
| 07 | Der Zickzack-Weg / 3 | Rechteckige Kontur, gegensinnige Diagonalriegel; Start `(220,72)`, Ziel `(960,280)`. Endpunkte müssen die Seitenwechsel erzwingen. |
| 08 | Kreisallee / 3 | Serpentinischer Korridor, fünf kleine Bumper, 4 × 3 Rechtspfeile. Wiederholung braucht einen lesbaren Rhythmus. |
| 09 | Die Heimkehr / 4 | Haarnadel mit zwei konzentrischen Bögen; Ziel links oben am Rücklaufende. Die gesamte Wendestrecke gehört zur Aufgabe. |

Zum Zeitpunkt der obigen Bestandsaufnahme: Gesamt-PAR 19, Bestwertrevision 6. Acht Kreise, sieben Bögen und drei flache Pfeilfelder sind kursbezogene Bestandsmerkmale.

#### Nachprüfung: harmonisierte Klassische Neun, Revision 7

Die anschließende Überarbeitung behält die Folge `1/2/2/1/1/2/3/3/4`, Gesamt-PAR 19, alle IDs und Kameragrenzen bei. Bestehende Rekorde bleiben gespeichert; die neue Fassung verwendet `classic_nine_course_v7`.

- Alle Normbanden erhalten gemeinsame nahtlose Ecken und deckungsgleiche Kollisionskanten. Auch andere Normwandkurse profitieren von diesem technischen Anschlussfehler-Fix; ihre Bahndaten wurden nicht verändert.
- Auftakt: Start und Ziel liegen exakt auf der Symmetrieachse y176.
- Bogenschuss und Engstelle: Viertelbögen bilden die wirkliche Außenkontur und schließen tangential an. In der Engstelle deckt das 3×4-Pfeilfeld den 64 Pixel hohen Hals ohne neutralen Randstreifen ab.
- Hufeisen: Symmetrische Zufahrt in eine echte runde Zielkammer; keine losen Wandarme oder doppelte Außenwand. Start und Ziel liegen auf y176.
- Kreisallee: Keine Bumper-Pfeil-Überlagerung; letzter Bumper sitzt im letzten Richtungswechsel, Zielkanal gleichmäßig 64 Pixel hoch.
- Heimkehr: Tatsächlicher U-Kanal mit 64 Pixel Achsabstand in Geraden und Kurve; Mittelinsel und Restflächen außerhalb der Kurve sind kein Spielboden. Start `(220,280)`, Ziel `(220,56)`.
- Am runden Stein, Zwei Kreise und Zickzack behalten ihre funktionierenden Grundrisse und erhalten ebenfalls die korrigierten Wandanschlüsse.

Die dauerhaften Prüfungen enthalten legale PAR-Routen für alle neun Löcher, die Ein-, Zwei- beziehungsweise Dreischlag-Risikorouten sowie zusätzliche kleine Winkel-/Kraftabweichungen für 03, 06, 08 und 09. Bei Kreisallee wird der letzte Putt passend zur tatsächlichen Balllage ausgerichtet und dosiert; das ist kein Nachweis, dass identische Eingaben nach jeder Abweichung funktionieren. Mengen: weiterhin acht Kreise, sieben echte Konturbögen und 36 flache Pfeilzellen.

Reproduzierbare Gesamtansichten: `tests/capture_classic_harmony.gd`; Spielansichten und beide Kameraenden der langen Bahnen: `tests/capture_classic_nine.tscn`. Die dauerhaften Bahninfos wurden in die Seitenleiste verlegt, damit auch der obere Rücklauf der Heimkehr frei sichtbar bleibt.

Abnahme dieser Fassung am 08.09.2026: **45 gültige Definitionen, 2296 Headless-Prüfungen, 0 Fehler**. Alle neun Gesamtansichten sowie Spielansichten und beide Enden der drei langen Bahnen wurden neu gerendert und auf Anschlüsse, Pfeile, HUD und Kameraränder geprüft. Windows-Debug-Export und EXE-Starttest endeten mit Exitcode 0. Der bekannte Zertifikatsspeicherhinweis der isolierten Godot-Umgebung blieb ohne Einfluss auf die lokalen Prüfungen. Die offenen Befunde anderer Kurse aus der ursprünglichen Bestandsaufnahme sind damit nicht erledigt.

### 10.2 Pfeil-Armageddon

Alle folgenden IDs haben den Präfix `arrow_armageddon_`. Die bisherige Behauptung eines unvermeidbaren Kernfelds ist durch die vorhandenen Zellzähltests allein nicht bewiesen.

| ID | Name / PAR | Geprüfter Aufbau und maßgebliche Lehre |
| --- | --- | --- |
| 01 | Der Anschub / 2 | Flaches 6 × 4-Rechtsfeld mit diagonalem Auslauf. Frühe Gefälleaufgabe; Randstreifen anhand der tatsächlichen Auslösung prüfen. |
| 02 | Diagonaldrift / 2 | Achsenparallele Treppenzellen im diagonalen Korridor. Testroute verwendet unzulässige 430 px/s; legalen Nachweis erneuern. |
| 03 | Seitenzug / 2 | Zwei entgegengesetzte flache Querfelder. Gegenhalten und wiederholte Pfeil-Wand-Kontakte gehören zur Aufgabe. |
| 04 | Wechselstrom / 3 | Gestufte Passage mit drei blauen Feldern. Vollständige Wegabdeckung ist durch Feldanzahl nicht belegt. |
| 05 | Kompasskreuz / 3 | Kreuzarme und zentrale Pfeilflächen. Fehlwege brauchen Rückweg; notwendige Durchquerung separat prüfen. |
| 06 | Pfeilspirale / 3 | Geschlossene Gänge mit L/T, Sandtasche und unmarkiertem Tunnelpaar. Inneres Ende ist mit der Zielkammer verbunden. |
| 07 | Die Staffel / 4 | Vier ansteigende Kammern und Grün–Blau–Blau–Rot. Kleine Felder lassen sichtbare neutrale Flächen; Pflichtwirkung benötigt einen Wegnachweis. |
| 08 | Gegenstrom / 4 | Wasser beidseits von Rot, innere Reihen links-diagonal. Festhängefall geprüft; neutraler unterer Umweg geometrisch nachgewiesen. |
| 09 | Armageddon / 4 | Geschlossene Diamantinsel, Trennwand, acht Pfeilrichtungen. Eine Umrundung allein beweist keine Nutzung aller Sektoren; sichtbare Zwischenräume gesondert prüfen. |

Zum Zeitpunkt der obigen Bestandsaufnahme: Gesamt-PAR 27, Bestwertrevision 4; 761 Pfeilzellen, eine Sandfläche, zwei Wasserflächen und ein Tunnelpaar. Diese Mengen sind keine allgemeine Designvorgabe.

#### Nachprüfung: geführtes Pfeil-Armageddon, Revision 5

Die anschließende Überarbeitung behält alle neun IDs, Namen, Abschläge, Lochpositionen, Kameragrenzen und die PAR-Folge `2/2/2/3/3/3/4/4/4` bei. Die neue Fassung verwendet `arrow_armageddon_course_v5`; die bisherigen Rekorde bleiben unter ihren alten Schlüsseln gespeichert.

| Löcher | Gezielte Korrektur |
| --- | --- |
| 01 – Anschub | Symmetrischer Trichter und wandbündiges 6×4-Pflichtfeld; die vier diagonalen Auslaufpfeile bleiben Unterstützung. |
| 02 – Diagonaldrift | Untere Diagonalflanke schließt den neutralen Randweg. Die Treppenzellen bleiben achsenparallel; die neue Zweischlagroute verwendet höchstens 420 statt unzulässiger 430 px/s. |
| 03 – Seitenzug | Zwei vollständige 6×7-Querfelder zwischen passenden Schultern. Keine neutralen Grasstreifen entlang der Banden. |
| 04 – Wechselstrom | Drei klar geführte 64-Pixel-Hälse mit jeweils voller Pfeilabdeckung und ruhigen Zwischenstücken. |
| 05 – Kompasskreuz | Wandbündiger Kreuzungsbereich; Fehlwegpfeile führen zur Kreuzung zurück statt weiter in die Sackgasse. |
| 06 – Pfeilspirale | Pflichtstreifen reichen bis zu den Wänden. Die unbespielbare obere Restfläche entfällt; der innere Tunneleingang liegt bei `(808,100)` in der tatsächlichen Auslauflinie, sein unmarkierter Partner weiterhin bei `(872,100)`. |
| 07 – Staffel | Vier gleichmäßig gefasste Kammern mit je 4×4 Pflichtzellen und diagonal ansteigenden Übergängen; Grün–Blau–Blau–Rot bleibt. |
| 08 – Gegenstrom | Beide Wasserbecken schließen an die obere beziehungsweise untere Kontur an. Der frühere neutrale Grasweg unter dem Wasser ist gesperrt. Die roten Außenreihen bleiben wasserabgewandt, die Innenreihen zusätzlich links-diagonal. |
| 09 – Armageddon | Der weite Diamantraum mit verstreuten Pfeilinseln wird durch einen geschlossenen Zickzack-Korridor ersetzt. Acht aufeinanderfolgende kurze Vollbreitenfelder verwenden alle acht Richtungen; neutrale Zwischenkammern erlauben neues Anspielen. |

Die Fassung enthält 834 atomare Pfeilzellen, weiterhin genau eine Sandfläche, zwei Wasserflächen und ein Tunnelpaar. Gefällestärken, Reibung und die ausgeschaltete Flow-Unterstützung bleiben unverändert. Die Korrektur erfolgt über Bahngeometrie und Feldlage, nicht über unsichtbare Lenkhilfen oder Sonderphysik.

Die neuen Designregressionen prüfen Pflichtpassagen über kontinuierliche Querschnitte der tatsächlichen Kontur einschließlich Ballradius und Wandstärke. Für die Spirale kommen verbundene Trennwände und der Tunnelübergang hinzu; Wasser gilt nicht als durchspielbarer Weg. Zellzählungen werden nur noch als Bestandskontrolle verwendet, nicht als Beweis gegen Umgehungen. Bei der Schlussbahn wird jeder der acht Abschnitte einzeln abgesichert und in der echten Ballroute tatsächlich durchfahren.

Legale PAR-Routen, dosierte Mehrschlagrouten und ausgewählte Winkel-/Kraftabweichungen ergänzen die Geometrieprüfung. Die Querfelder werden mit schwachen und starken Bällen gegen die Banden geprüft; Gegenstrom sichert Zurückrollen, Überwinden und Freikommen von der mittleren Naht. Eine erfolgreiche Präzisionsroute ist weiterhin kein pauschaler Nachweis beliebiger Schlagtoleranz. Insbesondere die Pfeilspirale ist in PAR 3 reproduzierbar, besitzt aber noch keine breit abgesicherte Fehlertoleranz; das bleibt ein eigener Balancingpunkt.

Reproduzierbare Gesamtansichten: `tests/capture_arrow_harmony.gd` nach `.godot/arrow-harmony/`; Spielansichten und beide Kameraenden der vier breiten Bahnen: `tests/capture_arrow_armageddon.tscn`. Die neuen Tests liegen in `tests/arrow_intro_design_test.gd`, `arrow_middle_design_test.gd`, `arrow_late_design_test.gd` und `arrow_finale_design_test.gd` und gehören zur vollständigen Headless-Suite.

**Abnahme der Revision 5 am 08.09.2026:** 45 gültige Katalogressourcen; vollständige Headless-Suite mit **3023 Prüfungen, 0 Fehlern**. Alle neun Gesamtansichten sowie 13 echte Spiel-/Kameraansichten wurden geprüft, ohne weitere sichtbare Wandlücken oder HUD-Überdeckungen. Windows-Debug-Export nach `build/windows/PuttAndPixelPrototype.exe` und anschließender Starttest dieser EXE wurden erfolgreich beendet (Exitcode 0). Der bereits bekannte Zertifikatsspeicher-Hinweis der isolierten Windows-Prüfumgebung besteht weiterhin; lokale Tests, Rendering und Programmstart funktionieren.

### 10.3 Moderne Referenzbahnen

Alle neun sind im Datenmodell `TECHNICAL` und im Referenzkurs sichtbar. Die mehrfach verwendete Grundform ist für vergleichbare Lernvarianten ausdrücklich sinnvoll.

| ID | Name / PAR | Geprüfter Aufbau und maßgebliche Lehre |
| --- | --- | --- |
| `reference_gate_lane` | Referenz: Tor-Gerade / 1 | Symmetrische Achse, diagonales Tor und Zielschultern. Echte Diagonalen machen den Übergang klar lesbar. |
| `reference_gate_bumpers` | Basis 1: Dreifach-Bumper / 2 | Drei Kreise im gleichen Anlauf. Hindernisvariation ist auch bei gleicher Silhouette möglich. |
| `reference_gate_rotor` | Basis 1: Rotor / 2 | Ein Rotor als isolierte Lernaufgabe. Vorhandene eingefrorene Teststellung ersetzt keine Timingprüfung. |
| `reference_gate_slider` | Basis 1: Schiebetor / 2 | Ein Schiebetor. Offene Referenzstellung beweist nicht die vollständige Sperrung oder Erreichbarkeit im realen Zyklus. |
| `reference_gate_seesaw` | Basis 1: Wippe / 2 | Niedrige linke Einfahrt, Gewichtswechsel, Seitenbanden und hohe Sperrkante. Orientierung und Einbindung gemeinsam prüfen. |
| `reference_gate_hill` | Basis 1: Hügelpass / 2 | 12 × 4-Pfeilzellen, von beiden Außenseiten Rot–Blau–Grün zur Kuppe. Zusammenhängendes gespiegeltes Höhenprofil. |
| `reference_angle_lane` | Referenz: Winkel / 2 | Punktsymmetrische reine Konturaufgabe. Die Bahnform kann das vollständige Hindernis sein. |
| `reference_mos_lane` | Referenz: MOS-Kurve / 3 | Facettierte symmetrische Form, 4 × 4-Pfeile und Rotor. Symmetrie der Form ist nicht Symmetrie aller Kräfte. |
| `reference_gate_hill_hole` | Basis 1: Hügelloch / 2 | 7 × 7 radial nach außen gerichtete Zellen; Ziel mittig durch gemeinsamen Halbrasterversatz. |

Aktuell Gesamt-PAR 18. Die Einordnung als technische Referenz ist keine Garantie für nicht umgehbare Mechanismen in jeder Variante.

### 10.4 Labyrinth-Neun

Alle folgenden IDs haben den Präfix `labyrinth_nine_`. Alle neun verwenden dieselbe rechteckige Normkontur mit unterschiedlicher Innenführung. Zusammen enthalten sie 26 bewegliche Mechanismen.

| ID | Name / PAR | Geprüfter Aufbau | Schläge der bisherigen vereinfachten Testliste |
| --- | --- | --- | ---: |
| 01 | Die erste Schleuse / 5 | Wechselnde Riegel, Tor und Rotor. | 5 |
| 02 | Zickzack-Kammern / 5 | Versetzte Kammern, zwei Rotoren und ein Tor. | 5 |
| 03 | Wippen-Labyrinth / 5 | Gedrehte Wippe mit unterem Einstieg; Querwand und T-Anschlüsse schließen daneben. | **8** |
| 04 | Dreifachtor / 6 | Fünf Riegel, zwei Schiebetore und ein Rotor. | 6 |
| 05 | Diagonalfalle / 5 | Geschlossene, oben und unten versetzte Dreiecke; mittlerer Rotor im Weg oberhalb der unteren Spitze. | 4 |
| 06 | Drei Kammern / 5 | Horizontale Wippe, Tor und Rotor. | **6** |
| 07 | Kreuzwege / 5 | Rotor, Tor und aktuell horizontale Wippe in der letzten Wandöffnung vor dem Loch. | **6** |
| 08 | Das Getriebe / 7 | Tor, zwei Rotoren und diagonale Innenführungen. | 7 |
| 09 | Der große Irrgarten / 7 | Sechs Riegel, zwei Tore und ein Rotor. | 7 |

Aktuell Gesamt-PAR 50. Die Routen für 03, 06 und 07 liegen schon unter vereinfachten Bedingungen über PAR. Aktualisierung vom 10.09.2026: Die Diagonalfalle (05) ist mit aktiven Mechanismen nach 150 Physikticks Startwartezeit zweimal in vier Schlägen innerhalb PAR 5 bestätigt. Für die übrigen acht Bahnen bleibt ein vollständiger Live-Nachweis offen. Alle 54 untersuchten Startvarianten und die Grenzen des Nachweises stehen in [LABYRINTH_LIVE_PRUEFUNG.md](LABYRINTH_LIVE_PRUEFUNG.md).

### 10.5 Vier echte Prototypbahnen

| ID | Name / PAR | Geprüfter Aufbau und maßgebliche Lehre |
| --- | --- | --- |
| `reference_01` | S-Kurve an der Mühle / 4 | Normkontur, Wasser, Sand, 6 × 3 blaue Pfeile, Windmühle. Testlisten für 4/2 Schläge; Rotor wird zur Routenprüfung offen eingefroren. Pflichtwirkung von Wasser und Risiko-Mühle zusätzlich prüfen. |
| `classic_diamond_02` | Die Diamantenlinie / 3 | Rechteckige Normkontur mit geschlossener symmetrischer Diamantinsel. Breite untere und präzise obere Route für 3/2 Schläge getestet. |
| `double_gate_03` | Das Doppeltor / 4 | Drei versetzte Kammern und zwei Tore. Geometrische Routen für 4/3 Schläge bei offen fixierten Toren; gemeinsames Zeitfenster zusätzlich isoliert getestet. |
| `cannon_workshop_04` | Die Kanonenwerkstatt / 4 | Pflichtschalter, getrennte sichere/riskante Kanone, Maschinenwand und Landebereiche. Routen für 4/3 Schläge sowie Aufnahme, Flug, Landung und Reset getestet. |

Der ursprüngliche Prototypkurs hatte einschließlich seiner fünf Labore Gesamt-PAR 38 und Bestwertrevision 2. `reference_01` liegt in `data/holes/reference_hole_01.tres`; der Name „Referenz“ im Dateipfad macht diese Bahn nicht zu einer technischen Referenzbahn.

**Aktualisierung am 08.09.2026 – Revision 3:** Fünf eigenständige Kursfassungen ersetzen die Labore in der offiziellen Runde: Sandufer (PAR 3), Doppelhügel (3), Uferkehre (3), Panoramaweg (5) und Bogenpromenade (4). Damit besitzt der Prototypkurs neun echte Bahnen und Gesamt-PAR 33. Der Gesamtkatalog steigt auf 50 Bahnen: 36 echte und 14 technische. Die fünf ursprünglichen Labore bleiben unverändert für Mechanikregressionen verfügbar. Ihre Legacy-Ausnahmen gelten nicht für die neuen Kursfassungen. Diese verwenden geschlossene Normkonturen, reine atomare Pfeilfelder und im Fall der Bogenpromenade zwei echte Konturbögen. Der frühere Bestandscheck oben beschreibt weiterhin den Stand vor dieser Erweiterung. Aufbau, Prüfung und Aufnahmen sind in [PROTOTYPKURS.md](PROTOTYPKURS.md) dokumentiert.

### 10.6 Fünf ältere technische Labore

| ID | Name / PAR | Bewusst beibehaltene Versuchsanordnung |
| --- | --- | --- |
| `allround_test` | Allround-Testloch / 4 | Fünf freie Rechteckwände, je Sand/Wasser/Legacy-Gefälle und eine Windmühle. |
| `slope_lab` | Gefälle-Labor / 6 | Vier freie Außenwände und acht alte Gefälleflächen für Richtungsvergleich. |
| `flow_test` | U-Flussbahn / 2 | Elf Rechteckbanden, fünf Flow-Segmente mit Mindest-/Maximaltempo, Ausrichtung und Zentrierung. Keine Vorlage für reine Gefällebahnen. |
| `scroll_test` | Scroll-Testbahn / 6 | Sieben Rechteckwände, zwei alte Gefälleflächen, Sand und zweiachsiges Scrolling im 32-Pixel-Bahnraster. |
| `curve_lab` | Kurven-Labor / 5 | Vier freie Außenwände, drei Kreise und vier 8-Pixel-Bögen zur isolierten Kollisionsprüfung. |

### 10.7 Befunde der Erstprüfung und heutiger Status

Die folgende Liste dokumentiert den Stand vor den Nachprüfungen in 10.1 und 10.2. **Punkte 1, 2 und 4 sind mit Pfeil-Armageddon Revision 5 behoben:** Die Wasserbecken schließen an die Kontur an, sämtliche Pfeil-PAR-Testschläge liegen im legalen Bereich 78–420 px/s, und kontinuierliche geometrische Prüfungen ersetzen die reine Kernfeldzählung. Punkt 5 wurde durch gesonderte Klassik- und Pfeilroutentests teilweise verbessert; deren konkret getestete Toleranzen sind kein allgemeiner Nachweis für sämtliche Bahnen. Die Labyrinth- und allgemeinen Validatorgrenzen bleiben offen.

1. **Neutraler Umweg beim Gegenstrom:** Unteres Wasser endet bei `y=272`, untere Wandmittellinie liegt im Bereich `x=560…632` bei `y=296`. Es bleiben 22 Pixel lichte Fläche bis zur Wandinnenkante. Die Linie `(220,70) → (320,200) → (500,286) → (780,286) → (960,286)` bleibt innerhalb der Kontur und meidet alle Pfeil- und Wasserflächen. Sie wurde geometrisch in höchstens 1-Pixel-Schritten unter Berücksichtigung des Ballradius geprüft; kleinster Abstand zur Wandmittellinie: 10 Pixel, erforderlich: mehr als 7. Dies widerlegt die vollständige Wegepflicht, ist aber keine neu kalibrierte Schlagroute.
2. **Unzulässige PAR-Testkraft:** Die Diagonaldrift verwendet in `tests/run_tests.gd` einen Schlag mit 430 px/s; der Standardcontroller endet bei 420. Die Bahn ist damit nicht als unlösbar bewiesen, aber dieser Nachweis muss durch eine legale Route ersetzt werden.
3. **PAR-Lücke im Labyrinth:** Wippen-Labyrinth, Drei Kammern und Kreuzwege haben Testlisten über PAR. Zudem friert `_simulate_hole_route()` Mechanismen ein; `labyrinth_safe` deaktiviert Rotor-/Torkollisionen und Wippen-Stirnsperren. Das belegt nur einen vereinfachten Grundweg.
4. **Zu starke Kernfeld-Prüfmeldung:** `_test_arrow_armageddon_course()` zählt Zellen in vordefinierten Rechtecken. Die Meldung „nicht umgehbar“ ist kein topologischer Nachweis. Die frischen Gesamtansichten zeigen insbesondere bei Staffel und Armageddon neutrale Zwischenräume, deren Umgehungswirkung gezielt geprüft werden muss.
5. **Ideallinie und sichere Route sind nicht gleich:** `_simulate_hole_route()` startet den Ball direkt und liefert Einlochen zurück. Er prüft weder generell zulässige Kraft, Cursorzielbarkeit, PAR-Grenze noch Toleranz. Klassik 2/3 besitzen präzise Ass-Linien statt nachgewiesener robuster Zweischlagwege; Klassik 4/5 verwenden identische sichere/riskante Listen. Das ist kein Beweis schlechter Spielbarkeit, aber eine klare Beleggrenze.
6. **Katalogprüfung deckt nicht alle Designregeln ab:** Sie prüft grundlegende Kontur-, Raster-, Bounds- und ID-Regeln. Sie garantiert weder Start–Ziel-Erreichbarkeit noch Hindernisrelevanz, Umgehungsfreiheit, komplette Bogen-/Mechanismusausdehnung oder allgemeine Flächenüberlagerungsfreiheit. Auch reine Gefällewerte `30/0/0/0/0` sind nicht vollständig im allgemeinen Pfeilvalidator erzwungen.
7. **Bildprüfung braucht aktuelle Inhalte:** Die vorhandenen Standard-Capture-Skripte liefern überwiegend Start-/Endkamera; einzelne ältere Bilder sind leer oder überholt. Für diesen Bestandscheck wurden alle 45 Gesamtansichten neu gerendert und betrachtet. Spielgröße, HUD und aktive Mechanismusphasen bleiben zusätzliche Prüfungen.

Die noch nicht behobenen Punkte bleiben ein Arbeitsvorrat für spätere Bahn- und Testkorrekturen. Die ursprüngliche Bestandsprüfung selbst hat keine Bahnressourcen, PAR-Werte oder Kursrevisionen verändert; anschließende Kursänderungen sind in den Nachprüfungen getrennt dokumentiert. Die Wippenkorrektur konkretisiert M02: Rückprall an gesperrten Stirnkanten und Freigabe erst nach ausreichendem Absenken statt eines beidseitig offenen Zwischenzustands.

## 11. Quellen im Projekt und Prüfkommandos

Die Regeln fassen die bisherigen Entscheidungen zusammen; reale Systemmaße werden hier nicht als verbindliche Spielmaße übernommen.

| Quelle | Wofür sie maßgeblich ist |
| --- | --- |
| [MINIGOLF_BAHNEN_RECHERCHE.md](MINIGOLF_BAHNEN_RECHERCHE.md) | Korridor/Zielfeld, eine dominante Aufgabe, Archetypen, ausdrücklich vorläufige Breitenhypothesen; historische Bestandsbeschreibung. |
| [GAME_DESIGN_GRUNDDOKUMENT.md](GAME_DESIGN_GRUNDDOKUMENT.md) | Designziele, nachvollziehbare Physik, bisherige Kurs- und Mechanikentscheidungen. |
| [Lochkatalog](data/holes/hole_catalog.tres) und [Kurskatalog](data/course_catalog.tres) | Vollständiger geprüfter Bestand und Zuordnung. |
| [LaneOutlineDefinition](src/lane_outline_definition.gd), [WallTileDefinition](src/wall_tile_definition.gd), [HoleDefinition](src/hole_definition.gd) | Kontur, Raster, zwölf Wandstücke, gemeinsames Netz und Grenzen der Datenvalidierung. |
| [WallDefinition](src/wall_definition.gd), [HoleRuntime](src/hole_runtime.gd), [HoleOverlay](src/hole_overlay.gd) | Kreis-/Bogenformen, Aufbau, Zeichnung, Flächenreihenfolge und Fahne. |
| [ArrowTileDefinition](src/arrow_tile_definition.gd), [SurfaceZone](src/surface_zone.gd), [Ball](src/ball.gd) | Zellmaße, Farben, Kräfte, Zone am Ballzentrum, Ruheverhalten und Tunneltransfer. |
| [ObstacleDefinition](src/obstacle_definition.gd), [Wippe](src/seesaw_obstacle.gd), [TunnelDefinition](src/tunnel_definition.gd) | Drehung, Vorzugsstellung, Seiten-/Stirnkollision und Übergänge. |
| [Schlagsystem](src/shot_controller.gd), [RoundSession](src/round_session.gd), [CourseDefinition](src/course_definition.gd) | Erreichbare Schlagkraft, dynamisches Limit und Bestwertrevisionen. |
| [tests/run_tests.gd](tests/run_tests.gd) | Mechanikregressionen, konkrete Routenlisten und die oben beschriebenen Prüfgrenzen. |

Die folgenden Befehle werden im Projektverzeichnis ausgeführt. Sie prüfen den bestehenden Katalog und die bestehenden Tests; zusätzliche Designnachweise aus Abschnitt 9 bleiben erforderlich.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/validate_catalog.gd
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn
```
