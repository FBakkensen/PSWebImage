# Image Discovery Test Data Library
# Centralized test data creation for image file discovery functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates a test directory structure with various image files for testing image discovery functionality.

.DESCRIPTION
    Creates a comprehensive test directory structure that includes:
    - Multiple subdirectories with different nesting levels
    - Various image file formats (JPEG, PNG, GIF, BMP, TIFF, WebP)
    - Non-image files to test filtering
    - Files with different naming patterns for include/exclude testing
    - Empty directories to test edge cases

.PARAMETER TestRootPath
    The root path where the test directory structure should be created.

.OUTPUTS
    [PSCustomObject] Information about the created test structure including paths and file counts.

.EXAMPLE
    $testStructure = New-ImageDiscoveryTestStructure -TestRootPath "C:\temp\test"
#>
function New-ImageDiscoveryTestStructure {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating image discovery test structure at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        
        # Define the directory structure
        $directories = @(
            "images",
            "images\gallery",
            "images\gallery\photos",
            "images\gallery\thumbnails",
            "images\assets",
            "images\assets\icons",
            "documents",
            "empty_folder",
            "mixed_content",
            "special_chars_ñáéíóú",
            "very\deep\nested\structure"
        )

        # Create directories
        $createdDirs = @()
        foreach ($dir in $directories) {
            $fullPath = Join-Path $testDir.FullName $dir
            $createdDir = New-Item -Path $fullPath -ItemType Directory -Force
            $createdDirs += $createdDir.FullName
            Write-Verbose "Created directory: $($createdDir.FullName)"
        }

        # Define test files with their content and locations
        $testFiles = @(
            # Root level images
            @{ Path = "test_image.jpg"; Content = "JPEG_TEST_CONTENT"; Type = "Image" },
            @{ Path = "sample.png"; Content = "PNG_TEST_CONTENT"; Type = "Image" },
            @{ Path = "animation.gif"; Content = "GIF_TEST_CONTENT"; Type = "Image" },
            
            # Gallery images
            @{ Path = "images\gallery\photo1.jpg"; Content = "JPEG_PHOTO1"; Type = "Image" },
            @{ Path = "images\gallery\photo2.PNG"; Content = "PNG_PHOTO2"; Type = "Image" },
            @{ Path = "images\gallery\photo3.jpeg"; Content = "JPEG_PHOTO3"; Type = "Image" },
            
            # Gallery photos subdirectory
            @{ Path = "images\gallery\photos\vacation1.jpg"; Content = "JPEG_VACATION1"; Type = "Image" },
            @{ Path = "images\gallery\photos\vacation2.png"; Content = "PNG_VACATION2"; Type = "Image" },
            @{ Path = "images\gallery\photos\vacation3.bmp"; Content = "BMP_VACATION3"; Type = "Image" },
            
            # Thumbnails
            @{ Path = "images\gallery\thumbnails\thumb1.jpg"; Content = "JPEG_THUMB1"; Type = "Image" },
            @{ Path = "images\gallery\thumbnails\thumb2.webp"; Content = "WEBP_THUMB2"; Type = "Image" },
            
            # Assets
            @{ Path = "images\assets\logo.png"; Content = "PNG_LOGO"; Type = "Image" },
            @{ Path = "images\assets\background.tiff"; Content = "TIFF_BACKGROUND"; Type = "Image" },
            @{ Path = "images\assets\banner.webp"; Content = "WEBP_BANNER"; Type = "Image" },
            
            # Icons
            @{ Path = "images\assets\icons\icon1.png"; Content = "PNG_ICON1"; Type = "Image" },
            @{ Path = "images\assets\icons\icon2.gif"; Content = "GIF_ICON2"; Type = "Image" },
            
            # Non-image files for filtering tests
            @{ Path = "readme.txt"; Content = "This is a text file"; Type = "Text" },
            @{ Path = "config.json"; Content = '{"test": true}'; Type = "JSON" },
            @{ Path = "images\gallery\description.txt"; Content = "Gallery description"; Type = "Text" },
            @{ Path = "documents\report.pdf"; Content = "PDF_CONTENT"; Type = "PDF" },
            
            # Mixed content directory
            @{ Path = "mixed_content\image.jpg"; Content = "JPEG_MIXED"; Type = "Image" },
            @{ Path = "mixed_content\data.csv"; Content = "col1,col2\nval1,val2"; Type = "CSV" },
            @{ Path = "mixed_content\photo.png"; Content = "PNG_MIXED"; Type = "Image" },
            
            # Special characters in path
            @{ Path = "special_chars_ñáéíóú\español.jpg"; Content = "JPEG_SPANISH"; Type = "Image" },
            
            # Deep nested structure
            @{ Path = "very\deep\nested\structure\deep_image.png"; Content = "PNG_DEEP"; Type = "Image" },
            
            # Files with patterns for include/exclude testing
            @{ Path = "images\test_include.jpg"; Content = "JPEG_INCLUDE_TEST"; Type = "Image" },
            @{ Path = "images\exclude_me.png"; Content = "PNG_EXCLUDE_TEST"; Type = "Image" },
            @{ Path = "images\gallery\backup_photo.jpg"; Content = "JPEG_BACKUP"; Type = "Image" }
        )

        # Create test files
        $createdFiles = @()
        $imageFiles = @()
        $nonImageFiles = @()

        foreach ($file in $testFiles) {
            $fullPath = Join-Path $testDir.FullName $file.Path
            $directory = Split-Path $fullPath -Parent
            
            # Ensure directory exists
            if (-not (Test-Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }
            
            # Create the file
            Set-Content -Path $fullPath -Value $file.Content -Encoding UTF8
            $createdFiles += $fullPath
            
            if ($file.Type -eq "Image") {
                $imageFiles += $fullPath
            } else {
                $nonImageFiles += $fullPath
            }
            
            Write-Verbose "Created file: $fullPath"
        }

        # Return structured information about the test setup
        $result = [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedDirectories = $createdDirs
            CreatedFiles = $createdFiles
            ImageFiles = $imageFiles
            NonImageFiles = $nonImageFiles
            TotalDirectories = $createdDirs.Count
            TotalFiles = $createdFiles.Count
            TotalImageFiles = $imageFiles.Count
            TotalNonImageFiles = $nonImageFiles.Count
            SupportedFormats = @('jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp')
        }

        Write-Verbose "Test structure created successfully with $($result.TotalFiles) files in $($result.TotalDirectories) directories"
        return $result
    }
    catch {
        Write-Error "Failed to create image discovery test structure: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates minimal test data for basic image discovery scenarios.

.DESCRIPTION
    Creates a simple test structure with just a few image files for basic testing scenarios.
    This is useful for unit tests that don't need the full complex structure.

.PARAMETER TestRootPath
    The root path where the minimal test structure should be created.

.OUTPUTS
    [PSCustomObject] Information about the created minimal test structure.

.EXAMPLE
    $minimalTest = New-MinimalImageTestStructure -TestRootPath "C:\temp\minimal"
#>
function New-MinimalImageTestStructure {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating minimal image discovery test structure at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Create minimal test files
        $testFiles = @(
            @{ Path = "image1.jpg"; Content = "JPEG_MINIMAL1"; Extension = "jpg" },
            @{ Path = "image2.png"; Content = "PNG_MINIMAL2"; Extension = "png" },
            @{ Path = "subfolder\image3.gif"; Content = "GIF_MINIMAL3"; Extension = "gif" }
        )

        $createdFiles = @()
        foreach ($file in $testFiles) {
            $fullPath = Join-Path $testDir.FullName $file.Path
            $directory = Split-Path $fullPath -Parent
            
            # Ensure directory exists
            if (-not (Test-Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }
            
            # Create the file
            Set-Content -Path $fullPath -Value $file.Content -Encoding UTF8
            $createdFiles += $fullPath
            Write-Verbose "Created minimal test file: $fullPath"
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedFiles = $createdFiles
            TotalFiles = $createdFiles.Count
        }
    }
    catch {
        Write-Error "Failed to create minimal image discovery test structure: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Removes test data created by the Image Discovery Test Data Library.

.DESCRIPTION
    Safely removes all test directories and files created by the test data library functions.
    Includes error handling to ensure cleanup doesn't fail the test run.

.PARAMETER TestRootPath
    The root path of the test structure to remove.

.EXAMPLE
    Remove-ImageDiscoveryTestData -TestRootPath "C:\temp\test"
#>
function Remove-ImageDiscoveryTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        if (Test-Path $TestRootPath) {
            Write-Verbose "Removing image discovery test data at: $TestRootPath"
            Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully removed test data directory: $TestRootPath"
        } else {
            Write-Verbose "Test data directory does not exist: $TestRootPath"
        }
    }
    catch {
        Write-Warning "Failed to remove test data directory '$TestRootPath': $($_.Exception.Message)"
        # Don't throw here to avoid failing tests due to cleanup issues
    }
}

<#
.SYNOPSIS
    Creates test data for include/exclude pattern testing scenarios.

.DESCRIPTION
    Creates a specific directory structure designed to test include and exclude pattern functionality.
    Files are named with specific patterns to validate filtering logic.

.PARAMETER TestRootPath
    The root path where the pattern test structure should be created.

.OUTPUTS
    [PSCustomObject] Information about the created pattern test structure.

.EXAMPLE
    $patternTest = New-PatternTestStructure -TestRootPath "C:\temp\patterns"
#>
function New-PatternTestStructure {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating pattern test structure at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Create files with specific patterns
        $patternFiles = @(
            # Files that should be included with "test_*" pattern
            @{ Path = "test_image1.jpg"; Content = "JPEG_TEST1"; ShouldMatch = @("test_*") },
            @{ Path = "test_image2.png"; Content = "PNG_TEST2"; ShouldMatch = @("test_*") },
            @{ Path = "subfolder\test_nested.gif"; Content = "GIF_TEST_NESTED"; ShouldMatch = @("test_*") },
            
            # Files that should be excluded with "*backup*" pattern
            @{ Path = "backup_image.jpg"; Content = "JPEG_BACKUP"; ShouldExclude = @("*backup*") },
            @{ Path = "image_backup.png"; Content = "PNG_BACKUP"; ShouldExclude = @("*backup*") },
            @{ Path = "subfolder\old_backup.gif"; Content = "GIF_OLD_BACKUP"; ShouldExclude = @("*backup*") },
            
            # Regular files that should pass normal filtering
            @{ Path = "regular_image.jpg"; Content = "JPEG_REGULAR"; ShouldMatch = @("*") },
            @{ Path = "photo.png"; Content = "PNG_PHOTO"; ShouldMatch = @("*") },
            @{ Path = "subfolder\normal.bmp"; Content = "BMP_NORMAL"; ShouldMatch = @("*") }
        )

        $createdFiles = @()
        foreach ($file in $patternFiles) {
            $fullPath = Join-Path $testDir.FullName $file.Path
            $directory = Split-Path $fullPath -Parent
            
            # Ensure directory exists
            if (-not (Test-Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }
            
            # Create the file
            Set-Content -Path $fullPath -Value $file.Content -Encoding UTF8
            $createdFiles += $fullPath
            Write-Verbose "Created pattern test file: $fullPath"
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedFiles = $createdFiles
            PatternFiles = $patternFiles
            TotalFiles = $createdFiles.Count
        }
    }
    catch {
        Write-Error "Failed to create pattern test structure: $($_.Exception.Message)"
        throw
    }
}
