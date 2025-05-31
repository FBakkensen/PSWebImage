# Parallel Image Processing Engine for WebImageOptimizer
# Implements multi-threaded image processing using PowerShell 7's ForEach-Object -Parallel
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Processes multiple images in parallel using PowerShell 7's ForEach-Object -Parallel.

.DESCRIPTION
    Implements parallel image processing with configurable thread count, thread-safe progress reporting,
    error handling across parallel threads, and memory management for large batches. Leverages
    PowerShell 7's native parallel processing capabilities for improved performance.

.PARAMETER ImageFiles
    Array of image file objects to process. Each object should have FullName, Name, and Extension properties.

.PARAMETER OutputPath
    The directory path where optimized images should be saved.

.PARAMETER Settings
    Hashtable containing optimization settings for different image formats.

.PARAMETER ThrottleLimit
    Maximum number of parallel threads to use (default: 4).

.PARAMETER ProcessingEngine
    The image processing engine to use (ImageMagick, DotNet, Auto).

.PARAMETER ProgressCallback
    Optional scriptblock for progress reporting. The callback receives a PSCustomObject with:
    - PercentComplete: Progress percentage (0-100)
    - FilesProcessed: Number of files completed
    - TotalFiles: Total number of files to process
    - CurrentFile: Name of the file just processed
    - ElapsedTime: Time elapsed since processing started
    - EstimatedTimeRemaining: Estimated time to completion
    - ProcessingRate: Files processed per second

.OUTPUTS
    [PSCustomObject] Processing results including success/error counts, timing, and error details.

.EXAMPLE
    $imageFiles = Get-ChildItem "*.jpg" | Select-Object FullName, Name, Extension
    $result = Invoke-ParallelImageProcessing -ImageFiles $imageFiles -OutputPath "C:\output"

.EXAMPLE
    $result = Invoke-ParallelImageProcessing -ImageFiles $files -OutputPath "C:\output" -ThrottleLimit 2

.EXAMPLE
    # Using progress callback with Write-Progress
    $progressCallback = {
        param($progress)
        Write-Progress -Activity "Processing Images" -Status "$($progress.CurrentFile)" -PercentComplete $progress.PercentComplete
    }
    $result = Invoke-ParallelImageProcessing -ImageFiles $files -OutputPath "C:\output" -ProgressCallback $progressCallback
#>
function Invoke-ParallelImageProcessing {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$ImageFiles,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Settings = @{},

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 4,

        [Parameter(Mandatory = $false)]
        [ValidateSet("ImageMagick", "DotNet", "Auto")]
        [string]$ProcessingEngine = "Auto",

        [Parameter(Mandatory = $false)]
        [scriptblock]$ProgressCallback,

        [Parameter(Mandatory = $false)]
        [switch]$TestMode
    )

    # Validate PowerShell 7 support
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "Parallel processing requires PowerShell 7.0 or higher. Current version: $($PSVersionTable.PSVersion)"
    }

    # Validate ForEach-Object -Parallel support
    $parallelSupport = Get-Command ForEach-Object | Where-Object { $_.Parameters.ContainsKey('Parallel') }
    if (-not $parallelSupport) {
        throw "ForEach-Object -Parallel is not available in this PowerShell version"
    }

    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Initialize result tracking with thread-safe collections
    $startTime = Get-Date
    $totalFiles = $ImageFiles.Count
    $errors = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
    $results = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

    # Thread-safe progress tracking
    $processedCount = [ref]0

    # For parallel processing, we'll track progress outside the parallel context
    # and call the progress callback from the main thread
    if ($ProgressCallback) {
        Write-Verbose "Creating progress tracker for callback"
        $progressTracker = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()
        Write-Verbose "Progress tracker created: $($progressTracker -ne $null)"
    } else {
        Write-Verbose "No progress callback provided"
        $progressTracker = $null
    }

    # Memory tracking
    $memoryBefore = [System.GC]::GetTotalMemory($false)

    Write-Verbose "Starting parallel processing of $totalFiles images with ThrottleLimit: $ThrottleLimit"

    # Calculate the private path before entering parallel context for reliability
    $privatePath = $PSScriptRoot

    # Import helper functions for parallel processing
    $helpersPath = Join-Path $privatePath "ParallelProcessingHelpers.ps1"
    if (Test-Path $helpersPath) {
        . $helpersPath
    } else {
        throw "ParallelProcessingHelpers.ps1 not found at: $helpersPath"
    }

    try {
        # Process images in parallel using PowerShell 7's ForEach-Object -Parallel
        $ImageFiles | ForEach-Object -Parallel {
            # Import required functions in parallel context using helper
            $privatePath = $using:privatePath

            # Import helper functions
            $helpersPath = Join-Path $privatePath "ParallelProcessingHelpers.ps1"
            if (Test-Path $helpersPath) {
                . $helpersPath
            }

            # Initialize parallel processing context
            $initResult = Initialize-ParallelProcessingContext -PrivatePath $privatePath
            if (-not $initResult.Success) {
                Write-Warning "Failed to initialize parallel context: $($initResult.ErrorMessage)"
            }

            # Ensure ValidationHelpers is available for our helper functions
            $validationHelpersPath = Join-Path $privatePath "ValidationHelpers.ps1"
            if (Test-Path $validationHelpersPath) {
                . $validationHelpersPath
            }

            # Get parameters from parent scope
            $outputPath = $using:OutputPath
            $settings = $using:Settings
            $processingEngine = $using:ProcessingEngine
            $testMode = $using:TestMode
            $errors = $using:errors
            $results = $using:results
            $progressTracker = $using:progressTracker
            $processedCount = $using:processedCount
            $totalFiles = $using:totalFiles
            $startTime = $using:startTime

            # Current file being processed
            $currentFile = $_
            $fileName = $currentFile.Name
            $outputFilePath = Join-Path $outputPath $fileName

            try {
                Write-Verbose "Processing $fileName in parallel thread"

                # Process the file using helper function
                $result = Invoke-SingleFileProcessing -FileInfo $currentFile -OutputPath $outputFilePath -Settings $settings -ProcessingEngine $processingEngine -TestMode $testMode

                # Add error to collection if processing failed
                if (-not $result.Success) {
                    $errorObj = [PSCustomObject]@{
                        FileName = $fileName
                        ErrorMessage = "Processing failed"
                        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    }
                    $errors.Add($errorObj)
                }

                # Always add the result to the collection
                $results.Add($result)

                # Track progress if callback is provided
                if ($progressTracker) {
                    $currentProcessed = [System.Threading.Interlocked]::Increment($processedCount)
                    $progressInfo = Update-ProcessingProgress -ProcessedCount $currentProcessed -TotalFiles $totalFiles -CurrentFileName $fileName -StartTime $startTime
                    $progressTracker.Add($progressInfo)
                }
            }
            catch {
                # Handle errors in parallel context
                $errorObj = [PSCustomObject]@{
                    FileName = $fileName
                    ErrorMessage = $_.Exception.Message
                    ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                }
                $errors.Add($errorObj)

                Write-Verbose "Error processing $fileName : $($_.Exception.Message)"

                # Track progress even for errors
                if ($progressTracker) {
                    $currentProcessed = [System.Threading.Interlocked]::Increment($processedCount)
                    $progressInfo = Update-ProcessingProgress -ProcessedCount $currentProcessed -TotalFiles $totalFiles -CurrentFileName $fileName -StartTime $startTime
                    $progressTracker.Add($progressInfo)
                }
            }
        } -ThrottleLimit $ThrottleLimit

        # Process progress callbacks if provided
        $progressTrackerType = if ($progressTracker) { $progressTracker.GetType().Name } else { "null" }
        Write-Verbose "Checking progress callback: ProgressCallback=$($null -ne $ProgressCallback), progressTracker=$($null -ne $progressTracker), progressTracker type=$progressTrackerType"
        if ($ProgressCallback -and ($null -ne $progressTracker)) {
            Write-Verbose "Progress callback provided, processing queue..."
            $progressItems = @($progressTracker.ToArray())

            Write-Verbose "Processing $($progressItems.Count) progress updates"

            # Sort by FilesProcessed and call callback for each progress update
            $progressItems | Sort-Object FilesProcessed | ForEach-Object {
                try {
                    & $ProgressCallback $_
                }
                catch {
                    Write-Verbose "Progress callback error: $($_.Exception.Message)"
                }
            }
        }

        # Calculate final statistics
        $endTime = Get-Date
        $totalProcessingTime = $endTime - $startTime
        $memoryAfter = [System.GC]::GetTotalMemory($false)
        $memoryUsed = [Math]::Round(($memoryAfter - $memoryBefore) / 1MB, 2)

        # Convert concurrent collections to arrays for final result
        $finalResults = @($results.ToArray())
        $finalErrors = @($errors.ToArray())

        $successCount = ($finalResults | Where-Object { $_.Success }).Count
        $errorCount = $finalErrors.Count
        $totalProcessed = $finalResults.Count

        # Determine unique threads used
        $threadsUsed = ($finalResults | Select-Object -ExpandProperty ThreadId -Unique).Count

        # Create final result object
        $result = [PSCustomObject]@{
            TotalProcessed = $totalProcessed
            SuccessCount = $successCount
            ErrorCount = $errorCount
            ProcessingMethod = "Parallel"
            ThrottleLimitUsed = $ThrottleLimit
            ThreadsUsed = $threadsUsed
            ParallelExecutionTime = $totalProcessingTime
            MemoryUsageMB = $memoryUsed
            Results = $finalResults
            Errors = $finalErrors
            AverageProcessingTimePerImage = if ($totalProcessed -gt 0) {
                [timespan]::FromMilliseconds($totalProcessingTime.TotalMilliseconds / $totalProcessed)
            } else {
                [timespan]::Zero
            }
        }

        Write-Verbose "Parallel processing completed: $successCount successful, $errorCount errors, $threadsUsed threads used"
        return $result
    }
    catch {
        Write-Error "Parallel processing failed: $($_.Exception.Message)"

        # Return error result
        return [PSCustomObject]@{
            TotalProcessed = 0
            SuccessCount = 0
            ErrorCount = $totalFiles
            ProcessingMethod = "Parallel"
            ThrottleLimitUsed = $ThrottleLimit
            ThreadsUsed = 0
            ParallelExecutionTime = [timespan]::Zero
            MemoryUsageMB = 0
            Results = @()
            Errors = @([PSCustomObject]@{
                FileName = "PARALLEL_PROCESSING_ERROR"
                ErrorMessage = $_.Exception.Message
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            })
            AverageProcessingTimePerImage = [timespan]::Zero
        }
    }
    finally {
        # Force garbage collection to clean up parallel processing resources
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}
