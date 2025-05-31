# Write-OptimizationReport Function for WebImageOptimizer
# Generates processing summary reports in multiple output formats
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Generates optimization reports in multiple output formats.

.DESCRIPTION
    Creates comprehensive reports of image optimization processing results
    with support for console display, CSV export, and JSON summary formats.
    Leverages PowerShell 7's enhanced JSON and CSV capabilities for structured output.

.PARAMETER ProcessingResults
    Array of processing result objects containing file processing information.

.PARAMETER OutputFormat
    The format for the report output. Valid values: 'Console', 'CSV', 'JSON'.

.PARAMETER OutputPath
    The file path for CSV or JSON output. Required when OutputFormat is 'CSV' or 'JSON'.

.PARAMETER IncludeDetails
    If specified, includes detailed per-file information in the report.

.OUTPUTS
    [string] For Console format, returns formatted report text.
    [void] For CSV/JSON formats, writes to specified file path.

.EXAMPLE
    $results = @(/* processing results */)
    $report = Write-OptimizationReport -ProcessingResults $results -OutputFormat 'Console'

.EXAMPLE
    Write-OptimizationReport -ProcessingResults $results -OutputFormat 'CSV' -OutputPath 'report.csv'

.EXAMPLE
    Write-OptimizationReport -ProcessingResults $results -OutputFormat 'JSON' -OutputPath 'summary.json'
#>
function Write-OptimizationReport {
    [CmdletBinding()]
    [OutputType([string], [void])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Console', 'CSV', 'JSON')]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        Write-Verbose "Generating optimization report in $OutputFormat format"

        # Validate OutputPath for file formats
        if ($OutputFormat -in @('CSV', 'JSON') -and [string]::IsNullOrEmpty($OutputPath)) {
            throw "OutputPath is required when OutputFormat is '$OutputFormat'"
        }

        # Calculate summary statistics
        $summary = Get-ProcessingSummary -ProcessingResults $ProcessingResults

        switch ($OutputFormat) {
            'Console' {
                return Format-ConsoleReport -Summary $summary -ProcessingResults $ProcessingResults -IncludeDetails:$IncludeDetails
            }
            'CSV' {
                Export-CsvReport -ProcessingResults $ProcessingResults -OutputPath $OutputPath
                Write-Verbose "CSV report exported to: $OutputPath"
            }
            'JSON' {
                Export-JsonReport -Summary $summary -ProcessingResults $ProcessingResults -OutputPath $OutputPath -IncludeDetails:$IncludeDetails
                Write-Verbose "JSON report exported to: $OutputPath"
            }
        }
    }
    catch {
        Write-Error "Failed to generate optimization report: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Calculates summary statistics from processing results.

.DESCRIPTION
    Analyzes processing results to generate comprehensive summary statistics
    including success/failure counts, size reduction metrics, and performance data.

.PARAMETER ProcessingResults
    Array of processing result objects.

.OUTPUTS
    [PSCustomObject] Summary statistics object.
#>
function Get-ProcessingSummary {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults
    )

    $totalFiles = $ProcessingResults.Count
    $successfulResults = $ProcessingResults | Where-Object { $_.Success -eq $true }
    $failedResults = $ProcessingResults | Where-Object { $_.Success -eq $false }

    $successCount = $successfulResults.Count
    $errorCount = $failedResults.Count

    # Calculate size metrics
    $totalOriginalSize = ($ProcessingResults | Measure-Object -Property OriginalSize -Sum).Sum
    $totalOptimizedSize = ($successfulResults | Measure-Object -Property OptimizedSize -Sum).Sum
    $spaceSaved = $totalOriginalSize - $totalOptimizedSize

    $overallCompressionRatio = if ($totalOriginalSize -gt 0) {
        [math]::Round((1 - ($totalOptimizedSize / $totalOriginalSize)) * 100, 2)
    } else { 0.0 }

    # Calculate timing metrics - handle TimeSpan objects properly
    $totalProcessingTimeTicks = ($ProcessingResults | ForEach-Object { $_.ProcessingTime.Ticks } | Measure-Object -Sum).Sum
    $totalProcessingTime = [timespan]::FromTicks($totalProcessingTimeTicks)
    $averageProcessingTime = if ($totalFiles -gt 0) {
        [timespan]::FromTicks($totalProcessingTimeTicks / $totalFiles)
    } else { [timespan]::Zero }

    return [PSCustomObject]@{
        GeneratedAt = Get-Date
        TotalFiles = $totalFiles
        SuccessfullyProcessed = $successCount
        Failed = $errorCount
        SuccessRate = if ($totalFiles -gt 0) { [math]::Round(($successCount / $totalFiles) * 100, 2) } else { 0.0 }
        TotalOriginalSize = $totalOriginalSize
        TotalOptimizedSize = $totalOptimizedSize
        SpaceSaved = $spaceSaved
        CompressionRatio = $overallCompressionRatio
        TotalProcessingTime = $totalProcessingTime
        AverageProcessingTime = $averageProcessingTime
        ProcessingRate = if ($totalProcessingTime.TotalSeconds -gt 0) {
            [math]::Round($totalFiles / $totalProcessingTime.TotalSeconds, 2)
        } else { 0.0 }
    }
}

<#
.SYNOPSIS
    Formats a console report from summary and processing data.

.DESCRIPTION
    Creates a formatted text report suitable for console display
    with summary statistics and optional detailed file information.

.PARAMETER Summary
    Summary statistics object.

.PARAMETER ProcessingResults
    Array of processing result objects.

.PARAMETER IncludeDetails
    If specified, includes detailed per-file information.

.OUTPUTS
    [string] Formatted console report.
#>
function Format-ConsoleReport {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Summary,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    $report = @()
    $report += "=" * 60
    $report += "Web Image Optimization Report"
    $report += "Generated: $(if ($Summary.GeneratedAt) { $Summary.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss') } else { (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') })"
    $report += "=" * 60
    $report += ""
    $report += "SUMMARY STATISTICS"
    $report += "-" * 20
    $report += "Total Files: $($Summary.TotalFiles)"
    $report += "Successfully Processed: $($Summary.SuccessfullyProcessed)"
    $report += "Failed: $($Summary.Failed)"
    $report += "Success Rate: $($Summary.SuccessRate)%"
    $report += ""
    $report += "SIZE REDUCTION"
    $report += "-" * 15
    $report += "Original Size: $([math]::Round($Summary.TotalOriginalSize / 1MB, 2)) MB"
    $report += "Optimized Size: $([math]::Round($Summary.TotalOptimizedSize / 1MB, 2)) MB"
    $report += "Space Saved: $([math]::Round($Summary.SpaceSaved / 1MB, 2)) MB"
    $report += "Compression Ratio: $($Summary.CompressionRatio)%"
    $report += ""
    $report += "PERFORMANCE"
    $report += "-" * 12
    $report += "Total Processing Time: $($Summary.TotalProcessingTime.ToString('hh\:mm\:ss\.fff'))"
    $report += "Average Time per File: $($Summary.AverageProcessingTime.ToString('ss\.fff')) seconds"
    $report += "Processing Rate: $($Summary.ProcessingRate) files/second"

    if ($IncludeDetails.IsPresent) {
        $report += ""
        $report += "DETAILED RESULTS"
        $report += "-" * 16
        foreach ($result in $ProcessingResults) {
            $status = if ($result.Success) { "SUCCESS" } else { "FAILED" }
            $compressionInfo = if ($result.Success) {
                " ($($result.CompressionRatio)% reduction)"
            } else {
                " - $($result.ErrorMessage)"
            }
            $report += "$($result.FileName): $status$compressionInfo"
        }
    }

    $report += ""
    $report += "=" * 60

    return $report -join "`n"
}

<#
.SYNOPSIS
    Exports processing results to CSV format.

.DESCRIPTION
    Creates a CSV file with detailed processing results using PowerShell 7's
    enhanced Export-Csv capabilities.

.PARAMETER ProcessingResults
    Array of processing result objects.

.PARAMETER OutputPath
    Path for the CSV output file.
#>
function Export-CsvReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Prepare data for CSV export
        $csvData = $ProcessingResults | Select-Object @(
            'FileName',
            'Success',
            @{Name='OriginalSizeMB'; Expression={[math]::Round($_.OriginalSize / 1MB, 2)}},
            @{Name='OptimizedSizeMB'; Expression={[math]::Round($_.OptimizedSize / 1MB, 2)}},
            'CompressionRatio',
            @{Name='ProcessingTimeMs'; Expression={$_.ProcessingTime.TotalMilliseconds}},
            'ThreadId',
            @{Name='Timestamp'; Expression={$_.Timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff')}},
            'ErrorMessage'
        )

        # Export to CSV using PowerShell 7 enhancements
        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

        Write-Verbose "CSV report exported successfully to: $OutputPath"
    }
    catch {
        Write-Error "Failed to export CSV report: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Exports processing summary and results to JSON format.

.DESCRIPTION
    Creates a JSON file with comprehensive processing summary and optional
    detailed results using PowerShell 7's enhanced ConvertTo-Json capabilities.

.PARAMETER Summary
    Summary statistics object.

.PARAMETER ProcessingResults
    Array of processing result objects.

.PARAMETER OutputPath
    Path for the JSON output file.

.PARAMETER IncludeDetails
    If specified, includes detailed per-file results in the JSON output.
#>
function Export-JsonReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Summary,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ProcessingResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Prepare JSON structure
        $jsonData = [PSCustomObject]@{
            ReportType = 'WebImageOptimization'
            GeneratedAt = $Summary.GeneratedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Summary = [PSCustomObject]@{
                TotalFiles = $Summary.TotalFiles
                SuccessfullyProcessed = $Summary.SuccessfullyProcessed
                Failed = $Summary.Failed
                SuccessRate = $Summary.SuccessRate
                TotalOriginalSizeMB = [math]::Round($Summary.TotalOriginalSize / 1MB, 2)
                TotalOptimizedSizeMB = [math]::Round($Summary.TotalOptimizedSize / 1MB, 2)
                SpaceSavedMB = [math]::Round($Summary.SpaceSaved / 1MB, 2)
                CompressionRatio = $Summary.CompressionRatio
                TotalProcessingTime = $Summary.TotalProcessingTime.ToString('hh\:mm\:ss\.fff')
                AverageProcessingTimeMs = $Summary.AverageProcessingTime.TotalMilliseconds
                ProcessingRate = $Summary.ProcessingRate
            }
        }

        # Add detailed results if requested
        if ($IncludeDetails.IsPresent) {
            $jsonData | Add-Member -MemberType NoteProperty -Name 'Results' -Value @(
                $ProcessingResults | ForEach-Object {
                    [PSCustomObject]@{
                        FileName = $_.FileName
                        Success = $_.Success
                        OriginalSizeMB = [math]::Round($_.OriginalSize / 1MB, 2)
                        OptimizedSizeMB = [math]::Round($_.OptimizedSize / 1MB, 2)
                        CompressionRatio = $_.CompressionRatio
                        ProcessingTimeMs = $_.ProcessingTime.TotalMilliseconds
                        ThreadId = $_.ThreadId
                        Timestamp = if ($_.Timestamp) { $_.Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') } else { $null }
                        ErrorMessage = $_.ErrorMessage
                    }
                }
            )
        }

        # Export to JSON using PowerShell 7 enhanced depth support
        $jsonData | ConvertTo-Json -Depth 10 -Compress:$false | Set-Content -Path $OutputPath -Encoding UTF8

        Write-Verbose "JSON report exported successfully to: $OutputPath"
    }
    catch {
        Write-Error "Failed to export JSON report: $($_.Exception.Message)"
        throw
    }
}
