param([switch]$FullSuite)
$ErrorActionPreference = 'Stop'
$editorRoot = Split-Path -Parent $PSScriptRoot
$editorEngine = Join-Path $editorRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$editorPreviousAppData = $env:APPDATA
$editorResult = 1
try {
    # Isolate every user:// write, including tests of newly introduced save paths.
    $env:APPDATA = Join-Path $editorRoot 'tmp/editor-test-appdata'
    $editorScene = if ($FullSuite) { 'res://tests/test_runner.tscn' } else { 'res://tests/editor_runner.tscn' }
    & $editorEngine --headless --fixed-fps 60 --path $editorRoot $editorScene
    $editorResult = $LASTEXITCODE
} finally {
    $env:APPDATA = $editorPreviousAppData
}
exit $editorResult
