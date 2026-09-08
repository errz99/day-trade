param(
    [ValidateSet("tui", "iup", "gtk", "gtk4", "winforms", "all")]
    [string]$Target = "tui"
)

function Build-Target([string]$UI) {
    $outName = "day-trade-$UI.exe"
    Write-Host "[BUILD] Compiling $UI -> $outName" -ForegroundColor Cyan

    # GUI targets (iup/gtk/winforms) run as Windows applications so no console
    # window appears; the tui stays a console application (default console subsystem).
    $odinArgs = @("-out:$outName", "-define:UI=$UI")
    if ($UI -eq "iup" -or $UI -eq "gtk" -or $UI -eq "winforms") {
        $odinArgs += "-subsystem:windows"
    }

    odin build . @odinArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Build failed for $UI"
        exit $LASTEXITCODE
    }
    Write-Host "[OK] Successfully built $outName" -ForegroundColor Green

    # Embed the manifest into the executable when one exists next to it
    $manifestFile = "$outName.manifest"
    if (Test-Path $manifestFile) {
        if (-not (Test-Path "_embed_manifest.exe")) {
            odin build tools/embed_manifest -out:_embed_manifest.exe
            if ($LASTEXITCODE -ne 0) {
                Write-Error "[ERROR] Failed to build the manifest embedder"
                exit $LASTEXITCODE
            }
        }
        & .\_embed_manifest.exe $outName $manifestFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Manifest embedding failed for $UI"
            exit $LASTEXITCODE
        }
        Write-Host "[OK] Manifest embedded into $outName" -ForegroundColor Green
    }
}

if ($Target -eq "gtk4") { $Target = "gtk" }

if ($Target -eq "all") {
    Build-Target "tui"
    Build-Target "iup"
    Build-Target "gtk"
    Build-Target "winforms"
} else {
    Build-Target $Target
}
