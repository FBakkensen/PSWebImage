# Performance Benchmarking Engine for WebImageOptimizer
# Implements comprehensive performance benchmarking and analysis capabilities
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

# Import required helper functions
$privatePath = Split-Path $PSScriptRoot -Parent
$helpersPath = Join-Path $privatePath "Private"

# Import performance analysis helpers if they exist
$performanceHelpersPath = Join-Path $helpersPath "PerformanceAnalysisHelpers.ps1"
if (Test-Path $performanceHelpersPath) {
    . $performanceHelpersPath
}

# Import performance optimization helpers if they exist
$optimizationHelpersPath = Join-Path $helpersPath "PerformanceOptimizationHelpers.ps1"
if (Test-Path $optimizationHelpersPath) {
    . $optimizationHelpersPath
}

<#
.SYNOPSIS
    Executes comprehensive performance benchmarks for image optimization.

.DESCRIPTION
    Runs detailed performance benchmarks to measure processing speed, memory usage,
    scalability, and cross-platform performance. Provides comprehensive analysis
    and optimization recommendations based on PowerShell 7's performance capabilities.

.PARAMETER Path
    Path to the directory containing images to benchmark.

.PARAMETER BenchmarkType
    Type of benchmark to execute: 'Speed', 'Memory', 'Scalability', 'CrossPlatform', 'Comprehensive'.

.PARAMETER Iterations
    Number of benchmark iterations to run for statistical accuracy.

.PARAMETER OutputPath
    Optional path to save benchmark results and reports.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics in the results.

.OUTPUTS
    [PSCustomObject] Comprehensive benchmark results with performance metrics and analysis.

.EXAMPLE
    $results = Invoke-PerformanceBenchmark -Path "C:\TestImages" -BenchmarkType 'Comprehensive'

.EXAMPLE
    $results = Invoke-PerformanceBenchmark -Path "C:\TestImages" -BenchmarkType 'Speed' -Iterations 5 -IncludeDetailedMetrics
#>
function Invoke-PerformanceBenchmark {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Speed', 'Memory', 'Scalability', 'CrossPlatform', 'Comprehensive')]
        [string]$BenchmarkType = 'Comprehensive',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Starting performance benchmark: $BenchmarkType"

    # Validate input path
    if (-not (Test-Path $Path)) {
        throw "Benchmark path not found: $Path"
    }

    # Initialize benchmark results
    $benchmarkResults = [PSCustomObject]@{
        BenchmarkType = $BenchmarkType
        StartTime = Get-Date
        EndTime = $null
        TotalDuration = [timespan]::Zero
        Iterations = $Iterations
        InputPath = $Path
        OutputPath = $OutputPath
        PerformanceMetrics = @{}
        DetailedMetrics = @{}
        Recommendations = @()
        Success = $false
        ErrorMessage = $null
    }

    try {
        # Get test images
        $imageFiles = Get-ChildItem -Path $Path -Recurse -Include "*.jpg", "*.png", "*.jpeg"
        if ($imageFiles.Count -eq 0) {
            throw "No supported image files found in path: $Path"
        }

        Write-Verbose "Found $($imageFiles.Count) images for benchmarking"

        # Execute benchmark based on type
        switch ($BenchmarkType) {
            'Speed' {
                $benchmarkResults.PerformanceMetrics = Invoke-SpeedBenchmark -ImageFiles $imageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics
            }
            'Memory' {
                $benchmarkResults.PerformanceMetrics = Invoke-MemoryBenchmark -ImageFiles $imageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics
            }
            'Scalability' {
                $benchmarkResults.PerformanceMetrics = Invoke-ScalabilityBenchmark -ImageFiles $imageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics
            }
            'CrossPlatform' {
                $benchmarkResults.PerformanceMetrics = Invoke-CrossPlatformBenchmark -ImageFiles $imageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics
            }
            'Comprehensive' {
                $benchmarkResults.PerformanceMetrics = Invoke-ComprehensiveBenchmark -ImageFiles $imageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics
            }
        }

        # Generate recommendations
        $benchmarkResults.Recommendations = Get-OptimizationRecommendations -PerformanceMetrics $benchmarkResults.PerformanceMetrics

        # Set completion time
        $benchmarkResults.EndTime = Get-Date
        $benchmarkResults.TotalDuration = $benchmarkResults.EndTime - $benchmarkResults.StartTime
        $benchmarkResults.Success = $true

        # Save results if output path specified
        if ($OutputPath) {
            Export-BenchmarkResults -BenchmarkData $benchmarkResults -OutputPath $OutputPath -Format 'JSON'
        }

        Write-Verbose "Performance benchmark completed successfully in $($benchmarkResults.TotalDuration.TotalSeconds) seconds"
        return $benchmarkResults
    }
    catch {
        $benchmarkResults.ErrorMessage = $_.Exception.Message
        $benchmarkResults.EndTime = Get-Date
        $benchmarkResults.TotalDuration = $benchmarkResults.EndTime - $benchmarkResults.StartTime
        Write-Error "Performance benchmark failed: $($_.Exception.Message)"
        return $benchmarkResults
    }
}

<#
.SYNOPSIS
    Executes speed-focused performance benchmarks.

.DESCRIPTION
    Measures processing speed, throughput, and performance characteristics
    focused on image processing rate and efficiency.

.PARAMETER ImageFiles
    Array of image files to benchmark.

.PARAMETER Iterations
    Number of iterations to run.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics.

.OUTPUTS
    [hashtable] Speed benchmark results.
#>
function Invoke-SpeedBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Executing speed benchmark with $($ImageFiles.Count) images, $Iterations iterations"

    $speedMetrics = @{
        AverageProcessingRate = 0.0
        PeakProcessingRate = 0.0
        MinimumProcessingRate = [double]::MaxValue
        AverageTimePerImage = [timespan]::Zero
        TotalProcessingTime = [timespan]::Zero
        ImagesProcessed = 0
        IterationResults = @()
    }

    # Create temporary output directory
    $tempOutput = Join-Path $env:TEMP "SpeedBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

    try {
        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Verbose "Speed benchmark iteration $i of $Iterations"

            $iterationOutput = Join-Path $tempOutput "Iteration_$i"
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Run optimization
            $result = Optimize-WebImages -Path $ImageFiles[0].Directory.FullName -OutputPath $iterationOutput

            $stopwatch.Stop()

            # Calculate metrics for this iteration
            $processingRate = if ($stopwatch.Elapsed.TotalMinutes -gt 0) {
                $result.FilesProcessed / $stopwatch.Elapsed.TotalMinutes
            } else { 0 }

            $iterationMetrics = @{
                Iteration = $i
                ProcessingTime = $stopwatch.Elapsed
                FilesProcessed = $result.FilesProcessed
                ProcessingRate = $processingRate
                Success = $result.Success
            }

            $speedMetrics.IterationResults += $iterationMetrics

            # Update aggregate metrics
            if ($processingRate -gt $speedMetrics.PeakProcessingRate) {
                $speedMetrics.PeakProcessingRate = $processingRate
            }
            if ($processingRate -lt $speedMetrics.MinimumProcessingRate) {
                $speedMetrics.MinimumProcessingRate = $processingRate
            }

            $speedMetrics.TotalProcessingTime = $speedMetrics.TotalProcessingTime.Add($stopwatch.Elapsed)
            $speedMetrics.ImagesProcessed += $result.FilesProcessed
        }

        # Calculate final averages
        if ($Iterations -gt 0) {
            $speedMetrics.AverageProcessingRate = ($speedMetrics.IterationResults | Measure-Object -Property ProcessingRate -Average).Average
            $speedMetrics.AverageTimePerImage = [timespan]::FromMilliseconds($speedMetrics.TotalProcessingTime.TotalMilliseconds / $speedMetrics.ImagesProcessed)
        }

        Write-Verbose "Speed benchmark completed. Average rate: $([math]::Round($speedMetrics.AverageProcessingRate, 2)) images/minute"
        return $speedMetrics
    }
    finally {
        # Cleanup
        if (Test-Path $tempOutput) {
            Remove-Item -Path $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Executes memory-focused performance benchmarks.

.DESCRIPTION
    Measures memory usage patterns, peak memory consumption,
    and memory efficiency during image processing.

.PARAMETER ImageFiles
    Array of image files to benchmark.

.PARAMETER Iterations
    Number of iterations to run.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics.

.OUTPUTS
    [hashtable] Memory benchmark results.
#>
function Invoke-MemoryBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Executing memory benchmark with $($ImageFiles.Count) images, $Iterations iterations"

    $memoryMetrics = @{
        AverageMemoryUsageMB = 0.0
        PeakMemoryUsageMB = 0.0
        MinimumMemoryUsageMB = [double]::MaxValue
        MemoryEfficiencyScore = 0.0
        MemoryLeakDetected = $false
        IterationResults = @()
    }

    # Create temporary output directory
    $tempOutput = Join-Path $env:TEMP "MemoryBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

    try {
        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Verbose "Memory benchmark iteration $i of $Iterations"

            # Force garbage collection before measurement
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $initialMemory = [System.GC]::GetTotalMemory($false)

            $iterationOutput = Join-Path $tempOutput "Iteration_$i"

            # Run optimization
            $result = Optimize-WebImages -Path $ImageFiles[0].Directory.FullName -OutputPath $iterationOutput

            # Measure peak memory
            $peakMemory = [System.GC]::GetTotalMemory($false)

            # Force cleanup and measure final memory
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $finalMemory = [System.GC]::GetTotalMemory($false)

            # Calculate memory metrics for this iteration
            $memoryUsedMB = ($peakMemory - $initialMemory) / 1MB
            $memoryLeakMB = ($finalMemory - $initialMemory) / 1MB

            $iterationMetrics = @{
                Iteration = $i
                InitialMemoryMB = $initialMemory / 1MB
                PeakMemoryMB = $peakMemory / 1MB
                FinalMemoryMB = $finalMemory / 1MB
                MemoryUsedMB = $memoryUsedMB
                MemoryLeakMB = $memoryLeakMB
                FilesProcessed = $result.FilesProcessed
                Success = $result.Success
            }

            $memoryMetrics.IterationResults += $iterationMetrics

            # Update aggregate metrics
            if ($memoryUsedMB -gt $memoryMetrics.PeakMemoryUsageMB) {
                $memoryMetrics.PeakMemoryUsageMB = $memoryUsedMB
            }
            if ($memoryUsedMB -lt $memoryMetrics.MinimumMemoryUsageMB) {
                $memoryMetrics.MinimumMemoryUsageMB = $memoryUsedMB
            }

            # Check for memory leaks (threshold: 10MB)
            if ($memoryLeakMB -gt 10) {
                $memoryMetrics.MemoryLeakDetected = $true
            }
        }

        # Calculate final averages
        if ($Iterations -gt 0) {
            $memoryMetrics.AverageMemoryUsageMB = ($memoryMetrics.IterationResults | Measure-Object -Property MemoryUsedMB -Average).Average

            # Calculate efficiency score (lower memory usage per image = higher score)
            $totalImages = ($memoryMetrics.IterationResults | Measure-Object -Property FilesProcessed -Sum).Sum
            if ($totalImages -gt 0) {
                $memoryPerImage = $memoryMetrics.AverageMemoryUsageMB / ($totalImages / $Iterations)
                $memoryMetrics.MemoryEfficiencyScore = [math]::Max(0, 100 - $memoryPerImage)
            }
        }

        Write-Verbose "Memory benchmark completed. Average usage: $([math]::Round($memoryMetrics.AverageMemoryUsageMB, 2)) MB"
        return $memoryMetrics
    }
    finally {
        # Cleanup
        if (Test-Path $tempOutput) {
            Remove-Item -Path $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Executes scalability-focused performance benchmarks.

.DESCRIPTION
    Measures how performance scales with different dataset sizes
    and processing loads to identify scalability characteristics.

.PARAMETER ImageFiles
    Array of image files to benchmark.

.PARAMETER Iterations
    Number of iterations to run.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics.

.OUTPUTS
    [hashtable] Scalability benchmark results.
#>
function Invoke-ScalabilityBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Executing scalability benchmark with $($ImageFiles.Count) images, $Iterations iterations"

    $scalabilityMetrics = @{
        LinearScalingScore = 0.0
        ScalingEfficiency = 0.0
        OptimalBatchSize = 0
        ScalingResults = @()
        PerformanceBySize = @{}
    }

    # Test different batch sizes
    $batchSizes = @(5, 10, 15, [math]::Min(25, $ImageFiles.Count))

    # Create temporary output directory
    $tempOutput = Join-Path $env:TEMP "ScalabilityBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

    try {
        foreach ($batchSize in $batchSizes) {
            if ($batchSize -gt $ImageFiles.Count) { continue }

            Write-Verbose "Testing scalability with batch size: $batchSize"

            $batchResults = @()

            for ($i = 1; $i -le $Iterations; $i++) {
                $iterationOutput = Join-Path $tempOutput "Batch_$($batchSize)_Iteration_$i"

                # Select subset of images
                $batchImages = $ImageFiles | Select-Object -First $batchSize

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $result = Optimize-WebImages -Path $batchImages[0].Directory.FullName -OutputPath $iterationOutput
                $stopwatch.Stop()

                $batchResults += @{
                    BatchSize = $batchSize
                    Iteration = $i
                    ProcessingTime = $stopwatch.Elapsed
                    FilesProcessed = $result.FilesProcessed
                    ProcessingRate = if ($stopwatch.Elapsed.TotalMinutes -gt 0) { $result.FilesProcessed / $stopwatch.Elapsed.TotalMinutes } else { 0 }
                    TimePerImage = if ($result.FilesProcessed -gt 0) { $stopwatch.Elapsed.TotalSeconds / $result.FilesProcessed } else { 0 }
                }
            }

            # Calculate averages for this batch size
            $avgTimePerImage = ($batchResults | Measure-Object -Property TimePerImage -Average).Average
            $avgProcessingRate = ($batchResults | Measure-Object -Property ProcessingRate -Average).Average

            $scalabilityMetrics.PerformanceBySize[$batchSize] = @{
                AverageTimePerImage = $avgTimePerImage
                AverageProcessingRate = $avgProcessingRate
                Results = $batchResults
            }
        }

        # Analyze scaling characteristics
        $timePerImageValues = @()
        $processingRates = @()

        foreach ($size in $batchSizes) {
            if ($scalabilityMetrics.PerformanceBySize.ContainsKey($size)) {
                $timePerImageValues += $scalabilityMetrics.PerformanceBySize[$size].AverageTimePerImage
                $processingRates += $scalabilityMetrics.PerformanceBySize[$size].AverageProcessingRate
            }
        }

        # Calculate linear scaling score (consistency of time per image)
        if ($timePerImageValues.Count -gt 1) {
            $variance = ($timePerImageValues | Measure-Object -StandardDeviation).StandardDeviation
            $mean = ($timePerImageValues | Measure-Object -Average).Average
            $coefficientOfVariation = if ($mean -gt 0) { $variance / $mean } else { 1 }
            $scalabilityMetrics.LinearScalingScore = [math]::Max(0, 100 - ($coefficientOfVariation * 100))
        }

        # Find optimal batch size (highest processing rate)
        $maxRate = ($processingRates | Measure-Object -Maximum).Maximum
        $optimalIndex = $processingRates.IndexOf($maxRate)
        if ($optimalIndex -ge 0 -and $optimalIndex -lt $batchSizes.Count) {
            $scalabilityMetrics.OptimalBatchSize = $batchSizes[$optimalIndex]
        }

        # Calculate overall scaling efficiency
        $scalabilityMetrics.ScalingEfficiency = $scalabilityMetrics.LinearScalingScore

        Write-Verbose "Scalability benchmark completed. Linear scaling score: $([math]::Round($scalabilityMetrics.LinearScalingScore, 2))"
        return $scalabilityMetrics
    }
    finally {
        # Cleanup
        if (Test-Path $tempOutput) {
            Remove-Item -Path $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Executes cross-platform performance benchmarks.

.DESCRIPTION
    Measures performance characteristics across different platforms
    and identifies platform-specific optimizations.

.PARAMETER ImageFiles
    Array of image files to benchmark.

.PARAMETER Iterations
    Number of iterations to run.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics.

.OUTPUTS
    [hashtable] Cross-platform benchmark results.
#>
function Invoke-CrossPlatformBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Executing cross-platform benchmark with $($ImageFiles.Count) images, $Iterations iterations"

    $crossPlatformMetrics = @{
        CurrentPlatform = $null
        PlatformOptimizations = @()
        PerformanceConsistency = 0.0
        PlatformSpecificResults = @{}
    }

    # Detect current platform
    $platform = if ($IsWindows) { "Windows" }
                elseif ($IsLinux) { "Linux" }
                elseif ($IsMacOS) { "macOS" }
                else { "Unknown" }

    $crossPlatformMetrics.CurrentPlatform = $platform

    # Create temporary output directory
    $tempOutput = Join-Path $env:TEMP "CrossPlatformBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

    try {
        # Run standard benchmark for current platform
        $platformResults = @()

        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Verbose "Cross-platform benchmark iteration $i of $Iterations on $platform"

            $iterationOutput = Join-Path $tempOutput "Platform_$($platform)_Iteration_$i"

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Optimize-WebImages -Path $ImageFiles[0].Directory.FullName -OutputPath $iterationOutput
            $stopwatch.Stop()

            $platformResults += @{
                Platform = $platform
                Iteration = $i
                ProcessingTime = $stopwatch.Elapsed
                FilesProcessed = $result.FilesProcessed
                ProcessingRate = if ($stopwatch.Elapsed.TotalMinutes -gt 0) { $result.FilesProcessed / $stopwatch.Elapsed.TotalMinutes } else { 0 }
                MemoryUsed = [System.GC]::GetTotalMemory($false) / 1MB
                Success = $result.Success
            }
        }

        # Store platform-specific results
        $crossPlatformMetrics.PlatformSpecificResults[$platform] = $platformResults

        # Calculate performance consistency (low variance = high consistency)
        $processingRates = $platformResults | ForEach-Object { $_.ProcessingRate }
        if ($processingRates.Count -gt 1) {
            $variance = ($processingRates | Measure-Object -StandardDeviation).StandardDeviation
            $mean = ($processingRates | Measure-Object -Average).Average
            $coefficientOfVariation = if ($mean -gt 0) { $variance / $mean } else { 1 }
            $crossPlatformMetrics.PerformanceConsistency = [math]::Max(0, 100 - ($coefficientOfVariation * 100))
        } else {
            $crossPlatformMetrics.PerformanceConsistency = 100
        }

        # Identify platform-specific optimizations
        $crossPlatformMetrics.PlatformOptimizations = Find-PlatformOptimizations -PerformanceData $crossPlatformMetrics.PlatformSpecificResults

        Write-Verbose "Cross-platform benchmark completed on $platform. Consistency score: $([math]::Round($crossPlatformMetrics.PerformanceConsistency, 2))"
        return $crossPlatformMetrics
    }
    finally {
        # Cleanup
        if (Test-Path $tempOutput) {
            Remove-Item -Path $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Executes comprehensive performance benchmarks.

.DESCRIPTION
    Combines all benchmark types to provide a complete performance analysis
    including speed, memory, scalability, and cross-platform characteristics.

.PARAMETER ImageFiles
    Array of image files to benchmark.

.PARAMETER Iterations
    Number of iterations to run.

.PARAMETER IncludeDetailedMetrics
    Include detailed performance metrics.

.OUTPUTS
    [hashtable] Comprehensive benchmark results.
#>
function Invoke-ComprehensiveBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ImageFiles,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetailedMetrics
    )

    Write-Verbose "Executing comprehensive benchmark with $($ImageFiles.Count) images, $Iterations iterations"

    $comprehensiveMetrics = @{
        SpeedMetrics = @{}
        MemoryMetrics = @{}
        ScalabilityMetrics = @{}
        CrossPlatformMetrics = @{}
        OverallScore = 0.0
        PerformanceGrade = "Unknown"
    }

    try {
        # Execute all benchmark types
        Write-Verbose "Running speed benchmark..."
        $comprehensiveMetrics.SpeedMetrics = Invoke-SpeedBenchmark -ImageFiles $ImageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics

        Write-Verbose "Running memory benchmark..."
        $comprehensiveMetrics.MemoryMetrics = Invoke-MemoryBenchmark -ImageFiles $ImageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics

        Write-Verbose "Running scalability benchmark..."
        $comprehensiveMetrics.ScalabilityMetrics = Invoke-ScalabilityBenchmark -ImageFiles $ImageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics

        Write-Verbose "Running cross-platform benchmark..."
        $comprehensiveMetrics.CrossPlatformMetrics = Invoke-CrossPlatformBenchmark -ImageFiles $ImageFiles -Iterations $Iterations -IncludeDetailedMetrics:$IncludeDetailedMetrics

        # Calculate overall performance score
        $speedScore = [math]::Min(100, ($comprehensiveMetrics.SpeedMetrics.AverageProcessingRate / 50) * 100)  # Target: 50 images/minute
        $memoryScore = [math]::Max(0, 100 - ($comprehensiveMetrics.MemoryMetrics.AverageMemoryUsageMB / 10))  # Lower memory = higher score
        $scalabilityScore = $comprehensiveMetrics.ScalabilityMetrics.LinearScalingScore
        $crossPlatformScore = $comprehensiveMetrics.CrossPlatformMetrics.PerformanceConsistency

        $comprehensiveMetrics.OverallScore = ($speedScore + $memoryScore + $scalabilityScore + $crossPlatformScore) / 4

        # Assign performance grade
        if ($comprehensiveMetrics.OverallScore -ge 90) { $comprehensiveMetrics.PerformanceGrade = "Excellent" }
        elseif ($comprehensiveMetrics.OverallScore -ge 80) { $comprehensiveMetrics.PerformanceGrade = "Good" }
        elseif ($comprehensiveMetrics.OverallScore -ge 70) { $comprehensiveMetrics.PerformanceGrade = "Fair" }
        elseif ($comprehensiveMetrics.OverallScore -ge 60) { $comprehensiveMetrics.PerformanceGrade = "Poor" }
        else { $comprehensiveMetrics.PerformanceGrade = "Critical" }

        Write-Verbose "Comprehensive benchmark completed. Overall score: $([math]::Round($comprehensiveMetrics.OverallScore, 2)) ($($comprehensiveMetrics.PerformanceGrade))"
        return $comprehensiveMetrics
    }
    catch {
        Write-Error "Comprehensive benchmark failed: $($_.Exception.Message)"
        throw
    }
}
