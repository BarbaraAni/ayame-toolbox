param (
    [string]$source = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads",
    #[string]$source = "F:\Musik\Smule\safetyNet",
    [string]$metadata = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\data\metadata.txt"
)

$logFile = Join-Path $source "ffmpeg_artist_error.log"

# Metadatenliste laden
$metadataList = Get-Content $metadata | ForEach-Object {
    ($_ -split "`t", 2)[1].Trim()
}

# Mediendateien sortieren
$mediaFiles = Get-ChildItem -Path $source -Recurse -Include *.mp3, *.m4a, *.mp4 -File | Sort-Object CreationTime

for ($i = 0; $i -lt $mediaFiles.Count; $i++) {
    $file = $mediaFiles[$i]
    if ($i -lt $metadataList.Count) {
        $artist = $metadataList[$i]
        $tempFile = Join-Path $file.Directory.FullName "$($file.BaseName)_temp$($file.Extension)"

        # ffmpeg – setzt Artist und Album, ohne Umbenennung
        ffmpeg -y -i "`"$($file.FullName)`"" -metadata artist="$artist" -metadata album="Smule" -c copy "`"$tempFile`"" 2>> "$logFile"

        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $file.FullName -Force
            Rename-Item -LiteralPath $tempFile -NewName $file.Name
            Write-Host "🎵 Metadata gesetzt: $artist (Album: Smule) → $($file.Name)"
        } else {
            Write-Warning "❌ Fehler beim Setzen des Interpreten für: $($file.Name)"
        }
    } else {
        Write-Warning "⚠️ Kein Artist vorhanden für: $($file.Name)"
    }
}
