# Progress Reporting Test Data Library for WebImageOptimizer
# Provides centralized test data creation for progress reporting and logging functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates test data for progress reporting scenarios.

.DESCRIPTION
    Creates a collection of mock progress data with various completion states
    to test progress reporting functionality including percentage calculations,
    timing metrics, and progress information accuracy.

.PARAMETER TestRootPath
    The root path where test data should be created.

.PARAMETER TotalFiles
    Total number of files to simulate in progress data (default: 10).

.PARAMETER IncludeErrors
    If specified, includes error scenarios in the progress data.

.OUTPUTS
    [PSCustomObject] Information about the created progress test data.

.EXAMPLE
    $progressData = New-ProgressReportingTestData -TestRootPath "C:\temp\test" -TotalFiles 5
#>
function New-ProgressReportingTestData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$TotalFiles = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeErrors
    )

    try {
        # Create test directory
        if (-not (Test-Path $TestRootPath)) {
            New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
        }

        # Create progress data collection
        $progressData = @()
        $startTime = Get-Date

        for ($i = 1; $i -le $TotalFiles; $i++) {
            $currentTime = $startTime.AddSeconds($i * 2) # Simulate 2 seconds per file
            $elapsedTime = $currentTime - $startTime
            $percentComplete = [math]::Round(($i / $TotalFiles) * 100, 2)

            $estimatedTimeRemaining = if ($i -gt 0) {
                $averageTimePerFile = $elapsedTime.TotalSeconds / $i
                $remainingFiles = $TotalFiles - $i
                [timespan]::FromSeconds($averageTimePerFile * $remainingFiles)
            } else {
                [timespan]::Zero
            }

            $processingRate = if ($elapsedTime.TotalSeconds -gt 0) {
                [math]::Round($i / $elapsedTime.TotalSeconds, 2)
            } else {
                0.0
            }

            $progressEntry = [PSCustomObject]@{
                PercentComplete = $percentComplete
                FilesProcessed = $i
                TotalFiles = $TotalFiles
                CurrentFile = "test_image_$i.jpg"
                ElapsedTime = $elapsedTime
                EstimatedTimeRemaining = $estimatedTimeRemaining
                ProcessingRate = $processingRate
                Timestamp = $currentTime
            }

            $progressData += $progressEntry
        }

        return [PSCustomObject]@{
            TestRootPath = $TestRootPath
            ProgressData = $progressData
            TotalFiles = $TotalFiles
            StartTime = $startTime
            EndTime = $startTime.AddSeconds($TotalFiles * 2)
            IncludesErrors = $IncludeErrors.IsPresent
        }
    }
    catch {
        throw "Failed to create progress reporting test data: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Creates test data for logging scenarios with multiple log levels.

.DESCRIPTION
    Creates a collection of mock log entries with different log levels
    (Verbose, Information, Warning, Error) to test logging functionality.

.PARAMETER TestRootPath
    The root path where test data should be created.

.PARAMETER EntryCount
    Number of log entries to create (default: 20).

.OUTPUTS
    [PSCustomObject] Information about the created logging test data.

.EXAMPLE
    $logData = New-LoggingTestData -TestRootPath "C:\temp\test" -EntryCount 15
#>
function New-LoggingTestData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$EntryCount = 20
    )

    try {
        # Create test directory
        if (-not (Test-Path $TestRootPath)) {
            New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
        }

        $logEntries = @()
        $logLevels = @('Verbose', 'Information', 'Warning', 'Error')
        $baseTime = Get-Date

        for ($i = 1; $i -le $EntryCount; $i++) {
            $level = $logLevels[($i - 1) % $logLevels.Count]
            $timestamp = $baseTime.AddSeconds($i * 0.5)

            $message = switch ($level) {
                'Verbose' { "Processing file test_image_$i.jpg with quality setting 85" }
                'Information' { "Successfully optimized test_image_$i.jpg (reduced by 25%)" }
                'Warning' { "File test_image_$i.jpg already optimized, skipping" }
                'Error' { "Failed to process test_image_$i.jpg: Invalid format" }
            }

            $logEntry = [PSCustomObject]@{
                Timestamp = $timestamp
                Level = $level
                Message = $message
                FileName = "test_image_$i.jpg"
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                ProcessId = $PID
            }

            $logEntries += $logEntry
        }

        return [PSCustomObject]@{
            TestRootPath = $TestRootPath
            LogEntries = $logEntries
            EntryCount = $EntryCount
            LogLevels = $logLevels
        }
    }
    catch {
        throw "Failed to create logging test data: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Creates test data for processing results and performance metrics.

.DESCRIPTION
    Creates mock processing results with performance metrics for testing
    report generation functionality including CSV and JSON export.

.PARAMETER TestRootPath
    The root path where test data should be created.

.PARAMETER ResultCount
    Number of processing results to create (default: 15).

.PARAMETER IncludeFailures
    If specified, includes failed processing results.

.OUTPUTS
    [PSCustomObject] Information about the created processing results test data.

.EXAMPLE
    $resultsData = New-ProcessingResultsTestData -TestRootPath "C:\temp\test" -ResultCount 10 -IncludeFailures
#>
function New-ProcessingResultsTestData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$ResultCount = 15,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeFailures
    )

    try {
        # Create test directory
        if (-not (Test-Path $TestRootPath)) {
            New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
        }

        $processingResults = @()
        $baseTime = Get-Date

        for ($i = 1; $i -le $ResultCount; $i++) {
            $isFailure = $IncludeFailures.IsPresent -and ($i % 4 -eq 0) # Every 4th item fails

            $originalSize = Get-Random -Minimum 500000 -Maximum 5000000 # 500KB to 5MB
            $optimizedSize = if ($isFailure) { 0 } else { [int]($originalSize * (Get-Random -Minimum 0.4 -Maximum 0.8)) }
            $compressionRatio = if ($originalSize -gt 0 -and $optimizedSize -gt 0) {
                [math]::Round((1 - ($optimizedSize / $originalSize)) * 100, 2)
            } else { 0.0 }

            $processingTime = [timespan]::FromMilliseconds((Get-Random -Minimum 100 -Maximum 2000))

            $result = [PSCustomObject]@{
                FileName = "test_image_$i.jpg"
                InputPath = Join-Path $TestRootPath "input\test_image_$i.jpg"
                OutputPath = Join-Path $TestRootPath "output\test_image_$i.jpg"
                Success = -not $isFailure
                ProcessingTime = $processingTime
                OriginalSize = $originalSize
                OptimizedSize = $optimizedSize
                CompressionRatio = $compressionRatio
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                Timestamp = $baseTime.AddSeconds($i * 1.5)
                ErrorMessage = if ($isFailure) { "Mock processing error for testing" } else { $null }
            }

            $processingResults += $result
        }

        $successCount = ($processingResults | Where-Object { $_.Success }).Count
        $errorCount = $ResultCount - $successCount
        $totalOriginalSize = ($processingResults | Measure-Object -Property OriginalSize -Sum).Sum
        $totalOptimizedSize = ($processingResults | Where-Object { $_.Success } | Measure-Object -Property OptimizedSize -Sum).Sum
        $overallCompressionRatio = if ($totalOriginalSize -gt 0) {
            [math]::Round((1 - ($totalOptimizedSize / $totalOriginalSize)) * 100, 2)
        } else { 0.0 }

        return [PSCustomObject]@{
            TestRootPath = $TestRootPath
            ProcessingResults = $processingResults
            ResultCount = $ResultCount
            SuccessCount = $successCount
            ErrorCount = $errorCount
            TotalOriginalSize = $totalOriginalSize
            TotalOptimizedSize = $totalOptimizedSize
            OverallCompressionRatio = $overallCompressionRatio
            IncludesFailures = $IncludeFailures.IsPresent
        }
    }
    catch {
        throw "Failed to create processing results test data: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Creates test data for thread-safe logging scenarios.

.DESCRIPTION
    Creates mock data for testing thread-safe logging functionality
    including concurrent log entry creation and thread safety validation.

.PARAMETER TestRootPath
    The root path where test data should be created.

.PARAMETER ThreadCount
    Number of threads to simulate (default: 4).

.PARAMETER EntriesPerThread
    Number of log entries per thread (default: 5).

.OUTPUTS
    [PSCustomObject] Information about the created thread-safe logging test data.

.EXAMPLE
    $threadData = New-ThreadSafeLoggingTestData -TestRootPath "C:\temp\test" -ThreadCount 3 -EntriesPerThread 10
#>
function New-ThreadSafeLoggingTestData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [int]$ThreadCount = 4,

        [Parameter(Mandatory = $false)]
        [int]$EntriesPerThread = 5
    )

    try {
        # Create test directory
        if (-not (Test-Path $TestRootPath)) {
            New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
        }

        $threadData = @()
        $baseTime = Get-Date

        for ($threadId = 1; $threadId -le $ThreadCount; $threadId++) {
            $threadEntries = @()

            for ($entryId = 1; $entryId -le $EntriesPerThread; $entryId++) {
                $timestamp = $baseTime.AddMilliseconds(($threadId * 100) + ($entryId * 50))

                $logEntry = [PSCustomObject]@{
                    ThreadId = $threadId
                    EntryId = $entryId
                    Timestamp = $timestamp
                    Level = 'Information'
                    Message = "Thread $threadId processing entry $entryId"
                    FileName = "thread_${threadId}_file_${entryId}.jpg"
                }

                $threadEntries += $logEntry
            }

            $threadData += [PSCustomObject]@{
                ThreadId = $threadId
                Entries = $threadEntries
                EntryCount = $EntriesPerThread
            }
        }

        return [PSCustomObject]@{
            TestRootPath = $TestRootPath
            ThreadData = $threadData
            ThreadCount = $ThreadCount
            EntriesPerThread = $EntriesPerThread
            TotalEntries = $ThreadCount * $EntriesPerThread
        }
    }
    catch {
        throw "Failed to create thread-safe logging test data: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Creates test data for report export scenarios.

.DESCRIPTION
    Creates mock data for testing report export functionality
    including CSV and JSON format generation with various data structures.

.PARAMETER TestRootPath
    The root path where test data should be created.

.PARAMETER ReportType
    Type of report to create test data for ('Summary', 'Detailed', 'Performance').

.OUTPUTS
    [PSCustomObject] Information about the created report export test data.

.EXAMPLE
    $reportData = New-ReportExportTestData -TestRootPath "C:\temp\test" -ReportType 'Summary'
#>
function New-ReportExportTestData {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Summary', 'Detailed', 'Performance')]
        [string]$ReportType = 'Summary'
    )

    try {
        # Create test directory
        if (-not (Test-Path $TestRootPath)) {
            New-Item -Path $TestRootPath -ItemType Directory -Force | Out-Null
        }

        $reportData = switch ($ReportType) {
            'Summary' {
                [PSCustomObject]@{
                    ReportType = 'Summary'
                    GeneratedAt = Get-Date
                    TotalFiles = 25
                    SuccessfullyProcessed = 22
                    Failed = 3
                    TotalOriginalSize = 125000000  # 125MB
                    TotalOptimizedSize = 87500000  # 87.5MB
                    SpaceSaved = 37500000          # 37.5MB
                    CompressionRatio = 30.0
                    ProcessingTime = [timespan]::FromMinutes(5.5)
                    AverageFileSize = 5000000      # 5MB
                    AverageCompressionRatio = 28.5
                }
            }
            'Detailed' {
                $detailedResults = @()
                for ($i = 1; $i -le 10; $i++) {
                    $detailedResults += [PSCustomObject]@{
                        FileName = "detailed_test_$i.jpg"
                        OriginalSize = Get-Random -Minimum 1000000 -Maximum 10000000
                        OptimizedSize = Get-Random -Minimum 700000 -Maximum 7000000
                        CompressionRatio = Get-Random -Minimum 15.0 -Maximum 45.0
                        ProcessingTime = [timespan]::FromMilliseconds((Get-Random -Minimum 500 -Maximum 3000))
                        Status = if ($i % 8 -eq 0) { 'Failed' } else { 'Success' }
                    }
                }

                [PSCustomObject]@{
                    ReportType = 'Detailed'
                    GeneratedAt = Get-Date
                    Results = $detailedResults
                }
            }
            'Performance' {
                [PSCustomObject]@{
                    ReportType = 'Performance'
                    GeneratedAt = Get-Date
                    TotalProcessingTime = [timespan]::FromMinutes(8.2)
                    FilesPerSecond = 2.5
                    BytesPerSecond = 12500000      # 12.5MB/s
                    ThreadsUsed = 4
                    MemoryUsageMB = 256
                    CPUUsagePercent = 75.5
                    PeakMemoryMB = 312
                    AverageFileProcessingTime = [timespan]::FromMilliseconds(1200)
                }
            }
        }

        return [PSCustomObject]@{
            TestRootPath = $TestRootPath
            ReportType = $ReportType
            ReportData = $reportData
        }
    }
    catch {
        throw "Failed to create report export test data: $($_.Exception.Message)"
    }
}
