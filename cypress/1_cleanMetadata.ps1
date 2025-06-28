param (
    [string]$source = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads"
    #[string]$source = "F:\Musik\Smule\safetyNet"
)

$logFile = Join-Path $source "ffmpeg_clean_error.log"

Get-ChildItem -Path $source -Recurse -Include *.mp3, *.m4a, *.mp4 -File | ForEach-Object {
    $input = $_.FullName
    $tempOutput = Join-Path $_.Directory.FullName "$($_.BaseName)_clean$($_.Extension)"

    Write-Host "Bereinige: $input"
    ffmpeg -y -i "`"$input`"" -map_metadata -1 -c copy "`"$tempOutput`"" 2>> $logFile

    if (Test-Path $tempOutput) {
        Remove-Item $input -Force
        Rename-Item $tempOutput -NewName $_.Name
    } else {
        Write-Warning "Fehler beim Bereinigen von $_.Name"
    }
}
