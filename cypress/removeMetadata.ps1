# Entfernt Metadaten aus allen .mp3, .m4a und .mp4 Dateien im angegebenen Ordner

# ==== KONFIGURATION ====
$folder = "cypress/downloads"  # Pfad zu deinem Zielordner (relativ oder absolut)
# =======================

# Prüfen, ob ffmpeg installiert ist
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "❌ ffmpeg ist nicht installiert oder nicht im PATH verfügbar."
    exit 1
}

# Absoluten Pfad ermitteln
$folderPath = Resolve-Path $folder

# Dateien durchsuchen und verarbeiten
Get-ChildItem -Path $folderPath -Recurse -Include *.mp3, *.m4a, *.mp4 | ForEach-Object {
    $input = $_.FullName
    $tempOutput = "$($input.Substring(0, $input.LastIndexOf('.')))_clean$($_.Extension)"

    Write-Host "🎵 Bearbeite: $($_.Name)"
    ffmpeg -y -i "$input" -map_metadata -1 -c copy "$tempOutput" > $null 2>&1

    if (Test-Path $tempOutput) {
        Remove-Item "$input" -Force
        Rename-Item "$tempOutput" "$input"
        Write-Host "✅ Fertig: $($_.Name)`n"
    } else {
        Write-Host "⚠️ Fehler bei: $($_.Name)`n"
    }
}

Write-Host "🎉 Alle Metadaten entfernt!" -ForegroundColor Green
pause
