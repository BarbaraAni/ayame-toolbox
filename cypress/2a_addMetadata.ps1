param(
    [string]$DownloadsRoot = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads",
    [string]$MetadataFile  = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\data\metadata.txt",
    [switch]$DryRun
)

$logFile = Join-Path $DownloadsRoot "ffmpeg_tag_error.log"

if (-not (Test-Path -LiteralPath $MetadataFile)) {
    throw "Metadata file not found: $MetadataFile"
}

$metaRows = Get-Content -LiteralPath $MetadataFile | Where-Object { $_.Trim() } | ForEach-Object {
    $parts = $_ -split "`t", 2
    if ($parts.Count -lt 2) {
        Write-Warning "Skipping malformed line (no TAB): $_"
        return
    }
    [pscustomobject]@{ Url = $parts[0].Trim(); Singers = $parts[1].Trim() }
}

if ($metaRows.Count -eq 0) { throw "No valid lines found in metadata file." }

$mediaExt = @("*.mp3","*.m4a","*.mp4")

$folders = Get-ChildItem -LiteralPath $DownloadsRoot -Directory |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}T' } |
        Sort-Object Name

if ($folders.Count -eq 0) { throw "No timestamp folders found in $DownloadsRoot" }

$files = foreach ($dir in $folders) {
    $f = Get-ChildItem -LiteralPath $dir.FullName -File -Include $mediaExt | Select-Object -First 1
    if (-not $f) { Write-Warning "No media in: $($dir.FullName)"; continue }
    $f
}

if ($files.Count -eq 0) { throw "No media files found inside timestamp folders." }

if ($metaRows.Count -ne $files.Count) {
    Write-Warning "Count mismatch: metadata lines = $($metaRows.Count), files = $($files.Count). Pairing up to the smaller count."
}

$pairCount = [Math]::Min($metaRows.Count, $files.Count)

for ($i = 0; $i -lt $pairCount; $i++) {
    $row   = $metaRows[$i]
    $file  = $files[$i]
    $ext   = $file.Extension.ToLowerInvariant()
    $input = $file.FullName
    $temp  = Join-Path $file.DirectoryName "$($file.BaseName)_tagged$ext"

    Write-Host ("[{0}/{1}] Tagging:`n  File: {2}`n  Artist: {3}`n  URL->comment: {4}" -f ($i+1), $pairCount, $input, $row.Singers, $row.Url)

    if ($DryRun) { continue }

    $ffArgs = @(
    "-y",
    "-i", $input,
    "-map_metadata", "-1",
    "-c", "copy",
    "-metadata", "artist=$($row.Singers)",
    "-metadata", "comment=$($row.Url)"
    )

    if ($ext -eq ".mp3") {
        $ffArgs += @("-id3v2_version","3")
    } elseif ($ext -in @(".m4a",".mp4")) {
        # Helps keep tags in the container’s metadata
        $ffArgs += @("-movflags","use_metadata_tags")
    }

    # IMPORTANT: specify the OUTPUT file as the LAST argument
    $ffArgs += $temp

    & ffmpeg @ffArgs 2>> $logFile

    if (Test-Path -LiteralPath $temp) {
        try {
            Remove-Item -LiteralPath $input -Force
            Rename-Item -LiteralPath $temp -NewName $file.Name
        } catch {
            Write-Warning "Failed to replace: $($file.FullName) -> $($_.Exception.Message)"
        }
    } else {
        Write-Warning "ffmpeg did not create output for: $($file.FullName). See log: $logFile"
    }
}

Write-Host "Done. Errors (if any) logged to: $logFile"
