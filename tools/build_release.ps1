param([string]$Engine = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
if (!$Engine) { $Engine = Join-Path $projectRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' }
$settings = Get-Content -LiteralPath 'project.godot' -Raw
$version = [regex]::Match($settings, 'config/version="([0-9]+\.[0-9]+\.[0-9]+)"').Groups[1].Value
if (!$version) { throw 'Keine gueltige Release-Version in project.godot.' }
$packageName = "PuttAndPixel-$version-windows-x64"
$releaseRoot = Join-Path $projectRoot 'build/releases'
$packageDir = Join-Path $releaseRoot $packageName
$logDir = Join-Path $projectRoot "tmp/release-$version"
New-Item -ItemType Directory -Force $packageDir,$logDir | Out-Null
$executable = Join-Path $packageDir 'PuttAndPixel.exe'
& $Engine --headless --path $projectRoot --log-file (Join-Path $logDir 'export-engine.log') --export-release 'Windows Desktop' $executable *> (Join-Path $logDir 'export.log')
if ($LASTEXITCODE -ne 0) { throw 'Release-Export fehlgeschlagen; siehe Exportprotokoll.' }
Copy-Item -LiteralPath 'release/SPIELSTART.txt','release/NEUERUNGEN.txt' -Destination $packageDir
& $Engine --headless --path $projectRoot --log-file (Join-Path $logDir 'licenses-engine.log') --script res://tools/release_licenses.gd -- (Join-Path $packageDir 'GODOT-LIZENZEN.txt') *> (Join-Path $logDir 'licenses.log')
if ($LASTEXITCODE -ne 0) { throw 'Lizenzhinweise konnten nicht erzeugt werden.' }
$commit = git -c "safe.directory=$($projectRoot.Replace('\','/'))" rev-parse HEAD
$dirty = [bool](git -c "safe.directory=$($projectRoot.Replace('\','/'))" status --porcelain)
[ordered]@{ version=$version; platform='Windows x64'; configuration='release'; source_commit=$commit; source_dirty=$dirty; created_utc=[DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $packageDir 'BUILD.json') -Encoding utf8
Write-Output "Release-Build: $executable"
Write-Output 'Vor dem Packen: Tests, Standalone-Start und Renderaufnahmen pruefen; dann PRUEFBERICHT.txt ergaenzen.'
