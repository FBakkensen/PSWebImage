# Progress Reporting Helper Functions for WebImageOptimizer
# Provides logging, progress tracking, and performance metrics functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Writes log messages with multiple log levels using PowerShell 7 stream handling.

.DESCRIPTION
    Provides structured logging with support for Verbose, Information, Warning, and Error
    levels, leveraging PowerShell 7's improved stream handling capabilities.

.PARAMETER Level
    The log level. Valid values: 'Verbose', 'Information', 'Warning', 'Error'.

.PARAMETER Message
    The log message to write.

.PARAMETER FileName
    Optional filename associated with the log entry.

.PARAMETER Timestamp
    Optional timestamp for the log entry. Defaults to current time.

.OUTPUTS
    [void] Writes to appropriate PowerShell stream based on log level.

.EXAMPLE
    Write-OptimizationLog -Level 'Information' -Message 'Processing completed successfully'

.EXAMPLE
    Write-OptimizationLog -Level 'Error' -Message 'Failed to process file' -FileName 'image.jpg'
#>
function Write-OptimizationLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Verbose', 'Information', 'Warning', 'Error')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [datetime]$Timestamp = (Get-Date)
    )

    # Format the log message with timestamp
    $formattedMessage = "[$($Timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))]"

    if (-not [string]::IsNullOrEmpty($FileName)) {
        $formattedMessage += " [$FileName]"
    }

    $formattedMessage += " $Message"

    # Write to appropriate stream based on level
    switch ($Level) {
        'Verbose' {
            Write-Verbose $formattedMessage
        }
        'Information' {
            Write-Information $formattedMessage -InformationAction Continue
        }
        'Warning' {
            Write-Warning $formattedMessage
        }
        'Error' {
            Write-Error $formattedMessage
        }
    }
}

<#
.SYNOPSIS
    Calculates processing metrics with high-precision timing.

.DESCRIPTION
    Computes performance metrics including processing time, size reduction,
    and compression ratios with high-precision timing capabilities.

.PARAMETER StartTime
    The start time of processing.

.PARAMETER EndTime
    The end time of processing.

.PARAMETER FilesProcessed
    Number of files processed.

.PARAMETER OriginalSize
    Original file size in bytes.

.PARAMETER OptimizedSize
    Optimized file size in bytes.

.OUTPUTS
    [PSCustomObject] Performance metrics object.

.EXAMPLE
    $metrics = Get-ProcessingMetrics -StartTime $start -EndTime $end -FilesProcessed 10

.EXAMPLE
    $metrics = Get-ProcessingMetrics -OriginalSize 1000000 -OptimizedSize 750000
#>
function Get-ProcessingMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,

        [Parameter(Mandatory = $false)]
        [datetime]$EndTime,

        [Parameter(Mandatory = $false)]
        [int]$FilesProcessed = 0,

        [Parameter(Mandatory = $false)]
        [long]$OriginalSize = 0,

        [Parameter(Mandatory = $false)]
        [long]$OptimizedSize = 0
    )

    $metrics = [PSCustomObject]@{
        ProcessingTime = [timespan]::Zero
        FilesProcessed = $FilesProcessed
        ProcessingRate = 0.0
        SizeReduction = 0
        CompressionRatio = 0.0
        OriginalSize = $OriginalSize
        OptimizedSize = $OptimizedSize
    }

    # Calculate timing metrics if times provided
    if ($StartTime -and $EndTime) {
        $metrics.ProcessingTime = $EndTime - $StartTime

        if ($metrics.ProcessingTime.TotalSeconds -gt 0 -and $FilesProcessed -gt 0) {
            $metrics.ProcessingRate = [math]::Round($FilesProcessed / $metrics.ProcessingTime.TotalSeconds, 2)
        }
    }

    # Calculate size metrics if sizes provided
    if ($OriginalSize -gt 0) {
        $metrics.SizeReduction = $OriginalSize - $OptimizedSize

        if ($OptimizedSize -ge 0) {
            $metrics.CompressionRatio = [math]::Round((1 - ($OptimizedSize / $OriginalSize)) * 100, 2)
        }
    }

    return $metrics
}

<#
.SYNOPSIS
    Adds a log entry to a thread-safe collection.

.DESCRIPTION
    Safely adds log entries to a concurrent collection for use in parallel
    processing scenarios, ensuring thread safety.

.PARAMETER LogCollection
    A thread-safe collection (ConcurrentBag) to store log entries.

.PARAMETER LogEntry
    The log entry object to add to the collection.

.OUTPUTS
    [void] Adds entry to the collection.

.EXAMPLE
    $logCollection = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
    Add-ThreadSafeLogEntry -LogCollection $logCollection -LogEntry $logEntry
#>
function Add-ThreadSafeLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]$LogCollection,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$LogEntry
    )

    try {
        # Add timestamp if not present
        if (-not $LogEntry.PSObject.Properties['Timestamp']) {
            $LogEntry | Add-Member -MemberType NoteProperty -Name 'Timestamp' -Value (Get-Date) -Force
        }

        # Add thread ID if not present
        if (-not $LogEntry.PSObject.Properties['ThreadId']) {
            $LogEntry | Add-Member -MemberType NoteProperty -Name 'ThreadId' -Value ([System.Threading.Thread]::CurrentThread.ManagedThreadId) -Force
        }

        # Thread-safe add to collection
        $LogCollection.Add($LogEntry)
    }
    catch {
        Write-Warning "Failed to add log entry to thread-safe collection: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Retrieves and orders log entries from a thread-safe collection.

.DESCRIPTION
    Extracts all log entries from a concurrent collection and orders them
    by timestamp for consistent reporting.

.PARAMETER LogCollection
    A thread-safe collection containing log entries.

.OUTPUTS
    [PSCustomObject[]] Ordered array of log entries.

.EXAMPLE
    $orderedEntries = Get-AggregatedLogEntries -LogCollection $logCollection
#>
function Get-AggregatedLogEntries {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]$LogCollection
    )

    try {
        # Convert to array and sort by timestamp
        $allEntries = @($LogCollection.ToArray())

        if ($allEntries.Count -gt 0) {
            return $allEntries | Sort-Object Timestamp
        }

        return @()
    }
    catch {
        Write-Warning "Failed to aggregate log entries: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Displays real-time progress using Write-Progress enhancements.

.DESCRIPTION
    Shows processing progress with percentage completion using PowerShell 7's
    enhanced Write-Progress capabilities.

.PARAMETER ProgressInfo
    Progress information object containing completion data.

.PARAMETER Activity
    The activity description for the progress bar.

.OUTPUTS
    [void] Displays progress bar.

.EXAMPLE
    Show-ProcessingProgress -ProgressInfo $progressInfo -Activity 'Optimizing Images'
#>
function Show-ProcessingProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ProgressInfo,

        [Parameter(Mandatory = $false)]
        [string]$Activity = 'Processing Images'
    )

    try {
        $status = "Processing $($ProgressInfo.CurrentFile) ($($ProgressInfo.FilesProcessed)/$($ProgressInfo.TotalFiles))"

        $currentOperation = if ($ProgressInfo.ProcessingRate -gt 0) {
            "Rate: $($ProgressInfo.ProcessingRate) files/sec | ETA: $($ProgressInfo.EstimatedTimeRemaining.ToString('mm\:ss'))"
        } else {
            "Elapsed: $($ProgressInfo.ElapsedTime.ToString('mm\:ss'))"
        }

        Write-Progress -Activity $Activity -Status $status -PercentComplete $ProgressInfo.PercentComplete -CurrentOperation $currentOperation
    }
    catch {
        Write-Warning "Failed to display progress: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Tests if progress should be updated based on frequency threshold.

.DESCRIPTION
    Determines if a progress update should occur based on the completion
    percentage and update threshold (e.g., every 5%).

.PARAMETER PercentComplete
    Current completion percentage.

.PARAMETER UpdateThreshold
    Threshold percentage for updates (default: 5.0).

.OUTPUTS
    [bool] True if progress should be updated.

.EXAMPLE
    $shouldUpdate = Test-ProgressUpdateFrequency -PercentComplete 25.0 -UpdateThreshold 5.0
#>
function Test-ProgressUpdateFrequency {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [double]$PercentComplete,

        [Parameter(Mandatory = $false)]
        [double]$UpdateThreshold = 5.0
    )

    # Update at threshold intervals or at 100% completion
    return ($PercentComplete % $UpdateThreshold -eq 0) -or ($PercentComplete -eq 100.0)
}

<#
.SYNOPSIS
    Extracts processing errors from results with detailed error information.

.DESCRIPTION
    Filters processing results to extract only failed operations and
    formats them with detailed error information for reporting.

.PARAMETER ProcessingResults
    Array of processing result objects.

.OUTPUTS
    [PSCustomObject[]] Array of error objects with detailed information.

.EXAMPLE
    $errors = Get-ProcessingErrors -ProcessingResults $results
#>
function Get-ProcessingErrors {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults
    )

    try {
        $errors = $ProcessingResults | Where-Object { $_.Success -eq $false } | ForEach-Object {
            [PSCustomObject]@{
                FileName = $_.FileName
                ErrorMessage = $_.ErrorMessage
                Timestamp = if ($_.Timestamp) { $_.Timestamp } else { Get-Date }
                InputPath = $_.InputPath
                ThreadId = $_.ThreadId
                ProcessingTime = $_.ProcessingTime
            }
        }

        return $errors
    }
    catch {
        Write-Warning "Failed to extract processing errors: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Generates an error summary report with categorized failures.

.DESCRIPTION
    Creates a formatted error summary report that categorizes and
    summarizes processing failures for easy analysis.

.PARAMETER ProcessingResults
    Array of processing result objects.

.OUTPUTS
    [string] Formatted error summary report.

.EXAMPLE
    $errorReport = Write-ErrorSummaryReport -ProcessingResults $results
#>
function Write-ErrorSummaryReport {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults
    )

    try {
        $errors = Get-ProcessingErrors -ProcessingResults $ProcessingResults
        $totalErrors = $errors.Count

        if ($totalErrors -eq 0) {
            return "Error Summary: No processing errors occurred."
        }

        $report = @()
        $report += "=" * 40
        $report += "Error Summary Report"
        $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $report += "=" * 40
        $report += ""
        $report += "Total Errors: $totalErrors"
        $report += ""
        $report += "FAILED FILES"
        $report += "-" * 12

        foreach ($error in $errors) {
            $report += "$($error.FileName): $($error.ErrorMessage)"
        }

        $report += ""
        $report += "=" * 40

        return $report -join "`n"
    }
    catch {
        Write-Error "Failed to generate error summary report: $($_.Exception.Message)"
        return "Error Summary: Failed to generate report."
    }
}
