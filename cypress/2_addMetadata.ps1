param(
    [string]$DownloadsRoot = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads",
    [string]$MetadataFile  = "F:\Coding\1_Private_Project\ayame_toolbox\cypress\data\metadata.txt",
    [switch]$DryRun
)

$logFile = Join-Path $DownloadsRoot "ffmpeg_tag_error.log"

# --- Helpers -----------------------------------------------------------------
function Write-Step($msg) { Write-Host "[+] $msg" -ForegroundColor Cyan }

# --- 0) Guard checks ----------------------------------------------------------
if (-not (Test-Path -LiteralPath $MetadataFile)) {
    throw "Metadata file not found: $MetadataFile"
}

# --- 1) Read metadata lines (URL<TAB>Singers) --------------------------------
Write-Step "Reading metadata from $MetadataFile"
$metaRows =
Get-Content -LiteralPath $MetadataFile |
        Where-Object { $_.Trim() -ne "" } |
        ForEach-Object {
            $parts = $_ -split "`t", 2
            if ($parts.Count -lt 2) {
                Write-Warning "Skipping malformed line (no TAB): $_"
                return
            }
            [pscustomobject]@{
                Url     = $parts[0].Trim()
                Singers = $parts[1].Trim()
            }
        }

if (-not $metaRows -or $metaRows.Count -eq 0) {
    throw "No valid lines found in metadata file."
}

# --- 2) Collect timestamp folders (each with exactly one media file) ---------
# Use explicit extension filter to avoid quirks with -Include and -Recurse
$validExts = @('.mp3','.m4a','.mp4')

Write-Step "Scanning timestamp folders in $DownloadsRoot"
$folders =
Get-ChildItem -LiteralPath $DownloadsRoot -Directory |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}T' } |
        Sort-Object Name

if (-not $folders -or $folders.Count -eq 0) {
    throw "No timestamp folders found in $DownloadsRoot"
}

# Build list of target files in the same order
$files = foreach ($dir in $folders) {
    $f = Get-ChildItem -LiteralPath $dir.FullName -File |
            Where-Object { $_.Extension.ToLowerInvariant() -in $validExts } |
            Select-Object -First 1
    if (-not $f) {
        Write-Warning "No media file found in: $($dir.FullName)"
        continue
    }
    $f
}

if (-not $files -or $files.Count -eq 0) {
    throw "No media files found inside timestamp folders."
}

# --- 3) Pair counts -----------------------------------------------------------
if ($metaRows.Count -ne $files.Count) {
    Write-Warning ("Count mismatch: metadata lines = {0}, files = {1}. Pairing up to the smaller count." -f $metaRows.Count, $files.Count)
}
$pairCount = [Math]::Min($metaRows.Count, $files.Count)

Write-Step "Preparing to tag $pairCount file(s)"
if (-not $DryRun) {
    # Reset log
    "" | Out-File -FilePath $logFile -Encoding UTF8
}

# --- 4) Tagging loop ----------------------------------------------------------
for ($i = 0; $i -lt $pairCount; $i++) {
    $row   = $metaRows[$i]
    $file  = $files[$i]

    if (-not $file) {
        Write-Warning "Skipping missing file at index $i"
        continue
    }

    $ext   = $file.Extension.ToLowerInvariant()
    $input = $file.FullName
    $temp  = Join-Path $file.DirectoryName ("{0}_tagged{1}" -f $file.BaseName, $ext)

    Write-Host ""
    Write-Step ("[{0}/{1}] Tagging file:`n  {2}`n  artist: {3}`n  url -> comment/description: {4}" -f ($i+1), $pairCount, $input, $row.Singers, $row.Url)

    if ($DryRun) { continue }

    # Build ffmpeg args
    $ffArgs = @(
    "-y",
    "-hide_banner",
    "-i", $input,
    "-map_metadata", "-1",
    "-c", "copy"
    )

    # Container-level metadata (shown by many tools)
    $ffArgs = @(
    "-y",
    "-hide_banner",
    "-i", $input,
    "-map_metadata", "-1",
    "-c", "copy",
    "-metadata", "artist=$($row.Singers)",
    "-metadata", "album=Smule",
    "-metadata", "publisher=$($row.Url)",
    "-metadata", "comment=$($row.Url)"
    )

    # Output LAST
    $ffArgs += $temp

    # Execute ffmpeg
    & ffmpeg @ffArgs 2>> $logFile

    if (Test-Path -LiteralPath $temp) {
        try {
            Remove-Item -LiteralPath $input -Force
            Rename-Item -LiteralPath $temp -NewName $file.Name
        } catch {
            Write-Warning "Failed to replace original file: $($file.FullName). Error: $($_.Exception.Message)"
            # Keep temp file for inspection
        }
    } else {
        Write-Warning "ffmpeg did not create output for: $($file.FullName). See log: $logFile"
    }
}

Write-Host ""
Write-Step "Done. Errors (if any) logged to: $logFile"

# --- 5) Optional: quick verify example (uncomment to test one file) ----------
ffprobe -v error -show_entries format_tags=artist,comment,description,synopsis -of default=nw=1:nk=1 "F:\Coding\1_Private_Project\ayame_toolbox\cypress\downloads\2025-08-15T13-08-33-985Z\Free (From Kpop Demon Hunters).mp3"
# ffprobe -v error -show_entries format_tags=artist,comment,description,synopsis -of default=nw=1:nk=1 "FULL\PATH\TO\A\FILE.m4a"
