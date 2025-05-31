# API Reference

This document provides detailed API reference for all public functions in the WebImageOptimizer module.

## Optimize-WebImages

The main function for optimizing images for web usage with comprehensive processing capabilities.

### Synopsis

```powershell
Optimize-WebImages [-Path] <String> [[-OutputPath] <String>] [[-Settings] <Hashtable>]
                   [[-IncludeFormats] <String[]>] [[-ExcludePatterns] <String[]>]
                   [-CreateBackup] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Description

The primary function that orchestrates image optimization processing using multiple engines and advanced features. Supports batch processing, parallel execution, backup creation, and comprehensive reporting. Leverages PowerShell 7's enhanced parameter features and cross-platform capabilities.

### Parameters

#### -Path (Mandatory)

**Type**: `String`
**Position**: 0
**Pipeline Input**: False
**Mandatory**: True

The path to the directory containing images to optimize. This parameter is mandatory and specifies the root directory for recursive image discovery.

**Example**:
```powershell
Optimize-WebImages -Path "C:\Images"
```

#### -OutputPath (Optional)

**Type**: `String`
**Position**: 1
**Pipeline Input**: False
**Mandatory**: False

The path where optimized images should be saved. If not specified, images are optimized in-place (overwriting originals). When specified, the original directory structure is preserved in the output location.

**Example**:
```powershell
Optimize-WebImages -Path "C:\Source" -OutputPath "C:\Optimized"
```

#### -Settings (Optional)

**Type**: `Hashtable`
**Position**: 2
**Pipeline Input**: False
**Mandatory**: False

Custom optimization settings for different image formats. Overrides default configuration settings. The hashtable should contain format-specific settings for jpeg, png, webp, and avif.

**Example**:
```powershell
$settings = @{
    jpeg = @{ quality = 75; progressive = $true }
    png = @{ compression = 8; stripMetadata = $true }
}
Optimize-WebImages -Path "C:\Images" -Settings $settings
```

#### -IncludeFormats (Optional)

**Type**: `String[]`
**Position**: 3
**Pipeline Input**: False
**Mandatory**: False

Array of file extensions to include in processing. Only files with these extensions will be processed. Extensions should include the dot (e.g., '.jpg', '.png').

**Example**:
```powershell
Optimize-WebImages -Path "C:\Images" -IncludeFormats @('.jpg', '.png', '.webp')
```

#### -ExcludePatterns (Optional)

**Type**: `String[]`
**Position**: 4
**Pipeline Input**: False
**Mandatory**: False

Array of wildcard patterns for files to exclude from processing. Files matching any of these patterns will be skipped.

**Example**:
```powershell
Optimize-WebImages -Path "C:\Images" -ExcludePatterns @('*temp*', '*backup*')
```

#### -CreateBackup (Optional)

**Type**: `SwitchParameter`
**Pipeline Input**: False
**Mandatory**: False

When specified, creates timestamped backups of original images before optimization. Backups include manifest files for integrity verification.

**Example**:
```powershell
Optimize-WebImages -Path "C:\Images" -CreateBackup
```

#### -WhatIf (Optional)

**Type**: `SwitchParameter`
**Pipeline Input**: False
**Mandatory**: False

Shows what would happen if the command runs without actually performing any optimization. Useful for previewing changes before applying them.

**Example**:
```powershell
Optimize-WebImages -Path "C:\Images" -WhatIf
```

### Return Values

**Type**: `PSCustomObject`

Returns a comprehensive result object containing:

- **ProcessedFiles**: Number of files successfully processed
- **SkippedFiles**: Number of files skipped
- **ErrorFiles**: Number of files that encountered errors
- **TotalSizeReduction**: Total size reduction achieved
- **ProcessingTime**: Time taken for processing
- **ProcessingMode**: Processing mode used (Sequential/Parallel)
- **ProcessingEngine**: Engine used for optimization
- **ConfigurationUsed**: Configuration settings applied
- **BackupLocation**: Location of backups (if created)

### Examples

#### Example 1: Basic Optimization

```powershell
Optimize-WebImages -Path "C:\Images"
```

Optimizes all supported images in the specified directory using default settings.

#### Example 2: Custom Output Directory

```powershell
Optimize-WebImages -Path "C:\Images" -OutputPath "C:\Optimized" -CreateBackup
```

Optimizes images to a different directory and creates backups of originals.

#### Example 3: Custom Quality Settings

```powershell
$settings = @{
    jpeg = @{ quality = 75 }
    png = @{ compression = 8 }
}
Optimize-WebImages -Path "C:\Images" -Settings $settings -WhatIf
```

Shows what would be optimized with custom quality settings.

#### Example 4: Format-Specific Processing

```powershell
Optimize-WebImages -Path "C:\Images" -IncludeFormats @('.jpg', '.jpeg') -ExcludePatterns @('*thumb*')
```

Processes only JPEG files while excluding thumbnails.

#### Example 5: Advanced Workflow Integration

```powershell
# Complete workflow with error handling and reporting
try {
    $settings = @{
        jpeg = @{ quality = 80; progressive = $true; stripMetadata = $true }
        png = @{ compression = 7; stripMetadata = $true; optimize = $true }
        webp = @{ quality = 85; method = 6; stripMetadata = $true }
    }

    $result = Optimize-WebImages -Path "C:\ProjectImages" -OutputPath "C:\OptimizedImages" -Settings $settings -CreateBackup -Verbose

    # Generate summary report
    $report = @{
        ProcessedFiles = $result.ProcessedFiles
        SkippedFiles = $result.SkippedFiles
        ErrorFiles = $result.ErrorFiles
        SizeReduction = "$([math]::Round($result.TotalSizeReduction / 1MB, 2)) MB"
        ProcessingTime = $result.ProcessingTime
        Engine = $result.ProcessingEngine
    }

    $report | ConvertTo-Json | Out-File "optimization-report.json"
    Write-Host "Optimization completed successfully. Report saved to optimization-report.json"
}
catch {
    Write-Error "Optimization failed: $($_.Exception.Message)"
}
```

#### Example 6: Conditional Processing

```powershell
# Process images based on file size and age
$largeImageSettings = @{
    jpeg = @{ quality = 75; progressive = $true }
    png = @{ compression = 8; stripMetadata = $true }
}

$smallImageSettings = @{
    jpeg = @{ quality = 85; progressive = $true }
    png = @{ compression = 6; stripMetadata = $true }
}

# Get image files and categorize by size
$images = Get-ChildItem "C:\Images" -Recurse -Include "*.jpg", "*.png"
$largeImages = $images | Where-Object { $_.Length -gt 1MB }
$smallImages = $images | Where-Object { $_.Length -le 1MB }

# Process with different settings
if ($largeImages) {
    Optimize-WebImages -Path ($largeImages | Select-Object -First 1).DirectoryName -Settings $largeImageSettings
}
if ($smallImages) {
    Optimize-WebImages -Path ($smallImages | Select-Object -First 1).DirectoryName -Settings $smallImageSettings
}
```

## Invoke-WebImageBenchmark

Executes comprehensive performance benchmarks for web image optimization.

### Synopsis

```powershell
Invoke-WebImageBenchmark [-Path] <String> [[-BenchmarkType] <String>] [[-ImageCount] <Int32>]
                         [[-OutputFormat] <String>] [[-OutputPath] <String>] [<CommonParameters>]
```

### Description

Runs detailed performance benchmarks to measure processing speed, memory usage, scalability, and cross-platform performance. Provides comprehensive analysis and optimization recommendations for the WebImageOptimizer module.

### Parameters

#### -Path (Mandatory)

**Type**: `String`
**Position**: 0
**Pipeline Input**: False
**Mandatory**: True

Path to the directory containing images to benchmark.

#### -BenchmarkType (Optional)

**Type**: `String`
**Position**: 1
**Pipeline Input**: False
**Mandatory**: False
**ValidateSet**: 'Speed', 'Memory', 'Scalability', 'CrossPlatform', 'Comprehensive'
**Default**: 'Comprehensive'

Type of benchmark to execute. Options include:
- **Speed**: Processing speed benchmarks
- **Memory**: Memory usage analysis
- **Scalability**: Multi-core scaling tests
- **CrossPlatform**: Platform compatibility tests
- **Comprehensive**: All benchmark types

#### -ImageCount (Optional)

**Type**: `Int32`
**Position**: 2
**Pipeline Input**: False
**Mandatory**: False
**Default**: 100

Number of test images to use for benchmarking.

#### -OutputFormat (Optional)

**Type**: `String`
**Position**: 3
**Pipeline Input**: False
**Mandatory**: False
**ValidateSet**: 'Console', 'JSON', 'CSV', 'XML', 'HTML'
**Default**: 'Console'

Output format for benchmark results.

#### -OutputPath (Optional)

**Type**: `String`
**Position**: 4
**Pipeline Input**: False
**Mandatory**: False

Path where benchmark results should be saved (for non-Console output formats).

### Return Values

**Type**: `PSCustomObject`

Returns benchmark results including:

- **BenchmarkType**: Type of benchmark executed
- **ProcessingSpeed**: Images processed per minute
- **MemoryUsage**: Peak memory usage during processing
- **ScalingEfficiency**: Multi-core scaling percentage
- **Recommendations**: Performance optimization recommendations
- **DetailedResults**: Comprehensive benchmark data

### Examples

#### Example 1: Basic Speed Benchmark

```powershell
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Speed"
```

#### Example 2: Comprehensive Benchmark with JSON Output

```powershell
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Comprehensive" -OutputFormat "JSON" -OutputPath "C:\Results\benchmark.json"
```

#### Example 3: Memory Usage Analysis

```powershell
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Memory" -ImageCount 500
```

## Notes

- Requires PowerShell 7.0 or higher for optimal performance and cross-platform support
- Supports ImageMagick and .NET fallback processing engines
- All functions support common parameters including -Verbose, -Debug, and -ErrorAction
- Functions are designed to work seamlessly across Windows, Linux, and macOS platforms
