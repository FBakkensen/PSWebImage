# Performance Benchmarking Test Data Library for WebImageOptimizer
# Provides centralized test data creation for performance benchmarking scenarios
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates test data for performance benchmarking scenarios.

.DESCRIPTION
    Provides standardized test data creation procedures for performance benchmarking
    tests following the Test Data Library pattern. Supports various benchmark
    scenarios including small, medium, large datasets, and cross-platform testing.
#>

<#
.SYNOPSIS
    Creates a performance benchmark test dataset with configurable parameters.

.DESCRIPTION
    Creates a comprehensive test dataset for performance benchmarking with
    configurable image counts, sizes, and formats. Supports multiple benchmark
    scenarios and cross-platform testing.

.PARAMETER TestRootPath
    Root path for the test data.

.PARAMETER BenchmarkType
    Type of benchmark: 'Speed', 'Memory', 'Scalability', 'CrossPlatform', 'Comprehensive'.

.PARAMETER ImageCount
    Number of images to create for the benchmark.

.PARAMETER IncludeVariedSizes
    Include images of varied sizes for comprehensive testing.

.OUTPUTS
    [PSCustomObject] Benchmark dataset information.

.EXAMPLE
    $dataset = New-PerformanceBenchmarkDataset -TestRootPath $testPath -BenchmarkType 'Speed' -ImageCount 50
#>
function New-PerformanceBenchmarkDataset {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Speed', 'Memory', 'Scalability', 'CrossPlatform', 'Comprehensive')]
        [string]$BenchmarkType = 'Speed',

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 25,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVariedSizes
    )

    # Create test directory structure
    if (-not (Test-Path $TestRootPath)) {
        New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
    }

    $inputDir = Join-Path $TestRootPath "Input"
    $outputDir = Join-Path $TestRootPath "Output"
    $benchmarkDir = Join-Path $TestRootPath "Benchmarks"

    New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    New-Item -Path $benchmarkDir -ItemType Directory -Force | Out-Null

    # Create test images based on benchmark type
    $createdImages = @()
    
    switch ($BenchmarkType) {
        'Speed' {
            # Create standard images for speed testing
            $createdImages = New-BenchmarkSpeedTestImages -InputDirectory $inputDir -ImageCount $ImageCount
        }
        'Memory' {
            # Create larger images for memory testing
            $createdImages = New-BenchmarkMemoryTestImages -InputDirectory $inputDir -ImageCount $ImageCount
        }
        'Scalability' {
            # Create varied dataset for scalability testing
            $createdImages = New-BenchmarkScalabilityTestImages -InputDirectory $inputDir -ImageCount $ImageCount
        }
        'CrossPlatform' {
            # Create cross-platform compatible test images
            $createdImages = New-BenchmarkCrossPlatformTestImages -InputDirectory $inputDir -ImageCount $ImageCount
        }
        'Comprehensive' {
            # Create comprehensive test suite
            $createdImages = New-BenchmarkComprehensiveTestImages -InputDirectory $inputDir -ImageCount $ImageCount -IncludeVariedSizes:$IncludeVariedSizes
        }
    }

    return [PSCustomObject]@{
        TestRootPath = $TestRootPath
        InputDirectory = $inputDir
        OutputDirectory = $outputDir
        BenchmarkDirectory = $benchmarkDir
        BenchmarkType = $BenchmarkType
        ImageCount = $ImageCount
        CreatedImages = $createdImages
        TotalImages = $createdImages.Count
    }
}

<#
.SYNOPSIS
    Creates test images optimized for speed benchmarking.

.DESCRIPTION
    Creates a set of test images with standard sizes and formats
    optimized for speed benchmarking scenarios.

.PARAMETER InputDirectory
    Directory to create test images in.

.PARAMETER ImageCount
    Number of images to create.

.OUTPUTS
    [Array] Array of created image file information.
#>
function New-BenchmarkSpeedTestImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 25
    )

    $createdImages = @()
    
    # Create standard test images for speed testing
    for ($i = 1; $i -le $ImageCount; $i++) {
        $format = if ($i % 2 -eq 0) { 'jpg' } else { 'png' }
        $fileName = "speed_test_$($i.ToString('D3')).$format"
        $filePath = Join-Path $InputDirectory $fileName
        
        # Create a simple test image using System.Drawing
        $imageInfo = New-TestImageFile -FilePath $filePath -Width 800 -Height 600 -Format $format
        $createdImages += $imageInfo
    }

    return $createdImages
}

<#
.SYNOPSIS
    Creates test images optimized for memory benchmarking.

.DESCRIPTION
    Creates larger test images designed to test memory usage
    and memory management during processing.

.PARAMETER InputDirectory
    Directory to create test images in.

.PARAMETER ImageCount
    Number of images to create.

.OUTPUTS
    [Array] Array of created image file information.
#>
function New-BenchmarkMemoryTestImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 10
    )

    $createdImages = @()
    
    # Create larger images for memory testing
    for ($i = 1; $i -le $ImageCount; $i++) {
        $format = if ($i % 3 -eq 0) { 'png' } else { 'jpg' }
        $fileName = "memory_test_$($i.ToString('D3')).$format"
        $filePath = Join-Path $InputDirectory $fileName
        
        # Create larger images to test memory usage
        $width = 1920 + ($i * 100)  # Varying sizes
        $height = 1080 + ($i * 75)
        
        $imageInfo = New-TestImageFile -FilePath $filePath -Width $width -Height $height -Format $format
        $createdImages += $imageInfo
    }

    return $createdImages
}

<#
.SYNOPSIS
    Creates test images for scalability benchmarking.

.DESCRIPTION
    Creates a varied set of test images with different sizes and formats
    to test scalability characteristics.

.PARAMETER InputDirectory
    Directory to create test images in.

.PARAMETER ImageCount
    Number of images to create.

.OUTPUTS
    [Array] Array of created image file information.
#>
function New-BenchmarkScalabilityTestImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 30
    )

    $createdImages = @()
    
    # Create varied images for scalability testing
    $sizes = @(
        @{Width=640; Height=480},    # Small
        @{Width=1024; Height=768},   # Medium
        @{Width=1920; Height=1080},  # Large
        @{Width=2560; Height=1440}   # Extra Large
    )
    
    for ($i = 1; $i -le $ImageCount; $i++) {
        $sizeIndex = ($i - 1) % $sizes.Count
        $size = $sizes[$sizeIndex]
        
        $format = switch ($i % 4) {
            0 { 'jpg' }
            1 { 'png' }
            2 { 'jpg' }
            3 { 'png' }
        }
        
        $fileName = "scalability_test_$($i.ToString('D3')).$format"
        $filePath = Join-Path $InputDirectory $fileName
        
        $imageInfo = New-TestImageFile -FilePath $filePath -Width $size.Width -Height $size.Height -Format $format
        $createdImages += $imageInfo
    }

    return $createdImages
}

<#
.SYNOPSIS
    Creates test images for cross-platform benchmarking.

.DESCRIPTION
    Creates test images with cross-platform compatible formats
    and naming conventions for cross-platform testing.

.PARAMETER InputDirectory
    Directory to create test images in.

.PARAMETER ImageCount
    Number of images to create.

.OUTPUTS
    [Array] Array of created image file information.
#>
function New-BenchmarkCrossPlatformTestImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 20
    )

    $createdImages = @()
    
    # Create cross-platform compatible test images
    for ($i = 1; $i -le $ImageCount; $i++) {
        # Use cross-platform safe naming
        $format = if ($i % 2 -eq 0) { 'jpg' } else { 'png' }
        $fileName = "xplatform_test_$($i.ToString('D3')).$format"
        $filePath = Join-Path $InputDirectory $fileName
        
        # Standard sizes that work well across platforms
        $width = 1024
        $height = 768
        
        $imageInfo = New-TestImageFile -FilePath $filePath -Width $width -Height $height -Format $format
        $createdImages += $imageInfo
    }

    return $createdImages
}

<#
.SYNOPSIS
    Creates comprehensive test images for full benchmarking.

.DESCRIPTION
    Creates a comprehensive set of test images covering all
    benchmark scenarios for complete performance analysis.

.PARAMETER InputDirectory
    Directory to create test images in.

.PARAMETER ImageCount
    Number of images to create.

.PARAMETER IncludeVariedSizes
    Include images of varied sizes.

.OUTPUTS
    [Array] Array of created image file information.
#>
function New-BenchmarkComprehensiveTestImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 50,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVariedSizes
    )

    $createdImages = @()
    
    # Create comprehensive test dataset
    $formats = @('jpg', 'png')
    $baseSizes = @(
        @{Width=640; Height=480},
        @{Width=1024; Height=768},
        @{Width=1920; Height=1080}
    )
    
    for ($i = 1; $i -le $ImageCount; $i++) {
        $format = $formats[($i - 1) % $formats.Count]
        $sizeIndex = ($i - 1) % $baseSizes.Count
        $baseSize = $baseSizes[$sizeIndex]
        
        $width = $baseSize.Width
        $height = $baseSize.Height
        
        if ($IncludeVariedSizes) {
            # Add some variation to sizes
            $width += (Get-Random -Minimum -100 -Maximum 100)
            $height += (Get-Random -Minimum -75 -Maximum 75)
        }
        
        $fileName = "comprehensive_test_$($i.ToString('D3')).$format"
        $filePath = Join-Path $InputDirectory $fileName
        
        $imageInfo = New-TestImageFile -FilePath $filePath -Width $width -Height $height -Format $format
        $createdImages += $imageInfo
    }

    return $createdImages
}

<#
.SYNOPSIS
    Creates a test image file with specified parameters.

.DESCRIPTION
    Creates a test image file using System.Drawing with the specified
    dimensions and format for benchmarking purposes.

.PARAMETER FilePath
    Path where the image file should be created.

.PARAMETER Width
    Width of the image in pixels.

.PARAMETER Height
    Height of the image in pixels.

.PARAMETER Format
    Image format ('jpg' or 'png').

.OUTPUTS
    [PSCustomObject] Information about the created image file.
#>
function New-TestImageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [int]$Width = 800,

        [Parameter(Mandatory = $false)]
        [int]$Height = 600,

        [Parameter(Mandatory = $false)]
        [ValidateSet('jpg', 'png')]
        [string]$Format = 'jpg'
    )

    try {
        # Create a simple test image using System.Drawing
        Add-Type -AssemblyName System.Drawing
        
        $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Fill with a gradient pattern for realistic file sizes
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new($Width, $Height),
            [System.Drawing.Color]::Blue,
            [System.Drawing.Color]::Red
        )
        
        $graphics.FillRectangle($brush, 0, 0, $Width, $Height)
        
        # Save the image
        $imageFormat = if ($Format -eq 'jpg') { 
            [System.Drawing.Imaging.ImageFormat]::Jpeg 
        } else { 
            [System.Drawing.Imaging.ImageFormat]::Png 
        }
        
        $bitmap.Save($FilePath, $imageFormat)
        
        # Clean up
        $graphics.Dispose()
        $brush.Dispose()
        $bitmap.Dispose()
        
        # Return file information
        $fileInfo = Get-Item $FilePath
        return [PSCustomObject]@{
            FullName = $fileInfo.FullName
            Name = $fileInfo.Name
            Extension = $fileInfo.Extension
            Length = $fileInfo.Length
            Width = $Width
            Height = $Height
            Format = $Format
        }
    }
    catch {
        Write-Error "Failed to create test image: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Removes performance benchmark test data.

.DESCRIPTION
    Cleans up test data created for performance benchmarking,
    including all subdirectories and files.

.PARAMETER TestDataPath
    Path to the test data to remove.

.EXAMPLE
    Remove-PerformanceBenchmarkTestData -TestDataPath $dataset.TestRootPath
#>
function Remove-PerformanceBenchmarkTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestDataPath
    )

    if (Test-Path $TestDataPath) {
        try {
            Remove-Item -Path $TestDataPath -Recurse -Force
            Write-Verbose "Removed performance benchmark test data: $TestDataPath"
        }
        catch {
            Write-Warning "Failed to remove test data: $($_.Exception.Message)"
        }
    }
}
