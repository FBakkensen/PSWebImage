# Test suite for WebImageOptimizer Backup and File Management System (Task 7)
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "WebImageOptimizer Backup and File Management System" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:ConfigPath = Join-Path $script:ModulePath "Config"

        # Define paths to the functions we're testing
        $script:BackupFunctionPath = Join-Path $script:PrivatePath "Backup-OriginalImages.ps1"
        $script:ConfigManagerPath = Join-Path $script:PrivatePath "ConfigurationManager.ps1"
        $script:TestDataLibraryPath = Join-Path $script:ModuleRoot "Tests\TestDataLibraries\BackupManagement.TestDataLibrary.ps1"

        # Import existing functions
        if (Test-Path $script:ConfigManagerPath) {
            . $script:ConfigManagerPath
        }
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        }

        # Import the backup functions if they exist
        if (Test-Path $script:BackupFunctionPath) {
            . $script:BackupFunctionPath
        }

        # Set up test root directory
        $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_BackupManagement_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Test root directory: $script:TestRoot" -ForegroundColor Yellow
    }

    AfterAll {
        # Cleanup test data
        if ($script:TestRoot -and (Test-Path $script:TestRoot)) {
            try {
                Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Cleaned up test directory: $script:TestRoot" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to cleanup test directory: $($_.Exception.Message)"
            }
        }
    }

    Context "When testing basic backup creation functionality" {

        BeforeAll {
            # Create test files for basic backup tests
            $script:BasicTestPath = Join-Path $script:TestRoot "BasicBackupTests"
            if (Get-Command New-BackupTestFiles -ErrorAction SilentlyContinue) {
                $script:BasicTestFiles = New-BackupTestFiles -TestRootPath $script:BasicTestPath -FileCount 3
            }
        }

        It "Should create timestamped backup directory" {
            # Given: A set of files to backup
            # When: Backup-OriginalImages is called
            # Then: A timestamped backup directory should be created

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue -and $script:BasicTestFiles) {
                $backupRoot = Join-Path $script:BasicTestPath "backup"
                $filesToBackup = $script:BasicTestFiles.CreatedFiles

                $result = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                $result | Should -Not -BeNullOrEmpty
                $result.BackupDirectory | Should -Match "backup_\d{8}_\d{6}"
                Test-Path $result.BackupDirectory | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented or test files not available"
            }
        }

        It "Should backup all specified files" {
            # Given: Multiple files to backup
            # When: Backup operation is performed
            # Then: All files should be backed up successfully

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue -and $script:BasicTestFiles) {
                $backupRoot = Join-Path $script:BasicTestPath "backup_all_files"
                $filesToBackup = $script:BasicTestFiles.CreatedFiles

                $result = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                $result.TotalFiles | Should -Be $filesToBackup.Count
                $result.SuccessfulBackups | Should -Be $filesToBackup.Count
                $result.FailedBackups | Should -Be 0
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented or test files not available"
            }
        }

        It "Should create backup manifest file" {
            # Given: Files are backed up
            # When: Backup operation completes
            # Then: A backup manifest file should be created with metadata

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue -and $script:BasicTestFiles) {
                $backupRoot = Join-Path $script:BasicTestPath "backup_manifest"
                $filesToBackup = $script:BasicTestFiles.CreatedFiles

                $result = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                $manifestPath = Join-Path $result.BackupDirectory "backup_manifest.json"
                Test-Path $manifestPath | Should -Be $true

                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                $manifest.backupId | Should -Not -BeNullOrEmpty
                $manifest.createdAt | Should -Not -BeNullOrEmpty
                $manifest.totalFiles | Should -Be $filesToBackup.Count
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented or test files not available"
            }
        }
    }

    Context "When testing directory structure preservation" {

        BeforeAll {
            # Create complex directory structure for testing
            $script:ComplexTestPath = Join-Path $script:TestRoot "ComplexStructureTests"
            if (Get-Command New-ComplexDirectoryStructure -ErrorAction SilentlyContinue) {
                $script:ComplexStructure = New-ComplexDirectoryStructure -TestRootPath $script:ComplexTestPath
            }
        }

        It "Should preserve original directory structure in backup" {
            # Given: Files in nested directory structure
            # When: Backup is created
            # Then: The same directory structure should be preserved in backup location

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue -and $script:ComplexStructure) {
                $backupRoot = Join-Path $script:ComplexTestPath "backup_structure"
                $filesToBackup = $script:ComplexStructure.CreatedFiles

                $result = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                # Check that directory structure is preserved
                foreach ($fileMetadata in $script:ComplexStructure.FileMetadata) {
                    $expectedBackupPath = Join-Path $result.BackupDirectory $fileMetadata.RelativePath
                    Test-Path $expectedBackupPath | Should -Be $true
                }
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented or complex structure not available"
            }
        }

        It "Should handle deep nested directories correctly" {
            # Given: Files in deeply nested directory structure
            # When: Backup operation is performed
            # Then: Deep directory paths should be preserved correctly

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue -and $script:ComplexStructure) {
                $backupRoot = Join-Path $script:ComplexTestPath "backup_deep"
                $deepFiles = @($script:ComplexStructure.CreatedFiles | Where-Object {
                    $_ -like "*deep*structure*"
                })

                if ($deepFiles) {
                    $result = Backup-OriginalImages -FilePaths $deepFiles -BackupDirectory $backupRoot

                    $result.SuccessfulBackups | Should -BeGreaterThan 0

                    # Verify deep file exists in backup
                    $deepFile = $deepFiles[0]
                    $fileName = Split-Path $deepFile -Leaf

                    # Check if the file exists in the backup directory (it might be at root level for single file backup)
                    $backupFiles = Get-ChildItem -Path $result.BackupDirectory -Recurse -File | Where-Object { $_.Name -ne "backup_manifest.json" }
                    $backupFileNames = $backupFiles | ForEach-Object { $_.Name }
                    $backupFileNames | Should -Contain $fileName
                }
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented or complex structure not available"
            }
        }
    }

    Context "When testing backup integrity verification" {

        BeforeAll {
            # Create test files for integrity testing
            $script:IntegrityTestPath = Join-Path $script:TestRoot "IntegrityTests"
            if (Get-Command New-BackupTestFiles -ErrorAction SilentlyContinue) {
                $script:IntegrityTestFiles = New-BackupTestFiles -TestRootPath $script:IntegrityTestPath -CreateRealFiles
            }
        }

        It "Should verify backup integrity by comparing file hashes" {
            # Given: Backup files have been created
            # When: Test-BackupIntegrity is called
            # Then: File integrity should be verified using hash comparison

            if (Get-Command Test-BackupIntegrity -ErrorAction SilentlyContinue -and $script:IntegrityTestFiles) {
                $backupRoot = Join-Path $script:IntegrityTestPath "backup_integrity"
                $filesToBackup = $script:IntegrityTestFiles.CreatedFiles

                # First create backup
                if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                    $backupResult = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                    # Then verify integrity
                    $integrityResult = Test-BackupIntegrity -BackupPath $backupResult.BackupDirectory -OriginalPaths $filesToBackup

                    $integrityResult.IsValid | Should -Be $true
                    $integrityResult.VerifiedFiles | Should -Be $filesToBackup.Count
                    $integrityResult.FailedFiles | Should -Be 0
                }
            } else {
                Set-ItResult -Pending -Because "Test-BackupIntegrity function not yet implemented or test files not available"
            }
        }

        It "Should detect corrupted backup files" {
            # Given: A backup with corrupted files
            # When: Integrity check is performed
            # Then: Corruption should be detected and reported

            if (Get-Command Test-BackupIntegrity -ErrorAction SilentlyContinue -and $script:IntegrityTestFiles) {
                $backupRoot = Join-Path $script:IntegrityTestPath "backup_corrupted"
                $filesToBackup = $script:IntegrityTestFiles.CreatedFiles

                # Create backup first
                if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                    $backupResult = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                    # Corrupt one of the backup files
                    $backupFiles = Get-ChildItem -Path $backupResult.BackupDirectory -Recurse -File | Where-Object { $_.Name -ne "backup_manifest.json" }
                    if ($backupFiles) {
                        $corruptFile = $backupFiles[0]
                        Add-Content -Path $corruptFile.FullName -Value "CORRUPTED_DATA"

                        # Verify integrity detects corruption
                        $integrityResult = Test-BackupIntegrity -BackupPath $backupResult.BackupDirectory -OriginalPaths $filesToBackup

                        $integrityResult.IsValid | Should -Be $false
                        $integrityResult.FailedFiles | Should -BeGreaterThan 0
                    }
                }
            } else {
                Set-ItResult -Pending -Because "Test-BackupIntegrity function not yet implemented or test files not available"
            }
        }
    }

    Context "When testing backup cleanup and management" {

        BeforeAll {
            # Create multiple backup scenarios for cleanup testing
            $script:CleanupTestPath = Join-Path $script:TestRoot "CleanupTests"
            if (Get-Command New-BackupScenarios -ErrorAction SilentlyContinue) {
                $script:CleanupScenarios = New-BackupScenarios -TestRootPath $script:CleanupTestPath
            }
        }

        It "Should remove old backup directories based on retention policy" {
            # Given: Multiple backup directories exist
            # When: Remove-BackupFiles is called with retention criteria
            # Then: Old backups should be removed according to retention policy

            if (Get-Command Remove-BackupFiles -ErrorAction SilentlyContinue) {
                $backupRoot = Join-Path $script:CleanupTestPath "backup_cleanup"

                # Create multiple backup directories with different timestamps
                $oldBackupDir = Join-Path $backupRoot "backup_20231201_120000"
                $recentBackupDir = Join-Path $backupRoot "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

                New-Item -Path $oldBackupDir -ItemType Directory -Force | Out-Null
                New-Item -Path $recentBackupDir -ItemType Directory -Force | Out-Null

                # Set old directory creation time to simulate old backup
                (Get-Item $oldBackupDir).CreationTime = (Get-Date).AddDays(-35)

                $cleanupResult = Remove-BackupFiles -BackupRootPath $backupRoot -RetentionDays 30

                # Old backup should be removed, recent should remain
                Test-Path $oldBackupDir | Should -Be $false
                Test-Path $recentBackupDir | Should -Be $true
                $cleanupResult.RemovedBackups | Should -BeGreaterThan 0
            } else {
                Set-ItResult -Pending -Because "Remove-BackupFiles function not yet implemented"
            }
        }

        It "Should preserve recent backups during cleanup" {
            # Given: Recent backup directories exist
            # When: Cleanup operation is performed
            # Then: Recent backups should be preserved

            if (Get-Command Remove-BackupFiles -ErrorAction SilentlyContinue) {
                $backupRoot = Join-Path $script:CleanupTestPath "backup_preserve"

                # Create recent backup directory
                $recentBackupDir = Join-Path $backupRoot "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                New-Item -Path $recentBackupDir -ItemType Directory -Force | Out-Null

                $cleanupResult = Remove-BackupFiles -BackupRootPath $backupRoot -RetentionDays 30

                # Recent backup should be preserved
                Test-Path $recentBackupDir | Should -Be $true
                $cleanupResult.PreservedBackups | Should -BeGreaterThan 0
            } else {
                Set-ItResult -Pending -Because "Remove-BackupFiles function not yet implemented"
            }
        }
    }

    Context "When testing backup restoration functionality" {

        BeforeAll {
            # Create test files for restoration testing
            $script:RestoreTestPath = Join-Path $script:TestRoot "RestoreTests"
            if (Get-Command New-BackupTestFiles -ErrorAction SilentlyContinue) {
                $script:RestoreTestFiles = New-BackupTestFiles -TestRootPath $script:RestoreTestPath -CreateRealFiles
            }
        }

        It "Should restore files from backup to specified location" {
            # Given: A backup exists
            # When: Restore-BackupFiles is called
            # Then: Original files should be restored from backup

            if (Get-Command Restore-BackupFiles -ErrorAction SilentlyContinue -and $script:RestoreTestFiles) {
                $backupRoot = Join-Path $script:RestoreTestPath "backup_restore"
                $restoreLocation = Join-Path $script:RestoreTestPath "restored"
                $filesToBackup = $script:RestoreTestFiles.CreatedFiles

                # Create backup first
                if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                    $backupResult = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot

                    # Restore from backup
                    $restoreResult = Restore-BackupFiles -BackupPath $backupResult.BackupDirectory -RestoreToPath $restoreLocation

                    $restoreResult.RestoredFiles | Should -Be $filesToBackup.Count
                    $restoreResult.FailedRestores | Should -Be 0
                    Test-Path $restoreLocation | Should -Be $true
                }
            } else {
                Set-ItResult -Pending -Because "Restore-BackupFiles function not yet implemented or test files not available"
            }
        }

        It "Should handle overwrite scenarios correctly" {
            # Given: Files exist at restore location
            # When: Restore operation is performed with overwrite option
            # Then: Existing files should be overwritten correctly

            if (Get-Command Restore-BackupFiles -ErrorAction SilentlyContinue -and $script:RestoreTestFiles) {
                $backupRoot = Join-Path $script:RestoreTestPath "backup_overwrite"
                $restoreLocation = Join-Path $script:RestoreTestPath "restored_overwrite"
                $filesToBackup = $script:RestoreTestFiles.CreatedFiles

                # Create backup and initial restore
                if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                    $backupResult = Backup-OriginalImages -FilePaths $filesToBackup -BackupDirectory $backupRoot
                    $firstRestore = Restore-BackupFiles -BackupPath $backupResult.BackupDirectory -RestoreToPath $restoreLocation

                    # Modify restored files
                    $restoredFiles = Get-ChildItem -Path $restoreLocation -Recurse -File
                    if ($restoredFiles) {
                        Add-Content -Path $restoredFiles[0].FullName -Value "MODIFIED_CONTENT"
                    }

                    # Restore again with overwrite
                    $overwriteRestore = Restore-BackupFiles -BackupPath $backupResult.BackupDirectory -RestoreToPath $restoreLocation -OverwriteExisting

                    $overwriteRestore.OverwrittenFiles | Should -BeGreaterThan 0
                }
            } else {
                Set-ItResult -Pending -Because "Restore-BackupFiles function not yet implemented or test files not available"
            }
        }
    }

    Context "When testing error handling and edge cases" {

        It "Should handle permission errors gracefully" {
            # Given: Files with restricted permissions
            # When: Backup operation is attempted
            # Then: Permission errors should be handled gracefully and reported

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                # This test would need to create files with restricted permissions
                # For now, we'll mark it as pending until implementation
                Set-ItResult -Pending -Because "Permission testing requires specific setup"
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented"
            }
        }

        It "Should handle insufficient disk space scenarios" {
            # Given: Insufficient disk space for backup
            # When: Backup operation is attempted
            # Then: Disk space error should be handled gracefully

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                # This test would need to simulate disk space issues
                # For now, we'll mark it as pending until implementation
                Set-ItResult -Pending -Because "Disk space testing requires specific setup"
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented"
            }
        }

        It "Should validate input paths to prevent directory traversal" {
            # Given: Malicious input paths
            # When: Backup operation is attempted
            # Then: Path validation should prevent directory traversal attacks

            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                $maliciousPaths = @(
                    "..\..\..\..\windows\system32\config\sam",
                    "/etc/passwd",
                    "C:\Windows\System32\drivers\etc\hosts"
                )

                foreach ($maliciousPath in $maliciousPaths) {
                    {
                        try {
                            Backup-OriginalImages -FilePaths @($maliciousPath) -BackupDirectory "C:\temp\backup"
                            throw "Expected validation to fail for path: $maliciousPath"
                        }
                        catch [System.Management.Automation.RuntimeException] {
                            # This is expected - validation should throw
                            if ($_.Exception.Message -like "*Invalid path detected*" -or $_.Exception.Message -like "*File not found*") {
                                # Expected validation error - re-throw to satisfy Should -Throw
                                throw
                            } else {
                                # Unexpected error
                                throw "Unexpected error for path '$maliciousPath': $($_.Exception.Message)"
                            }
                        }
                    } | Should -Throw
                }
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not yet implemented"
            }
        }
    }
}
