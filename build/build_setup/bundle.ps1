# F8 Bundler
# Merges all #Include files into a single script for easier compilation.

$ErrorActionPreference = "Stop"

$rootFile = Join-Path $PSScriptRoot "..\..\F8.ahk"
$outFile = Join-Path $PSScriptRoot "..\artifacts\F8_bundled.ahk"
$sourceDir = Join-Path $PSScriptRoot "..\.."
$outDir = Split-Path -Parent $outFile

if (!(Test-Path $rootFile)) {
    Write-Error "Could not find root file: $rootFile"
    exit 1
}

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$content = Get-Content $rootFile

$finalContent = @()
foreach ($line in $content) {
    if ($line -match "^#Include\s+(.+)$") {
        $includeFile = $matches[1].Trim()
        $includeFile = $includeFile -replace "^['""]|['""]$", ""
        
        $fullPath = Join-Path $sourceDir $includeFile
        
        if (Test-Path $fullPath) {
            Write-Host "Inlining: $includeFile" -ForegroundColor Gray
            $finalContent += "; --- START INCLUDE: $includeFile ---"
            $finalContent += Get-Content -Path $fullPath
            $finalContent += "; --- END INCLUDE: $includeFile ---"
        } else {
            Write-Host "Warning: Could not find include $includeFile at $fullPath" -ForegroundColor Yellow
            $finalContent += $line
        }
    } else {
        $finalContent += $line
    }
}

$finalContent | Out-File -FilePath $outFile -Encoding ascii
Write-Host "Bundled script created: $outFile" -ForegroundColor Green
