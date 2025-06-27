# Entfernt Metadaten aus allen .mp3, .m4a und .mp4 Dateien im angegebenen Quellordner
# und verschiebt sie danach ins Zielverzeichnis

# ==== KONFIGURATION ====
$sourceBase = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads"
$targetBase = "F:\Musik\Smule\safetyNet"
# ========================

# ffmpeg prüfen
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg ist nicht installiert oder nicht im PATH verfügbar."
    exit 1
}

# Zielordner erstellen, falls nicht vorhanden
New-Item -ItemType Directory -Force -Path $targetBase | Out-Null

# Mediendateien suchen
$mediaFiles = Get-ChildItem -Path $sourceBase -Recurse -Include *.mp3, *.m4a, *.mp4 -File

foreach ($file in $mediaFiles) {
    $input = $file.FullName
    $cleanName = "$($file.BaseName)_clean$($file.Extension)"
    $tempOutput = Join-Path -Path $file.Directory.FullName -ChildPath $cleanName

    Write-Host "Bearbeite: $($file.FullName)"
    ffmpeg -y -i "$input" -map_metadata -1 -c copy "$tempOutput" > $null 2>&1

    if (Test-Path $tempOutput) {
        Remove-Item "$input" -Force
        Rename-Item "$tempOutput" "$input"
        Write-Host "Metadaten entfernt: $($file.Name)"

        # Datei verschieben
        $fileNameCleaned = $file.Name -replace 'amp;039;', "'"
        $targetPath = Join-Path $targetBase $fileNameCleaned
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileNameCleaned)
        $ext = [System.IO.Path]::GetExtension($fileNameCleaned)
        $counter = 1

        while (Test-Path $targetPath) {
            $targetPath = Join-Path $targetBase "$baseName`_$counter$ext"
            $counter++
        }

        Move-Item -Path $file.FullName -Destination $targetPath -Force
        Write-Host "Verschoben nach: $([System.IO.Path]::GetFileName($targetPath))`n"
    } else {
        Write-Host "Fehler beim Verarbeiten von: $($file.Name)`n"
    }
}

# Leere Ordner unter sourceBase löschen
$emptyFolders = Get-ChildItem -Path $sourceBase -Recurse -Directory | Where-Object {
    @(Get-ChildItem -Path $_.FullName -Force -Recurse -File).Count -eq 0
}

foreach ($folder in $emptyFolders) {
    Remove-Item -Path $folder.FullName -Force -Recurse
    Write-Host "Gelöschter leerer Ordner: $($folder.FullName)"
}

Write-Host "`n Alle Dateien wurden bereinigt, verschoben und leere Ordner gelöscht!" -ForegroundColor Green
pause
