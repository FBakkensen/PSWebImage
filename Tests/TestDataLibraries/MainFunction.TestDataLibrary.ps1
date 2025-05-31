# Main Function Test Data Library
# Centralized test data creation for Optimize-WebImages main function testing
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates test scenarios for the main Optimize-WebImages function.

.DESCRIPTION
    Creates comprehensive test scenarios including directory structures, test images,
    configuration files, and parameter combinations for testing the main function
    with various scenarios including success cases, error cases, and edge cases.

.PARAMETER TestRootPath
    The root path where the test scenario should be created.

.PARAMETER IncludeRealImages
    If specified, attempts to create real image files for more realistic testing.

.OUTPUTS
    [PSCustomObject] Information about the created test scenario including paths and metadata.

.EXAMPLE
    $scenario = New-MainFunctionTestScenario -TestRootPath "C:\temp\maintest"
#>
function New-MainFunctionTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRealImages
    )

    try {
        Write-Verbose "Creating main function test scenario at: $TestRootPath"

        # Create main test directory structure
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        $inputDir = New-Item -Path (Join-Path $testDir "input") -ItemType Directory -Force
        $outputDir = New-Item -Path (Join-Path $testDir "output") -ItemType Directory -Force
        $backupDir = New-Item -Path (Join-Path $testDir "backup") -ItemType Directory -Force
        $configDir = New-Item -Path (Join-Path $testDir "config") -ItemType Directory -Force

        # Create subdirectories for different test scenarios
        $subDirs = @(
            New-Item -Path (Join-Path $inputDir "photos") -ItemType Directory -Force
            New-Item -Path (Join-Path $inputDir "graphics") -ItemType Directory -Force
            New-Item -Path (Join-Path $inputDir "mixed") -ItemType Directory -Force
        )

        # Create test images in different directories
        $testImages = @()

        # Photos directory - JPEG images
        $photoImages = @(
            @{ Name = "photo1.jpg"; Format = "JPEG"; Size = 1024000; Directory = "photos" }
            @{ Name = "photo2.jpg"; Format = "JPEG"; Size = 2048000; Directory = "photos" }
            @{ Name = "landscape.jpeg"; Format = "JPEG"; Size = 1536000; Directory = "photos" }
        )

        # Graphics directory - PNG images
        $graphicImages = @(
            @{ Name = "logo.png"; Format = "PNG"; Size = 512000; Directory = "graphics" }
            @{ Name = "icon.png"; Format = "PNG"; Size = 256000; Directory = "graphics" }
        )

        # Mixed directory - various formats
        $mixedImages = @(
            @{ Name = "banner.webp"; Format = "WebP"; Size = 768000; Directory = "mixed" }
            @{ Name = "thumbnail.avif"; Format = "AVIF"; Size = 384000; Directory = "mixed" }
            @{ Name = "background.png"; Format = "PNG"; Size = 1024000; Directory = "mixed" }
        )

        $allImageSpecs = $photoImages + $graphicImages + $mixedImages

        foreach ($imageSpec in $allImageSpecs) {
            $imagePath = Join-Path (Join-Path $inputDir $imageSpec.Directory) $imageSpec.Name

            if ($IncludeRealImages) {
                # Create mock image with realistic size
                $content = "MOCK_IMAGE_" + ("X" * ($imageSpec.Size / 100))
            } else {
                # Create simple mock content
                $content = @"
MOCK_IMAGE_FILE
Format: $($imageSpec.Format)
Size: $($imageSpec.Size)
Directory: $($imageSpec.Directory)
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
            }

            Set-Content -Path $imagePath -Value $content -Encoding UTF8
            $testImages += [PSCustomObject]@{
                Path = $imagePath
                Name = $imageSpec.Name
                Format = $imageSpec.Format
                Directory = $imageSpec.Directory
                Size = (Get-Item $imagePath).Length
            }

            Write-Verbose "Created test image: $($imageSpec.Name) in $($imageSpec.Directory)"
        }

        # Create test configuration files
        $testConfigs = New-MainFunctionTestConfigurations -ConfigDirectory $configDir.FullName

        # Create parameter test scenarios
        $parameterScenarios = New-MainFunctionParameterScenarios -InputPath $inputDir.FullName -OutputPath $outputDir.FullName -BackupPath $backupDir.FullName

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            InputDirectory = $inputDir.FullName
            OutputDirectory = $outputDir.FullName
            BackupDirectory = $backupDir.FullName
            ConfigDirectory = $configDir.FullName
            SubDirectories = $subDirs | ForEach-Object { $_.FullName }
            TestImages = $testImages
            TotalImages = $testImages.Count
            TestConfigurations = $testConfigs
            ParameterScenarios = $parameterScenarios
            SupportedFormats = @('JPEG', 'PNG', 'WebP', 'AVIF')
        }
    }
    catch {
        Write-Error "Failed to create main function test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates test configuration files for main function testing.

.DESCRIPTION
    Creates various configuration files to test different configuration scenarios
    including valid configurations, invalid configurations, and edge cases.

.PARAMETER ConfigDirectory
    The directory where configuration files should be created.

.OUTPUTS
    [PSCustomObject] Information about the created configuration files.
#>
function New-MainFunctionTestConfigurations {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigDirectory
    )

    try {
        Write-Verbose "Creating test configurations in: $ConfigDirectory"

        $configurations = @()

        # Valid configuration with custom settings
        $validConfig = @{
            defaultSettings = @{
                jpeg = @{ quality = 75; progressive = $true }
                png = @{ compression = 8; stripMetadata = $true }
                webp = @{ quality = 85; method = 4 }
            }
            processing = @{
                maxThreads = 2
                enableParallelProcessing = $true
            }
            output = @{
                createBackup = $true
                preserveStructure = $true
            }
        }

        $validConfigPath = Join-Path $ConfigDirectory "valid-config.json"
        $validConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $validConfigPath -Encoding UTF8
        $configurations += [PSCustomObject]@{
            Name = "ValidConfig"
            Path = $validConfigPath
            Type = "Valid"
            Description = "Valid configuration with custom settings"
        }

        # Invalid configuration with missing required fields
        $invalidConfig = @{
            defaultSettings = @{
                jpeg = @{ quality = "invalid" }  # Invalid quality value
            }
        }

        $invalidConfigPath = Join-Path $ConfigDirectory "invalid-config.json"
        $invalidConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $invalidConfigPath -Encoding UTF8
        $configurations += [PSCustomObject]@{
            Name = "InvalidConfig"
            Path = $invalidConfigPath
            Type = "Invalid"
            Description = "Invalid configuration with incorrect data types"
        }

        # Minimal configuration
        $minimalConfig = @{
            defaultSettings = @{
                jpeg = @{ quality = 85 }
            }
        }

        $minimalConfigPath = Join-Path $ConfigDirectory "minimal-config.json"
        $minimalConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $minimalConfigPath -Encoding UTF8
        $configurations += [PSCustomObject]@{
            Name = "MinimalConfig"
            Path = $minimalConfigPath
            Type = "Minimal"
            Description = "Minimal valid configuration"
        }

        return [PSCustomObject]@{
            ConfigDirectory = $ConfigDirectory
            Configurations = $configurations
            TotalConfigurations = $configurations.Count
        }
    }
    catch {
        Write-Error "Failed to create test configurations: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates parameter test scenarios for main function testing.

.DESCRIPTION
    Creates various parameter combinations to test different scenarios including
    valid parameters, invalid parameters, edge cases, and error conditions.

.PARAMETER InputPath
    The input directory path for test scenarios.

.PARAMETER OutputPath
    The output directory path for test scenarios.

.PARAMETER BackupPath
    The backup directory path for test scenarios.

.OUTPUTS
    [PSCustomObject] Information about the parameter test scenarios.
#>
function New-MainFunctionParameterScenarios {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    try {
        Write-Verbose "Creating parameter test scenarios"

        $scenarios = @()

        # Basic valid scenario
        $scenarios += [PSCustomObject]@{
            Name = "BasicValid"
            Description = "Basic valid parameters with mandatory Path only"
            Parameters = @{
                Path = $InputPath
            }
            ExpectedResult = "Success"
            ShouldSucceed = $true
        }

        # Full parameter scenario
        $scenarios += [PSCustomObject]@{
            Name = "FullParameters"
            Description = "All parameters specified with valid values"
            Parameters = @{
                Path = $InputPath
                OutputPath = $OutputPath
                Settings = @{
                    jpeg = @{ quality = 80 }
                    png = @{ compression = 7 }
                }
                IncludeFormats = @('.jpg', '.png', '.webp')
                ExcludePatterns = @('*temp*', '*backup*')
                CreateBackup = $true
            }
            ExpectedResult = "Success"
            ShouldSucceed = $true
        }

        # WhatIf scenario
        $scenarios += [PSCustomObject]@{
            Name = "WhatIfMode"
            Description = "WhatIf parameter testing"
            Parameters = @{
                Path = $InputPath
                OutputPath = $OutputPath
                WhatIf = $true
            }
            ExpectedResult = "WhatIf"
            ShouldSucceed = $true
        }

        # Invalid path scenario
        $scenarios += [PSCustomObject]@{
            Name = "InvalidPath"
            Description = "Non-existent input path"
            Parameters = @{
                Path = "C:\NonExistent\Path"
            }
            ExpectedResult = "Error"
            ShouldSucceed = $false
        }

        # Empty path scenario
        $scenarios += [PSCustomObject]@{
            Name = "EmptyPath"
            Description = "Empty input path"
            Parameters = @{
                Path = ""
            }
            ExpectedResult = "Error"
            ShouldSucceed = $false
        }

        return [PSCustomObject]@{
            Scenarios = $scenarios
            TotalScenarios = $scenarios.Count
            ValidScenarios = ($scenarios | Where-Object { $_.ShouldSucceed }).Count
            ErrorScenarios = ($scenarios | Where-Object { -not $_.ShouldSucceed }).Count
        }
    }
    catch {
        Write-Error "Failed to create parameter test scenarios: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Removes test data created by the Main Function Test Data Library.

.DESCRIPTION
    Safely removes all test directories and files created by the test data library functions.
    Includes error handling to ensure cleanup doesn't fail the test run.

.PARAMETER TestRootPath
    The root path of the test structure to remove.

.EXAMPLE
    Remove-MainFunctionTestData -TestRootPath "C:\temp\maintest"
#>
function Remove-MainFunctionTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalBackupPaths
    )

    $cleanupErrors = @()

    try {
        # Clean up main test directory
        if (Test-Path $TestRootPath) {
            Write-Verbose "Removing main function test data at: $TestRootPath"
            Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully removed test data directory: $TestRootPath"
        } else {
            Write-Verbose "Test data directory does not exist: $TestRootPath"
        }
    }
    catch {
        $cleanupErrors += "Failed to remove test data directory '$TestRootPath': $($_.Exception.Message)"
        Write-Warning $cleanupErrors[-1]
    }

    # Clean up backup directories that might have been created outside the test root
    $backupPathsToCheck = @()

    # Add explicitly provided backup paths
    if ($AdditionalBackupPaths) {
        $backupPathsToCheck += $AdditionalBackupPaths
    }

    # Check for backup directories in common locations
    $commonBackupLocations = @(
        "backup",  # Default backup directory in current working directory
        (Join-Path (Get-Location) "backup"),  # Explicit path to backup in current directory
        (Join-Path $env:TEMP "backup")  # Backup in temp directory
    )

    foreach ($backupLocation in $commonBackupLocations) {
        if (Test-Path $backupLocation) {
            $backupPathsToCheck += $backupLocation
        }
    }

    # Clean up backup directories
    foreach ($backupPath in $backupPathsToCheck) {
        try {
            if (Test-Path $backupPath) {
                Write-Verbose "Checking backup directory for test-related backups: $backupPath"

                # Look for backup directories created during test runs (backup_YYYYMMDD_HHMMSS pattern)
                $testBackupDirs = Get-ChildItem -Path $backupPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '^backup_\d{8}_\d{6}$' -and $_.CreationTime -gt (Get-Date).AddHours(-2) }

                foreach ($testBackupDir in $testBackupDirs) {
                    try {
                        Write-Verbose "Removing test backup directory: $($testBackupDir.FullName)"
                        Remove-Item -Path $testBackupDir.FullName -Recurse -Force -ErrorAction Stop
                        Write-Verbose "Successfully removed test backup directory: $($testBackupDir.FullName)"
                    }
                    catch {
                        $cleanupErrors += "Failed to remove test backup directory '$($testBackupDir.FullName)': $($_.Exception.Message)"
                        Write-Warning $cleanupErrors[-1]
                    }
                }

                # If backup directory is empty after cleanup, remove it
                try {
                    $remainingItems = Get-ChildItem -Path $backupPath -ErrorAction SilentlyContinue
                    if (-not $remainingItems) {
                        Write-Verbose "Removing empty backup directory: $backupPath"
                        Remove-Item -Path $backupPath -Force -ErrorAction Stop
                        Write-Verbose "Successfully removed empty backup directory: $backupPath"
                    }
                }
                catch {
                    # Don't treat this as an error since the directory might be used by other processes
                    Write-Verbose "Could not remove backup directory (may not be empty or in use): $backupPath"
                }
            }
        }
        catch {
            $cleanupErrors += "Failed to process backup directory '$backupPath': $($_.Exception.Message)"
            Write-Warning $cleanupErrors[-1]
        }
    }

    # Report cleanup summary
    if ($cleanupErrors.Count -gt 0) {
        Write-Warning "Cleanup completed with $($cleanupErrors.Count) errors. Some temporary files may remain."
        # Don't throw here to avoid failing tests due to cleanup issues
    } else {
        Write-Verbose "Cleanup completed successfully with no errors."
    }
}
