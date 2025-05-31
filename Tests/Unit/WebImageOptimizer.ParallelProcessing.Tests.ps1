# Test suite for WebImageOptimizer Parallel Processing Implementation (Task 8)
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "WebImageOptimizer Parallel Processing Implementation" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:TestDataLibraryPath = Join-Path $script:ModuleRoot "Tests\TestDataLibraries\ParallelProcessing.TestDataLibrary.ps1"
        $script:ParallelProcessingPath = Join-Path $script:PrivatePath "Invoke-ParallelImageProcessing.ps1"

        # Import required dependencies
        $script:ImageOptimizationPath = Join-Path $script:PrivatePath "Invoke-ImageOptimization.ps1"
        $script:ConfigurationPath = Join-Path $script:PrivatePath "ConfigurationManager.ps1"

        # Import the test data library
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        }

        # Import existing functions
        if (Test-Path $script:ImageOptimizationPath) {
            . $script:ImageOptimizationPath
        }

        if (Test-Path $script:ConfigurationPath) {
            . $script:ConfigurationPath
        }

        # Import the parallel processing function if it exists
        if (Test-Path $script:ParallelProcessingPath) {
            . $script:ParallelProcessingPath
        }

        # Set up test root directory
        $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_ParallelProcessing_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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

    Context "Given PowerShell 7 parallel processing capabilities are available" {

        BeforeAll {
            # Verify PowerShell 7 features are available
            $script:PowerShell7Available = $PSVersionTable.PSVersion.Major -ge 7
            $script:ParallelSupported = Get-Command ForEach-Object | Where-Object { $_.Parameters.ContainsKey('Parallel') }
        }

        It "Should have PowerShell 7 or higher available" {
            $script:PowerShell7Available | Should -Be $true
        }

        It "Should have ForEach-Object -Parallel support" {
            $script:ParallelSupported | Should -Not -BeNullOrEmpty
        }
    }

    Context "When processing multiple images in parallel with default settings" {

        BeforeAll {
            # Create test images for parallel processing
            $script:BasicParallelTestPath = Join-Path $script:TestRoot "BasicParallel"
            if (Get-Command New-ParallelProcessingTestImages -ErrorAction SilentlyContinue) {
                $script:BasicParallelTestImages = New-ParallelProcessingTestImages -TestRootPath $script:BasicParallelTestPath -ImageCount 6
            }
        }

        It "Should process all images successfully using parallel execution" {
            # Given: A collection of image files and default configuration
            # When: Parallel processing is invoked
            # Then: All images are processed successfully using multiple threads

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:BasicParallelTestImages) {
                $outputPath = Join-Path $script:BasicParallelTestPath "output"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:BasicParallelTestImages.CreatedImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath

                $result | Should -Not -BeNullOrEmpty
                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.SuccessCount | Should -Be $imageFiles.Count
                $result.ErrorCount | Should -Be 0
                $result.ProcessingMethod | Should -Be "Parallel"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test images not available"
            }
        }

        It "Should use multiple threads for processing" {
            # Given: A collection of image files
            # When: Parallel processing is invoked
            # Then: Processing uses multiple threads as indicated by performance metrics

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:BasicParallelTestImages) {
                $outputPath = Join-Path $script:BasicParallelTestPath "output_threads"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:BasicParallelTestImages.CreatedImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath

                $result.ThreadsUsed | Should -BeGreaterThan 1
                $result.ParallelExecutionTime | Should -BeOfType [timespan]
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test images not available"
            }
        }
    }

    Context "When processing images with custom thread count configuration" {

        BeforeAll {
            # Create test images for custom thread testing
            $script:CustomThreadTestPath = Join-Path $script:TestRoot "CustomThread"
            if (Get-Command New-ParallelProcessingTestImages -ErrorAction SilentlyContinue) {
                $script:CustomThreadTestImages = New-ParallelProcessingTestImages -TestRootPath $script:CustomThreadTestPath -ImageCount 8
            }
        }

        It "Should respect custom ThrottleLimit parameter" {
            # Given: A collection of image files and custom thread limit
            # When: Parallel processing is invoked with -ThrottleLimit
            # Then: Processing uses the specified number of threads

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:CustomThreadTestImages) {
                $outputPath = Join-Path $script:CustomThreadTestPath "output"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:CustomThreadTestImages.CreatedImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $customThreadCount = 2
                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ThrottleLimit $customThreadCount

                $result.ThrottleLimitUsed | Should -Be $customThreadCount
                $result.TotalProcessed | Should -Be $imageFiles.Count
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test images not available"
            }
        }

        It "Should handle single thread execution (ThrottleLimit = 1)" {
            # Given: A collection of image files and ThrottleLimit of 1
            # When: Parallel processing is invoked with single thread
            # Then: Processing works correctly in single-threaded mode

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:CustomThreadTestImages) {
                $outputPath = Join-Path $script:CustomThreadTestPath "output_single"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:CustomThreadTestImages.CreatedImages | Select-Object -First 3 | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ThrottleLimit 1

                $result.ThrottleLimitUsed | Should -Be 1
                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.SuccessCount | Should -Be $imageFiles.Count
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test images not available"
            }
        }
    }

    Context "When handling errors gracefully across parallel threads" {

        BeforeAll {
            # Create mixed validity test scenario
            $script:ErrorHandlingTestPath = Join-Path $script:TestRoot "ErrorHandling"
            if (Get-Command New-MixedValidityTestScenario -ErrorAction SilentlyContinue) {
                $script:MixedValidityTest = New-MixedValidityTestScenario -TestRootPath $script:ErrorHandlingTestPath
            }
        }

        It "Should process valid files and collect errors for invalid files" {
            # Given: A mix of valid and invalid image files
            # When: Parallel processing is invoked
            # Then: Valid files are processed successfully and errors are collected properly

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:MixedValidityTest) {
                $outputPath = Join-Path $script:ErrorHandlingTestPath "output"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $allFiles = ($script:MixedValidityTest.ValidFiles + $script:MixedValidityTest.InvalidFiles) | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $allFiles -OutputPath $outputPath

                $result.TotalProcessed | Should -Be $allFiles.Count
                $result.SuccessCount | Should -BeGreaterThan 0
                $result.ErrorCount | Should -BeGreaterThan 0
                $result.Errors | Should -Not -BeNullOrEmpty
                $result.Errors.Count | Should -Be $result.ErrorCount
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test scenario not available"
            }
        }

        It "Should maintain thread safety during error collection" {
            # Given: Files that will cause processing errors
            # When: Parallel processing encounters errors
            # Then: Error collection is thread-safe and complete

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:MixedValidityTest) {
                $outputPath = Join-Path $script:ErrorHandlingTestPath "output_threadsafe"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $invalidFiles = $script:MixedValidityTest.InvalidFiles | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $invalidFiles -OutputPath $outputPath -ThrottleLimit 3 -TestMode

                $result.ErrorCount | Should -Be $invalidFiles.Count
                $result.Errors | Should -HaveCount $invalidFiles.Count
                # Each error should have required properties
                $result.Errors | ForEach-Object {
                    $_.FileName | Should -Not -BeNullOrEmpty
                    $_.ErrorMessage | Should -Not -BeNullOrEmpty
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test scenario not available"
            }
        }
    }

    Context "When testing memory management for large batches" {

        BeforeAll {
            # Create large batch test scenario
            $script:MemoryTestPath = Join-Path $script:TestRoot "MemoryTest"
            if (Get-Command New-LargeBatchTestScenario -ErrorAction SilentlyContinue) {
                $script:LargeBatchTest = New-LargeBatchTestScenario -TestRootPath $script:MemoryTestPath -BatchSize 20
            }
        }

        It "Should handle large batches without excessive memory usage" {
            # Given: A large collection of image files
            # When: Parallel processing is invoked
            # Then: Memory usage stays within acceptable limits

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:LargeBatchTest) {
                $outputPath = Join-Path $script:MemoryTestPath "output"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:LargeBatchTest.CreatedImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                # Measure memory before processing
                $memoryBefore = [System.GC]::GetTotalMemory($false)

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ThrottleLimit 4

                # Measure memory after processing and force garbage collection
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                $memoryAfter = [System.GC]::GetTotalMemory($true)

                $memoryIncrease = $memoryAfter - $memoryBefore
                $memoryIncreaseMB = [Math]::Round($memoryIncrease / 1MB, 2)

                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.MemoryUsageMB | Should -BeLessThan 100  # Should not use more than 100MB
                Write-Host "Memory increase during large batch processing: $memoryIncreaseMB MB" -ForegroundColor Cyan
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented or test scenario not available"
            }
        }
    }

    Context "When validating PowerShell 7 specific features" {

        It "Should leverage ForEach-Object -Parallel syntax" {
            # Given: PowerShell 7 parallel processing capabilities
            # When: Parallel processing function is implemented
            # Then: It should use PowerShell 7's native ForEach-Object -Parallel

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue) {
                $functionContent = Get-Content $script:ParallelProcessingPath -Raw
                $functionContent | Should -Match "ForEach-Object.*-Parallel"
                $functionContent | Should -Match "-ThrottleLimit"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented"
            }
        }

        It "Should use PowerShell 7 enhanced error handling" {
            # Given: PowerShell 7 error handling improvements
            # When: Parallel processing encounters errors
            # Then: It should use enhanced error handling features

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue) {
                $functionContent = Get-Content $script:ParallelProcessingPath -Raw
                # Should use try-catch blocks and proper error aggregation
                $functionContent | Should -Match "try\s*\{"
                $functionContent | Should -Match "catch\s*\{"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function not yet implemented"
            }
        }
    }

    Context "When using progress callback functionality" {

        BeforeAll {
            # Create test images for progress callback testing
            $script:ProgressCallbackTestPath = Join-Path $script:TestRoot "ProgressCallback"
            if (Get-Command New-ProgressCallbackTestScenario -ErrorAction SilentlyContinue) {
                $script:ProgressCallbackTestData = New-ProgressCallbackTestScenario -TestRootPath $script:ProgressCallbackTestPath -ImageCount 6
            }
        }

        It "Should invoke progress callback with correct progress information" {
            # Given: A collection of image files and a progress callback
            # When: Parallel processing is invoked with progress callback
            # Then: Progress callback is invoked with accurate progress information

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:ProgressCallbackTestData) {
                $outputPath = Join-Path $script:ProgressCallbackTestPath "output_basic"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                # Create progress storage for testing
                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

                # Create mock progress callback
                if (Get-Command New-MockProgressCallback -ErrorAction SilentlyContinue) {
                    $progressCallback = New-MockProgressCallback -ProgressStorage $progressData
                } else {
                    # Fallback simple callback for testing
                    $progressCallback = {
                        param($progress)
                        $progressData.Add($progress)
                    }
                }

                $imageFiles = $script:ProgressCallbackTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode

                # Verify progress callback was invoked
                $progressUpdates = @($progressData.ToArray())
                $progressUpdates.Count | Should -BeGreaterThan 0
                $progressUpdates.Count | Should -Be $imageFiles.Count

                # Verify progress information structure
                $progressUpdates | ForEach-Object {
                    $_.PercentComplete | Should -BeOfType [double]
                    $_.FilesProcessed | Should -BeOfType [int]
                    $_.TotalFiles | Should -Be $imageFiles.Count
                    $_.CurrentFile | Should -Not -BeNullOrEmpty
                    $_.ElapsedTime | Should -BeOfType [timespan]
                    $_.EstimatedTimeRemaining | Should -BeOfType [timespan]
                    $_.ProcessingRate | Should -BeOfType [double]
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }

        It "Should report accurate progress percentages" {
            # Given: A known number of image files
            # When: Progress callback is invoked during processing
            # Then: Progress percentages should be accurate and sequential

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:ProgressCallbackTestData) {
                $outputPath = Join-Path $script:ProgressCallbackTestPath "output_percentage"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
                $progressCallback = {
                    param($progress)
                    $progressData.Add($progress)
                }

                $imageFiles = $script:ProgressCallbackTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode

                $progressUpdates = @($progressData.ToArray() | Sort-Object FilesProcessed)

                # Verify percentage calculations
                for ($i = 0; $i -lt $progressUpdates.Count; $i++) {
                    $expectedPercentage = [math]::Round((($i + 1) / $imageFiles.Count) * 100, 2)
                    $progressUpdates[$i].PercentComplete | Should -Be $expectedPercentage
                    $progressUpdates[$i].FilesProcessed | Should -Be ($i + 1)
                }

                # Final progress should be 100%
                $progressUpdates[-1].PercentComplete | Should -Be 100.0
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }

        It "Should maintain thread-safe progress tracking across parallel threads" {
            # Given: Multiple image files processed in parallel
            # When: Progress callback is invoked from multiple threads
            # Then: Progress counting should be thread-safe and accurate

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:ProgressCallbackTestData) {
                $outputPath = Join-Path $script:ProgressCallbackTestPath "output_threadsafe"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
                $progressCallback = {
                    param($progress)
                    $progressData.Add($progress)
                }

                $imageFiles = $script:ProgressCallbackTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                # Use multiple threads to test thread safety
                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -ThrottleLimit 3 -TestMode

                $progressUpdates = @($progressData.ToArray())

                # Verify no duplicate progress counts (thread safety)
                $filesProcessedCounts = $progressUpdates | Select-Object -ExpandProperty FilesProcessed | Sort-Object
                $uniqueCounts = $filesProcessedCounts | Select-Object -Unique

                $filesProcessedCounts.Count | Should -Be $uniqueCounts.Count
                $progressUpdates.Count | Should -Be $imageFiles.Count
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }
    }

    Context "When progress callback encounters errors" {

        BeforeAll {
            # Create test scenario with mixed valid/error files
            $script:ProgressErrorTestPath = Join-Path $script:TestRoot "ProgressError"
            if (Get-Command New-ProgressCallbackTestScenario -ErrorAction SilentlyContinue) {
                $script:ProgressErrorTestData = New-ProgressCallbackTestScenario -TestRootPath $script:ProgressErrorTestPath -ImageCount 4 -IncludeErrorFiles
            }
        }

        It "Should report progress for both successful and failed file processing" {
            # Given: A mix of valid and invalid files with progress callback
            # When: Parallel processing encounters both successes and errors
            # Then: Progress should be reported for all files regardless of processing outcome

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:ProgressErrorTestData) {
                $outputPath = Join-Path $script:ProgressErrorTestPath "output_mixed"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
                $progressCallback = {
                    param($progress)
                    $progressData.Add($progress)
                }

                # Combine valid and error files
                $allFiles = @()
                $allFiles += $script:ProgressErrorTestData.ValidImages
                $allFiles += $script:ProgressErrorTestData.ErrorFiles

                $imageFiles = $allFiles | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode

                $progressUpdates = @($progressData.ToArray())

                # Progress should be reported for all files (success + error)
                $progressUpdates.Count | Should -Be $imageFiles.Count
                $maxProgress = ($progressUpdates | Measure-Object -Property PercentComplete -Maximum).Maximum
                $maxProgress | Should -Be 100.0

                # Verify processing results include both successes and errors
                $result.SuccessCount | Should -BeGreaterThan 0
                $result.ErrorCount | Should -BeGreaterThan 0
                ($result.SuccessCount + $result.ErrorCount) | Should -Be $imageFiles.Count
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }

        It "Should handle progress callback errors gracefully without breaking processing" {
            # Given: A progress callback that throws errors
            # When: Parallel processing is invoked with the error-prone callback
            # Then: Processing should continue and complete despite callback errors

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:ProgressErrorTestData) {
                $outputPath = Join-Path $script:ProgressErrorTestPath "output_callback_error"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                # Create a callback that throws errors after a few calls
                $callCount = 0
                $progressCallback = {
                    param($progress)
                    $script:callCount++
                    if ($script:callCount -gt 2) {
                        throw "Test callback error"
                    }
                }

                $imageFiles = $script:ProgressErrorTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                # Processing should complete despite callback errors
                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode

                # Verify processing completed successfully
                $result | Should -Not -BeNullOrEmpty
                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.ProcessingMethod | Should -Be "Parallel"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }
    }

    Context "When progress callback parameter is optional" {

        BeforeAll {
            # Create simple test scenario for optional parameter testing
            $script:OptionalCallbackTestPath = Join-Path $script:TestRoot "OptionalCallback"
            if (Get-Command New-ProgressCallbackTestScenario -ErrorAction SilentlyContinue) {
                $script:OptionalCallbackTestData = New-ProgressCallbackTestScenario -TestRootPath $script:OptionalCallbackTestPath -ImageCount 3
            }
        }

        It "Should work correctly when no progress callback is provided" {
            # Given: Image files but no progress callback
            # When: Parallel processing is invoked without progress callback
            # Then: Processing should complete normally without progress reporting

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:OptionalCallbackTestData) {
                $outputPath = Join-Path $script:OptionalCallbackTestPath "output_no_callback"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:OptionalCallbackTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                # Should work without progress callback
                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -TestMode

                $result | Should -Not -BeNullOrEmpty
                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.SuccessCount | Should -Be $imageFiles.Count
                $result.ProcessingMethod | Should -Be "Parallel"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }

        It "Should work correctly when progress callback is null" {
            # Given: Image files and explicitly null progress callback
            # When: Parallel processing is invoked with null callback
            # Then: Processing should complete normally without progress reporting

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:OptionalCallbackTestData) {
                $outputPath = Join-Path $script:OptionalCallbackTestPath "output_null_callback"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $imageFiles = $script:OptionalCallbackTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                # Should work with null progress callback
                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $null -TestMode

                $result | Should -Not -BeNullOrEmpty
                $result.TotalProcessed | Should -Be $imageFiles.Count
                $result.SuccessCount | Should -Be $imageFiles.Count
                $result.ProcessingMethod | Should -Be "Parallel"
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }
    }

    Context "When validating progress information accuracy" {

        BeforeAll {
            # Create test scenario for accuracy validation
            $script:AccuracyTestPath = Join-Path $script:TestRoot "Accuracy"
            if (Get-Command New-ProgressCallbackTestScenario -ErrorAction SilentlyContinue) {
                $script:AccuracyTestData = New-ProgressCallbackTestScenario -TestRootPath $script:AccuracyTestPath -ImageCount 5
            }
        }

        It "Should provide accurate elapsed time and processing rate calculations" {
            # Given: Image files and progress callback
            # When: Progress is reported during processing
            # Then: Elapsed time and processing rate should be accurate

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:AccuracyTestData) {
                $outputPath = Join-Path $script:AccuracyTestPath "output_timing"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
                $startTime = Get-Date

                $progressCallback = {
                    param($progress)
                    $progressData.Add($progress)
                }

                $imageFiles = $script:AccuracyTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode
                $endTime = Get-Date

                $progressUpdates = @($progressData.ToArray() | Sort-Object FilesProcessed)

                # Verify elapsed time is reasonable
                $progressUpdates | ForEach-Object {
                    $_.ElapsedTime | Should -BeOfType [timespan]
                    $_.ElapsedTime.TotalSeconds | Should -BeGreaterThan 0
                    $_.ElapsedTime.TotalSeconds | Should -BeLessThan ($endTime - $startTime).TotalSeconds + 5  # Allow some tolerance
                }

                # Verify processing rate calculations
                $progressUpdates | ForEach-Object {
                    $_.ProcessingRate | Should -BeOfType [double]
                    $_.ProcessingRate | Should -BeGreaterOrEqual 0
                    if ($_.ElapsedTime.TotalSeconds -gt 0) {
                        $expectedRate = $_.FilesProcessed / $_.ElapsedTime.TotalSeconds
                        $_.ProcessingRate | Should -BeGreaterOrEqual ($expectedRate * 0.8)  # Allow some tolerance
                    }
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }

        It "Should provide accurate estimated time remaining calculations" {
            # Given: Image files and progress callback
            # When: Progress is reported during processing
            # Then: Estimated time remaining should decrease as processing progresses

            if (Get-Command Invoke-ParallelImageProcessing -ErrorAction SilentlyContinue -and $script:AccuracyTestData) {
                $outputPath = Join-Path $script:AccuracyTestPath "output_estimates"
                New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

                $progressData = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

                $progressCallback = {
                    param($progress)
                    $progressData.Add($progress)
                }

                $imageFiles = $script:AccuracyTestData.ValidImages | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_
                        Name = Split-Path $_ -Leaf
                        Extension = [System.IO.Path]::GetExtension($_)
                    }
                }

                $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath $outputPath -ProgressCallback $progressCallback -TestMode

                $progressUpdates = @($progressData.ToArray() | Sort-Object FilesProcessed)

                # Verify estimated time remaining
                $progressUpdates | ForEach-Object {
                    $_.EstimatedTimeRemaining | Should -BeOfType [timespan]
                    $_.EstimatedTimeRemaining.TotalSeconds | Should -BeGreaterOrEqual 0
                }

                # Estimated time should generally decrease (allowing for some variance due to parallel processing)
                if ($progressUpdates.Count -gt 2) {
                    $firstEstimate = $progressUpdates[0].EstimatedTimeRemaining.TotalSeconds
                    $lastEstimate = $progressUpdates[-1].EstimatedTimeRemaining.TotalSeconds
                    $lastEstimate | Should -BeLessOrEqual $firstEstimate
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ParallelImageProcessing function or test data not available"
            }
        }
    }
}
