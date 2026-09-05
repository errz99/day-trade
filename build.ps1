param(
    [ValidateSet("tui", "iup", "gtk", "gtk4", "all")]
    [string]$Target = "tui"
)

function Build-Target([string]$UI) {
    $outName = "day-trade-$UI.exe"
    Write-Host "[BUILD] Compiling $UI -> $outName" -ForegroundColor Cyan
    odin build . -out:$outName -define:UI="$UI"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Build failed for $UI"
        exit $LASTEXITCODE
    }
    Write-Host "[OK] Successfully built $outName" -ForegroundColor Green
}

if ($Target -eq "gtk4") { $Target = "gtk" }

if ($Target -eq "all") {
    Build-Target "tui"
    Build-Target "iup"
    Build-Target "gtk"
} else {
    Build-Target $Target
}
