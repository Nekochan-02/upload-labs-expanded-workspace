param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$ModId = 'Nekochan-ExpandedWorkspace'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$SourceRoot = Join-Path $RepoRoot "mod/source/mods-unpacked/$ModId"
$ManifestPath = Join-Path $SourceRoot 'manifest.json'
$MainPath = Join-Path $SourceRoot 'mod_main.gd'
$DistDir = Join-Path $RepoRoot 'dist'
$StagingRoot = Join-Path $RepoRoot '.tmp-release-staging'
$ZipPath = Join-Path $DistDir "$ModId-$Version.zip"
$FixedZipTimestamp = [DateTimeOffset]'1980-01-01T00:00:00Z'

function Fail([string]$Message) {
    throw "[build_release] $Message"
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    Fail "Required file missing: $ManifestPath"
}
if (-not (Test-Path -LiteralPath $MainPath -PathType Leaf)) {
    Fail "Required file missing: $MainPath"
}

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$ManifestVersion = [string]$Manifest.version_number
if ($ManifestVersion -ne $Version) {
    Fail "Version mismatch: argument=$Version manifest=$ManifestVersion"
}

$RelativePrefix = "mod/source/mods-unpacked/$ModId/"
$TrackedFiles = & git -C $RepoRoot ls-files -- $RelativePrefix
if ($LASTEXITCODE -ne 0) {
    Fail 'git ls-files failed. Release packaging requires a Git checkout.'
}

$BlockedRelativePaths = @(
    'extensions/scenes/connector_point.gd',
    'extensions/scenes/windows/window_base.gd',
    'extensions/scenes/windows/window_indexed.gd'
)

$AllowedFiles = New-Object System.Collections.Generic.List[string]
foreach ($Tracked in $TrackedFiles) {
    $Normalized = $Tracked -replace '\\', '/'
    if (-not $Normalized.StartsWith($RelativePrefix)) {
        continue
    }

    $Rel = $Normalized.Substring($RelativePrefix.Length)
    $IsAllowed = (
        $Rel -eq 'manifest.json' -or
        $Rel -eq 'mod_main.gd' -or
        $Rel -match '^extensions/.+\.gd$' -or
        $Rel -match '^hooks/.+\.gd$'
    )

    if (-not $IsAllowed) {
        continue
    }

    if ($BlockedRelativePaths -contains $Rel) {
        Fail "Blocked v0.2.9 source file selected for packaging: $Rel"
    }

    $AllowedFiles.Add($Rel)
}

foreach ($Required in @('manifest.json', 'mod_main.gd')) {
    if (-not $AllowedFiles.Contains($Required)) {
        Fail "Required file was not selected by allowlist: $Required"
    }
}

if (Test-Path -LiteralPath $StagingRoot) {
    Remove-Item -LiteralPath $StagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $StagingRoot | Out-Null
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

try {
    $StageModRoot = Join-Path $StagingRoot "mods-unpacked/$ModId"
    New-Item -ItemType Directory -Path $StageModRoot -Force | Out-Null

    if (Test-Path -LiteralPath (Join-Path $SourceRoot 'hooks') -PathType Container) {
        New-Item -ItemType Directory -Path (Join-Path $StageModRoot 'hooks') -Force | Out-Null
    }

    foreach ($Rel in $AllowedFiles) {
        $Src = Join-Path $SourceRoot ($Rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        $Dst = Join-Path $StageModRoot ($Rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Path (Split-Path -Parent $Dst) -Force | Out-Null
        Copy-Item -LiteralPath $Src -Destination $Dst
    }

    $ForbiddenFilePatterns = @('*.exe', '*.dll', '*.pck', '*.save', '*.sav', '*.tscn', '*.tres', '*.res')
    $ForbiddenPathTerms = @('.git', 'vanilla-reference', 'logs', 'Workshop')

    $StageItems = Get-ChildItem -LiteralPath $StagingRoot -Recurse -Force
    foreach ($Item in $StageItems) {
        $Relative = $Item.FullName.Substring($StagingRoot.Length + 1) -replace '\\', '/'
        foreach ($Term in $ForbiddenPathTerms) {
            if ($Relative -match "(^|/)$([regex]::Escape($Term))(/|$)") {
                Fail "Forbidden path term found in staging: $Relative"
            }
        }
        if (-not $Item.PSIsContainer) {
            foreach ($Pattern in $ForbiddenFilePatterns) {
                if ($Item.Name -like $Pattern) {
                    Fail "Forbidden file found in staging: $Relative"
                }
            }
        }
    }

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $Zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $Directories = Get-ChildItem -LiteralPath $StagingRoot -Recurse -Force -Directory |
            Sort-Object FullName
        foreach ($Directory in $Directories) {
            $EntryName = ($Directory.FullName.Substring($StagingRoot.Length + 1) -replace '\\', '/') + '/'
            $Entry = $Zip.CreateEntry($EntryName)
            $Entry.LastWriteTime = $FixedZipTimestamp
        }

        $Files = Get-ChildItem -LiteralPath $StagingRoot -Recurse -Force -File |
            Sort-Object FullName
        foreach ($File in $Files) {
            $EntryName = $File.FullName.Substring($StagingRoot.Length + 1) -replace '\\', '/'
            $Entry = $Zip.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
            $Entry.LastWriteTime = $FixedZipTimestamp
            $InputStream = [System.IO.File]::OpenRead($File.FullName)
            $OutputStream = $Entry.Open()
            try {
                $InputStream.CopyTo($OutputStream)
            }
            finally {
                $OutputStream.Dispose()
                $InputStream.Dispose()
            }
        }
    }
    finally {
        $Zip.Dispose()
    }

    $ZipRead = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $Entries = $ZipRead.Entries | Sort-Object FullName
        $RootEntries = @($Entries |
            ForEach-Object { ($_.FullName -split '/')[0] } |
            Where-Object { $_ } |
            Sort-Object -Unique)

        if (($RootEntries.Count -ne 1) -or ($RootEntries[0] -ne 'mods-unpacked')) {
            Fail "Invalid ZIP root entries: $($RootEntries -join ', ')"
        }
        foreach ($Entry in $Entries) {
            foreach ($Term in $ForbiddenPathTerms) {
                if ($Entry.FullName -match "(^|/)$([regex]::Escape($Term))(/|$)") {
                    Fail "Forbidden path term found in ZIP: $($Entry.FullName)"
                }
            }
            if (-not $Entry.FullName.EndsWith('/')) {
                foreach ($Pattern in $ForbiddenFilePatterns) {
                    if ((Split-Path -Leaf $Entry.FullName) -like $Pattern) {
                        Fail "Forbidden file found in ZIP: $($Entry.FullName)"
                    }
                }
            }
        }
    }
    finally {
        $ZipRead.Dispose()
    }

    $Hash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $FileCount = (Get-ChildItem -LiteralPath $StagingRoot -Recurse -Force -File).Count
    $ZipSize = (Get-Item -LiteralPath $ZipPath).Length

    Write-Output "artifact: $ZipPath"
    Write-Output "size_bytes: $ZipSize"
    Write-Output "file_count: $FileCount"
    Write-Output "zip_root: mods-unpacked"
    Write-Output "manifest_version: $ManifestVersion"
    Write-Output "mod_id: $ModId"
    Write-Output "sha256: $Hash"
}
finally {
    if (Test-Path -LiteralPath $StagingRoot) {
        Remove-Item -LiteralPath $StagingRoot -Recurse -Force
    }
}
