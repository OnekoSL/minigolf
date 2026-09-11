$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --log-file "$projectRoot/tmp/worlds/generator-engine.log" --script res://tests/build_eight_worlds.gd
    if ($LASTEXITCODE -ne 0) { throw 'Bahnaufbau fehlgeschlagen; Ausgaben wurden nicht uebernommen.' }
    Copy-Item -Path tmp/worlds/staging/data/* -Destination data -Recurse -Force
} finally {
    Pop-Location
}
