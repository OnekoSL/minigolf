# Prototypkurs – Revision 3

Stand: 08.09.2026. Neun echte Kursbahnen, Gesamt-PAR 33. Die Kurs-ID bleibt `prototype_course_03`; neue Ergebnisse verwenden `prototype_course_03_v3`. Bestehende Bestwerte der alten PAR-38-Runde werden nicht übernommen oder gelöscht.

| Loch | Bahn | PAR | Spielaufgabe |
| --- | --- | ---: | --- |
| 1 | S-Kurve an der Mühle | 4 | S-Kontur mit Wasserlinie, Sand und Mühle |
| 2 | Die Diamantenlinie | 3 | Geschlossene Diamantinsel auf zwei unterschiedlichen Linien umspielen |
| 3 | Das Doppeltor | 4 | Versetzte Kammern und zwei zeitabhängige Passagen |
| 4 | Sandufer | 3 | Sand dosieren und vor dem Wasser in den Zielarm einbiegen |
| 5 | Doppelhügel | 3 | Zwei vollständige Hügelquerschnitte, zunächst grün, dann blau |
| 6 | Uferkehre | 3 | Abfahrt, quer gespielte Kehre und durch Gefälle unterstützter Rückweg |
| 7 | Panoramaweg | 5 | Zwei Richtungswechsel durch eine breite, horizontal scrollende Kontur |
| 8 | Bogenpromenade | 4 | Einen durch zwei konzentrische Außenbögen gebildeten Wendekanal spielen |
| 9 | Die Kanonenwerkstatt | 4 | Schalter und sichere oder riskante Kanone zum getrennten Zielbereich |

Die Geometrie und Mechaniken der vier vorhandenen Kursbahnen bleiben erhalten. Alle neun erhalten dieselbe dezente Gartenoptik. Rasenstreifen werden an der tatsächlichen Kontur einschließlich ihrer Bögen beschnitten. Die rein dekorativen Pflanzbeete stehen außerhalb des Spielfelds mit mindestens 22 Pixeln Abstand zur Kontur; sie haben keine Kollision.

Die fünf neuen Ressourcen `prototype_04` bis `prototype_08` ersetzen die Kursplätze von Allround-Testloch, Gefälle-Labor, U-Flussbahn, Scroll-Testbahn und Kurven-Labor. Diese ursprünglichen Technikressourcen bleiben für Regressionen und F2 verfügbar. Der Katalog umfasst nun 36 echte Kursbahnen und 14 technische Bahnen; Übung und freies Spiel zeigen acht Seiten mit bis zu fünf echten Bahnen.

## Darstellung und Ergebnisse

Die Ergebnistabelle enthält Kursname, Lochzahl und Gesamt-PAR. Spielerzeilen verwenden die Profilfarbe; Unter-PAR-Ergebnisse sind grün, Über-PAR-Ergebnisse apricot hinterlegt. Zahlen und PAR-Zeile bleiben unabhängig von der Farbe lesbar. Die Endtabelle sortiert Spieler nach Gesamtschlägen und erhält gemeinsame Ränge bei Gleichstand. Solo-Runden zeigen zusätzlich Schlagzahl, Differenz zu PAR und die Zahl der unter PAR beendeten Löcher. Pause und laufende Runden behalten die Spielerreihenfolge.

## Prüfung und Reproduktion

`tests/prototype_course_test.gd` gehört zur vollständigen Headless-Suite. Es prüft die Trennung von Labor und Kurs, die aktuellen Konturen und Pfeile sowie PAR-Abschlüsse aller fünf neuen Bahnen ohne Wasserverlust und mit Anspielabweichungen von ±0,3 Grad. Die bestehenden Tests sichern weiterhin die vier älteren Kursbahnen; deren isolierte Mechaniktests und teilweise offen fixierte Mechanismen sind kein vollständiger menschlicher Timingtest.

`tests/build_prototype_course.gd` erzeugt die fünf neuen `.tres`-Ressourcen reproduzierbar. Änderungen an diesen Bahnen deshalb auch im Generator pflegen.

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tests/test_runner.tscn --log-file .godot/prototype-suite.log
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_prototype_course.gd
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_prototype_ui.tscn
```

Die Aufnahmen liegen unter `.godot/prototype-polish/`: Gesamtübersicht, neun Detailbilder, Spielansichten am Abschlag und an den Kameraenden sowie Solo-, Hotseat- und Pausentabellen. Die Tabellenaufnahmen verwenden Beispieldaten und schreiben keine Bestwerte.

Abnahme: vollständige Headless-Suite mit **3110 Checks, 0 Fehlern**; die neuen PAR-Routen bestehen einschließlich der Anspielabweichungen. Die Spielansichten und Tabellen für einen und vier Spieler sowie die Ein-Loch-Übung wurden gerendert und visuell geprüft. Der Windows-Debug-Export liegt separat unter `build/windows/PuttAndPixelPrototype-v3.exe`, da die bisherige EXE während der Überarbeitung noch geöffnet war.
