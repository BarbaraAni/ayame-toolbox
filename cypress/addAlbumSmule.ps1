param (
    [string]$source = "F:\Musik\Smule"
)

$logFile = Join-Path $source "ffmpeg_album_error.log"

Get-ChildItem -Path $source -Recurse -Include *.mp3 -File | ForEach-Object {
    $file = $_
    $input = $file.FullName
    $temp = Join-Path $file.Directory.FullName "$($file.BaseName)_temp$($file.Extension)"

    ffmpeg -y -i "`"$input`"" -metadata album="Smule" -c copy "`"$temp`"" 2>> $logFile

    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $input -Force
        Rename-Item -LiteralPath $temp -NewName $file.Name
        Write-Host "Album gesetzt für: $($file.Name)"
    } else {
        Write-Warning "XX Fehler beim Setzen des Albums für: $($file.Name)"
    }
}
