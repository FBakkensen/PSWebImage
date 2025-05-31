# Backup Cleanup Tests for WebImageOptimizer
# Tests to verify that backup directories are properly cleaned up after test execution
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

BeforeAll {
    # Import the module and test data libraries
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot "WebImageOptimizer\WebImageOptimizer.psd1") -Force
    
    # Import test data libraries
    . (Join-Path $PSScriptRoot "..\TestDataLibraries\MainFunction.TestDataLibrary.ps1")
    . (Join-Path $PSScriptRoot "..\TestDataLibraries\BackupManagement.TestDataLibrary.ps1")
    
    # Set up test environment
    $script:TestRootPath = Join-Path $env:TEMP "WebImageOptimizer_BackupCleanup_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:OriginalLocation = Get-Location
}

AfterAll {
    # Comprehensive cleanup
    try {
        if ($script:TestRootPath) {
            Remove-MainFunctionTestData -TestRootPath $script:TestRootPath
        }
        
        # Restore original location
        if ($script:OriginalLocation) {
            Set-Location $script:OriginalLocation
        }
    }
    catch {
        Write-Warning "Failed to complete cleanup: $($_.Exception.Message)"
    }
}

Describe "Backup Directory Cleanup Functionality" -Tags @('Unit', 'BackupCleanup') {

    Context "When backup directories are created during tests" {
        
        BeforeEach {
            # Ensure clean state
            if (Test-Path "backup") {
                Remove-Item -Path "backup" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        AfterEach {
            # Clean up after each test
            if (Test-Path "backup") {
                Remove-Item -Path "backup" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should create backup directories in expected locations" {
            # Given: A test scenario with files to backup
            $testScenario = New-MainFunctionTestScenario -TestRootPath $script:TestRootPath
            $testFiles = Get-ChildItem -Path $testScenario.InputDirectory -File -Recurse | Select-Object -First 3
            
            # When: I create backups using the Backup-OriginalImages function
            if (Get-Command Backup-OriginalImages -ErrorAction SilentlyContinue) {
                $backupResult = Backup-OriginalImages -FilePaths ($testFiles | ForEach-Object { $_.FullName })
                
                # Then: Backup directories should be created
                $backupResult | Should -Not -BeNullOrEmpty
                $backupResult.BackupDirectory | Should -Not -BeNullOrEmpty
                Test-Path $backupResult.BackupDirectory | Should -Be $true
                
                # And: The backup directory should follow the expected pattern
                $backupDirName = Split-Path $backupResult.BackupDirectory -Leaf
                $backupDirName | Should -Match '^backup_\d{8}_\d{6}$'
            } else {
                Set-ItResult -Pending -Because "Backup-OriginalImages function not available"
            }
        }

        It "Should clean up backup directories using Remove-MainFunctionTestData" {
            # Given: Backup directories exist in the current directory
            $backupRoot = "backup"
            $testBackupDir1 = Join-Path $backupRoot "backup_20250531_120000"
            $testBackupDir2 = Join-Path $backupRoot "backup_20250531_130000"
            
            # Create test backup directories
            New-Item -Path $testBackupDir1 -ItemType Directory -Force | Out-Null
            New-Item -Path $testBackupDir2 -ItemType Directory -Force | Out-Null
            
            # Add some test files to make them realistic
            "test backup content 1" | Set-Content -Path (Join-Path $testBackupDir1 "test1.txt")
            "test backup content 2" | Set-Content -Path (Join-Path $testBackupDir2 "test2.txt")
            
            # Verify they exist
            Test-Path $testBackupDir1 | Should -Be $true
            Test-Path $testBackupDir2 | Should -Be $true
            
            # When: I call the cleanup function
            Remove-MainFunctionTestData -TestRootPath $script:TestRootPath
            
            # Then: The backup directories should be removed
            Test-Path $testBackupDir1 | Should -Be $false
            Test-Path $testBackupDir2 | Should -Be $false
            Test-Path $backupRoot | Should -Be $false
        }

        It "Should clean up backup directories using Remove-BackupTestData" {
            # Given: Backup directories exist in the current directory
            $backupRoot = "backup"
            $testBackupDir1 = Join-Path $backupRoot "backup_20250531_140000"
            $testBackupDir2 = Join-Path $backupRoot "backup_20250531_150000"
            
            # Create test backup directories
            New-Item -Path $testBackupDir1 -ItemType Directory -Force | Out-Null
            New-Item -Path $testBackupDir2 -ItemType Directory -Force | Out-Null
            
            # Add some test files
            "backup test content 1" | Set-Content -Path (Join-Path $testBackupDir1 "backup1.txt")
            "backup test content 2" | Set-Content -Path (Join-Path $testBackupDir2 "backup2.txt")
            
            # Verify they exist
            Test-Path $testBackupDir1 | Should -Be $true
            Test-Path $testBackupDir2 | Should -Be $true
            
            # When: I call the backup cleanup function with Force
            Remove-BackupTestData -TestRootPath $script:TestRootPath -Force
            
            # Then: The backup directories should be removed
            Test-Path $testBackupDir1 | Should -Be $false
            Test-Path $testBackupDir2 | Should -Be $false
            Test-Path $backupRoot | Should -Be $false
        }

        It "Should handle permission errors gracefully during cleanup" {
            # Given: A backup directory that might have permission issues
            $backupRoot = "backup"
            $testBackupDir = Join-Path $backupRoot "backup_20250531_160000"
            
            # Create test backup directory
            New-Item -Path $testBackupDir -ItemType Directory -Force | Out-Null
            "permission test content" | Set-Content -Path (Join-Path $testBackupDir "permission_test.txt")
            
            # Verify it exists
            Test-Path $testBackupDir | Should -Be $true
            
            # When: I call the cleanup function (should handle any permission issues gracefully)
            { Remove-BackupTestData -TestRootPath $script:TestRootPath -Force } | Should -Not -Throw
            
            # Then: The cleanup should complete without throwing errors
            # (The directory may or may not be removed depending on permissions, but no exception should be thrown)
        }

        It "Should only remove recent test-related backup directories" {
            # Given: Both old and recent backup directories
            $backupRoot = "backup"
            $oldBackupDir = Join-Path $backupRoot "backup_20230101_120000"  # Very old
            $recentBackupDir = Join-Path $backupRoot "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"  # Recent
            
            # Create both directories
            New-Item -Path $oldBackupDir -ItemType Directory -Force | Out-Null
            New-Item -Path $recentBackupDir -ItemType Directory -Force | Out-Null
            
            # Set the old directory's creation time to be very old
            (Get-Item $oldBackupDir).CreationTime = Get-Date "2023-01-01"
            
            # Add content to both
            "old backup content" | Set-Content -Path (Join-Path $oldBackupDir "old.txt")
            "recent backup content" | Set-Content -Path (Join-Path $recentBackupDir "recent.txt")
            
            # Verify both exist
            Test-Path $oldBackupDir | Should -Be $true
            Test-Path $recentBackupDir | Should -Be $true
            
            # When: I call the cleanup function
            Remove-MainFunctionTestData -TestRootPath $script:TestRootPath
            
            # Then: Only the recent backup should be removed (old one preserved)
            Test-Path $oldBackupDir | Should -Be $true  # Old backup preserved
            Test-Path $recentBackupDir | Should -Be $false  # Recent backup removed
            
            # Clean up the old directory manually
            Remove-Item -Path $oldBackupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "When no backup directories exist" {
        
        It "Should handle cleanup gracefully when no backups exist" {
            # Given: No backup directories exist
            if (Test-Path "backup") {
                Remove-Item -Path "backup" -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # When: I call the cleanup functions
            { Remove-MainFunctionTestData -TestRootPath $script:TestRootPath } | Should -Not -Throw
            { Remove-BackupTestData -TestRootPath $script:TestRootPath -Force } | Should -Not -Throw
            
            # Then: No errors should occur
            # (This test verifies that cleanup functions handle the case where no backups exist)
        }
    }

    Context "When backup directories are in different locations" {
        
        It "Should clean up backups in temp directory" {
            # Given: Backup directories in temp location
            $tempBackupRoot = Join-Path $env:TEMP "backup"
            $tempBackupDir = Join-Path $tempBackupRoot "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            
            # Create temp backup directory
            New-Item -Path $tempBackupDir -ItemType Directory -Force | Out-Null
            "temp backup content" | Set-Content -Path (Join-Path $tempBackupDir "temp.txt")
            
            # Verify it exists
            Test-Path $tempBackupDir | Should -Be $true
            
            # When: I call the cleanup function with additional backup paths
            Remove-MainFunctionTestData -TestRootPath $script:TestRootPath -AdditionalBackupPaths @($tempBackupRoot)
            
            # Then: The temp backup should be cleaned up
            Test-Path $tempBackupDir | Should -Be $false
            
            # Clean up temp backup root if empty
            if (Test-Path $tempBackupRoot) {
                $remainingItems = Get-ChildItem -Path $tempBackupRoot -ErrorAction SilentlyContinue
                if (-not $remainingItems) {
                    Remove-Item -Path $tempBackupRoot -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
