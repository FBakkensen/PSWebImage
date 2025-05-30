# Image Optimization Test Data Library
# Centralized test data creation for image optimization functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates test image files for image optimization testing.

.DESCRIPTION
    Creates simple test image files using .NET System.Drawing when available,
    or creates mock image files with appropriate extensions for testing the
    optimization logic without requiring actual image processing.

.PARAMETER TestRootPath
    The root path where the test image files should be created.

.PARAMETER CreateRealImages
    If specified, attempts to create real image files using .NET System.Drawing.
    Otherwise creates mock files with image extensions.

.OUTPUTS
    [PSCustomObject] Information about the created test images including paths and metadata.

.EXAMPLE
    $testImages = New-ImageOptimizationTestImages -TestRootPath "C:\temp\test"
#>
function New-ImageOptimizationTestImages {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateRealImages
    )

    try {
        Write-Verbose "Creating image optimization test images at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Define test image specifications
        $testImageSpecs = @(
            # JPEG test images
            @{
                Name = "test_image_high_quality.jpg"
                Format = "JPEG"
                Width = 800
                Height = 600
                Quality = 95
                Size = "Large"
                Content = "JPEG_HIGH_QUALITY_TEST_CONTENT_800x600"
            },
            @{
                Name = "test_image_medium_quality.jpg"
                Format = "JPEG"
                Width = 400
                Height = 300
                Quality = 75
                Size = "Medium"
                Content = "JPEG_MEDIUM_QUALITY_TEST_CONTENT_400x300"
            },
            @{
                Name = "test_image_low_quality.jpg"
                Format = "JPEG"
                Width = 200
                Height = 150
                Quality = 50
                Size = "Small"
                Content = "JPEG_LOW_QUALITY_TEST_CONTENT_200x150"
            },

            # PNG test images
            @{
                Name = "test_image_png_large.png"
                Format = "PNG"
                Width = 1024
                Height = 768
                Quality = 100
                Size = "Large"
                Content = "PNG_LARGE_TEST_CONTENT_1024x768"
            },
            @{
                Name = "test_image_png_small.png"
                Format = "PNG"
                Width = 256
                Height = 192
                Quality = 100
                Size = "Small"
                Content = "PNG_SMALL_TEST_CONTENT_256x192"
            },

            # WebP test images
            @{
                Name = "test_image_webp.webp"
                Format = "WebP"
                Width = 512
                Height = 384
                Quality = 90
                Size = "Medium"
                Content = "WEBP_TEST_CONTENT_512x384"
            },

            # AVIF test images
            @{
                Name = "test_image_avif.avif"
                Format = "AVIF"
                Width = 640
                Height = 480
                Quality = 85
                Size = "Medium"
                Content = "AVIF_TEST_CONTENT_640x480"
            },

            # Images with metadata for testing metadata removal
            @{
                Name = "test_image_with_metadata.jpg"
                Format = "JPEG"
                Width = 600
                Height = 400
                Quality = 85
                Size = "Medium"
                Content = "JPEG_WITH_METADATA_TEST_CONTENT_600x400"
                HasMetadata = $true
            },

            # Large image for testing resizing
            @{
                Name = "test_image_oversized.jpg"
                Format = "JPEG"
                Width = 4000
                Height = 3000
                Quality = 90
                Size = "Oversized"
                Content = "JPEG_OVERSIZED_TEST_CONTENT_4000x3000"
            }
        )

        $createdImages = @()
        $imageMetadata = @()

        foreach ($spec in $testImageSpecs) {
            $imagePath = Join-Path $testDir.FullName $spec.Name

            if ($CreateRealImages) {
                # Attempt to create real image using .NET System.Drawing
                $realImageCreated = New-RealTestImage -ImagePath $imagePath -Specification $spec
                if (-not $realImageCreated) {
                    # Fallback to mock image
                    New-MockTestImage -ImagePath $imagePath -Specification $spec
                }
            } else {
                # Create mock image file
                New-MockTestImage -ImagePath $imagePath -Specification $spec
            }

            $createdImages += $imagePath
            $imageMetadata += [PSCustomObject]@{
                Path = $imagePath
                Name = $spec.Name
                Format = $spec.Format
                Width = $spec.Width
                Height = $spec.Height
                Quality = $spec.Quality
                Size = $spec.Size
                HasMetadata = $spec.HasMetadata -eq $true
                FileSize = if (Test-Path $imagePath) { (Get-Item $imagePath).Length } else { 0 }
            }

            Write-Verbose "Created test image: $($spec.Name)"
        }

        # Return structured information about the test images
        $result = [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedImages = $createdImages
            ImageMetadata = $imageMetadata
            TotalImages = $createdImages.Count
            SupportedFormats = @('JPEG', 'PNG', 'WebP', 'AVIF')
            TestScenarios = @('HighQuality', 'MediumQuality', 'LowQuality', 'WithMetadata', 'Oversized')
        }

        Write-Verbose "Image optimization test images created successfully: $($result.TotalImages) images"
        return $result
    }
    catch {
        Write-Error "Failed to create image optimization test images: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates a mock test image file with specified properties.

.DESCRIPTION
    Creates a text file with image extension that contains metadata about the
    simulated image properties. Used for testing optimization logic without
    requiring actual image processing capabilities.

.PARAMETER ImagePath
    The full path where the mock image should be created.

.PARAMETER Specification
    Hashtable containing image specifications (width, height, quality, etc.).
#>
function New-MockTestImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Specification
    )

    try {
        # Create mock image content with embedded metadata
        $mockContent = @"
MOCK_IMAGE_FILE
Format: $($Specification.Format)
Width: $($Specification.Width)
Height: $($Specification.Height)
Quality: $($Specification.Quality)
Size: $($Specification.Size)
Content: $($Specification.Content)
HasMetadata: $($Specification.HasMetadata -eq $true)
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

        # Write the mock content to file
        Set-Content -Path $ImagePath -Value $mockContent -Encoding UTF8
        Write-Verbose "Created mock image: $ImagePath"
        return $true
    }
    catch {
        Write-Warning "Failed to create mock image '$ImagePath': $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Attempts to create a real test image using .NET System.Drawing.

.DESCRIPTION
    Creates a simple colored bitmap image using .NET System.Drawing if available.
    This provides more realistic testing scenarios when the .NET image processing
    capabilities are available.

.PARAMETER ImagePath
    The full path where the real image should be created.

.PARAMETER Specification
    Hashtable containing image specifications (width, height, quality, etc.).

.OUTPUTS
    [bool] True if the real image was created successfully, false otherwise.
#>
function New-RealTestImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Specification
    )

    try {
        # Check if System.Drawing is available
        if (-not ([System.Management.Automation.PSTypeName]'System.Drawing.Bitmap').Type) {
            Write-Verbose "System.Drawing not available, cannot create real image"
            return $false
        }

        # Create a simple colored bitmap
        $bitmap = New-Object System.Drawing.Bitmap($Specification.Width, $Specification.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        # Fill with a color based on the format
        $color = switch ($Specification.Format) {
            'JPEG' { [System.Drawing.Color]::LightBlue }
            'PNG' { [System.Drawing.Color]::LightGreen }
            'WebP' { [System.Drawing.Color]::LightCoral }
            'AVIF' { [System.Drawing.Color]::LightYellow }
            default { [System.Drawing.Color]::LightGray }
        }

        $graphics.Clear($color)

        # Add some text to make it identifiable
        $font = New-Object System.Drawing.Font("Arial", 12)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $text = "$($Specification.Format) Test Image $($Specification.Width)x$($Specification.Height)"
        $graphics.DrawString($text, $font, $brush, 10, 10)

        # Save the image
        $format = switch ($Specification.Format) {
            'JPEG' { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            'PNG' { [System.Drawing.Imaging.ImageFormat]::Png }
            default { [System.Drawing.Imaging.ImageFormat]::Png }
        }

        $bitmap.Save($ImagePath, $format)

        # Cleanup
        $graphics.Dispose()
        $bitmap.Dispose()
        $font.Dispose()
        $brush.Dispose()

        Write-Verbose "Created real test image: $ImagePath"
        return $true
    }
    catch {
        Write-Verbose "Failed to create real image '$ImagePath': $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Creates optimization test scenarios with before/after image pairs.

.DESCRIPTION
    Creates pairs of images representing before and after optimization scenarios
    for testing the optimization results and metrics calculation.

.PARAMETER TestRootPath
    The root path where the test scenario should be created.

.OUTPUTS
    [PSCustomObject] Information about the created optimization test scenario.

.EXAMPLE
    $scenario = New-OptimizationTestScenario -TestRootPath "C:\temp\scenario"
#>
function New-OptimizationTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating optimization test scenario at: $TestRootPath"

        # Create scenario directory
        $scenarioDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        $beforeDir = New-Item -Path (Join-Path $scenarioDir "before") -ItemType Directory -Force
        $afterDir = New-Item -Path (Join-Path $scenarioDir "after") -ItemType Directory -Force

        # Create before/after pairs for testing
        $scenarios = @(
            @{
                Name = "jpeg_quality_reduction"
                BeforeFile = "high_quality.jpg"
                AfterFile = "optimized_quality.jpg"
                BeforeSize = 1024000  # 1MB
                AfterSize = 512000    # 512KB (50% reduction)
                Format = "JPEG"
            },
            @{
                Name = "png_compression"
                BeforeFile = "uncompressed.png"
                AfterFile = "compressed.png"
                BeforeSize = 2048000  # 2MB
                AfterSize = 1024000   # 1MB (50% reduction)
                Format = "PNG"
            },
            @{
                Name = "format_conversion"
                BeforeFile = "original.png"
                AfterFile = "converted.webp"
                BeforeSize = 1536000  # 1.5MB
                AfterSize = 768000    # 768KB (50% reduction)
                Format = "WebP"
            }
        )

        $createdScenarios = @()
        foreach ($scenario in $scenarios) {
            $beforePath = Join-Path $beforeDir $scenario.BeforeFile
            $afterPath = Join-Path $afterDir $scenario.AfterFile

            # Create before file (larger)
            $beforeContent = "BEFORE_OPTIMIZATION_" + ("X" * ($scenario.BeforeSize / 100))
            Set-Content -Path $beforePath -Value $beforeContent -Encoding UTF8

            # Create after file (smaller)
            $afterContent = "AFTER_OPTIMIZATION_" + ("X" * ($scenario.AfterSize / 100))
            Set-Content -Path $afterPath -Value $afterContent -Encoding UTF8

            $createdScenarios += [PSCustomObject]@{
                Name = $scenario.Name
                BeforePath = $beforePath
                AfterPath = $afterPath
                BeforeSize = (Get-Item $beforePath).Length
                AfterSize = (Get-Item $afterPath).Length
                ExpectedReduction = [Math]::Round((1 - ($scenario.AfterSize / $scenario.BeforeSize)) * 100, 2)
                Format = $scenario.Format
            }

            Write-Verbose "Created optimization scenario: $($scenario.Name)"
        }

        return [PSCustomObject]@{
            TestRootPath = $scenarioDir.FullName
            BeforeDirectory = $beforeDir.FullName
            AfterDirectory = $afterDir.FullName
            Scenarios = $createdScenarios
            TotalScenarios = $createdScenarios.Count
        }
    }
    catch {
        Write-Error "Failed to create optimization test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Removes test data created by the Image Optimization Test Data Library.

.DESCRIPTION
    Safely removes all test directories and files created by the test data library functions.
    Includes error handling to ensure cleanup doesn't fail the test run.

.PARAMETER TestRootPath
    The root path of the test structure to remove.

.EXAMPLE
    Remove-ImageOptimizationTestData -TestRootPath "C:\temp\test"
#>
function Remove-ImageOptimizationTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        if (Test-Path $TestRootPath) {
            Write-Verbose "Removing image optimization test data at: $TestRootPath"
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
    Creates minimal test images for basic optimization testing.

.DESCRIPTION
    Creates a simple set of test images for basic optimization scenarios.
    Useful for unit tests that don't need the full complex image set.

.PARAMETER TestRootPath
    The root path where the minimal test images should be created.

.OUTPUTS
    [PSCustomObject] Information about the created minimal test images.

.EXAMPLE
    $minimalImages = New-MinimalOptimizationTestImages -TestRootPath "C:\temp\minimal"
#>
function New-MinimalOptimizationTestImages {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating minimal optimization test images at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Create minimal test images
        $testImages = @(
            @{ Name = "test.jpg"; Format = "JPEG"; Content = "JPEG_MINIMAL_TEST_CONTENT" },
            @{ Name = "test.png"; Format = "PNG"; Content = "PNG_MINIMAL_TEST_CONTENT" },
            @{ Name = "test.webp"; Format = "WebP"; Content = "WEBP_MINIMAL_TEST_CONTENT" }
        )

        $createdImages = @()
        foreach ($image in $testImages) {
            $imagePath = Join-Path $testDir.FullName $image.Name
            Set-Content -Path $imagePath -Value $image.Content -Encoding UTF8
            $createdImages += $imagePath
            Write-Verbose "Created minimal test image: $($image.Name)"
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedImages = $createdImages
            TotalImages = $createdImages.Count
        }
    }
    catch {
        Write-Error "Failed to create minimal optimization test images: $($_.Exception.Message)"
        throw
    }
}
