# Test suite for WebImageOptimizer Progress Reporting and Logging Implementation (Task 9)
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "WebImageOptimizer Progress Reporting and Logging Implementation" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:TestDataLibraryPath = Join-Path $script:ModuleRoot "Tests\TestDataLibraries\ProgressReporting.TestDataLibrary.ps1"

        # Progress reporting implementation paths
        $script:WriteOptimizationReportPath = Join-Path $script:PrivatePath "Write-OptimizationReport.ps1"
        $script:ProgressReportingHelpersPath = Join-Path $script:PrivatePath "ProgressReportingHelpers.ps1"

        # Import the test data library
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        }

        # Import existing dependencies
        $script:ConfigurationPath = Join-Path $script:PrivatePath "ConfigurationManager.ps1"
        if (Test-Path $script:ConfigurationPath) {
            . $script:ConfigurationPath
        }

        # Import progress reporting functions if they exist
        if (Test-Path $script:WriteOptimizationReportPath) {
            . $script:WriteOptimizationReportPath
        }

        if (Test-Path $script:ProgressReportingHelpersPath) {
            . $script:ProgressReportingHelpersPath
        }

        # Set up test root directory
        $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_ProgressReporting_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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

    Context "Given PowerShell 7 enhanced progress reporting capabilities are available" {

        BeforeAll {
            # Verify PowerShell 7 features are available
            $script:PowerShell7Available = $PSVersionTable.PSVersion.Major -ge 7
            $script:WriteProgressSupported = Get-Command Write-Progress -ErrorAction SilentlyContinue
        }

        It "Should have PowerShell 7 or higher available" {
            $script:PowerShell7Available | Should -Be $true
        }

        It "Should have Write-Progress cmdlet available" {
            $script:WriteProgressSupported | Should -Not -BeNullOrEmpty
        }
    }

    Context "When generating optimization reports with multiple output formats" {

        BeforeAll {
            # Create test data for report generation
            $script:ReportTestPath = Join-Path $script:TestRoot "ReportGeneration"
            if (Get-Command New-ProcessingResultsTestData -ErrorAction SilentlyContinue) {
                $script:ReportTestData = New-ProcessingResultsTestData -TestRootPath $script:ReportTestPath -ResultCount 10 -IncludeFailures
            }
        }

        It "Should generate console summary report with processing statistics" {
            # Given: Processing results with success and failure data
            # When: Write-OptimizationReport is called with Console format
            # Then: A formatted console report should be generated with key statistics

            if (Get-Command Write-OptimizationReport -ErrorAction SilentlyContinue -and $script:ReportTestData) {
                $report = Write-OptimizationReport -ProcessingResults $script:ReportTestData.ProcessingResults -OutputFormat 'Console'

                $report | Should -Not -BeNullOrEmpty
                $report | Should -Match "Total Files"
                $report | Should -Match "Successfully Processed"
                $report | Should -Match "Failed"
                $report | Should -Match "Compression Ratio"
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationReport function not yet implemented or test data not available"
            }
        }

        It "Should export CSV report with structured processing data" {
            # Given: Processing results with detailed file information
            # When: Write-OptimizationReport is called with CSV format
            # Then: A CSV file should be created with structured data

            if (Get-Command Write-OptimizationReport -ErrorAction SilentlyContinue -and $script:ReportTestData) {
                $csvPath = Join-Path $script:ReportTestPath "processing_report.csv"

                Write-OptimizationReport -ProcessingResults $script:ReportTestData.ProcessingResults -OutputFormat 'CSV' -OutputPath $csvPath

                Test-Path $csvPath | Should -Be $true
                $csvContent = Import-Csv $csvPath
                $csvContent | Should -Not -BeNullOrEmpty
                $csvContent.Count | Should -Be $script:ReportTestData.ProcessingResults.Count

                # Verify CSV structure
                $csvContent[0].PSObject.Properties.Name | Should -Contain 'FileName'
                $csvContent[0].PSObject.Properties.Name | Should -Contain 'Success'
                $csvContent[0].PSObject.Properties.Name | Should -Contain 'OriginalSizeMB'
                $csvContent[0].PSObject.Properties.Name | Should -Contain 'OptimizedSizeMB'
                $csvContent[0].PSObject.Properties.Name | Should -Contain 'CompressionRatio'
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationReport function not yet implemented or test data not available"
            }
        }

        It "Should export JSON summary with machine-readable processing results" {
            # Given: Processing results with performance metrics
            # When: Write-OptimizationReport is called with JSON format
            # Then: A JSON file should be created with comprehensive summary data

            if (Get-Command Write-OptimizationReport -ErrorAction SilentlyContinue -and $script:ReportTestData) {
                $jsonPath = Join-Path $script:ReportTestPath "processing_summary.json"

                Write-OptimizationReport -ProcessingResults $script:ReportTestData.ProcessingResults -OutputFormat 'JSON' -OutputPath $jsonPath -IncludeDetails

                Test-Path $jsonPath | Should -Be $true
                $jsonContent = Get-Content $jsonPath -Raw | ConvertFrom-Json
                $jsonContent | Should -Not -BeNullOrEmpty

                # Verify JSON structure
                $jsonContent.PSObject.Properties.Name | Should -Contain 'Summary'
                $jsonContent.PSObject.Properties.Name | Should -Contain 'Results'
                $jsonContent.Summary.TotalFiles | Should -Be $script:ReportTestData.ProcessingResults.Count
                $jsonContent.Summary.SuccessfullyProcessed | Should -BeGreaterOrEqual 0
                $jsonContent.Summary.Failed | Should -BeGreaterOrEqual 0
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationReport function not yet implemented or test data not available"
            }
        }
    }

    Context "When implementing multiple log levels with PowerShell 7 stream handling" {

        BeforeAll {
            # Create test data for logging scenarios
            $script:LoggingTestPath = Join-Path $script:TestRoot "Logging"
            if (Get-Command New-LoggingTestData -ErrorAction SilentlyContinue) {
                $script:LoggingTestData = New-LoggingTestData -TestRootPath $script:LoggingTestPath -EntryCount 12
            }
        }

        It "Should support Verbose log level with detailed processing information" {
            # Given: Detailed processing information for each file
            # When: Write-OptimizationLog is called with Verbose level
            # Then: Verbose messages should be written to the verbose stream

            if (Get-Command Write-OptimizationLog -ErrorAction SilentlyContinue) {
                $verboseMessages = @()
                $null = Write-OptimizationLog -Level 'Verbose' -Message 'Processing file test.jpg with quality 85' -FileName 'test.jpg' -Verbose 4>&1 | ForEach-Object { $verboseMessages += $_ }

                $verboseMessages | Should -Not -BeNullOrEmpty
                $verboseMessages[0] | Should -Match 'Processing file test.jpg'
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationLog function not yet implemented"
            }
        }

        It "Should support Information log level with summary statistics" {
            # Given: Summary statistics and important milestones
            # When: Write-OptimizationLog is called with Information level
            # Then: Information messages should be written to the information stream

            if (Get-Command Write-OptimizationLog -ErrorAction SilentlyContinue) {
                $infoMessages = @()
                $null = Write-OptimizationLog -Level 'Information' -Message 'Successfully optimized 10 files' 6>&1 | ForEach-Object { $infoMessages += $_ }

                $infoMessages | Should -Not -BeNullOrEmpty
                $infoMessages[0] | Should -Match 'Successfully optimized'
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationLog function not yet implemented"
            }
        }

        It "Should support Warning log level for non-critical issues" {
            # Given: Non-critical issues and suboptimal conditions
            # When: Write-OptimizationLog is called with Warning level
            # Then: Warning messages should be written to the warning stream

            if (Get-Command Write-OptimizationLog -ErrorAction SilentlyContinue) {
                $warningMessages = @()
                $null = Write-OptimizationLog -Level 'Warning' -Message 'File already optimized, skipping' -FileName 'test.jpg' 3>&1 | ForEach-Object { $warningMessages += $_ }

                $warningMessages | Should -Not -BeNullOrEmpty
                $warningMessages[0] | Should -Match 'already optimized'
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationLog function not yet implemented"
            }
        }

        It "Should support Error log level for processing failures" {
            # Given: Processing failures and critical issues
            # When: Write-OptimizationLog is called with Error level
            # Then: Error messages should be written to the error stream

            if (Get-Command Write-OptimizationLog -ErrorAction SilentlyContinue) {
                $errorMessages = @()
                $null = Write-OptimizationLog -Level 'Error' -Message 'Failed to process file: Invalid format' -FileName 'test.jpg' 2>&1 | ForEach-Object { $errorMessages += $_ }

                $errorMessages | Should -Not -BeNullOrEmpty
                $errorMessages[0] | Should -Match 'Failed to process'
            } else {
                Set-ItResult -Pending -Because "Write-OptimizationLog function not yet implemented"
            }
        }
    }

    Context "When tracking performance metrics with high-precision timing" {

        BeforeAll {
            # Create test data for performance metrics
            $script:PerformanceTestPath = Join-Path $script:TestRoot "Performance"
            if (Get-Command New-ReportExportTestData -ErrorAction SilentlyContinue) {
                $script:PerformanceTestData = New-ReportExportTestData -TestRootPath $script:PerformanceTestPath -ReportType 'Performance'
            }
        }

        It "Should track processing time with high precision" {
            # Given: Image processing operations with timing requirements
            # When: Performance metrics are collected
            # Then: Processing time should be tracked with millisecond precision

            if (Get-Command Get-ProcessingMetrics -ErrorAction SilentlyContinue -and $script:PerformanceTestData) {
                $startTime = Get-Date
                Start-Sleep -Milliseconds 100
                $endTime = Get-Date

                $metrics = Get-ProcessingMetrics -StartTime $startTime -EndTime $endTime -FilesProcessed 5

                $metrics.ProcessingTime | Should -BeOfType [timespan]
                $metrics.ProcessingTime.TotalMilliseconds | Should -BeGreaterThan 90
                $metrics.ProcessingTime.TotalMilliseconds | Should -BeLessThan 200
            } else {
                Set-ItResult -Pending -Because "Get-ProcessingMetrics function not yet implemented or test data not available"
            }
        }

        It "Should calculate size reduction and compression ratios" {
            # Given: Original and optimized file sizes
            # When: Performance metrics are calculated
            # Then: Size reduction and compression ratios should be accurate

            if (Get-Command Get-ProcessingMetrics -ErrorAction SilentlyContinue) {
                $originalSize = 1000000  # 1MB
                $optimizedSize = 750000  # 750KB

                $metrics = Get-ProcessingMetrics -OriginalSize $originalSize -OptimizedSize $optimizedSize

                $metrics.SizeReduction | Should -Be 250000
                $metrics.CompressionRatio | Should -Be 25.0
            } else {
                Set-ItResult -Pending -Because "Get-ProcessingMetrics function not yet implemented"
            }
        }
    }

    Context "When implementing thread-safe logging for parallel processing scenarios" {

        BeforeAll {
            # Create test data for thread-safe logging
            $script:ThreadSafeTestPath = Join-Path $script:TestRoot "ThreadSafe"
            if (Get-Command New-ThreadSafeLoggingTestData -ErrorAction SilentlyContinue) {
                $script:ThreadSafeTestData = New-ThreadSafeLoggingTestData -TestRootPath $script:ThreadSafeTestPath -ThreadCount 3 -EntriesPerThread 5
            }
        }

        It "Should maintain thread safety during concurrent log entry creation" {
            # Given: Multiple threads writing log entries simultaneously
            # When: Add-ThreadSafeLogEntry is called from multiple threads
            # Then: All log entries should be captured without data corruption

            if (Get-Command Add-ThreadSafeLogEntry -ErrorAction SilentlyContinue -and $script:ThreadSafeTestData) {
                $logCollection = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

                # Import the helper functions for parallel context
                $helpersPath = $script:ProgressReportingHelpersPath

                # Simulate concurrent logging from multiple threads
                $script:ThreadSafeTestData.ThreadData | ForEach-Object -Parallel {
                    $threadData = $_
                    $logCollection = $using:logCollection
                    $helpersPath = $using:helpersPath

                    # Import functions in parallel context
                    if (Test-Path $helpersPath) {
                        . $helpersPath
                    }

                    foreach ($entry in $threadData.Entries) {
                        Add-ThreadSafeLogEntry -LogCollection $logCollection -LogEntry $entry
                    }
                } -ThrottleLimit 3

                $allEntries = @($logCollection.ToArray())
                $allEntries.Count | Should -Be $script:ThreadSafeTestData.TotalEntries

                # Verify no entries were lost or corrupted
                $uniqueEntries = $allEntries | Group-Object -Property ThreadId, EntryId
                $uniqueEntries.Count | Should -Be $script:ThreadSafeTestData.TotalEntries
            } else {
                Set-ItResult -Pending -Because "Add-ThreadSafeLogEntry function not yet implemented or test data not available"
            }
        }

        It "Should aggregate log entries from multiple threads correctly" {
            # Given: Log entries from multiple parallel processing threads
            # When: Log entries are aggregated for reporting
            # Then: All entries should be properly collected and ordered

            if (Get-Command Get-AggregatedLogEntries -ErrorAction SilentlyContinue -and $script:ThreadSafeTestData) {
                $logCollection = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

                # Add test entries to collection
                foreach ($threadData in $script:ThreadSafeTestData.ThreadData) {
                    foreach ($entry in $threadData.Entries) {
                        $logCollection.Add($entry)
                    }
                }

                $aggregatedEntries = Get-AggregatedLogEntries -LogCollection $logCollection

                $aggregatedEntries | Should -Not -BeNullOrEmpty
                $aggregatedEntries.Count | Should -Be $script:ThreadSafeTestData.TotalEntries

                # Verify entries are properly ordered by timestamp
                $orderedEntries = $aggregatedEntries | Sort-Object Timestamp
                $orderedEntries[0].Timestamp | Should -BeLessOrEqual $orderedEntries[-1].Timestamp
            } else {
                Set-ItResult -Pending -Because "Get-AggregatedLogEntries function not yet implemented or test data not available"
            }
        }
    }

    Context "When implementing real-time progress reporting with Write-Progress enhancements" {

        BeforeAll {
            # Create test data for progress reporting
            $script:ProgressTestPath = Join-Path $script:TestRoot "Progress"
            if (Get-Command New-ProgressReportingTestData -ErrorAction SilentlyContinue) {
                $script:ProgressTestData = New-ProgressReportingTestData -TestRootPath $script:ProgressTestPath -TotalFiles 8
            }
        }

        It "Should display real-time progress with percentage completion" {
            # Given: A collection of files being processed
            # When: Show-ProcessingProgress is called with progress data
            # Then: Write-Progress should be called with accurate percentage and status

            if (Get-Command Show-ProcessingProgress -ErrorAction SilentlyContinue -and $script:ProgressTestData) {
                $progressInfo = $script:ProgressTestData.ProgressData[3] # 50% complete

                # Test that the function executes without error
                { Show-ProcessingProgress -ProgressInfo $progressInfo } | Should -Not -Throw

                # Verify the progress info has the expected properties
                $progressInfo.PercentComplete | Should -BeOfType [double]
                $progressInfo.CurrentFile | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Show-ProcessingProgress function not yet implemented or test data not available"
            }
        }

        It "Should update progress every 5% of completion as per PRD requirements" {
            # Given: Progress reporting frequency requirements (every 5%)
            # When: Progress updates are generated
            # Then: Updates should occur at 5% intervals

            if (Get-Command Test-ProgressUpdateFrequency -ErrorAction SilentlyContinue -and $script:ProgressTestData) {
                $totalFiles = 20
                $updateThreshold = 5.0

                $shouldUpdate = @()
                for ($i = 1; $i -le $totalFiles; $i++) {
                    $percentComplete = ($i / $totalFiles) * 100
                    $shouldUpdate += Test-ProgressUpdateFrequency -PercentComplete $percentComplete -UpdateThreshold $updateThreshold
                }

                $updateCount = ($shouldUpdate | Where-Object { $_ -eq $true }).Count
                $updateCount | Should -BeGreaterOrEqual 4  # At least 20%, 40%, 60%, 80%, 100%
            } else {
                Set-ItResult -Pending -Because "Test-ProgressUpdateFrequency function not yet implemented or test data not available"
            }
        }
    }

    Context "When implementing error aggregation and reporting with PowerShell 7 enhanced error records" {

        BeforeAll {
            # Create test data with error scenarios
            $script:ErrorTestPath = Join-Path $script:TestRoot "Errors"
            if (Get-Command New-ProcessingResultsTestData -ErrorAction SilentlyContinue) {
                $script:ErrorTestData = New-ProcessingResultsTestData -TestRootPath $script:ErrorTestPath -ResultCount 12 -IncludeFailures
            }
        }

        It "Should aggregate processing errors with detailed error information" {
            # Given: Processing results containing both successes and failures
            # When: Get-ProcessingErrors is called
            # Then: All errors should be collected with detailed information

            if (Get-Command Get-ProcessingErrors -ErrorAction SilentlyContinue -and $script:ErrorTestData) {
                $errors = Get-ProcessingErrors -ProcessingResults $script:ErrorTestData.ProcessingResults

                $errors | Should -Not -BeNullOrEmpty
                $errors.Count | Should -Be $script:ErrorTestData.ErrorCount

                # Verify error structure
                $errors | ForEach-Object {
                    $_.FileName | Should -Not -BeNullOrEmpty
                    $_.ErrorMessage | Should -Not -BeNullOrEmpty
                    $_.Timestamp | Should -BeOfType [datetime]
                }
            } else {
                Set-ItResult -Pending -Because "Get-ProcessingErrors function not yet implemented or test data not available"
            }
        }

        It "Should generate error summary report with categorized failures" {
            # Given: Various types of processing errors
            # When: Write-ErrorSummaryReport is called
            # Then: Errors should be categorized and summarized

            if (Get-Command Write-ErrorSummaryReport -ErrorAction SilentlyContinue -and $script:ErrorTestData) {
                $errorSummary = Write-ErrorSummaryReport -ProcessingResults $script:ErrorTestData.ProcessingResults

                $errorSummary | Should -Not -BeNullOrEmpty
                $errorSummary | Should -Match "Error Summary"
                $errorSummary | Should -Match "Total Errors"
                $errorSummary | Should -Match $script:ErrorTestData.ErrorCount
            } else {
                Set-ItResult -Pending -Because "Write-ErrorSummaryReport function not yet implemented or test data not available"
            }
        }
    }
}
