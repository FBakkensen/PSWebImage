# Parallel Processing Test Data Library
# Centralized test data creation for parallel processing functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates test image collections for parallel processing testing.

.DESCRIPTION
    Creates multiple test image files and scenarios specifically designed for testing
    parallel processing functionality, including batch processing, error handling,
    progress reporting, and memory management scenarios.

.PARAMETER TestRootPath
    The root path where the test image collections should be created.

.PARAMETER ImageCount
    Number of test images to create for parallel processing (default: 10).

.PARAMETER CreateRealImages
    If specified, attempts to create real image files using .NET System.Drawing.
    Otherwise creates mock files with image extensions.

.OUTPUTS
    [PSCustomObject] Information about the created test image collection.

.EXAMPLE
    $testData = New-ParallelProcessingTestImages -TestRootPath "C:\temp\parallel" -ImageCount 15
#>
function New-ParallelProcessingTestImages {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 10,

        [Parameter(Mandatory = $false)]
        [switch]$CreateRealImages
    )

    try {
        Write-Verbose "Creating parallel processing test images at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Define test image specifications for parallel processing
        $testImageSpecs = @()

        # Create a variety of image formats and sizes for parallel testing
        $formats = @('JPEG', 'PNG', 'WebP', 'AVIF')
        $sizes = @(
            @{ Width = 400; Height = 300; Size = "Small" },
            @{ Width = 800; Height = 600; Size = "Medium" },
            @{ Width = 1200; Height = 900; Size = "Large" }
        )

        for ($i = 1; $i -le $ImageCount; $i++) {
            $format = $formats[($i - 1) % $formats.Count]
            $size = $sizes[($i - 1) % $sizes.Count]

            $extension = switch ($format) {
                'JPEG' { 'jpg' }
                'PNG' { 'png' }
                'WebP' { 'webp' }
                'AVIF' { 'avif' }
            }

            $testImageSpecs += @{
                Name = "parallel_test_image_$($i.ToString('00')).$extension"
                Format = $format
                Width = $size.Width
                Height = $size.Height
                Quality = 85
                Size = $size.Size
                Content = "$($format)_PARALLEL_TEST_CONTENT_$($i)_$($size.Width)x$($size.Height)"
                Index = $i
            }
        }

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
                Index = $spec.Index
                FileSize = if (Test-Path $imagePath) { (Get-Item $imagePath).Length } else { 0 }
            }

            Write-Verbose "Created parallel test image: $($spec.Name)"
        }

        # Return structured information about the test images
        $result = [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedImages = $createdImages
            ImageMetadata = $imageMetadata
            TotalImages = $createdImages.Count
            SupportedFormats = @('JPEG', 'PNG', 'WebP', 'AVIF')
            TestScenarios = @('SmallBatch', 'MediumBatch', 'LargeBatch', 'MixedFormats', 'MixedSizes')
            BatchSizes = @{
                Small = [Math]::Min(3, $ImageCount)
                Medium = [Math]::Min(7, $ImageCount)
                Large = $ImageCount
            }
        }

        Write-Verbose "Created $($result.TotalImages) test images for parallel processing"
        return $result
    }
    catch {
        Write-Error "Failed to create parallel processing test images: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates a large batch test scenario for memory management testing.

.DESCRIPTION
    Creates a large collection of test images specifically designed for testing
    memory management and performance characteristics of parallel processing.

.PARAMETER TestRootPath
    The root path where the large batch test should be created.

.PARAMETER BatchSize
    Number of images in the large batch (default: 50).

.OUTPUTS
    [PSCustomObject] Information about the created large batch test scenario.

.EXAMPLE
    $largeBatch = New-LargeBatchTestScenario -TestRootPath "C:\temp\large" -BatchSize 100
#>
function New-LargeBatchTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 50
    )

    try {
        Write-Verbose "Creating large batch test scenario with $BatchSize images"

        # Create the test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Create large batch of images with varying characteristics
        $createdImages = @()
        $totalSize = 0

        for ($i = 1; $i -le $BatchSize; $i++) {
            $fileName = "large_batch_image_$($i.ToString('000')).jpg"
            $filePath = Join-Path $testDir.FullName $fileName

            # Create content that simulates different file sizes
            $baseContent = "LARGE_BATCH_TEST_IMAGE_$i"
            $paddingSize = 1000 + ($i * 100)  # Varying file sizes
            $content = $baseContent.PadRight($paddingSize, 'X')

            Set-Content -Path $filePath -Value $content -Encoding UTF8
            $createdImages += $filePath
            $totalSize += (Get-Item $filePath).Length

            if ($i % 10 -eq 0) {
                Write-Verbose "Created $i of $BatchSize large batch images"
            }
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedImages = $createdImages
            BatchSize = $BatchSize
            TotalSize = $totalSize
            AverageSize = [Math]::Round($totalSize / $BatchSize, 2)
            MemoryTestScenarios = @('HighMemoryUsage', 'MemoryPressure', 'GarbageCollection')
        }
    }
    catch {
        Write-Error "Failed to create large batch test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates a mixed validity test scenario for error handling testing.

.DESCRIPTION
    Creates a collection of both valid and invalid files to test error handling
    and resilience in parallel processing scenarios.

.PARAMETER TestRootPath
    The root path where the mixed validity test should be created.

.OUTPUTS
    [PSCustomObject] Information about the created mixed validity test scenario.

.EXAMPLE
    $mixedTest = New-MixedValidityTestScenario -TestRootPath "C:\temp\mixed"
#>
function New-MixedValidityTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating mixed validity test scenario"

        # Create the test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        $validFiles = @()
        $invalidFiles = @()

        # Create valid image files
        $validSpecs = @(
            @{ Name = "valid_image_01.jpg"; Content = "VALID_JPEG_CONTENT_800x600" },
            @{ Name = "valid_image_02.png"; Content = "VALID_PNG_CONTENT_640x480" },
            @{ Name = "valid_image_03.webp"; Content = "VALID_WEBP_CONTENT_1024x768" }
        )

        foreach ($spec in $validSpecs) {
            $filePath = Join-Path $testDir.FullName $spec.Name
            Set-Content -Path $filePath -Value $spec.Content -Encoding UTF8
            $validFiles += $filePath
        }

        # Create invalid/problematic files
        $invalidSpecs = @(
            @{ Name = "corrupted_image.jpg"; Content = "CORRUPTED_INVALID_CONTENT" },
            @{ Name = "empty_file.png"; Content = "" },
            @{ Name = "wrong_extension.txt"; Content = "NOT_AN_IMAGE_FILE" },
            @{ Name = "locked_file.jpg"; Content = "LOCKED_FILE_CONTENT"; Locked = $true }
        )

        foreach ($spec in $invalidSpecs) {
            $filePath = Join-Path $testDir.FullName $spec.Name
            Set-Content -Path $filePath -Value $spec.Content -Encoding UTF8
            $invalidFiles += $filePath

            # Simulate locked file by setting read-only (simplified simulation)
            if ($spec.Locked) {
                try {
                    Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
                } catch {
                    Write-Verbose "Could not set read-only attribute on $filePath"
                }
            }
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            ValidFiles = $validFiles
            InvalidFiles = $invalidFiles
            TotalFiles = $validFiles.Count + $invalidFiles.Count
            ValidCount = $validFiles.Count
            InvalidCount = $invalidFiles.Count
            ErrorScenarios = @('CorruptedFiles', 'EmptyFiles', 'WrongExtensions', 'LockedFiles')
        }
    }
    catch {
        Write-Error "Failed to create mixed validity test scenario: $($_.Exception.Message)"
        throw
    }
}

# Helper function to create mock test images (reused from other test libraries)
function New-MockTestImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Specification
    )

    try {
        Set-Content -Path $ImagePath -Value $Specification.Content -Encoding UTF8
        Write-Verbose "Created mock test image: $ImagePath"
        return $true
    }
    catch {
        Write-Verbose "Failed to create mock test image '$ImagePath': $($_.Exception.Message)"
        return $false
    }
}

# Helper function to create real test images (simplified version)
function New-RealTestImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Specification
    )

    try {
        # For now, fallback to mock images
        # In a real implementation, this would use System.Drawing to create actual images
        return New-MockTestImage -ImagePath $ImagePath -Specification $Specification
    }
    catch {
        Write-Verbose "Failed to create real test image '$ImagePath': $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Creates a test scenario specifically designed for progress callback testing.

.DESCRIPTION
    Creates a controlled set of test images with predictable processing characteristics
    to enable accurate testing of progress callback functionality, including timing,
    percentage calculations, and progress information accuracy.

.PARAMETER TestRootPath
    The root path where the progress callback test scenario should be created.

.PARAMETER ImageCount
    Number of test images to create for progress testing (default: 10).

.PARAMETER IncludeErrorFiles
    If specified, includes files that will cause processing errors to test error progress reporting.

.OUTPUTS
    [PSCustomObject] Information about the created progress callback test scenario.

.EXAMPLE
    $progressTest = New-ProgressCallbackTestScenario -TestRootPath "C:\temp\progress" -ImageCount 8
#>
function New-ProgressCallbackTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeErrorFiles
    )

    try {
        # Create test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        Write-Verbose "Created progress callback test directory: $($testDir.FullName)"

        $createdImages = @()
        $errorFiles = @()

        # Create valid test images with predictable names for progress tracking
        for ($i = 1; $i -le $ImageCount; $i++) {
            $fileName = "progress_success_test_image_{0:D3}.jpg" -f $i
            $filePath = Join-Path $testDir.FullName $fileName

            $imageSpec = @{
                Content = "MOCK_JPEG_CONTENT_FOR_PROGRESS_TEST_$i"
                Format = "JPEG"
                Width = 800
                Height = 600
                Quality = 85
            }

            if (New-MockTestImage -ImagePath $filePath -Specification $imageSpec) {
                $createdImages += $filePath
            }
        }

        # Create error files if requested
        if ($IncludeErrorFiles) {
            $errorSpecs = @(
                @{ Name = "progress_error_corrupted.jpg"; Content = "CORRUPTED_CONTENT" },
                @{ Name = "progress_error_empty.png"; Content = "" },
                @{ Name = "progress_error_invalid.txt"; Content = "NOT_AN_IMAGE" }
            )

            foreach ($spec in $errorSpecs) {
                $filePath = Join-Path $testDir.FullName $spec.Name
                Set-Content -Path $filePath -Value $spec.Content -Encoding UTF8
                $errorFiles += $filePath
            }
        }

        # Return structured information
        $result = [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            ValidImages = $createdImages
            ErrorFiles = $errorFiles
            TotalFiles = $createdImages.Count + $errorFiles.Count
            ValidImageCount = $createdImages.Count
            ErrorFileCount = $errorFiles.Count
            ExpectedSuccessCount = $createdImages.Count
            ExpectedErrorCount = $errorFiles.Count
            TestScenario = "ProgressCallback"
        }

        Write-Verbose "Created progress callback test scenario with $($result.ValidImageCount) valid images and $($result.ErrorFileCount) error files"
        return $result
    }
    catch {
        Write-Error "Failed to create progress callback test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates a mock progress callback function for testing progress reporting.

.DESCRIPTION
    Creates a scriptblock that captures progress information for testing purposes.
    The callback stores all progress updates in a thread-safe collection for later verification.

.PARAMETER ProgressStorage
    A thread-safe collection to store progress updates (ConcurrentBag).

.PARAMETER ThrowErrorAfter
    If specified, the callback will throw an error after this many progress updates.

.OUTPUTS
    [scriptblock] A progress callback function for testing.

.EXAMPLE
    $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
    $callback = New-MockProgressCallback -ProgressStorage $progressData
#>
function New-MockProgressCallback {
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]$ProgressStorage,

        [Parameter(Mandatory = $false)]
        [int]$ThrowErrorAfter = -1
    )

    # Create a simple callback that captures the storage reference
    # We'll use a script-scoped variable approach for testing
    $script:TestProgressStorage = $ProgressStorage
    $script:TestThrowErrorAfter = $ThrowErrorAfter

    $callback = {
        param($progressInfo)

        # Store the progress information using script scope
        $script:TestProgressStorage.Add($progressInfo)

        # Throw error if requested (for testing error handling)
        if ($script:TestThrowErrorAfter -gt 0 -and $script:TestProgressStorage.Count -ge $script:TestThrowErrorAfter) {
            throw "Mock progress callback error for testing"
        }
    }

    return $callback
}

<#
.SYNOPSIS
    Creates a test scenario for testing progress callback error handling.

.DESCRIPTION
    Creates a test scenario where the progress callback itself throws errors
    to verify that callback errors don't break the main processing.

.PARAMETER TestRootPath
    The root path where the error callback test scenario should be created.

.PARAMETER ImageCount
    Number of test images to create (default: 5).

.OUTPUTS
    [PSCustomObject] Information about the created error callback test scenario.

.EXAMPLE
    $errorTest = New-ProgressCallbackErrorTestScenario -TestRootPath "C:\temp\error" -ImageCount 5
#>
function New-ProgressCallbackErrorTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$ImageCount = 5
    )

    try {
        # Create test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        Write-Verbose "Created progress callback error test directory: $($testDir.FullName)"

        $createdImages = @()

        # Create test images
        for ($i = 1; $i -le $ImageCount; $i++) {
            $fileName = "callback_success_error_test_$i.jpg"
            $filePath = Join-Path $testDir.FullName $fileName

            $imageSpec = @{
                Content = "MOCK_JPEG_CONTENT_FOR_CALLBACK_ERROR_TEST_$i"
                Format = "JPEG"
                Width = 400
                Height = 300
                Quality = 80
            }

            if (New-MockTestImage -ImagePath $filePath -Specification $imageSpec) {
                $createdImages += $filePath
            }
        }

        # Return structured information
        $result = [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            CreatedImages = $createdImages
            TotalImages = $createdImages.Count
            TestScenario = "ProgressCallbackError"
            ErrorAfterCount = [Math]::Ceiling($ImageCount / 2)  # Error after half the files
        }

        Write-Verbose "Created progress callback error test scenario with $($result.TotalImages) images"
        return $result
    }
    catch {
        Write-Error "Failed to create progress callback error test scenario: $($_.Exception.Message)"
        throw
    }
}
