# Backup and File Management System for WebImageOptimizer (Task 7)
# Implements secure backup creation and file management operations

<#
.SYNOPSIS
    Creates timestamped backups of original image files before processing.

.DESCRIPTION
    Creates secure backups of image files with timestamped directory structure,
    maintains original directory hierarchy, and provides integrity verification.
    Supports rollback capabilities and backup management operations.

.PARAMETER FilePaths
    Array of file paths to backup.

.PARAMETER BackupDirectory
    Root directory where backups will be created. If not specified, uses configuration default.

.PARAMETER Configuration
    Configuration hashtable containing backup settings.

.PARAMETER VerifyIntegrity
    If specified, verifies backup integrity after creation.

.OUTPUTS
    [hashtable] Contains backup operation results and metadata.

.EXAMPLE
    $result = Backup-OriginalImages -FilePaths @("C:\images\photo1.jpg", "C:\images\photo2.png") -BackupDirectory "C:\backup"

.EXAMPLE
    $result = Backup-OriginalImages -FilePaths $imageFiles -Configuration $config -VerifyIntegrity
#>
function Backup-OriginalImages {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FilePaths,

        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory,

        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyIntegrity
    )

    Write-Verbose "Starting backup operation for $($FilePaths.Count) files"

    # Validate input paths (do this outside try-catch to allow validation errors to bubble up)
    foreach ($path in $FilePaths) {
        # Basic path validation to prevent directory traversal
        if ($path -match '\.\.[/\\]' -or $path -match '^[/\\]' -or $path -match '^[A-Za-z]:[/\\].*[/\\]\.\.[/\\]') {
            throw "Invalid path detected (potential directory traversal): $path"
        }

        if (-not (Test-Path -Path $path)) {
            throw "File not found: $path"
        }

        # Additional validation after resolving path
        try {
            $resolvedPath = Resolve-Path -Path $path -ErrorAction Stop
            if ($resolvedPath.Path -match '\.\.[/\\]') {
                throw "Invalid resolved path detected (potential directory traversal): $path"
            }
        }
        catch {
            throw "Failed to resolve path: $path - $($_.Exception.Message)"
        }
    }

    try {

        # Determine backup directory
        if (-not $BackupDirectory) {
            if ($Configuration -and $Configuration.output -and $Configuration.output.backupDirectory) {
                $BackupDirectory = $Configuration.output.backupDirectory
            } else {
                $BackupDirectory = "backup"
            }
        }

        # Create timestamped backup directory
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupId = "backup_$timestamp"
        $timestampedBackupDir = Join-Path $BackupDirectory $backupId

        Write-Verbose "Creating backup directory: $timestampedBackupDir"
        $backupDirInfo = New-Item -Path $timestampedBackupDir -ItemType Directory -Force -ErrorAction Stop

        # Initialize backup tracking
        $backupResults = @{
            BackupId = $backupId
            BackupDirectory = $backupDirInfo.FullName
            CreatedAt = Get-Date
            TotalFiles = $FilePaths.Count
            SuccessfulBackups = 0
            FailedBackups = 0
            BackupFiles = @()
            FailedFiles = @()
            TotalOriginalSize = 0
            TotalBackupSize = 0
        }

        # Find common base path for maintaining directory structure
        $commonBasePath = Find-CommonBasePath -Paths $FilePaths

        # Backup each file
        foreach ($filePath in $FilePaths) {
            try {
                Write-Verbose "Backing up file: $filePath"

                # Calculate relative path from common base
                $relativePath = if ($commonBasePath) {
                    $filePath.Replace($commonBasePath, "").TrimStart('\', '/')
                } else {
                    Split-Path $filePath -Leaf
                }
                $backupFilePath = Join-Path $timestampedBackupDir $relativePath

                # Ensure backup subdirectory exists
                $backupFileDir = Split-Path $backupFilePath -Parent
                if (-not (Test-Path $backupFileDir)) {
                    New-Item -Path $backupFileDir -ItemType Directory -Force | Out-Null
                }

                # Copy file to backup location
                Copy-Item -Path $filePath -Destination $backupFilePath -Force -ErrorAction Stop

                # Collect file metadata
                $originalFile = Get-Item -Path $filePath
                $backupFile = Get-Item -Path $backupFilePath

                $fileBackupInfo = @{
                    OriginalPath = $originalFile.FullName
                    BackupPath = $backupFile.FullName
                    RelativePath = $relativePath
                    OriginalSize = $originalFile.Length
                    BackupSize = $backupFile.Length
                    OriginalHash = (Get-FileHash -Path $originalFile.FullName -Algorithm SHA256).Hash
                    BackupHash = (Get-FileHash -Path $backupFile.FullName -Algorithm SHA256).Hash
                    BackedUpAt = Get-Date
                }

                $backupResults.BackupFiles += $fileBackupInfo
                $backupResults.SuccessfulBackups++
                $backupResults.TotalOriginalSize += $originalFile.Length
                $backupResults.TotalBackupSize += $backupFile.Length

                Write-Verbose "Successfully backed up: $filePath -> $backupFilePath"
            }
            catch {
                Write-Warning "Failed to backup file '$filePath': $($_.Exception.Message)"
                $backupResults.FailedFiles += @{
                    OriginalPath = $filePath
                    Error = $_.Exception.Message
                    FailedAt = Get-Date
                }
                $backupResults.FailedBackups++
            }
        }

        # Create backup manifest
        $manifest = @{
            backupId = $backupResults.BackupId
            createdAt = $backupResults.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ssZ")
            originalBasePath = $commonBasePath
            backupBasePath = $backupResults.BackupDirectory
            files = $backupResults.BackupFiles
            totalFiles = $backupResults.TotalFiles
            successfulBackups = $backupResults.SuccessfulBackups
            failedBackups = $backupResults.FailedBackups
            totalOriginalSize = $backupResults.TotalOriginalSize
            totalBackupSize = $backupResults.TotalBackupSize
            integrityVerified = $false
        }

        # Save manifest to backup directory
        $manifestPath = Join-Path $timestampedBackupDir "backup_manifest.json"
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8

        Write-Verbose "Backup manifest created: $manifestPath"

        # Verify integrity if requested
        if ($VerifyIntegrity) {
            Write-Verbose "Verifying backup integrity"
            $integrityResult = Test-BackupIntegrity -BackupPath $timestampedBackupDir -OriginalPaths $FilePaths
            $manifest.integrityVerified = $integrityResult.IsValid

            # Update manifest with integrity results
            $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
        }

        Write-Verbose "Backup operation completed. Success: $($backupResults.SuccessfulBackups), Failed: $($backupResults.FailedBackups)"
        return $backupResults
    }
    catch {
        Write-Error "Backup operation failed: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Verifies the integrity of backup files by comparing with originals.

.DESCRIPTION
    Compares backup files with their original counterparts using file hashes
    to ensure backup integrity and detect any corruption.

.PARAMETER BackupPath
    Path to the backup directory containing the backup manifest.

.PARAMETER OriginalPaths
    Array of original file paths to verify against.

.OUTPUTS
    [hashtable] Contains integrity verification results.

.EXAMPLE
    $result = Test-BackupIntegrity -BackupPath "C:\backup\backup_20241201_143022" -OriginalPaths $originalFiles
#>
function Test-BackupIntegrity {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,

        [Parameter(Mandatory = $true)]
        [string[]]$OriginalPaths
    )

    Write-Verbose "Verifying backup integrity for: $BackupPath"

    try {
        # Load backup manifest
        $manifestPath = Join-Path $BackupPath "backup_manifest.json"
        if (-not (Test-Path $manifestPath)) {
            throw "Backup manifest not found: $manifestPath"
        }

        $manifest = Get-Content $manifestPath | ConvertFrom-Json

        $integrityResults = @{
            IsValid = $true
            BackupPath = $BackupPath
            VerifiedFiles = 0
            FailedFiles = 0
            VerificationErrors = @()
            VerifiedAt = Get-Date
        }

        # Verify each file in the manifest
        foreach ($fileInfo in $manifest.files) {
            try {
                # Check if backup file exists
                if (-not (Test-Path $fileInfo.BackupPath)) {
                    $integrityResults.IsValid = $false
                    $integrityResults.FailedFiles++
                    $integrityResults.VerificationErrors += "Backup file missing: $($fileInfo.BackupPath)"
                    continue
                }

                # Check if original file still exists
                if (-not (Test-Path $fileInfo.OriginalPath)) {
                    Write-Warning "Original file no longer exists: $($fileInfo.OriginalPath)"
                    continue
                }

                # Compare file hashes
                $currentOriginalHash = (Get-FileHash -Path $fileInfo.OriginalPath -Algorithm SHA256).Hash
                $currentBackupHash = (Get-FileHash -Path $fileInfo.BackupPath -Algorithm SHA256).Hash

                if ($currentBackupHash -ne $fileInfo.BackupHash) {
                    $integrityResults.IsValid = $false
                    $integrityResults.FailedFiles++
                    $integrityResults.VerificationErrors += "Backup file corrupted: $($fileInfo.BackupPath)"
                } elseif ($currentOriginalHash -ne $fileInfo.OriginalHash) {
                    Write-Warning "Original file has been modified since backup: $($fileInfo.OriginalPath)"
                } else {
                    $integrityResults.VerifiedFiles++
                }
            }
            catch {
                $integrityResults.IsValid = $false
                $integrityResults.FailedFiles++
                $integrityResults.VerificationErrors += "Verification error for $($fileInfo.OriginalPath): $($_.Exception.Message)"
            }
        }

        Write-Verbose "Integrity verification completed. Valid: $($integrityResults.IsValid), Verified: $($integrityResults.VerifiedFiles), Failed: $($integrityResults.FailedFiles)"
        return $integrityResults
    }
    catch {
        Write-Error "Integrity verification failed: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Removes old backup directories based on retention policy.

.DESCRIPTION
    Cleans up old backup directories while preserving recent backups
    according to the specified retention policy.

.PARAMETER BackupRootPath
    Root directory containing backup directories.

.PARAMETER RetentionDays
    Number of days to retain backups (default: 30).

.OUTPUTS
    [hashtable] Contains cleanup operation results.

.EXAMPLE
    $result = Remove-BackupFiles -BackupRootPath "C:\backup" -RetentionDays 30
#>
function Remove-BackupFiles {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRootPath,

        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 30
    )

    Write-Verbose "Starting backup cleanup in: $BackupRootPath (Retention: $RetentionDays days)"

    try {
        if (-not (Test-Path $BackupRootPath)) {
            Write-Warning "Backup root path does not exist: $BackupRootPath"
            return @{
                BackupRootPath = $BackupRootPath
                RemovedBackups = 0
                PreservedBackups = 0
                RemovedDirectories = @()
                PreservedDirectories = @()
                CleanupErrors = @()
            }
        }

        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $cleanupResults = @{
            BackupRootPath = $BackupRootPath
            RetentionDays = $RetentionDays
            CutoffDate = $cutoffDate
            RemovedBackups = 0
            PreservedBackups = 0
            RemovedDirectories = @()
            PreservedDirectories = @()
            CleanupErrors = @()
            CleanedUpAt = Get-Date
        }

        # Find backup directories (those matching backup_YYYYMMDD_HHMMSS pattern)
        $backupDirs = Get-ChildItem -Path $BackupRootPath -Directory | Where-Object {
            $_.Name -match '^backup_\d{8}_\d{6}$'
        }

        foreach ($backupDir in $backupDirs) {
            try {
                if ($backupDir.CreationTime -lt $cutoffDate) {
                    # Remove old backup
                    Write-Verbose "Removing old backup: $($backupDir.FullName)"
                    Remove-Item -Path $backupDir.FullName -Recurse -Force -ErrorAction Stop
                    $cleanupResults.RemovedBackups++
                    $cleanupResults.RemovedDirectories += $backupDir.FullName
                } else {
                    # Preserve recent backup
                    Write-Verbose "Preserving recent backup: $($backupDir.FullName)"
                    $cleanupResults.PreservedBackups++
                    $cleanupResults.PreservedDirectories += $backupDir.FullName
                }
            }
            catch {
                Write-Warning "Failed to process backup directory '$($backupDir.FullName)': $($_.Exception.Message)"
                $cleanupResults.CleanupErrors += @{
                    Directory = $backupDir.FullName
                    Error = $_.Exception.Message
                    FailedAt = Get-Date
                }
            }
        }

        Write-Verbose "Backup cleanup completed. Removed: $($cleanupResults.RemovedBackups), Preserved: $($cleanupResults.PreservedBackups)"
        return $cleanupResults
    }
    catch {
        Write-Error "Backup cleanup failed: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Restores files from backup to a specified location.

.DESCRIPTION
    Restores backed up files to a target location, optionally overwriting
    existing files. Maintains directory structure from backup.

.PARAMETER BackupPath
    Path to the backup directory containing files to restore.

.PARAMETER RestoreToPath
    Target directory where files should be restored.

.PARAMETER OverwriteExisting
    If specified, overwrites existing files at the restore location.

.OUTPUTS
    [hashtable] Contains restore operation results.

.EXAMPLE
    $result = Restore-BackupFiles -BackupPath "C:\backup\backup_20241201_143022" -RestoreToPath "C:\restored"
#>
function Restore-BackupFiles {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,

        [Parameter(Mandatory = $true)]
        [string]$RestoreToPath,

        [Parameter(Mandatory = $false)]
        [switch]$OverwriteExisting
    )

    Write-Verbose "Starting restore operation from: $BackupPath to: $RestoreToPath"

    try {
        # Load backup manifest
        $manifestPath = Join-Path $BackupPath "backup_manifest.json"
        if (-not (Test-Path $manifestPath)) {
            throw "Backup manifest not found: $manifestPath"
        }

        $manifest = Get-Content $manifestPath | ConvertFrom-Json

        # Ensure restore directory exists
        $restoreDir = New-Item -Path $RestoreToPath -ItemType Directory -Force -ErrorAction Stop

        $restoreResults = @{
            BackupPath = $BackupPath
            RestoreToPath = $restoreDir.FullName
            RestoredFiles = 0
            FailedRestores = 0
            OverwrittenFiles = 0
            SkippedFiles = 0
            RestoredFileList = @()
            RestoreErrors = @()
            RestoredAt = Get-Date
        }

        # Restore each file from the manifest
        foreach ($fileInfo in $manifest.files) {
            try {
                # Check if backup file exists
                if (-not (Test-Path $fileInfo.BackupPath)) {
                    $restoreResults.FailedRestores++
                    $restoreResults.RestoreErrors += "Backup file missing: $($fileInfo.BackupPath)"
                    continue
                }

                # Calculate restore file path
                $restoreFilePath = Join-Path $restoreDir.FullName $fileInfo.RelativePath

                # Ensure restore subdirectory exists
                $restoreFileDir = Split-Path $restoreFilePath -Parent
                if (-not (Test-Path $restoreFileDir)) {
                    New-Item -Path $restoreFileDir -ItemType Directory -Force | Out-Null
                }

                # Check if file already exists at restore location
                if (Test-Path $restoreFilePath) {
                    if ($OverwriteExisting) {
                        Write-Verbose "Overwriting existing file: $restoreFilePath"
                        Copy-Item -Path $fileInfo.BackupPath -Destination $restoreFilePath -Force -ErrorAction Stop
                        $restoreResults.OverwrittenFiles++
                    } else {
                        Write-Verbose "Skipping existing file: $restoreFilePath"
                        $restoreResults.SkippedFiles++
                        continue
                    }
                } else {
                    # Restore file
                    Copy-Item -Path $fileInfo.BackupPath -Destination $restoreFilePath -Force -ErrorAction Stop
                }

                $restoreResults.RestoredFiles++
                $restoreResults.RestoredFileList += $restoreFilePath

                Write-Verbose "Successfully restored: $($fileInfo.BackupPath) -> $restoreFilePath"
            }
            catch {
                Write-Warning "Failed to restore file '$($fileInfo.BackupPath)': $($_.Exception.Message)"
                $restoreResults.FailedRestores++
                $restoreResults.RestoreErrors += @{
                    BackupPath = $fileInfo.BackupPath
                    Error = $_.Exception.Message
                    FailedAt = Get-Date
                }
            }
        }

        Write-Verbose "Restore operation completed. Restored: $($restoreResults.RestoredFiles), Failed: $($restoreResults.FailedRestores), Overwritten: $($restoreResults.OverwrittenFiles)"
        return $restoreResults
    }
    catch {
        Write-Error "Restore operation failed: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Finds the common base path from an array of file paths.

.DESCRIPTION
    Helper function to determine the common base directory path
    from a collection of file paths for maintaining directory structure.

.PARAMETER Paths
    Array of file paths to analyze.

.OUTPUTS
    [string] The common base path.
#>
function Find-CommonBasePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    if ($Paths.Count -eq 0) {
        return ""
    }

    if ($Paths.Count -eq 1) {
        return Split-Path $Paths[0] -Parent
    }

    # Get directory paths
    $dirPaths = $Paths | ForEach-Object { Split-Path $_ -Parent }

    # Find common base path
    $commonPath = $dirPaths[0]
    for ($i = 1; $i -lt $dirPaths.Count; $i++) {
        while ($commonPath -and -not $dirPaths[$i].StartsWith($commonPath)) {
            $commonPath = Split-Path $commonPath -Parent
        }
    }

    return $commonPath
}
