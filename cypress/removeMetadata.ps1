# Entfernt Metadaten aus allen .mp3, .m4a und .mp4 Dateien im angegebenen Ordner
# und verschiebt alle Dateien aus Unterordnern in den Hauptordner

# ==== KONFIGURATION ====
$folder = "downloads"  # Zielordner (relativ oder absolut)
# ========================

# Prüfen, ob ffmpeg installiert ist
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg ist nicht installiert oder nicht im PATH verfügbar."
    exit 1
}

# Absoluten Pfad ermitteln
$folderPath = Resolve-Path $folder

# Alle Mediendateien rekursiv finden
$mediaFiles = Get-ChildItem -Path $folderPath -Recurse -Include *.mp3, *.m4a, *.mp4 -File

foreach ($file in $mediaFiles) {
    $input = $file.FullName
    $cleanName = "$($file.BaseName)_clean$($file.Extension)"
    $tempOutput = Join-Path -Path $file.Directory.FullName -ChildPath $cleanName

    Write-Host "Bearbeite: $($file.Name)"
    ffmpeg -y -i "$input" -map_metadata -1 -c copy "$tempOutput" > $null 2>&1

    if (Test-Path $tempOutput) {
        Remove-Item "$input" -Force
        Rename-Item "$tempOutput" "$input"
        Write-Host "Metadaten entfernt: $($file.Name)`n"
    } else {
        Write-Host "Fehler bei: $($file.Name)`n"
    }
}

# Jetzt alle Dateien aus Unterordnern in den Hauptordner verschieben
$mainFolder = $folderPath.Path
$filesToMove = Get-ChildItem -Path $mainFolder -Recurse -File

foreach ($file in $filesToMove) {
    if ($file.DirectoryName -ne $mainFolder) {
        $targetPath = Join-Path $mainFolder $file.Name
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $ext = $file.Extension
        $counter = 1

        # Wenn die Datei bereits existiert, eindeutigen Namen erzeugen
        while (Test-Path $targetPath) {
            $targetPath = Join-Path $mainFolder "$baseName`_$counter$ext"
            $counter++
        }

        Move-Item -Path $file.FullName -Destination $targetPath -Force
        Write-Host "Verschoben: $($file.Name) -> $([System.IO.Path]::GetFileName($targetPath))"
    }
}

Write-Host "`n Alle Dateien bereinigt und ins Hauptverzeichnis verschoben!" -ForegroundColor Green
pause
