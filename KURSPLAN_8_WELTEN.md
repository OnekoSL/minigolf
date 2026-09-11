# Acht Welten – Kurs- und Bahnplanung

Stand: 11.09.2026. Status: als erste spielbare Kursfassung umgesetzt. [Umsetzungsbericht und Prüfgrenzen](ACHT_WELTEN_UMSETZUNG.md) sowie [konkrete Bahnblätter](BAHNBAUPLAENE_8_WELTEN.md) beschreiben den aktuellen Stand. Die folgenden Konzeptkarten bleiben die gestalterische Grundlage; nicht jede Risikoidee ist bereits separat abgenommen.

## 1. Auftrag und Planungsrahmen

Die fünf bisherigen Kurse werden durch acht thematische Kurse ersetzt. Der Nutzer wünscht **Orte und Welten** als Themen und hat die Umsetzung dieses Plans beauftragt. Die Kursfassung enthält **neun Bahnen je Kurs**: 72 unterschiedliche reguläre Bahnen, ohne doppelte Verwendung zwischen offiziellen Kursen.

Jede Welt erhält ein sichtbares Ortsmotiv, einen spielerischen Schwerpunkt und eine Lernfolge. Alle Kurse sollen direkt wählbar bleiben; die Reihenfolge unten ist eine Schwierigkeitsempfehlung. Jeder Kurs führt seine zentralen Mechaniken selbst ein.

Die Planung ersetzt das frühere Ziel von sechs Kursen im Grunddokument. Der offizielle Katalog ist inzwischen auf die acht Welten umgestellt. Der folgende Bestandsabschnitt dokumentiert den Ausgangspunkt vor diesem Austausch.

## 2. Verifizierter Ausgangspunkt und Umfang

Grundlage sind [Kurskatalog](data/course_catalog.tres), [Lochkatalog](data/holes/hole_catalog.tres) und die zugehörigen Ressourcen, nicht die älteren Bestandszahlen in historischen Dokumenten.

| Bisheriger Kurs | Reguläre Bahnen | Technische Bahnen | Verwendung im Entwurf |
| --- | ---: | ---: | --- |
| Klassische Neun | 9 | 0 | Stadtpark und Schlossgarten |
| Pfeil-Armageddon | 9 | 0 | Bergpass, Tempelruinen und Sternwarte |
| Referenzbahnen | 0 | 9 | Technische Referenzen behalten; offizieller Kurs entfällt beim Austausch |
| Labyrinth-Neun | 9 | 0 | Schlossgarten, Uhrwerkfabrik und Tempelruinen; Wege stark überarbeiten |
| Prototypkurs | 9 | 0 | Dünenküste, Mühlental, Bergpass, Schlossgarten und Sternwarte |
| Weitere Labore außerhalb der Kursfolgen | 0 | 5 | Für Entwicklung und Regressionen behalten |
| **Bestand** | **36** | **14** | **50 registrierte Bahnen, fünf auswählbare Kurse** |

**Arbeitsbudget: 36 Überarbeitungen + 36 Neubauten = 72 reguläre Bahnen.** Die neun Referenzbahnen zählen nicht als fertige Produktionsbahnen. Eine Referenz kann einen Neubau anleiten, wird dadurch aber nicht unverändert zum Kursloch.

Jede der 36 regulären Bestandsbahnen ist unten genau einmal als Kandidat zugeordnet. Überarbeitung umfasst Weg, Schwierigkeit, Einbindung und Thema; eine bloße Umbenennung genügt nicht. Erweist sich eine Vorlage als ungeeignet, wird dieser Platz neu gebaut: Die 72 bleiben das Ziel, die Anzahl der Neubauten steigt entsprechend. Mit den 14 erhaltenen technischen Bahnen ergäbe sich ein Katalog von 86 Bahnen, sofern keine zusätzlichen Altvarianten registriert bleiben.

## 3. Die acht Kurse

| Nr. | Welt / vorgeschlagene Kurs-ID | Ortsmotiv und Darstellung | Spielerischer Schwerpunkt | Schwierigkeit | Überarbeiten / Neu |
| --- | --- | --- | --- | --- | ---: |
| 1 | **Stadtpark** / `stadtpark_course` | Helle Steinbanden, Wiesen, Blumenbeete und Pavillon | Zielen, Dosieren, einfache Banden und Bögen | Einstieg | 6 / 3 |
| 2 | **Dünenküste** / `duenenkueste_course` | Sandfarbene Einfassungen, Strandgras, Meer und Leuchtturm | Sand, Wasserabstand und kontrolliertes Ausrollen | Leicht–mittel | 3 / 6 |
| 3 | **Mühlental** / `muehlental_course` | Holz, Bachlauf, Mühlen und kleine Schleusen | Einzelne bewegliche Hindernisse und ruhiges Timing | Leicht–mittel | 2 / 7 |
| 4 | **Bergpass** / `bergpass_course` | Felskulisse, Höhenlinien, Kehren und Gipfelstation | Gefälle lesen, Kuppen überwinden und Tempo abbauen | Mittel | 6 / 3 |
| 5 | **Schlossgarten** / `schlossgarten_course` | Hecken, helle Mauern, Brunnen und symmetrische Höfe | Wege vorausplanen, Bandenfolgen und Abkürzungen | Mittel–anspruchsvoll | 6 / 3 |
| 6 | **Uhrwerkfabrik** / `uhrwerkfabrik_course` | Messing, dunkle Ziegel, Zahnräder und Wartungsbuchten | Tore, Rotoren und Wippen in kurzen Mechanikketten | Anspruchsvoll | 6 / 3 |
| 7 | **Tempelruinen** / `tempelruinen_course` | Warmer Stein, überwachsene Höfe, Säulen und dunkle Öffnungen | Tunnel, getrennte Kammern und räumliche Orientierung | Anspruchsvoll | 2 / 7 |
| 8 | **Sternwarte** / `sternwarte_course` | Nachtblau, Kupfer, Sternkarten und Kuppeln | Kanonenflug, Landungen und Kombination bekannter Aufgaben | Fortgeschrittenes Finale | 5 / 4 |
| | **Gesamt** | | | | **36 / 36** |

Die Ortsmotive verändern keine physikalischen Bedeutungen: Pfeilfarben bleiben den drei Gefällestärken zugeordnet, Wasser bleibt Wasser, Sand bleibt Sand. Auch in der Sternwarte gilt die normale Ballphysik. Wind, Gezeiten, Eis, variable Schwerkraft oder neue Plattformmechaniken sind für diesen Entwurf nicht erforderlich.

## 4. Gemeinsame Struktur der neun Bahnen

- **1–2: Ankommen.** Kernaufgabe einzeln, überschaubare Kontur, großzügige Anspiel- und Auslaufbereiche.
- **3: Erste Anwendung.** Bekannte Aufgabe mit verändertem Winkel oder Tempo.
- **4–6: Variationen.** Neue Wegentscheidung, kurze Entlastungsbahn und erste Kombination; Schwierigkeit steigt nicht auf jeder Bahn.
- **7–8: Vertiefung.** Anspruchsvollere Ausführung und bewusst erkennbare Risikoalternative.
- **9: Abschluss.** Prägnantes Motiv der Welt, höchstens drei bereits eingeführte Teilaufgaben. Länge allein ist kein Finale.

Als Startbudget je Kurs mindestens sechs kompakte Bahnen und höchstens drei längere Bahnen mit Kamerafahrt anstreben. Kompakt bedeutet: Die relevante Aufgabe ist im tatsächlichen Spielfeld neben dem HUD erfassbar. Lange Bestandsbahnen dürfen dafür gekürzt oder neu angeordnet werden.

Die folgenden Tabellen sind **Konzeptkarten**, keine geometrischen Baupläne. „Weg“ beschreibt die beabsichtigte sichere Route; sie ist noch nicht simuliert oder gespielt. **PAR wird erst nach dem Wegentwurf geschätzt und nach aktiver Spielprüfung festgelegt.** Es gibt noch keine belastbare PAR-Summe. So werden insbesondere alte Labyrinthwerte nicht ungeprüft übernommen.

`Neu` bezeichnet einen neuen Bahnplatz; eine angegebene Ressourcen-ID bezeichnet die zu überarbeitende Vorlage. Die Kennungen K1-01 bis K8-09 sind Planungskennungen, keine bereits registrierten Ressourcen-IDs.

## 5. Bahnfolge je Welt

### K1 – Stadtpark

Profil: überwiegend statisch, freundlich und auf Anhieb lesbar. Kreise und Bögen prägen die Welt; Gefälle wird sparsam eingesetzt. Keine zeitabhängige Pflichtpassage.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K1-01 | Am Parkeingang | Freie Gerade; vom Abschlag kontrolliert in das breite Zielfeld putten. | Faire Ass-Aufgabe genügt. | `classic_nine_01` |
| K1-02 | Der Findling | Einzelnen Kreis umspielen; seitlich vorlegen, dann zum Loch. | Präzise Bandenlinie am Kreis vorbei. | `classic_nine_02` |
| K1-03 | Blumenbogen | Durch einen angeschlossenen Bogen in die Zielgerade spielen; ruhiger Auslauf. | Bogen und Ziel in einer durchgehenden Linie. | `classic_nine_03` |
| K1-04 | Am Pavillon | Den vollflaechig roten Kreis gegen die nach links gerichtete Steigung zum mittigen Loch anspielen. | Faire Ass-Aufgabe mit dosierter Kraft. | `classic_nine_04` |
| K1-05 | Kieselweg | Zwei versetzte Kreise über breite Zwischenpositionen passieren. | Engere diagonale Linie durch beide Kreise. | `classic_nine_05` |
| K1-06 | Gartenspirale | Vom aeusseren Abschlag nach oben und durch die gerundete Spirale bis zum Loch in der Mitte spielen. | Boegen mit Bandenanschlaegen in weniger Schlaegen verbinden. | `classic_nine_06` |
| K1-07 | An der Parkbank | L-Kontur mit 45-Grad-Diagonalen an beiden aeusseren Umlenkecken; vorlegen und in den Zielarm spielen. | Einbandenschlag um die Ecke. | Neu |
| K1-08 | Zwei Alleen | Eine geschlossene Beetinsel auf dem breiten äußeren Weg umspielen. | Kürzerer enger Innenweg um dieselbe Insel. | Neu |
| K1-09 | Pavillonrunde | Außenbogen und anschließende Bandenlinie verbinden; breite Zwischenablage. | Beide bekannten Aufgaben in einem Schlag verbinden. | Neu |

### K2 – Dünenküste

Profil: Wasser als sichtbare Grenze und Sand als planbarer Tempofaktor. Sichere Routen benötigen keine Wasserberührung. Das Meer außerhalb der Bahn ist Dekoration; gefährliches Wasser innerhalb bleibt eindeutig erkennbar.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K2-01 | Strandzugang | Einen kurzen Sandstreifen mit ausreichender Kraft queren; großer Auslauf. | In einem Zug bis zum Loch. | Neu |
| K2-02 | Sandufer | Sandpassage dosieren, vor dem Wasser ablegen und ins Zielfeld abbiegen. | Enger am Ufer in die Zielrichtung rollen. | `prototype_04` |
| K2-03 | Buhnenweg | Versetzte statische Riegel entlang des Ufers in zwei Abschnitten passieren. | Bandenfolge durch beide Öffnungen. | Neu |
| K2-04 | Dünenmulde | Flaches Gefälle nutzen und im Sand vor der Zielkammer abbremsen. | Sand mit höherem Tempo durchspielen. | Neu |
| K2-05 | Muschelbucht | Kurze kreisförmige Insel umspielen; breite trockene Ablage am Außenrand. | Schmalere Linie zwischen Insel und Wasser. | Neu |
| K2-06 | Uferkehre | Abfahrt, quer gespielte Kehre und unterstützten Rücklauf kontrollieren. | Kehre ohne Zwischenstopp treffen. | `prototype_06` |
| K2-07 | Bogenpromenade | Durch den konzentrischen Wendekanal bis zum rückwärtigen Ziel spielen. | Kurve mit präziser Kraft durchrollen. | `prototype_08` |
| K2-08 | Hafenmauer | Sand queren und eine Bande zum trockenen Zielarm nutzen. | Sandquerung und Bande verbinden. | Neu |
| K2-09 | Am Leuchtturm | Sandanlauf, Uferkehre und breites Zielplateau als Abschluss verbinden. | Engere Küstenlinie spart eine Ablage. | Neu |

### K3 – Mühlental

Profil: Timing ohne Hektik. Vor jedem Mechanismus gibt es eine sichere Anspielzone; frühe Bahnen enthalten jeweils nur einen Mechanismustyp. Bäche werden durch normale Wasserflächen dargestellt.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K3-01 | Erste Mühle | Zwei versetzte Rotoren mit geschützter Zwischenablage passieren. | Durchfahrt direkt bis zum Loch. | Neu |
| K3-02 | Bachschleuse | Einzelnes Schiebetor beobachten, Öffnung abwarten, hindurchputten. | Längere Direktlinie im gleichen Zeitfenster. | Neu |
| K3-03 | Kippsteg | Wippe über die niedrige Stirnseite betreten, kippen lassen und ausrollen. | Dosierter Übergang bis ins Zielfeld. | Neu |
| K3-04 | Mühlteich | Ruhige statische Bogenbahn am Wasser; sichere äußere Ablage. | Engere Bandenlinie am Teich. | Neu |
| K3-05 | S-Kurve an der Mühle | S-Weg vorlegen, Rotorfenster nutzen und hinter der Mühle stoppen. | Kurve und Rotorpassage verbinden. | `reference_01` |
| K3-06 | Schleusenbogen | Nach einem Tor in eine Bogenkammer rollen; Tor und Ziel getrennt anspielen. | Mit passendem Tempo durch Tor und Bogen. | Neu |
| K3-07 | Das Doppeltor | Zwei Tore mit sicherem Zwischenraum nacheinander passieren. | Beide Öffnungen in einer Durchfahrt nutzen. | `double_gate_03` |
| K3-08 | Mühlensteg | Wippe und danach Rotor in getrennten Abschnitten überwinden. | Auslauf der Wippe im Rotorfenster nutzen. | Neu |
| K3-09 | Feierabendrunde | Rotor, Schleuse und Zielbogen mit zwei geschützten Ablagen verbinden. | Zwei Teilaufgaben pro Schlag verbinden. | Neu |

### K4 – Bergpass

Profil: klare Höhenprofile und reine Gefällephysik. Grün vor Blau vor Rot einführen; Pfeile zeigen immer bergab. Keine echten Höhenebenen, Sprünge oder Absturzphysik nötig.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K4-01 | Talstation | Flaches Pflichtfeld als Anschub nutzen, anschließend auf Grün stoppen. | In einem Zug bis ins Ziel. | `arrow_armageddon_01` |
| K4-02 | Querhang | Diagonalgefälle mit seitlich versetztem Anspiel ausgleichen. | Direkte Querung ins Zielfeld. | `arrow_armageddon_02` |
| K4-03 | Hangkante | Seitlichen Zug durch passende Vorhalteposition kontrollieren. | Engere Linie mit weniger Vorlegen. | `arrow_armageddon_03` |
| K4-04 | Doppelhügel | Zwei Kuppen mit getrennten Anspielräumen überwinden. | Beide Kuppen bei genauer Kraft verbinden. | `prototype_05` |
| K4-05 | Berghütte | Kurze ebene Kehre als Entlastung; vor der Zielgeraden ablegen. | Einbandenlinie durch die Kehre. | Neu |
| K4-06 | Sattelwechsel | Gegensinnige Gefälleabschnitte nacheinander aus neutraler Ablage spielen. | Den Wechsel ohne Zwischenstopp kontrollieren. | `arrow_armageddon_04` |
| K4-07 | Passkreuz | Mehrere Hangrichtungen über zentrale Anspielbereiche lesen und passieren. | Kürzere diagonale Folge durch das Kernfeld. | `arrow_armageddon_05` |
| K4-08 | Gipfelkuppe | Steilen Aufstieg überwinden und auf breitem flachen Gipfelfeld stoppen. | Enger gefasstes Ziel direkt anspielen. | Neu |
| K4-09 | Passfahrt | Kuppe, seitlichen Hang und Rücklauf verbinden; Ablagen zwischen den Aufgaben. | Zwei Hangabschnitte mit einem Schlag. | Neu |

### K5 – Schlossgarten

Profil: geplante Wege und geometrische Präzision. Hecken rahmen sichtbare Normwände, verdecken aber keine Kollision. Alte Labyrinthvorlagen werden hier zu überwiegend statischen Aufgaben umgebaut; schnelle Mechanikketten gehören zur Fabrik.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K5-01 | Vorhof | Geschlossene Brunneninsel auf breitem Weg umspielen. | Präzise Bandenlinie um die Insel. | Neu |
| K5-02 | Diamantgarten | Diamantinsel über die breite Flanke umspielen und zum Ziel vorlegen. | Engere obere Flanke mit weniger Schlägen. | `classic_diamond_02` |
| K5-03 | Heckengassen | Zwei erzwungene Seitenwechsel mit gut sichtbaren Durchgängen spielen. | Diagonale Bandenfolge verbindet die Wechsel. | `classic_nine_07` |
| K5-04 | Kreisallee | Versetzte Kreise im Korridor aus breiten Ablagen passieren. | Präzise durchgehende Linie zwischen den Kreisen. | `classic_nine_08` |
| K5-05 | Brunnenhof | Kurze symmetrische Winkelaufgabe als Ruhepunkt des Kurses. | Faire Ass-Linie über eine Bande. | Neu |
| K5-06 | Gartenkammern | Drei kurze Kammern mit statischen versetzten Öffnungen lesen. | Je zwei Öffnungen mit einem Schlag. | `labyrinth_nine_02` |
| K5-07 | Dreieckshof | Geschlossene Diagonalinseln in wechselnder Richtung umspielen. | Präzise Reflexionen an den Diagonalen. | `labyrinth_nine_05` |
| K5-08 | Rückweg zum Schloss | Haarnadel vollständig bis zum Ziel am Rücklaufende durchspielen. | Wendebogen ohne zusätzliche Ablage nutzen. | `classic_nine_09` |
| K5-09 | Schlossparterre | Inselwahl, Seitenwechsel und Schlussbogen kombinieren. | Engerer Innenweg spart einen Richtungswechsel. | Neu |

### K6 – Uhrwerkfabrik

Profil: kurze, lesbare Mechanikketten. Die langen Labyrinthvorlagen werden deutlich entzerrt und gegebenenfalls gekürzt. Alte PAR-Werte und Tests mit ausgesetzten Kollisionen gelten nicht als Abnahme dieser neuen Fassungen.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K6-01 | Werkstor | Ein Schiebetor aus breiter Wartungsbucht passieren; übrige Mechanismen entfernen. | Direkt hinter dem Tor einlochen. | `labyrinth_nine_01` |
| K6-02 | Zahnradsaal | Einzelnen Rotor in einer kurzen Pflichtöffnung passieren. | Rotorfenster für die längere Ziellinie nutzen. | Neu |
| K6-03 | Lastenwippe | Gedrehte Wippe mit klarer niedriger Einfahrt und freiem Auslauf überwinden. | Exakt dosiert bis in den Zielraum rollen. | `labyrinth_nine_03` |
| K6-04 | Pausenhof | Kurze statische Bandenaufgabe zwischen Maschinenkulissen. | Einbanden-Ass. | Neu |
| K6-05 | Drei Werkhallen | Wippe, Tor und Rotor einzeln über geschützte Zwischenräume passieren. | Zwei aufeinanderfolgende Abschnitte verbinden. | `labyrinth_nine_06` |
| K6-06 | Schichtwechsel | Drei Tore in kurzen Kammern mit abgestimmten, beobachtbaren Phasen. | Mehrere Öffnungen in einem Zeitfenster nutzen. | `labyrinth_nine_04` |
| K6-07 | Kreuzverteiler | Kreuzweg mit Tor und Rotor lesen, abschließende Wippe längs anspielen. | Die mittlere Ablage durch genaue Durchfahrt sparen. | `labyrinth_nine_07` |
| K6-08 | Schwungrad | Rotorpassage, danach kurze Gefälleabfahrt in sicheren Auffangraum. | Rotorfenster und kontrollierte Abfahrt verbinden. | Neu |
| K6-09 | Das große Uhrwerk | Verborgene Lochpaare im drehenden Zahnrad erkunden und den Zielarm der vierarmigen Kreuzung erreichen. | Den passenden Durchlass für die direkte Ziellinie treffen. | `labyrinth_nine_08` |

### K7 – Tempelruinen

Profil: räumliche Entdeckung mit sichtbaren, unmarkierten Tunnelöffnungen. Das erste Tunnelpaar ist ungefährlich erkundbar; spätere Kammern erhöhen die Komplexität. Die Zuordnung bleibt gemäß den Bahnregeln ohne Paarfarben oder Verbindungslinien.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K7-01 | Verborgener Durchgang | Ein Tunnelpaar in zwei einfachen Räumen durchspielen; großer sicherer Auslauf. | Austrittsrichtung direkt zum Loch ausrichten. | Neu |
| K7-02 | Säulenhof | Zwei statische Säulen umspielen und vor dem Tunnel kontrolliert ausrichten. | Bandenlinie durch Säulen und Tunnel verbinden. | Neu |
| K7-03 | Kammerwechsel | Tunnel nach einem Winkel anspielen; Richtungserhalt für den Ausgang nutzen. | Von der ersten Bande direkt bis ins Zielfeld. | Neu |
| K7-04 | Sonnenhof | Kurzer offener Bogen ohne Tunnel als Entlastung. | Präzise Ass-Linie durch den Bogen. | Neu |
| K7-05 | Tempelspirale | Pflichtspirale bis zum inneren Tunnel und weiter in die getrennte Zielkammer spielen. | Längere Abschnitte der Spirale durchrollen. | `arrow_armageddon_06` |
| K7-06 | Zwei Portale | Zwei Tunnelpaare nacheinander erkunden; jeder Ausgang besitzt sichere Ablage. | Ausrichtung beim ersten Eintritt erleichtert den zweiten. | Neu |
| K7-07 | Versunkener Hof | Tunnelaustritt auf trockenem Podest, anschließend Uferbogen um Wasser. | Engere Uferlinie nach der sicheren Landung. | Neu |
| K7-08 | Wächterkammer | Rotor vor dem Tunnel aus Wartezone passieren; Ausgang bleibt mechanikfrei. | Rotor und Tunneleintritt in einem Schlag. | Neu |
| K7-09 | Das innere Heiligtum | Irrgarten auf drei lesbare Kammern kürzen; Tunnel verbindet letzte Kammer und Ziel. | Bandenfolge verkürzt Kammerdurchfahrt. | `labyrinth_nine_09` |

### K8 – Sternwarte

Profil: Ballmaschinen und präzise Landungen vor einer ruhigen Nachtkulisse. Die Kanonen sind feste Mechanismen; der Ballflug wird nicht manuell gesteuert. Keine neue Mechanik erst auf der Schlussbahn einführen.

| Platz | Arbeitstitel | Hauptaufgabe und geplanter Weg | Option für Geübte | Herkunft |
| --- | --- | --- | --- | --- |
| K8-01 | Erste Flugbahn | Freie Kanone anspielen; auf großem trockenen Zielfeld landen und nachputten. | Anfahrt ohne Zwischenablage. | Neu |
| K8-02 | Startfreigabe | Gut sichtbaren Schalter passieren, freigeschaltete Kanone längs anspielen. | Schalter und Einfahrt in einem Schlag. | Neu |
| K8-03 | Planetenstaffel | Aufeinanderfolgende Pflichtgefälle mit neutralen Ablagen kontrollieren. | Mehrere Felder in einer durchgehenden Linie. | `arrow_armageddon_07` |
| K8-04 | Panoramadeck | Zwei geometrische Richtungswechsel; Mechanikpause mit Blick auf die Kuppeln. | Längere Bandenlinie spart eine Ablage. | `prototype_07` |
| K8-05 | Gegenbahn | Gegenläufiges Gefälle am Wasser durch klare Einfahrt und ruhigen Auslauf überwinden. | Präzisere direkte Querung. | `arrow_armageddon_08` |
| K8-06 | Kanonenlabor | Schalter und Wahl zwischen sicherer und riskanter Kanone; getrennte Landezonen. | Engere Einfahrt mit günstigerer Zielablage. | `cannon_workshop_04` |
| K8-07 | Doppelstart | Zwei feste Kanonen mit sicherem Anspielraum zwischen den Flügen verbinden. | Landung auf der Anspiellinie der zweiten Kanone. | Neu |
| K8-08 | Sternenbogen | Bisherige lange Pfeilfolge auf drei prägnante Gefälleaufgaben mit Ruheflächen verdichten. | Zwei Abschnitte ohne Stopp durchspielen. | `arrow_armageddon_09` |
| K8-09 | Zur großen Kuppel | Schalter, Kanonenflug und bekannte Gefällekurve zum breiten Schlussgrün verbinden. | Präzise Anfahrt und Ausrolllinie sparen eine Ablage. | Neu |

## 6. Vom Konzept zum baubaren Bahnblatt

Vor jeder `.tres`-Änderung wird die entsprechende Konzeptkarte mit folgenden Angaben konkretisiert. Erst dieses ausgefüllte Blatt ist der Bauauftrag:

| Feld | Erforderlicher Inhalt |
| --- | --- |
| Identität | Planungskennung, Zielkurs, Ressourcen-ID, Herkunft, Status |
| Hauptaufgabe | Ein Satz; Pflichtpassage und optionale Unterstützung ausdrücklich unterscheiden |
| Skizze | Kontur, Start, Ziel, Anspielräume, Zwischenablagen und komplette sichere Route |
| Maße | 16-Pixel-Raster, lichte Breiten mit Ballradius, Bogenanker, Platz für Ausläufe |
| Sichere Route | Geplante Schläge und Zwischenpositionen; daraus erster PAR-Vorschlag |
| Risikooption | Welche Ablage entfällt, welche Genauigkeit nötig ist, Folgen eines Fehlers |
| Mechanik | Typen, Phasen, Ein-/Ausfahrten, aktive Zwischenstellungen, Reset |
| Figuren | Erreichbare Kräfte je Golfer, insbesondere sichere Route für Mara |
| Fehlerfälle | Zu kurz, zu stark, schräger Kontakt, verpasstes Fenster, Wasser und Rücksetzung |
| Präsentation | Thema, Dekoration, Spielansicht und nötige Kameraausschnitte |
| Nachweis | Katalogprüfung, aktiver Spielweg, Winkel-/Kraft-/Zeittoleranz und aktuelle Aufnahmen |

Statusfolge: **Konzept → Weg und Skizze → Rohbau → aktive Spielprüfung → Themengestaltung → Kursabnahme**. Alle 72 Plätze besitzen inzwischen Geometrie, Themenzeichnung und automatisierte aktive PAR-Routen. Die konkrete menschliche Spiel- und Risikoabnahme bleibt gesondert; aktuelle PAR-Werte und ausgeführte Prüfungen stehen im Umsetzungsbericht.

## 7. Vorhandene Technik und zusätzlicher Produktionsbedarf

Die Bahnideen verwenden den vorhandenen Baukasten: Normwände, Kreise, Bögen, Sand, Wasser, atomare Gefälle, Rotoren, Schiebetore, Wippen, Tunnel sowie Schalter und Kanonen. Referenzen helfen bei Einzelmechaniken; insbesondere `reference_gate_seesaw`, `reference_gate_hill` und `reference_gate_hill_hole` bleiben technische Vergleichsfälle.

Die acht Themen verwenden inzwischen `CourseTheme` und acht Ressourcen unter `data/themes/`. `HoleDefinition.theme` bindet sie an; `HoleRuntime` und `HoleOverlay` zeichnen Umgebung und Banden daraus. Das ältere `garden_presentation` bleibt für historische Vergleichsfälle erhalten. Die Ballphysik enthält keine Themen-Sonderfälle.

Je Welt ein kleines wiederverwendbares Gestaltungspaket planen: Umgebungsfarben, Einfassungsmaterial, zwei bis drei Dekorationsgruppen und ein markantes Abschlussmotiv. Spielrelevante Kanten, Gefällefarben, Wasser und Fahne bleiben lesbar. Eine Welt braucht keine neue Physik, um einen eigenen Charakter zu erhalten.

## 8. Baufolge und Austausch der bisherigen Kurse

Die folgende Reihenfolge dokumentiert den ursprünglichen Arbeitsplan. Der erste technische Kursaustausch ist abgeschlossen; weitere Gestaltungs- und Spielabnahmen stehen im Umsetzungsbericht.

1. **Themen und Umfang abstimmen.** Die acht Welten, neun Plätze je Welt und die Herkunftszuordnung bilden den überprüfbaren Entwurf; Namen können sich noch ändern.
2. **Stadtpark als ersten vollständigen Kurs ausarbeiten.** Zuerst K1-01, K1-03 und K1-09 als einfache, mittlere und abschließende Musterbahn. Damit Bahnblatt, sichere Route, Gestaltung und Kameraprüfung erproben, dann die übrigen sechs bauen.
3. **Schwierige Machbarkeit früh prüfen.** Vor Serienbau K3-03 (Wippe), K6-05 (aktive Mechanikkette), K7-01 (Tunnelauslauf) und K8-02 (Schalter/Kanone) als Rohbau prüfen. Erkenntnisse in alle betroffenen Konzeptkarten übernehmen.
4. **Kurse in Lernreihenfolge fertigstellen.** Dünenküste, Mühlental, Bergpass, Schlossgarten, Uhrwerkfabrik, Tempelruinen, Sternwarte. Je Kurs erst Wege und Spielbarkeit, dann Gestaltung und finale Reihenfolge.
5. **Offiziellen Katalog auf acht fertige Kurse umstellen.** Neue Kurs-IDs aus der Übersicht verwenden, anfänglich Revision 1. Alte Kursbestwerte bleiben unter ihren bisherigen Schlüsseln gespeichert und werden nicht auf neue Lochfolgen übertragen. Bei späteren wertungsrelevanten Umbauten die jeweilige Revision erhöhen.
6. **Referenzen und Labore erhalten.** Technische Bahnen bleiben über die technische Übung erreichbar. Der Referenzkurs entfällt aus der offiziellen Auswahl. Bestehende Bahn-IDs und `.gd.uid`-Dateien beim Überarbeiten erhalten; abgelehnte Vorlagen nur nach Prüfung ihrer Test- und Ressourcenreferenzen ausmustern.

Die Umstellung erfordert später neue Kursressourcen, aktualisierte Kataloge und angepasste Kurs-/Menütests. Die vorhandene Kursauswahl paginiert drei Einträge pro Seite; acht Kurse benötigen drei Seiten mit 3/3/2 Einträgen. Übung und freies Spiel benötigen bei unverändert fünf Einträgen pro Seite 15 Seiten für 72 reguläre Bahnen. Eingabesperren, erste/letzte Seite und freie Neun-Loch-Folgen dabei mitprüfen.

Der Austausch kann in Entwicklungsschritten erfolgen; der abschließende veröffentlichte Stand enthält genau die acht neuen Kurse. Bestandsressourcen werden während dieser Planungsarbeit weder gelöscht noch umgeschrieben. Bestehende Generatoren, etwa für die Prototypbahnen, müssen beim späteren Umbau zusammen mit ihren Ausgaben angepasst werden.

## 9. Abnahmekriterien für die Umsetzung

- Acht Kurse mit jeweils neun eindeutigen regulären Bahnen; keine technischen Bahnen und keine doppelten offiziellen Bahnplätze.
- Jede Welt ist optisch erkennbar und bietet eine eigene Lernfolge. Wiederverwendung führt zu passenden Spielaufgaben, nicht zu bloßen Namensvarianten.
- Pro Bahn geschlossener, ballbreit geprüfter Spielweg und tatsächlich wirksame Pflichtaufgabe. Bewegliche Anschlüsse in End- und Zwischenstellungen prüfen.
- Sichere Route mit legalen Eingaben, aktiven Hindernissen und benannter Toleranz innerhalb des daraus festgelegten PAR; grundsätzliche Spielbarkeit mit allen vier Golfern.
- Keine Abnahme allein durch `validate()`, eingefrorene Mechanismen oder ideal kalibrierte Schläge. Die dokumentierten Lücken aus [LABYRINTH_LIVE_PRUEFUNG.md](LABYRINTH_LIVE_PRUEFUNG.md) gelten als Arbeitsbedarf bei den übernommenen Vorlagen.
- Neue Gesamtaufnahmen und Ansichten in tatsächlicher Spielgröße, bei langen Bahnen einschließlich Kameraenden und Zwischenpassagen. Themen dürfen keine Wirkflächen oder Kollisionen verdecken.
- Nach Spielcode-/Bahnänderungen vollständige Headless-Suite mit Exitcode 0 und `0 Fehler`; zusätzlich relevante aktive Spiel- und Sichtprüfungen nach [BAHNGESTALTUNG_REGELN.md](BAHNGESTALTUNG_REGELN.md). Windows-Export und Startprüfung bei Auslieferung mitführen.

**Prüfstand:** Bestandszuordnung und 72 Kursplätze sind geprüft. Geometrien, aktuelle PAR-Werte und technische Spielnachweise stehen in den verlinkten Bahnblättern und im Umsetzungsbericht. Menschliche Rundenzeiten und die vollständige Risikoabnahme bleiben offen.
