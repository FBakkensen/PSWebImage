# Test Data Library for WebImageOptimizer Backup and File Management System (Task 7)
# Provides centralized test data creation following Test Data Library pattern

<#
.SYNOPSIS
    Creates a set of test files for backup testing scenarios.

.DESCRIPTION
    Creates test files with various characteristics for testing backup functionality.
    Supports both mock files and real files for comprehensive testing.

.PARAMETER TestRootPath
    The root directory where test files will be created.

.PARAMETER CreateRealFiles
    If specified, creates actual files with content. Otherwise creates mock files.

.PARAMETER FileCount
    Number of test files to create (default: 5).

.OUTPUTS
    [hashtable] Contains information about created test files and their metadata.

.EXAMPLE
    $testFiles = New-BackupTestFiles -TestRootPath "C:\temp\backup_tests"
#>
function New-BackupTestFiles {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateRealFiles,

        [Parameter(Mandatory = $false)]
        [int]$FileCount = 5
    )

    Write-Verbose "Creating backup test files in: $TestRootPath"

    # Ensure test directory exists
    $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force -ErrorAction Stop
    Write-Verbose "Test directory created: $($testDir.FullName)"

    # Define test file specifications
    $testFileSpecs = @(
        @{
            Name = "test_image_small.jpg"
            Content = "JPEG_SMALL_TEST_CONTENT_FOR_BACKUP"
            Size = 1024
            Type = "Image"
            SubDirectory = ""
        },
        @{
            Name = "test_image_medium.png"
            Content = "PNG_MEDIUM_TEST_CONTENT_FOR_BACKUP_TESTING"
            Size = 5120
            Type = "Image"
            SubDirectory = "images"
        },
        @{
            Name = "test_image_large.gif"
            Content = "GIF_LARGE_TEST_CONTENT_FOR_BACKUP_COMPREHENSIVE_TESTING"
            Size = 10240
            Type = "Image"
            SubDirectory = "images/gallery"
        },
        @{
            Name = "test_document.txt"
            Content = "TEXT_DOCUMENT_FOR_BACKUP_TESTING"
            Size = 512
            Type = "Document"
            SubDirectory = "documents"
        },
        @{
            Name = "special_chars_ñáéíóú.jpg"
            Content = "JPEG_SPECIAL_CHARACTERS_TEST_CONTENT"
            Size = 2048
            Type = "Image"
            SubDirectory = "special"
        }
    )

    $createdFiles = @()
    $fileMetadata = @()

    # Create only the requested number of files
    $filesToCreate = $testFileSpecs | Select-Object -First $FileCount

    foreach ($spec in $filesToCreate) {
        # Create subdirectory if needed
        $fullSubDir = if ($spec.SubDirectory) {
            Join-Path $testDir.FullName $spec.SubDirectory
        } else {
            $testDir.FullName
        }

        if (-not (Test-Path $fullSubDir)) {
            New-Item -Path $fullSubDir -ItemType Directory -Force | Out-Null
        }

        $filePath = Join-Path $fullSubDir $spec.Name

        if ($CreateRealFiles) {
            # Create file with actual content
            $content = $spec.Content.PadRight($spec.Size, 'X')
            Set-Content -Path $filePath -Value $content -Encoding UTF8
        } else {
            # Create mock file
            Set-Content -Path $filePath -Value $spec.Content -Encoding UTF8
        }

        $createdFiles += $filePath

        # Collect metadata
        $fileInfo = Get-Item -Path $filePath
        $metadata = @{
            OriginalPath = $filePath
            RelativePath = if ($spec.SubDirectory) { 
                Join-Path $spec.SubDirectory $spec.Name 
            } else { 
                $spec.Name 
            }
            Name = $spec.Name
            Size = $fileInfo.Length
            Type = $spec.Type
            SubDirectory = $spec.SubDirectory
            CreatedAt = $fileInfo.CreationTime
            Hash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
        }
        $fileMetadata += $metadata
    }

    $result = @{
        TestRootPath = $testDir.FullName
        CreatedFiles = $createdFiles
        FileMetadata = $fileMetadata
        TotalFiles = $createdFiles.Count
        TotalSize = ($fileMetadata | Measure-Object -Property Size -Sum).Sum
        DirectoryStructure = ($fileMetadata | Select-Object -Property SubDirectory -Unique | Where-Object { $_.SubDirectory } | ForEach-Object { $_.SubDirectory })
    }

    Write-Verbose "Created $($result.TotalFiles) test files with total size $($result.TotalSize) bytes"
    return $result
}

<#
.SYNOPSIS
    Creates a complex nested directory structure for backup testing.

.DESCRIPTION
    Creates a realistic directory structure with multiple levels and various file types
    to test backup functionality with complex scenarios.

.PARAMETER TestRootPath
    The root directory where the complex structure will be created.

.OUTPUTS
    [hashtable] Contains information about the created directory structure.

.EXAMPLE
    $structure = New-ComplexDirectoryStructure -TestRootPath "C:\temp\complex_backup_test"
#>
function New-ComplexDirectoryStructure {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    Write-Verbose "Creating complex directory structure in: $TestRootPath"

    # Ensure test directory exists
    $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force -ErrorAction Stop

    # Define complex directory structure
    $directoryStructure = @(
        "images",
        "images/gallery",
        "images/gallery/2023",
        "images/gallery/2024",
        "images/thumbnails",
        "documents",
        "documents/reports",
        "temp",
        "backup_test/nested/deep/structure"
    )

    # Create directories
    foreach ($dir in $directoryStructure) {
        $fullPath = Join-Path $testDir.FullName $dir
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    }

    # Define files for complex structure
    $complexFiles = @(
        @{ Path = "images/main_photo.jpg"; Content = "MAIN_PHOTO_CONTENT"; Size = 2048 },
        @{ Path = "images/gallery/photo1.jpg"; Content = "GALLERY_PHOTO1"; Size = 1536 },
        @{ Path = "images/gallery/photo2.png"; Content = "GALLERY_PHOTO2"; Size = 2560 },
        @{ Path = "images/gallery/2023/vacation.jpg"; Content = "VACATION_2023"; Size = 3072 },
        @{ Path = "images/gallery/2024/wedding.png"; Content = "WEDDING_2024"; Size = 4096 },
        @{ Path = "images/thumbnails/thumb1.jpg"; Content = "THUMBNAIL1"; Size = 512 },
        @{ Path = "images/thumbnails/thumb2.png"; Content = "THUMBNAIL2"; Size = 768 },
        @{ Path = "documents/readme.txt"; Content = "README_DOCUMENT"; Size = 256 },
        @{ Path = "documents/reports/annual.pdf"; Content = "ANNUAL_REPORT"; Size = 8192 },
        @{ Path = "temp/temp_file.tmp"; Content = "TEMPORARY_FILE"; Size = 128 },
        @{ Path = "backup_test/nested/deep/structure/deep_file.dat"; Content = "DEEP_NESTED_FILE"; Size = 1024 }
    )

    $createdFiles = @()
    $fileMetadata = @()

    foreach ($fileSpec in $complexFiles) {
        $fullPath = Join-Path $testDir.FullName $fileSpec.Path
        $content = $fileSpec.Content.PadRight($fileSpec.Size, 'X')
        Set-Content -Path $fullPath -Value $content -Encoding UTF8

        $createdFiles += $fullPath

        $fileInfo = Get-Item -Path $fullPath
        $metadata = @{
            OriginalPath = $fullPath
            RelativePath = $fileSpec.Path
            Name = Split-Path $fileSpec.Path -Leaf
            Size = $fileInfo.Length
            Directory = Split-Path $fileSpec.Path -Parent
            CreatedAt = $fileInfo.CreationTime
            Hash = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash
        }
        $fileMetadata += $metadata
    }

    $result = @{
        TestRootPath = $testDir.FullName
        CreatedFiles = $createdFiles
        FileMetadata = $fileMetadata
        DirectoryStructure = $directoryStructure
        TotalFiles = $createdFiles.Count
        TotalSize = ($fileMetadata | Measure-Object -Property Size -Sum).Sum
        MaxDepth = ($directoryStructure | ForEach-Object { ($_ -split '/').Count } | Measure-Object -Maximum).Maximum
    }

    Write-Verbose "Created complex structure with $($result.TotalFiles) files across $($result.DirectoryStructure.Count) directories"
    return $result
}

<#
.SYNOPSIS
    Creates various backup test scenarios for comprehensive testing.

.DESCRIPTION
    Creates different backup scenarios including edge cases, error conditions,
    and typical use cases for thorough backup system testing.

.PARAMETER TestRootPath
    The root directory where backup scenarios will be created.

.OUTPUTS
    [hashtable] Contains information about created backup scenarios.

.EXAMPLE
    $scenarios = New-BackupScenarios -TestRootPath "C:\temp\backup_scenarios"
#>
function New-BackupScenarios {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    Write-Verbose "Creating backup test scenarios in: $TestRootPath"

    # Ensure test directory exists
    $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force -ErrorAction Stop

    $scenarios = @{
        EmptyDirectory = @{
            Path = Join-Path $testDir.FullName "empty_directory"
            Description = "Empty directory for testing backup behavior with no files"
        }
        SingleFile = @{
            Path = Join-Path $testDir.FullName "single_file"
            Description = "Directory with single file for basic backup testing"
            Files = @("single_test.jpg")
        }
        LargeFiles = @{
            Path = Join-Path $testDir.FullName "large_files"
            Description = "Directory with large files for performance testing"
            Files = @("large_file_1.jpg", "large_file_2.png")
        }
        SpecialCharacters = @{
            Path = Join-Path $testDir.FullName "special_chars"
            Description = "Files with special characters in names"
            Files = @("file with spaces.jpg", "file-with-dashes.png", "file_with_underscores.gif")
        }
    }

    # Create each scenario
    foreach ($scenarioName in $scenarios.Keys) {
        $scenario = $scenarios[$scenarioName]
        
        # Create scenario directory
        New-Item -Path $scenario.Path -ItemType Directory -Force | Out-Null
        
        # Create files if specified
        if ($scenario.Files) {
            foreach ($fileName in $scenario.Files) {
                $filePath = Join-Path $scenario.Path $fileName
                $content = "TEST_CONTENT_FOR_$($scenarioName.ToUpper())_$($fileName.ToUpper())"
                
                # Make large files actually large for performance testing
                if ($scenarioName -eq "LargeFiles") {
                    $content = $content.PadRight(50000, 'X')  # ~50KB files
                }
                
                Set-Content -Path $filePath -Value $content -Encoding UTF8
            }
        }
        
        # Update scenario with created file information
        if ($scenario.Files) {
            $scenario.CreatedFiles = $scenario.Files | ForEach-Object {
                Join-Path $scenario.Path $_
            }
        } else {
            $scenario.CreatedFiles = @()
        }
    }

    $result = @{
        TestRootPath = $testDir.FullName
        Scenarios = $scenarios
        TotalScenarios = $scenarios.Count
    }

    Write-Verbose "Created $($result.TotalScenarios) backup test scenarios"
    return $result
}

<#
.SYNOPSIS
    Removes backup test data and cleans up test directories.

.DESCRIPTION
    Safely removes test data created by backup test functions.
    Includes error handling for cleanup operations.

.PARAMETER TestRootPath
    The root directory of test data to remove.

.EXAMPLE
    Remove-BackupTestData -TestRootPath "C:\temp\backup_tests"
#>
function Remove-BackupTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    Write-Verbose "Cleaning up backup test data from: $TestRootPath"

    try {
        if (Test-Path -Path $TestRootPath) {
            Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully removed test data directory: $TestRootPath"
        } else {
            Write-Verbose "Test data directory does not exist: $TestRootPath"
        }
    }
    catch {
        Write-Warning "Failed to remove test data directory '$TestRootPath': $($_.Exception.Message)"
        throw
    }
}
