# Performance Analysis Helper Functions for WebImageOptimizer
# Provides supporting functions for performance benchmarking and optimization analysis
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Generates optimization recommendations based on performance metrics.

.DESCRIPTION
    Analyzes performance metrics and provides specific recommendations
    for optimizing image processing performance.

.PARAMETER PerformanceMetrics
    Hashtable containing performance metrics from benchmarking.

.OUTPUTS
    [Array] Array of optimization recommendations.

.EXAMPLE
    $recommendations = Get-OptimizationRecommendations -PerformanceMetrics $metrics
#>
function Get-OptimizationRecommendations {
    [CmdletBinding()]
    [OutputType([Array])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceMetrics
    )

    $recommendations = @()

    try {
        # Analyze speed metrics
        if ($PerformanceMetrics.ContainsKey('AverageProcessingRate')) {
            $processingRate = $PerformanceMetrics.AverageProcessingRate
            if ($processingRate -lt 50) {
                $recommendations += [PSCustomObject]@{
                    Category = "Speed"
                    Priority = "High"
                    Issue = "Processing rate below target (50+ images/minute)"
                    Recommendation = "Consider enabling parallel processing or optimizing image processing settings"
                    CurrentValue = "$([math]::Round($processingRate, 2)) images/minute"
                    TargetValue = "50+ images/minute"
                }
            } elseif ($processingRate -gt 500) {
                $recommendations += [PSCustomObject]@{
                    Category = "Speed"
                    Priority = "Info"
                    Issue = "Excellent processing performance"
                    Recommendation = "Performance exceeds targets. Consider increasing quality settings for better output"
                    CurrentValue = "$([math]::Round($processingRate, 2)) images/minute"
                    TargetValue = "50+ images/minute"
                }
            }
        }

        # Analyze memory metrics
        if ($PerformanceMetrics.ContainsKey('AverageMemoryUsageMB')) {
            $memoryUsage = $PerformanceMetrics.AverageMemoryUsageMB
            if ($memoryUsage -gt 1024) {
                $recommendations += [PSCustomObject]@{
                    Category = "Memory"
                    Priority = "High"
                    Issue = "Memory usage exceeds 1GB target"
                    Recommendation = "Reduce batch size or implement memory optimization techniques"
                    CurrentValue = "$([math]::Round($memoryUsage, 2)) MB"
                    TargetValue = "< 1024 MB"
                }
            } elseif ($memoryUsage -lt 0) {
                $recommendations += [PSCustomObject]@{
                    Category = "Memory"
                    Priority = "Info"
                    Issue = "Excellent memory efficiency"
                    Recommendation = "Memory usage is optimal. Current settings are well-tuned"
                    CurrentValue = "$([math]::Round($memoryUsage, 2)) MB"
                    TargetValue = "< 1024 MB"
                }
            }
        }

        # Analyze scalability metrics
        if ($PerformanceMetrics.ContainsKey('LinearScalingScore')) {
            $scalingScore = $PerformanceMetrics.LinearScalingScore
            if ($scalingScore -lt 70) {
                $recommendations += [PSCustomObject]@{
                    Category = "Scalability"
                    Priority = "Medium"
                    Issue = "Poor linear scaling performance"
                    Recommendation = "Review parallel processing configuration and optimize for better scalability"
                    CurrentValue = "$([math]::Round($scalingScore, 2))%"
                    TargetValue = "> 70%"
                }
            }
        }

        # Analyze cross-platform consistency
        if ($PerformanceMetrics.ContainsKey('PerformanceConsistency')) {
            $consistency = $PerformanceMetrics.PerformanceConsistency
            if ($consistency -lt 80) {
                $recommendations += [PSCustomObject]@{
                    Category = "Cross-Platform"
                    Priority = "Medium"
                    Issue = "Inconsistent cross-platform performance"
                    Recommendation = "Review platform-specific optimizations and ensure consistent configuration"
                    CurrentValue = "$([math]::Round($consistency, 2))%"
                    TargetValue = "> 80%"
                }
            }
        }

        # General recommendations if no issues found
        if ($recommendations.Count -eq 0) {
            $recommendations += [PSCustomObject]@{
                Category = "General"
                Priority = "Info"
                Issue = "No performance issues detected"
                Recommendation = "Performance is optimal. Continue monitoring for any changes"
                CurrentValue = "Optimal"
                TargetValue = "Maintain current performance"
            }
        }

        return $recommendations
    }
    catch {
        Write-Warning "Failed to generate optimization recommendations: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Finds platform-specific optimizations based on performance data.

.DESCRIPTION
    Analyzes performance data to identify platform-specific optimization
    opportunities and recommendations.

.PARAMETER PerformanceData
    Hashtable containing platform-specific performance data.

.OUTPUTS
    [Array] Array of platform-specific optimization recommendations.

.EXAMPLE
    $optimizations = Find-PlatformOptimizations -PerformanceData $platformData
#>
function Find-PlatformOptimizations {
    [CmdletBinding()]
    [OutputType([Array])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceData
    )

    $optimizations = @()

    try {
        foreach ($platform in $PerformanceData.Keys) {
            $platformResults = $PerformanceData[$platform]
            
            if ($platformResults -and $platformResults.Count -gt 0) {
                $avgProcessingRate = ($platformResults | Measure-Object -Property ProcessingRate -Average).Average
                $avgMemoryUsed = ($platformResults | Measure-Object -Property MemoryUsed -Average).Average

                # Platform-specific recommendations
                switch ($platform) {
                    "Windows" {
                        if ($avgProcessingRate -lt 100) {
                            $optimizations += [PSCustomObject]@{
                                Platform = $platform
                                Category = "Windows Optimization"
                                Recommendation = "Consider using Windows-specific ImageMagick optimizations or .NET Core performance features"
                                Impact = "Medium"
                            }
                        }
                    }
                    "Linux" {
                        if ($avgMemoryUsed -gt 500) {
                            $optimizations += [PSCustomObject]@{
                                Platform = $platform
                                Category = "Linux Optimization"
                                Recommendation = "Leverage Linux memory management features and consider container-based optimization"
                                Impact = "Medium"
                            }
                        }
                    }
                    "macOS" {
                        if ($avgProcessingRate -lt 80) {
                            $optimizations += [PSCustomObject]@{
                                Platform = $platform
                                Category = "macOS Optimization"
                                Recommendation = "Utilize macOS-specific graphics acceleration and Core Image optimizations"
                                Impact = "Medium"
                            }
                        }
                    }
                }

                # General platform optimization
                $optimizations += [PSCustomObject]@{
                    Platform = $platform
                    Category = "Platform Performance"
                    Recommendation = "Performance on $platform is within acceptable ranges"
                    Impact = "Info"
                    ProcessingRate = "$([math]::Round($avgProcessingRate, 2)) images/minute"
                    MemoryUsage = "$([math]::Round($avgMemoryUsed, 2)) MB"
                }
            }
        }

        return $optimizations
    }
    catch {
        Write-Warning "Failed to find platform optimizations: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Exports benchmark results to specified format and location.

.DESCRIPTION
    Exports comprehensive benchmark results to JSON, CSV, or XML format
    for analysis and reporting purposes.

.PARAMETER BenchmarkData
    Benchmark data to export.

.PARAMETER OutputPath
    Path where the results should be saved.

.PARAMETER Format
    Export format: 'JSON', 'CSV', 'XML'.

.OUTPUTS
    [string] Path to the exported file.

.EXAMPLE
    $exportPath = Export-BenchmarkResults -BenchmarkData $results -OutputPath "C:\Reports" -Format 'JSON'
#>
function Export-BenchmarkResults {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$BenchmarkData,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV', 'XML')]
        [string]$Format = 'JSON'
    )

    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        # Generate filename with timestamp
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $fileName = "PerformanceBenchmark_$($BenchmarkData.BenchmarkType)_$timestamp.$($Format.ToLower())"
        $fullPath = Join-Path $OutputPath $fileName

        # Export based on format
        switch ($Format) {
            'JSON' {
                $BenchmarkData | ConvertTo-Json -Depth 10 | Out-File -FilePath $fullPath -Encoding UTF8
            }
            'CSV' {
                # Flatten the data for CSV export
                $flattenedData = @()
                
                # Add basic metrics
                $flattenedData += [PSCustomObject]@{
                    Metric = "BenchmarkType"
                    Value = $BenchmarkData.BenchmarkType
                    Category = "General"
                }
                $flattenedData += [PSCustomObject]@{
                    Metric = "TotalDuration"
                    Value = $BenchmarkData.TotalDuration.TotalSeconds
                    Category = "General"
                }
                $flattenedData += [PSCustomObject]@{
                    Metric = "Success"
                    Value = $BenchmarkData.Success
                    Category = "General"
                }

                # Add performance metrics
                foreach ($key in $BenchmarkData.PerformanceMetrics.Keys) {
                    $value = $BenchmarkData.PerformanceMetrics[$key]
                    if ($value -is [hashtable]) {
                        foreach ($subKey in $value.Keys) {
                            $flattenedData += [PSCustomObject]@{
                                Metric = "$key.$subKey"
                                Value = $value[$subKey]
                                Category = $key
                            }
                        }
                    } else {
                        $flattenedData += [PSCustomObject]@{
                            Metric = $key
                            Value = $value
                            Category = "Performance"
                        }
                    }
                }

                $flattenedData | Export-Csv -Path $fullPath -NoTypeInformation
            }
            'XML' {
                $BenchmarkData | Export-Clixml -Path $fullPath
            }
        }

        Write-Verbose "Benchmark results exported to: $fullPath"
        return $fullPath
    }
    catch {
        Write-Error "Failed to export benchmark results: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Measures detailed processing performance metrics.

.DESCRIPTION
    Collects detailed performance metrics including timing, memory usage,
    and processing rates over multiple iterations.

.PARAMETER Path
    Path to images for performance measurement.

.PARAMETER Iterations
    Number of iterations to run.

.OUTPUTS
    [PSCustomObject] Detailed performance metrics.

.EXAMPLE
    $metrics = Measure-ProcessingPerformance -Path "C:\TestImages" -Iterations 5
#>
function Measure-ProcessingPerformance {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )

    $performanceMetrics = [PSCustomObject]@{
        TotalIterations = $Iterations
        IterationResults = @()
        AverageProcessingTime = [timespan]::Zero
        AverageProcessingRate = 0.0
        AverageMemoryUsage = 0.0
        StandardDeviation = 0.0
        MinProcessingTime = [timespan]::MaxValue
        MaxProcessingTime = [timespan]::Zero
        Success = $false
    }

    try {
        # Create temporary output directory
        $tempOutput = Join-Path $env:TEMP "PerformanceMeasurement_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

        $processingTimes = @()
        $processingRates = @()
        $memoryUsages = @()

        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Verbose "Performance measurement iteration $i of $Iterations"
            
            $iterationOutput = Join-Path $tempOutput "Iteration_$i"
            
            # Measure memory before
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($false)
            
            # Run optimization and measure time
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Optimize-WebImages -Path $Path -OutputPath $iterationOutput
            $stopwatch.Stop()
            
            # Measure memory after
            $memoryAfter = [System.GC]::GetTotalMemory($false)
            $memoryUsed = ($memoryAfter - $memoryBefore) / 1MB
            
            # Calculate metrics for this iteration
            $processingRate = if ($stopwatch.Elapsed.TotalMinutes -gt 0) {
                $result.FilesProcessed / $stopwatch.Elapsed.TotalMinutes
            } else { 0 }
            
            $iterationResult = [PSCustomObject]@{
                Iteration = $i
                ProcessingTime = $stopwatch.Elapsed
                FilesProcessed = $result.FilesProcessed
                ProcessingRate = $processingRate
                MemoryUsedMB = $memoryUsed
                Success = $result.Success
            }
            
            $performanceMetrics.IterationResults += $iterationResult
            
            # Collect data for statistics
            $processingTimes += $stopwatch.Elapsed.TotalSeconds
            $processingRates += $processingRate
            $memoryUsages += $memoryUsed
            
            # Update min/max
            if ($stopwatch.Elapsed -lt $performanceMetrics.MinProcessingTime) {
                $performanceMetrics.MinProcessingTime = $stopwatch.Elapsed
            }
            if ($stopwatch.Elapsed -gt $performanceMetrics.MaxProcessingTime) {
                $performanceMetrics.MaxProcessingTime = $stopwatch.Elapsed
            }
        }

        # Calculate final statistics
        if ($processingTimes.Count -gt 0) {
            $performanceMetrics.AverageProcessingTime = [timespan]::FromSeconds(($processingTimes | Measure-Object -Average).Average)
            $performanceMetrics.AverageProcessingRate = ($processingRates | Measure-Object -Average).Average
            $performanceMetrics.AverageMemoryUsage = ($memoryUsages | Measure-Object -Average).Average
            
            if ($processingTimes.Count -gt 1) {
                $performanceMetrics.StandardDeviation = ($processingTimes | Measure-Object -StandardDeviation).StandardDeviation
            }
        }

        $performanceMetrics.Success = $true
        return $performanceMetrics
    }
    catch {
        Write-Error "Performance measurement failed: $($_.Exception.Message)"
        $performanceMetrics.Success = $false
        return $performanceMetrics
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
    Measures memory usage patterns during processing.

.DESCRIPTION
    Monitors memory usage patterns during image processing to identify
    memory leaks, peak usage, and efficiency characteristics.

.PARAMETER ProcessingFunction
    Scriptblock containing the processing function to monitor.

.PARAMETER TestPath
    Path to test images.

.OUTPUTS
    [PSCustomObject] Memory usage pattern analysis.

.EXAMPLE
    $memoryPattern = Measure-MemoryUsagePattern -ProcessingFunction { param($path) Optimize-WebImages -Path $path } -TestPath "C:\TestImages"
#>
function Measure-MemoryUsagePattern {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ProcessingFunction,

        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    $memoryPattern = [PSCustomObject]@{
        InitialMemoryMB = 0.0
        PeakMemoryMB = 0.0
        FinalMemoryMB = 0.0
        MemoryLeakMB = 0.0
        MemoryEfficiency = 0.0
        MemorySnapshots = @()
        Success = $false
    }

    try {
        # Initial memory measurement
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        $initialMemory = [System.GC]::GetTotalMemory($false)
        $memoryPattern.InitialMemoryMB = $initialMemory / 1MB

        # Create temporary output
        $tempOutput = Join-Path $env:TEMP "MemoryPattern_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        # Monitor memory during processing
        $peakMemory = $initialMemory
        
        # Execute processing function
        $result = & $ProcessingFunction $TestPath $tempOutput
        
        # Measure peak memory
        $currentMemory = [System.GC]::GetTotalMemory($false)
        if ($currentMemory -gt $peakMemory) {
            $peakMemory = $currentMemory
        }
        
        $memoryPattern.PeakMemoryMB = $peakMemory / 1MB

        # Force cleanup and measure final memory
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        $finalMemory = [System.GC]::GetTotalMemory($false)
        $memoryPattern.FinalMemoryMB = $finalMemory / 1MB

        # Calculate memory leak
        $memoryPattern.MemoryLeakMB = ($finalMemory - $initialMemory) / 1MB

        # Calculate efficiency (lower peak usage relative to work done = higher efficiency)
        $memoryUsed = ($peakMemory - $initialMemory) / 1MB
        if ($result -and $result.FilesProcessed -gt 0) {
            $memoryPerFile = $memoryUsed / $result.FilesProcessed
            $memoryPattern.MemoryEfficiency = [math]::Max(0, 100 - $memoryPerFile)
        }

        $memoryPattern.Success = $true
        return $memoryPattern
    }
    catch {
        Write-Error "Memory usage pattern measurement failed: $($_.Exception.Message)"
        $memoryPattern.Success = $false
        return $memoryPattern
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
    Measures processing rate variations over multiple samples.

.DESCRIPTION
    Analyzes processing rate consistency and variations to identify
    performance stability and potential optimization opportunities.

.PARAMETER Path
    Path to test images.

.PARAMETER SampleCount
    Number of samples to collect.

.OUTPUTS
    [PSCustomObject] Processing rate variation analysis.

.EXAMPLE
    $rateVariation = Measure-ProcessingRateVariation -Path "C:\TestImages" -SampleCount 10
#>
function Measure-ProcessingRateVariation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$SampleCount = 5
    )

    $rateVariation = [PSCustomObject]@{
        SampleCount = $SampleCount
        ProcessingRates = @()
        AverageRate = 0.0
        StandardDeviation = 0.0
        CoefficientOfVariation = 0.0
        MinRate = [double]::MaxValue
        MaxRate = 0.0
        ConsistencyScore = 0.0
        Success = $false
    }

    try {
        # Create temporary output directory
        $tempOutput = Join-Path $env:TEMP "RateVariation_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null

        $rates = @()

        for ($i = 1; $i -le $SampleCount; $i++) {
            Write-Verbose "Processing rate sample $i of $SampleCount"
            
            $sampleOutput = Join-Path $tempOutput "Sample_$i"
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Optimize-WebImages -Path $Path -OutputPath $sampleOutput
            $stopwatch.Stop()
            
            $processingRate = if ($stopwatch.Elapsed.TotalMinutes -gt 0) {
                $result.FilesProcessed / $stopwatch.Elapsed.TotalMinutes
            } else { 0 }
            
            $rates += $processingRate
            $rateVariation.ProcessingRates += $processingRate
            
            # Update min/max
            if ($processingRate -lt $rateVariation.MinRate) {
                $rateVariation.MinRate = $processingRate
            }
            if ($processingRate -gt $rateVariation.MaxRate) {
                $rateVariation.MaxRate = $processingRate
            }
        }

        # Calculate statistics
        if ($rates.Count -gt 0) {
            $rateVariation.AverageRate = ($rates | Measure-Object -Average).Average
            
            if ($rates.Count -gt 1) {
                $rateVariation.StandardDeviation = ($rates | Measure-Object -StandardDeviation).StandardDeviation
                
                if ($rateVariation.AverageRate -gt 0) {
                    $rateVariation.CoefficientOfVariation = $rateVariation.StandardDeviation / $rateVariation.AverageRate
                    $rateVariation.ConsistencyScore = [math]::Max(0, 100 - ($rateVariation.CoefficientOfVariation * 100))
                }
            } else {
                $rateVariation.ConsistencyScore = 100
            }
        }

        $rateVariation.Success = $true
        return $rateVariation
    }
    catch {
        Write-Error "Processing rate variation measurement failed: $($_.Exception.Message)"
        $rateVariation.Success = $false
        return $rateVariation
    }
    finally {
        # Cleanup
        if (Test-Path $tempOutput) {
            Remove-Item -Path $tempOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
