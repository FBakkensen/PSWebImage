# Integration Test Data Library for WebImageOptimizer
# Provides centralized test data creation for integration testing scenarios
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates real image files and directory structures for integration testing.

.DESCRIPTION
    Creates comprehensive test scenarios with real image files for integration testing.
    This library focuses on creating actual image files (not mocks) to test end-to-end
    image processing workflows, cross-platform compatibility, and performance scenarios.

.PARAMETER TestRootPath
    The root path where the integration test scenario should be created.

.PARAMETER ImageCount
    Number of test images to create (default: 10).

.PARAMETER IncludeLargeDataset
    If specified, creates a large dataset for performance testing.

.PARAMETER IncludeCorruptedFiles
    If specified, includes corrupted files for error testing.

.OUTPUTS
    [PSCustomObject] Information about the created integration test scenario.

.EXAMPLE
    $testData = New-IntegrationTestImageCollection -TestRootPath "C:\Temp\IntegrationTest"
    # Creates a collection of real test images for integration testing

.NOTES
    This library creates real image files using .NET System.Drawing when available.
    Falls back to creating simple bitmap files for cross-platform compatibility.
#>
function New-IntegrationTestImageCollection {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter()]
        [int]$ImageCount = 10,

        [Parameter()]
        [switch]$IncludeLargeDataset,

        [Parameter()]
        [switch]$IncludeCorruptedFiles
    )

    try {
        # Create test directory structure
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        $inputDir = New-Item -Path (Join-Path $testDir "Input") -ItemType Directory -Force
        $outputDir = New-Item -Path (Join-Path $testDir "Output") -ItemType Directory -Force
        $backupDir = New-Item -Path (Join-Path $testDir "Backup") -ItemType Directory -Force

        # Create subdirectories for realistic structure
        $subDirs = @(
            New-Item -Path (Join-Path $inputDir "Photos") -ItemType Directory -Force
            New-Item -Path (Join-Path $inputDir "Graphics") -ItemType Directory -Force
            New-Item -Path (Join-Path $inputDir "Nested\Deep") -ItemType Directory -Force
        )

        # Create real image files
        $createdImages = @()
        $imageFormats = @('JPEG', 'PNG')

        # Try to load System.Drawing for real image creation
        $canCreateRealImages = $false
        try {
            Add-Type -AssemblyName System.Drawing
            $canCreateRealImages = $true
            Write-Verbose "System.Drawing available - creating real images"
        }
        catch {
            Write-Verbose "System.Drawing not available - creating mock images"
        }

        for ($i = 1; $i -le $ImageCount; $i++) {
            $format = $imageFormats[($i - 1) % $imageFormats.Count]
            $extension = if ($format -eq 'JPEG') { '.jpg' } else { '.png' }

            # Distribute images across directories - ensure each subdirectory gets at least one image
            $targetDir = switch ($i) {
                1 { $inputDir }           # Root directory
                2 { $subDirs[0] }         # Photos directory
                3 { $subDirs[1] }         # Graphics directory
                4 { $subDirs[2] }         # Nested\Deep directory
                default {
                    # For additional images, cycle through all directories
                    $dirIndex = ($i - 5) % 4
                    if ($dirIndex -eq 0) { $inputDir }
                    else { $subDirs[$dirIndex - 1] }
                }
            }

            $fileName = "TestImage_$i$extension"
            $filePath = Join-Path $targetDir $fileName

            if ($canCreateRealImages) {
                $image = New-RealTestImage -Width (100 + ($i * 50)) -Height (100 + ($i * 30)) -Format $format
                $image.Save($filePath)
                $image.Dispose()
            }
            else {
                # Create simple mock image files with realistic headers
                $content = New-MockImageContent -Format $format -Size (1024 + ($i * 512))
                [System.IO.File]::WriteAllBytes($filePath, $content)
            }

            $createdImages += [PSCustomObject]@{
                Path = $filePath
                Format = $format
                Size = (Get-Item $filePath).Length
                Directory = $targetDir.Name
            }
        }

        # Create large dataset if requested
        $largeDataset = $null
        if ($IncludeLargeDataset) {
            $largeDataset = New-IntegrationTestLargeDataset -TestRootPath (Join-Path $testDir "LargeDataset") -ImageCount 50
        }

        # Create corrupted files if requested
        $corruptedFiles = $null
        if ($IncludeCorruptedFiles) {
            $corruptedFiles = New-IntegrationTestCorruptedFiles -TestRootPath (Join-Path $testDir "Corrupted")
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            InputDirectory = $inputDir.FullName
            OutputDirectory = $outputDir.FullName
            BackupDirectory = $backupDir.FullName
            SubDirectories = $subDirs | ForEach-Object { $_.FullName }
            CreatedImages = $createdImages
            TotalImages = $createdImages.Count
            CanCreateRealImages = $canCreateRealImages
            LargeDataset = $largeDataset
            CorruptedFiles = $corruptedFiles
            SupportedFormats = $imageFormats
            CreatedAt = Get-Date
        }
    }
    catch {
        Write-Error "Failed to create integration test image collection: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates a real test image using System.Drawing.

.DESCRIPTION
    Creates a simple colored bitmap image with text overlay for testing purposes.

.PARAMETER Width
    Width of the image in pixels.

.PARAMETER Height
    Height of the image in pixels.

.PARAMETER Format
    Image format (JPEG or PNG).

.OUTPUTS
    [System.Drawing.Bitmap] The created image object.
#>
function New-RealTestImage {
    [CmdletBinding()]
    param(
        [int]$Width = 200,
        [int]$Height = 150,
        [string]$Format = 'JPEG'
    )

    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    # Create a gradient background
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Point]::new($Width, $Height),
        [System.Drawing.Color]::Blue,
        [System.Drawing.Color]::LightBlue
    )

    $graphics.FillRectangle($brush, 0, 0, $Width, $Height)

    # Add text overlay
    $font = New-Object System.Drawing.Font("Arial", 12)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $text = "Test $Format $Width x $Height"
    $graphics.DrawString($text, $font, $textBrush, 10, 10)

    # Cleanup
    $graphics.Dispose()
    $brush.Dispose()
    $font.Dispose()
    $textBrush.Dispose()

    return $bitmap
}

<#
.SYNOPSIS
    Creates mock image content with realistic file headers.

.DESCRIPTION
    Creates byte arrays that simulate image file content with proper headers
    for testing when System.Drawing is not available.

.PARAMETER Format
    Image format to simulate.

.PARAMETER Size
    Approximate size of the mock content.

.OUTPUTS
    [byte[]] Mock image content.
#>
function New-MockImageContent {
    [CmdletBinding()]
    param(
        [string]$Format,
        [int]$Size = 1024
    )

    $content = switch ($Format) {
        'JPEG' {
            # JPEG file header (SOI marker)
            $header = [byte[]]@(0xFF, 0xD8, 0xFF, 0xE0)
            $padding = New-Object byte[] ($Size - $header.Length)
            $header + $padding
        }
        'PNG' {
            # PNG file signature
            $header = [byte[]]@(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
            $padding = New-Object byte[] ($Size - $header.Length)
            $header + $padding
        }
        default {
            # Generic binary content
            New-Object byte[] $Size
        }
    }

    return $content
}

<#
.SYNOPSIS
    Creates a large dataset for performance testing.

.DESCRIPTION
    Creates a large collection of test images for testing parallel processing
    and performance characteristics.

.PARAMETER TestRootPath
    Root path for the large dataset.

.PARAMETER ImageCount
    Number of images to create (default: 50).

.OUTPUTS
    [PSCustomObject] Information about the large dataset.
#>
function New-IntegrationTestLargeDataset {
    [CmdletBinding()]
    param(
        [string]$TestRootPath,
        [int]$ImageCount = 50
    )

    $dataset = New-IntegrationTestImageCollection -TestRootPath $TestRootPath -ImageCount $ImageCount

    return [PSCustomObject]@{
        Path = $dataset.TestRootPath
        ImageCount = $dataset.TotalImages
        CreatedAt = Get-Date
        Purpose = "Performance testing with large dataset"
    }
}

<#
.SYNOPSIS
    Creates corrupted files for error testing.

.DESCRIPTION
    Creates files that appear to be images but have corrupted content
    to test error handling scenarios.

.PARAMETER TestRootPath
    Root path for corrupted files.

.OUTPUTS
    [PSCustomObject] Information about corrupted files.
#>
function New-IntegrationTestCorruptedFiles {
    [CmdletBinding()]
    param(
        [string]$TestRootPath
    )

    $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
    $corruptedFiles = @()

    # Create files with wrong extensions
    $wrongExtensions = @(
        @{ Name = "NotAnImage.jpg"; Content = [System.Text.Encoding]::UTF8.GetBytes("This is not an image") }
        @{ Name = "CorruptedPNG.png"; Content = [byte[]]@(0x00, 0x01, 0x02, 0x03) }
        @{ Name = "EmptyFile.jpg"; Content = @() }
    )

    foreach ($file in $wrongExtensions) {
        $filePath = Join-Path $testDir $file.Name
        [System.IO.File]::WriteAllBytes($filePath, $file.Content)
        $corruptedFiles += $filePath
    }

    return [PSCustomObject]@{
        Path = $testDir.FullName
        Files = $corruptedFiles
        Count = $corruptedFiles.Count
        CreatedAt = Get-Date
    }
}

<#
.SYNOPSIS
    Removes integration test data and cleans up resources.

.DESCRIPTION
    Safely removes all test data created by the Integration Test Data Library,
    including handling of locked files and subdirectories.

.PARAMETER TestDataPath
    Path to the test data to remove.

.EXAMPLE
    Remove-IntegrationTestData -TestDataPath $testData.TestRootPath
#>
function Remove-IntegrationTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestDataPath
    )

    if (Test-Path $TestDataPath) {
        try {
            # Force removal of readonly files and subdirectories
            Get-ChildItem -Path $TestDataPath -Recurse -Force | ForEach-Object {
                if ($_.PSIsContainer) {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    $_.Attributes = 'Normal'
                    Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            Remove-Item -Path $TestDataPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Verbose "Successfully removed integration test data: $TestDataPath"
        }
        catch {
            Write-Warning "Failed to completely remove test data: $($_.Exception.Message)"
        }
    }
}
