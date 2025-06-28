param (
    [string]$source = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads",
    [string]$target = "F:\Musik\Smule\safetyNet"
)

New-Item -ItemType Directory -Force -Path $target | Out-Null

Get-ChildItem -Path $source -Recurse -Include *.mp3, *.m4a, *.mp4 -File | ForEach-Object {
    $cleanedName = $_.Name -replace 'amp;039;', "'" -replace 'amp;amp;', '&'
    $targetPath = Join-Path $target $cleanedName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($cleanedName)
    $ext = [System.IO.Path]::GetExtension($cleanedName)
    $counter = 1

    while (Test-Path $targetPath) {
        $targetPath = Join-Path $target "$baseName`_$counter$ext"
        $counter++
    }

    Move-Item -LiteralPath $_.FullName -Destination $targetPath -Force
    Write-Host "Verschoben nach: $([System.IO.Path]::GetFileName($targetPath))"
}

# Leere Ordner entfernen
$emptyFolders = Get-ChildItem -Path $source -Recurse -Directory | Where-Object {
    @(Get-ChildItem -Path $_.FullName -Force -Recurse -File).Count -eq 0
}

foreach ($folder in $emptyFolders) {
    Remove-Item -Path $folder.FullName -Force -Recurse
    Write-Host "Gelöschter leerer Ordner: $($folder.FullName)"
}
