$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$version = [regex]::Match((Get-Content project.godot -Raw), 'config/version="([0-9]+\.[0-9]+\.[0-9]+)"').Groups[1].Value
if (!$version) { throw 'Release-Version fehlt.' }
$packageName = "PuttAndPixel-$version-windows-x64"
$releaseRoot = Join-Path $projectRoot 'build/releases'
$packageDir = Join-Path $releaseRoot $packageName
$files = @('PuttAndPixel.exe','SPIELSTART.txt','NEUERUNGEN.txt','GODOT-LIZENZEN.txt','BUILD.json','PRUEFBERICHT.txt')
foreach ($name in $files) {
    if (!(Test-Path -LiteralPath (Join-Path $packageDir $name) -PathType Leaf)) { throw "Paketdatei fehlt: $name" }
}
$exeHash = (Get-FileHash -LiteralPath (Join-Path $packageDir 'PuttAndPixel.exe') -Algorithm SHA256).Hash
if (!(Get-Content -LiteralPath (Join-Path $packageDir 'PRUEFBERICHT.txt') -Raw).Contains($exeHash)) {
    throw 'Pruefbericht gehoert nicht zur aktuellen EXE. Release zuerst pruefen.'
}
$unexpected = Get-ChildItem -LiteralPath $packageDir | Where-Object { $_.PSIsContainer -or $_.Name -notin ($files + @('SHA256SUMS.txt')) }
if ($unexpected) { throw 'Unerwartete Dateien im Release-Ordner; Paketinhalt pruefen.' }
$sums = foreach ($name in $files) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $packageDir $name) -Algorithm SHA256).Hash
    "$hash  $name"
}
$sums | Set-Content -LiteralPath (Join-Path $packageDir 'SHA256SUMS.txt') -Encoding ascii
$zip = Join-Path $releaseRoot "$packageName.zip"
Compress-Archive -LiteralPath $packageDir -DestinationPath $zip -CompressionLevel Optimal -Force
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
"$zipHash  $packageName.zip" | Set-Content -LiteralPath "$zip.sha256" -Encoding ascii
Write-Output "Release-Paket: $zip"
Write-Output "SHA256: $zipHash"
