# Public Performance Benchmarking Function for WebImageOptimizer
# Provides public access to comprehensive performance benchmarking capabilities
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Executes comprehensive performance benchmarks for web image optimization.

.DESCRIPTION
    Runs detailed performance benchmarks to measure processing speed, memory usage,
    scalability, and cross-platform performance. Provides comprehensive analysis
    and optimization recommendations for the WebImageOptimizer module.

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
    Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType 'Comprehensive'
    
    Runs a comprehensive performance benchmark on images in the specified directory.

.EXAMPLE
    Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType 'Speed' -Iterations 5 -IncludeDetailedMetrics
    
    Runs a speed-focused benchmark with 5 iterations and detailed metrics.

.EXAMPLE
    $results = Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType 'Memory' -OutputPath "C:\Reports"
    
    Runs a memory-focused benchmark and saves results to the specified output path.

.NOTES
    This function provides access to the comprehensive performance benchmarking
    capabilities of the WebImageOptimizer module. It measures:
    
    - Processing speed and throughput
    - Memory usage patterns and efficiency
    - Scalability characteristics
    - Cross-platform performance consistency
    - Overall performance scores and grades
    
    The benchmark results include optimization recommendations based on the
    analysis of performance metrics against established targets.
#>
function Invoke-WebImageBenchmark {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
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

    Write-Verbose "Starting web image performance benchmark: $BenchmarkType"

    try {
        # Validate that the path exists and contains images
        if (-not (Test-Path $Path)) {
            throw "Benchmark path not found: $Path"
        }

        $imageFiles = Get-ChildItem -Path $Path -Recurse -Include "*.jpg", "*.png", "*.jpeg"
        if ($imageFiles.Count -eq 0) {
            throw "No supported image files found in path: $Path"
        }

        Write-Verbose "Found $($imageFiles.Count) images for benchmarking"

        # Call the private benchmarking function
        $benchmarkParams = @{
            Path = $Path
            BenchmarkType = $BenchmarkType
            Iterations = $Iterations
            IncludeDetailedMetrics = $IncludeDetailedMetrics
        }

        if ($OutputPath) {
            $benchmarkParams.OutputPath = $OutputPath
        }

        $results = Invoke-PerformanceBenchmark @benchmarkParams

        # Add summary information for public consumption
        $publicResults = [PSCustomObject]@{
            BenchmarkType = $results.BenchmarkType
            StartTime = $results.StartTime
            EndTime = $results.EndTime
            TotalDuration = $results.TotalDuration
            Iterations = $results.Iterations
            InputPath = $results.InputPath
            OutputPath = $results.OutputPath
            Success = $results.Success
            ErrorMessage = $results.ErrorMessage
            
            # Performance Summary
            PerformanceSummary = @{
                OverallGrade = "Unknown"
                SpeedRating = "Unknown"
                MemoryRating = "Unknown"
                ScalabilityRating = "Unknown"
                CrossPlatformRating = "Unknown"
            }
            
            # Detailed Metrics (if available)
            PerformanceMetrics = $results.PerformanceMetrics
            
            # Recommendations
            Recommendations = $results.Recommendations
        }

        # Generate performance summary ratings
        if ($results.PerformanceMetrics) {
            # Speed rating
            if ($results.PerformanceMetrics.ContainsKey('SpeedMetrics') -and $results.PerformanceMetrics.SpeedMetrics.AverageProcessingRate) {
                $speedRate = $results.PerformanceMetrics.SpeedMetrics.AverageProcessingRate
                if ($speedRate -ge 200) { $publicResults.PerformanceSummary.SpeedRating = "Excellent" }
                elseif ($speedRate -ge 100) { $publicResults.PerformanceSummary.SpeedRating = "Good" }
                elseif ($speedRate -ge 50) { $publicResults.PerformanceSummary.SpeedRating = "Fair" }
                else { $publicResults.PerformanceSummary.SpeedRating = "Poor" }
            }

            # Memory rating
            if ($results.PerformanceMetrics.ContainsKey('MemoryMetrics') -and $results.PerformanceMetrics.MemoryMetrics.AverageMemoryUsageMB) {
                $memoryUsage = $results.PerformanceMetrics.MemoryMetrics.AverageMemoryUsageMB
                if ($memoryUsage -le 100) { $publicResults.PerformanceSummary.MemoryRating = "Excellent" }
                elseif ($memoryUsage -le 500) { $publicResults.PerformanceSummary.MemoryRating = "Good" }
                elseif ($memoryUsage -le 1024) { $publicResults.PerformanceSummary.MemoryRating = "Fair" }
                else { $publicResults.PerformanceSummary.MemoryRating = "Poor" }
            }

            # Scalability rating
            if ($results.PerformanceMetrics.ContainsKey('ScalabilityMetrics') -and $results.PerformanceMetrics.ScalabilityMetrics.LinearScalingScore) {
                $scalingScore = $results.PerformanceMetrics.ScalabilityMetrics.LinearScalingScore
                if ($scalingScore -ge 90) { $publicResults.PerformanceSummary.ScalabilityRating = "Excellent" }
                elseif ($scalingScore -ge 80) { $publicResults.PerformanceSummary.ScalabilityRating = "Good" }
                elseif ($scalingScore -ge 70) { $publicResults.PerformanceSummary.ScalabilityRating = "Fair" }
                else { $publicResults.PerformanceSummary.ScalabilityRating = "Poor" }
            }

            # Cross-platform rating
            if ($results.PerformanceMetrics.ContainsKey('CrossPlatformMetrics') -and $results.PerformanceMetrics.CrossPlatformMetrics.PerformanceConsistency) {
                $consistency = $results.PerformanceMetrics.CrossPlatformMetrics.PerformanceConsistency
                if ($consistency -ge 95) { $publicResults.PerformanceSummary.CrossPlatformRating = "Excellent" }
                elseif ($consistency -ge 85) { $publicResults.PerformanceSummary.CrossPlatformRating = "Good" }
                elseif ($consistency -ge 75) { $publicResults.PerformanceSummary.CrossPlatformRating = "Fair" }
                else { $publicResults.PerformanceSummary.CrossPlatformRating = "Poor" }
            }

            # Overall grade
            if ($results.PerformanceMetrics.ContainsKey('OverallScore')) {
                $overallScore = $results.PerformanceMetrics.OverallScore
                if ($overallScore -ge 90) { $publicResults.PerformanceSummary.OverallGrade = "Excellent" }
                elseif ($overallScore -ge 80) { $publicResults.PerformanceSummary.OverallGrade = "Good" }
                elseif ($overallScore -ge 70) { $publicResults.PerformanceSummary.OverallGrade = "Fair" }
                elseif ($overallScore -ge 60) { $publicResults.PerformanceSummary.OverallGrade = "Poor" }
                else { $publicResults.PerformanceSummary.OverallGrade = "Critical" }
            }
        }

        Write-Verbose "Web image performance benchmark completed successfully"
        return $publicResults
    }
    catch {
        Write-Error "Web image performance benchmark failed: $($_.Exception.Message)"
        
        # Return error result
        return [PSCustomObject]@{
            BenchmarkType = $BenchmarkType
            StartTime = Get-Date
            EndTime = Get-Date
            TotalDuration = [timespan]::Zero
            Iterations = $Iterations
            InputPath = $Path
            OutputPath = $OutputPath
            Success = $false
            ErrorMessage = $_.Exception.Message
            PerformanceSummary = @{
                OverallGrade = "Error"
                SpeedRating = "Error"
                MemoryRating = "Error"
                ScalabilityRating = "Error"
                CrossPlatformRating = "Error"
            }
            PerformanceMetrics = @{}
            Recommendations = @()
        }
    }
}
