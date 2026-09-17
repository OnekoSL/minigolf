# Bahneditor

Der Titelbildschirm bietet **Bahneditor** und **Eigene Inhalte**. Der Editor läuft auch im Windows-Export, ohne Godot-Editor. Gebaut wird mit Maus und Tastatur; fertige Bahnen und Kurse verwenden die normale Spielsteuerung einschließlich Controller.

## Eine Bahn bauen

1. Mit **Neu** eine Rechteckbahn beginnen oder unter **Vorlage** eine reguläre Spielbahn als unabhängige Kopie öffnen.
2. Rechts Name, PAR, Bahngröße, Thema und Grundbelag einstellen. Textfelder mit Enter oder durch Verlassen bestätigen.
3. **Kontur / Eckpunkte** wählen: Punkte ziehen, auf eine Kante klicken, um einen Punkt einzufügen, oder mit **Kontur neu zeichnen** neu beginnen. Entf entfernt den gewählten Punkt. Geraden und Diagonalen folgen dem Normraster. Außenbanden entstehen automatisch.
4. Mit **Außenbogen** eine Konturkante anklicken. Nach Auswahl lässt sich ihre Auswölbung ändern; die beiden Anker bleiben erhalten. Negative Werte wechseln die Seite der Auswölbung. Die Bahngröße muss die Kurve aufnehmen.
5. Wände, Kreise, Innenbögen, Beläge und Gefälle einsetzen. **Pfeile malen** zieht eine Spur; **Pfeilfeld aufziehen** füllt ein Rechteck. Pfeile am Konturrand werden zugeschnitten. Flächen können in der Zeichen-/Wirkungsreihenfolge verschoben werden.
6. Abschlag, Zielloch und Zielrichtung verschieben. Danach **Testspiel** starten und **Speichern** verwenden.

Die Zeichenfläche lässt sich mit der mittleren Maustaste verschieben und mit dem Mausrad zum Mauszeiger zoomen. **Gesamtansicht** passt die ganze Bahn ein. **Hilfen** schaltet Raster und Verbindungen um. Auswahl per Klick, Mehrfachauswahl mit Shift oder Auswahlrahmen. Ziehen verschiebt die Auswahl. Ein Pinselstrich oder Ziehvorgang ist ein Rückgängig-Schritt.

| Taste | Aktion |
| --- | --- |
| Strg+Z / Strg+Y | Rückgängig / Wiederholen, bis zu 100 Bearbeitungsschritte |
| Strg+D | Auswahl duplizieren |
| Entf | Gewählte Bauteile bzw. Konturpunkt entfernen |
| Escape | Laufende Zeichen-/Verschiebeaktion abbrechen |
| Strg+S | Speichern, sofern kein Texteingabefeld den Tastaturfokus hat |

Ungültige Zwischenstände bleiben bearbeitbar und grundsätzlich als Entwurf speicherbar. Unterstützte Datengrenzen gelten auch für Entwürfe: maximal 8192 × 8192 Pixel Bahngröße, 512 Konturpunkte, 8192 Elemente je Bauteilgruppe, 4–128 Bogensegmente und 4096 Pixel Bogenradius. Die Bibliothek fasst bis zu je 1024 Bahnen und Kurse; Dateien sind auf 16 MB begrenzt. Übergroße Daten werden mit einer Fehlermeldung abgewiesen.

## Mechaniken

Verfügbar sind Rotor, Schiebetor, Wippe, Tunnelzahnrad, Elefant, Tunnelpaar, Tempo-Rohr, Schalter und Kanone. Der Eigenschaftenbereich zeigt die Parameter des ausgewählten Typs.

Nach Auswahl erscheinen gelbe Ziehpunkte für Tunnelenden, Rohrausgänge und Ausgangsrichtungen, Kanonenlandung und Einfahrtrichtung sowie Torwege und Elefantenübergänge. Zahlenfelder erlauben genaue Werte. Die Zahnradpaare werden als acht durch Kommas getrennte Indizes von 0 bis 7 eingegeben; die Zuordnung muss gegenseitig sein.

Nach dem Setzen eines Tunnelpaars ist automatisch **Auswahl** aktiv: Die Enden lassen sich einzeln ziehen, der beschriftete mittlere Griff verschiebt beide gemeinsam. Für ein weiteres Paar erneut **Tunnelpaar** wählen. **Auswahl** ist auch oberhalb der Zeichenfläche jederzeit erreichbar.

**Schalter verbinden**: zuerst den Schalter, dann die Zielkanone anklicken. Eine Kanone erhält einen erforderlichen Schalter; ein Schalter kann mehrere Kanonen freigeben. Duplizierte Gruppen verknüpfen ihre Kopien miteinander. Löschen und Rückgängig halten die Referenzen konsistent.

Fehler unter der Zeichenfläche sind anklickbar. Technische Fehler verhindern das Testspielen und die Aufnahme in die spielbare Auswahl. Hinweise auf Bauteile oder Bewegungsbereiche außerhalb des sichtbaren Bahnbereichs verhindern das Spielen nicht. Die Datenprüfung belegt keine erreichbare PAR-Route; bewegliche Passagen müssen im Testspiel geprüft werden.

## Testspiel

Vor dem Start einen der vier Golfer auswählen. Die aktuelle Bahn wird unabhängig vom Speicherstand als Kopie gespielt. Die normale Ansicht und Schlagphysik bleiben erhalten.

- **Editor** oder Escape: zur unveränderten Bearbeitung zurückkehren.
- **Wiederholen**: Zustand zu Beginn des letzten Abschwungs einschließlich Hindernissen, Schaltern, Kanonen und Transporten wiederherstellen und den Schlag erneut ausführen.
- **Ball setzen**: Spiel pausieren und freien Boden anklicken; Escape bricht die Platzierung ab.
- **Spur an/aus**: den tatsächlich zurückgelegten Ballweg anzeigen.
- **Pause** / P und **Neustart** / R stehen weiterhin zur Verfügung.

Während der Eingabeübergabe laufen die Mechanismen nicht vor. Testspiele schreiben keine Bestwerte. Ein Neustart verwirft die letzte Schlagaufzeichnung. Zoom, Auswahl und Bearbeitungshistorie bleiben bei der Rückkehr erhalten.

## Bibliothek, Kurse und Dateien

**Eigene Inhalte** besitzt getrennte Ansichten für Bahnen und Kurse mit Vorschau. Ein Kurs enthält 1–9 geordnete Bahnplätze; Wiederholungen sind erlaubt. **Spielen** erlaubt 1–4 Spieler mit eigenen Namen und Golfern. Einzelbahnen lassen sich solo üben oder gemeinsam im freien Spiel spielen. Gespeicherte, gültige eigene Bahnen erscheinen außerdem in der normalen Übung und freien Lochauswahl.

Kurse verweisen auf die gespeicherten eigenen Bahnen. Spätere Bahnänderungen gelten deshalb auch in ihren Kursen. Eine verwendete Bahn kann erst gelöscht werden, wenn sie aus allen Kursen entfernt wurde.

**Exportieren** erzeugt JSON-Dateien; ein Kursexport enthält alle benötigten Bahnen. **Importieren** übernimmt sie mit neuen lokalen Kennungen, ohne bestehende Inhalte zu ersetzen. Entwürfe bleiben als Entwürfe erkennbar. Fremde Skripte oder Ressourcenpfade werden nicht geladen. Themen stammen aus dem vorhandenen Spielbestand.

Die Daten liegen unter `user://custom_content/`:

| Datei | Zweck |
| --- | --- |
| `library.json` | Explizit gespeicherte Bahnen und Kurse, Formatversion 1 |
| `library.json.bak` | Vorherige Bibliotheksfassung nach erfolgreicher Sicherung |
| `recovery.json` | Separater Entwurf, zwei Sekunden nach Änderungen automatisch gesichert |
| `progress.cfg` | Eigene Kursbestwerte, getrennt vom offiziellen Fortschritt |

Beim nächsten Editorstart wird ein vorhandener Wiederherstellungsentwurf angeboten. Speichern und Verwerfen entfernen ihn. Fehler beim Schreiben werden angezeigt; eine beschädigte Bibliothek wird nicht überschrieben. Auf Windows liegt `user://` gewöhnlich unter `%APPDATA%/Godot/app_userdata/Putt & Pixel - Spielrahmen-Prototyp/`.

Eigene Bestwerte hängen von Kursidentität, Bahnreihenfolge und den spielrelevanten Bahndaten einschließlich PAR ab. Name und Thema ändern den Wertungsstand nicht. Geometrie- oder Mechanikänderungen beginnen eine neue Wertung; frühere Ergebnisse bleiben in der Datei erhalten.

## Technik und Prüfungen

`EditorDocument` hält Entwurf, Elementkennungen und Änderungshistorie. `EditorCodec` übersetzt ausschließlich bekannte Datentypen; `CustomContentStore` verwaltet Bibliothek und Dateiaustausch. `EditorCanvas` und `EditorUI` bilden die Oberfläche. `EditorPlaytest` und `EditorTestState` ergänzen den vorhandenen Spielablauf. Darstellung und Kollision verwenden weiterhin `HoleRuntime` und `WallJoinGeometry`.

Die Tests laufen über `tests/editor_test.gd`, eingebunden in die Gesamtsuite. Für sichere Prüfungen mit getrenntem Windows-Benutzerdatenordner:

```powershell
# Editorregressionen
.\tools\test_editor.ps1

# Gesamte Spielsuite, unverändert 60 Physikschritte pro Spielsekunde
.\tools\test_editor.ps1 -FullSuite

# Eigenständiger Windows-Testexport: bauen, speichern, Neustart, Austausch, Kurs spielen
.\tools\test_editor_export.ps1

# Dasselbe mit gerenderten Aufnahmen
.\tools\test_editor_export.ps1 -Render

# Editoransichten, Mechaniken, Bibliothek und Kursdialog
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_editor.tscn
```

`--fixed-fps 60` beschleunigt die automatisierten Abläufe durch feste Framezeiten, ohne den Physikschritt zu ändern. Der Windows-Testexport benutzt dieselben Produktionsquellen mit einem separaten Prüf-Einstiegspunkt unter `tmp/editor-export-project`. Dieses Verzeichnis enthält Junctions auf Projektordner und darf nicht rekursiv gelöscht werden. Prüfdaten liegen ausschließlich unter `tmp/`; die normalen Spielstände werden von den beiden PowerShell-Prüfskripten nicht verwendet.

Aufnahmen der Editoroberfläche liegen unter `.godot/editor-captures/`; Aufnahmen des eigenständigen Tests in dem vom Exportprüfskript ausgegebenen Benutzerdatenordner. Native Windows-Bedienung und Hardware-Controllerprüfungen bleiben getrennte Prüfwege.

Prüfstand vom 17.09.2026 mit Godot 4.7.2: Gesamtsuite **5455 Checks, 0 Fehler**, Exitcode 0; darin 272 Editorprüfungen. Eigenständiger Windows-Testexport: 5 Checks für Bauen/Speichern/Austausch und 8 Checks nach Neustart einschließlich tatsächlich gespieltem Kurs und Bestwert, jeweils 0 Fehler. Der normale Windows-Build wurde exportiert und mit Exitcode 0 gestartet. Editor, Mechanikhilfen, Bibliothek, Kursdialog, lange Bahn, Zoom und Testspiel wurden anhand gerenderter Aufnahmen visuell geprüft. Eine native Bedienungsprüfung über Windows-Automation war wegen eines Capture-API-Fehlers nicht möglich; Hardware-Controller wurden nicht erneut geprüft.

Tunnelkorrektur, 17.09.2026: Automatischer Auswahlwechsel, einzelnes und gemeinsames Verschieben, Rückgängig/Wiederholen sowie Escape-Abbruch geprüft. Aktuelle Gesamtsuite: **5462 Checks, 0 Fehler**, Exitcode 0; davon 279 Editorprüfungen. Neue Bedienung visuell unter `07-tunnel-move.png` geprüft. `PuttAndPixel-Editor-TunnelFix.exe` separat exportiert und erfolgreich gestartet, damit eine laufende ältere Editorversion geöffnet bleiben kann.
