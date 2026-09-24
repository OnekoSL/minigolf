# Übersetzungen und Einstellungen

Die fünf UTF-8-PO-Kataloge `de.po`, `en.po`, `fr.po`, `es.po` und `it.po` sind in `project.godot` registriert und werden als Ressourcen exportiert. Deutsch ist die Start- und Rückfallsprache. Godot 4.7.2 benötigt keine zusätzlichen Bibliotheken.

## Texte pflegen

- Eigene Texte verwenden stabile Schlüssel wie `SETTINGS_TITLE` und `TEXT_START_GAME`. Bei einer Formulierungsänderung den bestehenden Schlüssel behalten und die fünf `msgstr`-Texte bearbeiten. Nummernsuffixe unterscheiden historisch verschiedene Beschriftungen mit gleichem englischem Wortlaut.
- Vor der Formatierung übersetzen: `I18n.text("TEXT_PLAYER") % number`. Platzhalter einschließlich Reihenfolge, Typ und Genauigkeit müssen in allen Sprachen übereinstimmen. Zeilenumbrüche werden als `\n` notiert. Die deutschen Kommentare im Katalog dienen als Orientierung.
- `I18n.content_name(resource)` übersetzt offizielle Namen über `COURSE_<ID>` beziehungsweise `HOLE_<ID>`. Eigene IDs mit `custom_` und unbekannte Ressourcen behalten ihren gespeicherten Anzeigenamen. Ressourcendateien, Bestwertschlüssel und JSON-Formate ändern sich durch einen Sprachwechsel nicht.
- `I18n.golfer_description(resource)` übersetzt Beschreibungen. Die Figurennamen bleiben unverändert.
- `I18n.source()` ist ausschließlich für feste Enum-Beschriftungen und UI-Konstanten vorgesehen. Die dazugehörige kleine Zuordnung liegt in `src/i18n_source_keys.gd`. Niemals Benutzereingaben durch diese Funktion übersetzen.
- Eigene Namen werden explizit ohne automatische Übersetzung angezeigt. Godots Dateidialog übersetzt seine festen Beschriftungen über die zusätzlichen englischen Engine-Schlüssel; seine Dateilisten übersetzt Godot nicht. Diese Engine-Schlüssel müssen ihren Originalwortlaut behalten.
- Offene Dialogeigenschaften lassen sich mit `I18n.bind(dialog, "title", key, parameters)` aktualisieren. Die Bindung lebt als Kind des Dialogs und verschwindet mit ihm. Selbst gezeichnete Texte reagieren auf `NOTIFICATION_TRANSLATION_CHANGED` mit Neuzeichnen. Der Editor erneuert seine Oberfläche unter Erhaltung von Dokument, Undo-Verlauf, Auswahl, Werkzeug und Ansicht.

Neue Sprache: PO-Katalog anlegen, in `project.godot` sowie `GameSettings.LANGUAGES` registrieren und den Eigennamen in `SettingsMenu.LANGUAGE_NAMES` ergänzen. Die Auswahllänge im Sprachwechsel wird aus dem Sprachkatalog abgeleitet. Danach die unten genannten Prüfungen ausführen.

## Validierung und Speicherung

Die bestehenden `validate()`-Methoden der Bahnbausteine geben weiterhin `PackedStringArray` zurück. Ein optionales `Array[ValidationIssue]` sammelt zusätzlich Schlüssel, Parameter und stabile Editor-Bauteilkennung. Der Editor ordnet Fehler über diese Kennung zu; er durchsucht keine übersetzten Meldungen nach Bauteilnamen. Fehlermeldungen müssen ihre Kennung unabhängig von der Sprache behalten.

`GameSettings` definiert die typisierten Werte. `SettingsStore` liest und schreibt ausschließlich `user://settings.cfg`; `SettingsManager` verwaltet gespeicherte Werte, Entwurf, laufende Vorschau und die Anzeige-Rücknahmefrist. Erst ein erfolgreicher Schreibvorgang ersetzt die gespeicherten Werte. Eine beschädigte vorhandene Datei wird nicht überschrieben. Bei fehlgeschlagenem Speichern bleibt das Menü offen; Abbrechen stellt die bisherigen Werte wieder her.

Standardwerte: Deutsch, Gesamt-/Effektlautstärke 100 %, Fenstermodus, Fenstergröße 2560×1440 (auf den Bildschirm begrenzt), VSync und Kamerawackeln an. Die weiteren Fenstergrößen sind 1280×720 und 1920×1080. Lautstärke 0 schaltet den jeweiligen Bus stumm. Alle Spielgeräusche laufen über den Bus `Effects`, dessen individuelle Lautstärke zusätzlich zum Master gilt.

Bestwerte, eigene Inhalte und Controllerprofile behalten ihre bisherigen Dateien. Kalibrierung ist ein eigener Speichervorgang und wird nicht durch Abbrechen des Einstellungsentwurfs zurückgesetzt.

## Prüfen

```powershell
# Gesamtsuite mit isolierten Speicherdateien
& .\tools\test_editor.ps1 -FullSuite

# Aufnahmen aller fünf Sprachen (ohne --headless)
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/capture_localization.tscn

# Echte Fenster-, Vollbild- und VSync-Wechsel, mit isoliertem APPDATA starten
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path . res://tests/settings_display_probe.tscn

# Eigenständiger Windows-Export, einschließlich Sprache und Neustart
& .\tools\test_editor_export.ps1
```

Die Aufnahmen liegen unter `.godot/localization/`. Die Capture-Szene speichert keine Einstellungen. Die Displayprobe verändert die Anzeige nur vorübergehend. Den Controller weiterhin separat mit `tests/controller_probe.tscn` prüfen; Simulationstests ersetzen keine Hardwarebedienung.

`tests/settings_i18n_test.gd` prüft Katalogvollständigkeit, Formatparameter, Inhaltsnamen, Sprachrückfall, Benutzernamen, Editorfehlerzuordnung, Vorschau, Übernehmen, Abbrechen, Dateifehler, Anzeigezeitlimit, Menüeingabeschranken und Erhaltung der pausierten Runde sowie des Editorentwurfs. Die absichtlich beschädigte Einstellungsdatei erzeugt erwartete `ConfigFile parse error`-Meldungen; GDScript-Parserfehler sind dagegen immer Fehler.

### Prüfstand 24.09.2026

- Godot 4.7.2, Gesamtsuite mit isoliertem `APPDATA`: **5.735 Checks, 0 Fehler**, Exitcode 0, keine GDScript-Parserfehler.
- Windows-Testexport mit Speichern und Neustart: **11 + 14 Checks, 0 Fehler**. Der lokale spielbare Export `build/windows/PuttAndPixel-Mehrsprachig.exe` startet ebenfalls mit Exitcode 0.
- Echte Fenster-/Vollbild-/VSync-Probe: **6 Checks, 0 Fehler**, einschließlich automatischer Rücknahme und unveränderter interner Spielauflösung.
- **55 Renderaufnahmen** über alle fünf Sprachen: Titel, vier Einstellungsseiten, Spielmodus, Kursauswahl, HUD, Ergebnistabelle, Editor und Dateidialog. Sonderzeichen und Anordnung visuell geprüft; keine erkennbaren Überlagerungen oder abgeschnittenen Bedienelemente.
- Die Hardwareprobe findet **0 Controller**. Echte Controllerbedienung und Hardwarekalibrierung bleiben ungeprüft; simulierte Eingabeschranken, Fokusverlust und Controllertrennung sind durch Regressionstests abgedeckt.
