param(
    [ValidateSet("iup", "gtk", "gtk4", "winforms", "all")]
    [string]$Target = "gtk"
)

function Build-Target([string]$UI) {
    $outName = "day-trade-$UI.exe"
    Write-Host "[BUILD] Compiling $UI -> $outName" -ForegroundColor Cyan

    # All targets are GUI applications (run with the Windows subsystem so no
    # console window appears). The text UI is available at runtime with -t.
    $odinArgs = @("-out:$outName", "-define:UI=$UI", "-subsystem:windows")

    odin build . @odinArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Build failed for $UI"
        exit $LASTEXITCODE
    }
    Write-Host "[OK] Successfully built $outName" -ForegroundColor Green

    # Embed the manifest into the executable when one exists next to it
    $manifestFile = "tools/$outName.manifest"
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
    Build-Target "iup"
    Build-Target "gtk"
    Build-Target "winforms"
} else {
    Build-Target $Target
}
