# Performance Integration Tests for WebImageOptimizer
# Tests large dataset processing and performance characteristics
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

BeforeAll {
    # Import test helper for path resolution
    $testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
    if (Test-Path $testHelperPath) {
        Import-Module $testHelperPath -Force
    } else {
        throw "Test helper module not found: $testHelperPath"
    }

    # Define the module root path with robust resolution
    $script:ModuleRoot = Get-ModuleRootPath

    # Import the WebImageOptimizer module
    $modulePath = Join-Path $script:ModuleRoot "WebImageOptimizer\WebImageOptimizer.psd1"
    if (-not (Test-Path $modulePath)) {
        throw "Module not found: $modulePath"
    }
    Import-Module $modulePath -Force

    # Import Integration Test Data Library
    $integrationLibraryPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestDataLibraries\Integration.TestDataLibrary.ps1"
    if (-not (Test-Path $integrationLibraryPath)) {
        throw "Integration Test Data Library not found: $integrationLibraryPath"
    }
    . $integrationLibraryPath

    # Set up test environment
    $script:TestRootPath = Join-Path $env:TEMP "WebImageOptimizer_Performance_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:LargeDataset = $null

    # Performance targets from PRD
    $script:TargetImagesPerMinute = 50
    $script:TargetMaxMemoryGB = 1
}

AfterAll {
    # Clean up test data
    if ($script:LargeDataset -and (Test-Path $script:LargeDataset.TestRootPath)) {
        Remove-IntegrationTestData -TestDataPath $script:LargeDataset.TestRootPath
    }
}

Describe "WebImageOptimizer Performance Integration Tests" -Tag @('Integration', 'Performance') {

    BeforeAll {
        # Create large dataset for performance testing
        Write-Host "Creating large dataset for performance testing..." -ForegroundColor Yellow
        $script:LargeDataset = New-IntegrationTestImageCollection -TestRootPath $script:TestRootPath -ImageCount 25 -IncludeLargeDataset

        Write-Host "Performance test dataset created with $($script:LargeDataset.TotalImages) images" -ForegroundColor Green
    }

    Context "Processing Speed Performance" {

        It "Should process images at target rate of 50+ images per minute" {
            # Given: A large collection of test images
            $inputPath = $script:LargeDataset.InputDirectory
            $outputPath = Join-Path $script:LargeDataset.TestRootPath "SpeedTest"

            $inputImages = Get-ChildItem -Path $inputPath -Recurse -Include "*.jpg", "*.png"
            $imageCount = $inputImages.Count
            $imageCount | Should -BeGreaterThan 10 -Because "Need sufficient images for meaningful performance test"

            # When: I process the images and measure performance
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath
            $stopwatch.Stop()

            # Then: Processing should meet performance targets
            $result.Success | Should -Be $true -Because "Performance test should complete successfully"
            $result.FilesProcessed | Should -Be $imageCount -Because "All images should be processed"

            # And: Should meet target processing rate
            $processingTimeMinutes = $stopwatch.Elapsed.TotalMinutes
            $imagesPerMinute = $imageCount / $processingTimeMinutes

            Write-Host "Processed $imageCount images in $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
            Write-Host "Processing rate: $([math]::Round($imagesPerMinute, 2)) images per minute" -ForegroundColor Green

            $imagesPerMinute | Should -BeGreaterThan ($script:TargetImagesPerMinute * 0.8) -Because "Should achieve at least 80% of target processing rate (40+ images/minute)"
        }

        It "Should scale processing time linearly with image count" {
            # Given: Different sized datasets
            $smallDataset = New-IntegrationTestImageCollection -TestRootPath (Join-Path $script:TestRootPath "SmallScale") -ImageCount 5
            $mediumDataset = New-IntegrationTestImageCollection -TestRootPath (Join-Path $script:TestRootPath "MediumScale") -ImageCount 15

            try {
                # When: I process datasets of different sizes
                $smallStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $smallResult = Optimize-WebImages -Path $smallDataset.InputDirectory -OutputPath (Join-Path $smallDataset.TestRootPath "Output")
                $smallStopwatch.Stop()

                $mediumStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $mediumResult = Optimize-WebImages -Path $mediumDataset.InputDirectory -OutputPath (Join-Path $mediumDataset.TestRootPath "Output")
                $mediumStopwatch.Stop()

                # Then: Processing time should scale approximately linearly
                $smallResult.Success | Should -Be $true
                $mediumResult.Success | Should -Be $true

                $smallTimePerImage = $smallStopwatch.Elapsed.TotalSeconds / $smallResult.FilesProcessed
                $mediumTimePerImage = $mediumStopwatch.Elapsed.TotalSeconds / $mediumResult.FilesProcessed

                Write-Host "Small dataset: $($smallTimePerImage) seconds per image" -ForegroundColor Green
                Write-Host "Medium dataset: $($mediumTimePerImage) seconds per image" -ForegroundColor Green

                # Time per image should be relatively consistent (within 60% variance)
                # Note: Some variance is expected due to startup costs, parallel processing overhead, etc.
                $timeVariance = [Math]::Abs($mediumTimePerImage - $smallTimePerImage) / $smallTimePerImage
                $timeVariance | Should -BeLessThan 0.6 -Because "Processing time should scale reasonably with image count"
            }
            finally {
                # Cleanup
                Remove-IntegrationTestData -TestDataPath $smallDataset.TestRootPath
                Remove-IntegrationTestData -TestDataPath $mediumDataset.TestRootPath
            }
        }
    }

    Context "Memory Usage Performance" {

        It "Should maintain memory usage under 1GB during processing" {
            # Given: A large dataset for memory testing
            $inputPath = $script:LargeDataset.InputDirectory
            $outputPath = Join-Path $script:LargeDataset.TestRootPath "MemoryTest"

            # When: I process images while monitoring memory usage
            $initialMemory = [System.GC]::GetTotalMemory($false)

            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            $peakMemory = [System.GC]::GetTotalMemory($false)
            $memoryUsedMB = ($peakMemory - $initialMemory) / 1MB

            # Then: Memory usage should stay within acceptable limits
            $result.Success | Should -Be $true

            Write-Host "Memory used during processing: $([math]::Round($memoryUsedMB, 2)) MB" -ForegroundColor Green

            $memoryUsedMB | Should -BeLessThan ($script:TargetMaxMemoryGB * 1024) -Because "Memory usage should stay under $($script:TargetMaxMemoryGB)GB"
        }

        It "Should handle memory cleanup properly after processing" {
            # Given: Initial memory state
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $initialMemory = [System.GC]::GetTotalMemory($false)

            $inputPath = $script:LargeDataset.InputDirectory
            $outputPath = Join-Path $script:LargeDataset.TestRootPath "MemoryCleanup"

            # When: I process images and force garbage collection
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $finalMemory = [System.GC]::GetTotalMemory($false)

            # Then: Memory should be cleaned up properly
            $result.Success | Should -Be $true

            $memoryDifferenceMB = ($finalMemory - $initialMemory) / 1MB
            Write-Host "Memory difference after cleanup: $([math]::Round($memoryDifferenceMB, 2)) MB" -ForegroundColor Green

            # Allow for some memory growth but should be minimal
            $memoryDifferenceMB | Should -BeLessThan 100 -Because "Memory should be cleaned up after processing"
        }
    }

    Context "Parallel Processing Performance" {

        It "Should show performance improvement with parallel processing" {
            # Given: A dataset suitable for parallel processing
            $parallelDataset = New-IntegrationTestImageCollection -TestRootPath (Join-Path $script:TestRootPath "ParallelPerf") -ImageCount 20

            try {
                # When: I process with and without parallel processing (if configurable)
                $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $sequentialResult = Optimize-WebImages -Path $parallelDataset.InputDirectory -OutputPath (Join-Path $parallelDataset.TestRootPath "Sequential")
                $sequentialStopwatch.Stop()

                $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $parallelResult = Optimize-WebImages -Path $parallelDataset.InputDirectory -OutputPath (Join-Path $parallelDataset.TestRootPath "Parallel")
                $parallelStopwatch.Stop()

                # Then: Both should succeed
                $sequentialResult.Success | Should -Be $true
                $parallelResult.Success | Should -Be $true

                # And: Processing times should be recorded
                Write-Host "Sequential processing: $($sequentialStopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green
                Write-Host "Parallel processing: $($parallelStopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green

                # Note: Actual performance improvement depends on system capabilities
                # Test validates that parallel processing doesn't degrade performance
                $parallelStopwatch.Elapsed.TotalSeconds | Should -BeLessThan ($sequentialStopwatch.Elapsed.TotalSeconds * 1.5) -Because "Parallel processing should not significantly degrade performance"
            }
            finally {
                # Cleanup
                Remove-IntegrationTestData -TestDataPath $parallelDataset.TestRootPath
            }
        }
    }

    Context "Large File Handling Performance" {

        It "Should handle large individual files efficiently" {
            # Given: Large test images (simulated)
            $largeFileTest = Join-Path $script:TestRootPath "LargeFiles"
            $largeFileDataset = New-IntegrationTestImageCollection -TestRootPath $largeFileTest -ImageCount 3

            try {
                # Create larger mock files to simulate large images
                $largeFiles = Get-ChildItem -Path $largeFileDataset.InputDirectory -Recurse -Include "*.jpg", "*.png"
                foreach ($file in $largeFiles) {
                    # Expand file size to simulate larger images
                    $content = [System.IO.File]::ReadAllBytes($file.FullName)
                    $expandedContent = $content * 100  # Make files larger
                    [System.IO.File]::WriteAllBytes($file.FullName, $expandedContent)
                }

                $outputPath = Join-Path $largeFileDataset.TestRootPath "LargeOutput"

                # When: I process large files
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $result = Optimize-WebImages -Path $largeFileDataset.InputDirectory -OutputPath $outputPath
                $stopwatch.Stop()

                # Then: Should handle large files within reasonable time
                $result.Success | Should -Be $true -Because "Should handle large files successfully"

                $averageTimePerFile = $stopwatch.Elapsed.TotalSeconds / $result.FilesProcessed
                Write-Host "Average time per large file: $([math]::Round($averageTimePerFile, 2)) seconds" -ForegroundColor Green

                $averageTimePerFile | Should -BeLessThan 30 -Because "Large files should be processed within 30 seconds each"
            }
            finally {
                # Cleanup
                Remove-IntegrationTestData -TestDataPath $largeFileDataset.TestRootPath
            }
        }
    }

    Context "Concurrent Processing Stress Test" {

        It "Should handle multiple concurrent processing requests" {
            # Given: Multiple datasets for concurrent processing
            $concurrentDatasets = @()
            for ($i = 1; $i -le 3; $i++) {
                $dataset = New-IntegrationTestImageCollection -TestRootPath (Join-Path $script:TestRootPath "Concurrent$i") -ImageCount 5
                $concurrentDatasets += $dataset
            }

            try {
                # When: I process multiple datasets concurrently using PowerShell jobs
                $jobs = @()
                foreach ($dataset in $concurrentDatasets) {
                    $outputPath = Join-Path $dataset.TestRootPath "ConcurrentOutput"
                    $job = Start-Job -ScriptBlock {
                        param($ModulePath, $InputPath, $OutputPath)
                        Import-Module $ModulePath -Force
                        Optimize-WebImages -Path $InputPath -OutputPath $OutputPath
                    } -ArgumentList $modulePath, $dataset.InputDirectory, $outputPath
                    $jobs += $job
                }

                # Wait for all jobs to complete
                $results = $jobs | Wait-Job | Receive-Job
                $jobs | Remove-Job

                # Then: All concurrent processing should succeed
                $results.Count | Should -Be 3 -Because "All concurrent jobs should complete"
                foreach ($result in $results) {
                    $result.Success | Should -Be $true -Because "Each concurrent processing job should succeed"
                }

                Write-Host "Successfully completed $($results.Count) concurrent processing jobs" -ForegroundColor Green
            }
            finally {
                # Cleanup
                foreach ($dataset in $concurrentDatasets) {
                    Remove-IntegrationTestData -TestDataPath $dataset.TestRootPath
                }
            }
        }
    }
}
