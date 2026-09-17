param([switch]$Render)
$ErrorActionPreference = 'Stop'
$editorRoot = Split-Path -Parent $PSScriptRoot
$editorStage = Join-Path $editorRoot 'tmp/editor-export-project'
$editorEngine = Join-Path $editorRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$editorBinary = Join-Path $editorRoot 'build/windows/PuttAndPixel-Editor-Probe.exe'
$editorData = Join-Path $editorRoot ('tmp/editor-export-check-' + [guid]::NewGuid().ToString('N'))
$editorOldAppData = $env:APPDATA
New-Item -ItemType Directory -Force $editorStage | Out-Null
$editorConfig = (Get-Content -LiteralPath (Join-Path $editorRoot 'project.godot') -Raw).Replace('run/main_scene="res://scenes/game_app.tscn"', 'run/main_scene="res://probe.tscn"')
[IO.File]::WriteAllText((Join-Path $editorStage 'project.godot'), $editorConfig)
Copy-Item -LiteralPath (Join-Path $editorRoot 'export_presets.cfg') -Destination $editorStage -Force
Copy-Item -LiteralPath (Join-Path $editorRoot 'tests/editor_export_probe.gd') -Destination (Join-Path $editorStage 'probe_main.gd') -Force
$editorScene = @'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://probe_main.gd" id="1"]
[node name="Probe" type="Node"]
script = ExtResource("1")
'@
[IO.File]::WriteAllText((Join-Path $editorStage 'probe.tscn'), $editorScene)
# Junctions point at the exact production sources. Never recursively delete this staging folder.
foreach ($editorFolder in @('src', 'data', 'assets', 'scenes', 'config', '.tools')) {
    $editorLink = Join-Path $editorStage $editorFolder
    if (!(Test-Path -LiteralPath $editorLink)) {
        New-Item -ItemType Junction -Path $editorLink -Target (Join-Path $editorRoot $editorFolder) | Out-Null
    }
}
& $editorEngine --headless --editor --path $editorStage --quit *> (Join-Path $editorRoot 'tmp/editor-probe-import.log')
if ($LASTEXITCODE -ne 0) { throw 'Import des Prüfprojekts fehlgeschlagen.' }
& $editorEngine --headless --path $editorStage --export-release 'Windows Desktop' $editorBinary *> (Join-Path $editorRoot 'tmp/editor-probe-export.log')
if ($LASTEXITCODE -ne 0) { throw 'Prüfexport fehlgeschlagen.' }
try {
    $env:APPDATA = $editorData
    foreach ($editorPhase in @('create', 'verify')) {
        $editorLog = Join-Path $editorRoot "tmp/editor-packaged-$editorPhase.log"
        $editorArgs = @('--headless', '--verbose', '--fixed-fps', '60', '--log-file', ('"' + $editorLog + '"'))
        if ($Render) { $editorArgs = @('--verbose', '--fixed-fps', '60', '--resolution', '1280x720', '--log-file', ('"' + $editorLog + '"')) }
        if ($editorPhase -eq 'verify') { $editorArgs += @('--', '--verify') }
        if ($Render) {
            # Render tests need an interactive surface; no computer-use capture is required.
            & $editorBinary @($editorArgs | ForEach-Object { $_.Trim('"') })
            do { Start-Sleep -Milliseconds 250; $editorRunning = Get-Process -Name 'PuttAndPixel-Editor-Probe' -ErrorAction SilentlyContinue } while ($editorRunning)
        } else {
            $editorProcess = Start-Process -FilePath $editorBinary -ArgumentList $editorArgs -WindowStyle Hidden -PassThru -Wait
            if ($editorProcess.ExitCode -ne 0) { throw "Windows-Prüfung $editorPhase fehlgeschlagen." }
        }
        $editorOutput = Get-Content -LiteralPath $editorLog -Raw
        if ($editorOutput -notmatch 'Export-Editor: \d+ Checks, 0 Fehler' -or $editorOutput -match 'SCRIPT ERROR:') { throw "Kein erfolgreicher Abschluss für $editorPhase; siehe $editorLog" }
        Select-String -LiteralPath $editorLog -Pattern '^OK |^Export-Editor:' | ForEach-Object { $_.Line }
    }
} finally {
    $env:APPDATA = $editorOldAppData
}
Write-Output "Isolierte Prüfdaten und Aufnahmen: $editorData"
