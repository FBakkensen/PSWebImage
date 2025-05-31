# User Guide

Welcome to the WebImageOptimizer User Guide. This comprehensive guide will help you get the most out of the WebImageOptimizer PowerShell module for optimizing images for web usage.

## Overview

WebImageOptimizer is a powerful PowerShell module designed to optimize images for web usage with advanced features including:

- Multi-format image optimization (JPEG, PNG, WebP, AVIF)
- Parallel processing for high-performance batch operations
- Cross-platform support (Windows, Linux, macOS)
- Intelligent configuration management
- Comprehensive backup and recovery capabilities
- Performance monitoring and benchmarking

## Getting Started

### Prerequisites

Before using WebImageOptimizer, ensure you have:

1. **PowerShell 7.0 or higher** - Required for optimal performance
2. **ImageMagick** (recommended) - Primary processing engine
3. **.NET 6.0 or higher** - For fallback processing

### Installation

Install from PowerShell Gallery:

```powershell
Install-Module -Name WebImageOptimizer -Scope CurrentUser
Import-Module WebImageOptimizer
```

### Verify Installation

Check that the module is properly installed:

```powershell
Get-Module WebImageOptimizer -ListAvailable
Get-Command -Module WebImageOptimizer
```

## Basic Usage

### Simple Optimization

Optimize all images in a directory:

```powershell
Optimize-WebImages -Path "C:\MyImages"
```

This command will:
- Recursively scan the directory for supported image formats
- Apply default optimization settings
- Preserve the original directory structure
- Process images in-place (overwriting originals)

### Output to Different Directory

Optimize images to a separate output directory:

```powershell
Optimize-WebImages -Path "C:\Source" -OutputPath "C:\Optimized"
```

### Create Backups

Always create backups before optimization:

```powershell
Optimize-WebImages -Path "C:\Images" -CreateBackup
```

Backups are stored in timestamped directories with manifest files for integrity verification.

## Advanced Features

### Custom Quality Settings

Configure quality settings for different formats:

```powershell
$settings = @{
    jpeg = @{
        quality = 75
        progressive = $true
        stripMetadata = $true
    }
    png = @{
        compression = 8
        stripMetadata = $true
        optimize = $true
    }
    webp = @{
        quality = 85
        method = 6
        stripMetadata = $true
    }
    avif = @{
        quality = 85
        speed = 6
        stripMetadata = $true
    }
}

Optimize-WebImages -Path "C:\Images" -Settings $settings
```

### Format Filtering

Process only specific image formats:

```powershell
# Only process JPEG and PNG files
Optimize-WebImages -Path "C:\Images" -IncludeFormats @('.jpg', '.jpeg', '.png')
```

### Exclude Patterns

Skip files matching specific patterns:

```powershell
# Exclude temporary and backup files
Optimize-WebImages -Path "C:\Images" -ExcludePatterns @('*temp*', '*backup*', '*_old*')
```

### Preview Mode (WhatIf)

Preview what would be optimized without making changes:

```powershell
Optimize-WebImages -Path "C:\Images" -WhatIf
```

## Configuration

### Configuration File Structure

WebImageOptimizer uses JSON-based configuration with the following structure:

```json
{
  "defaultSettings": {
    "jpeg": { "quality": 85, "progressive": true },
    "png": { "compression": 6, "stripMetadata": true },
    "webp": { "quality": 90, "method": 6 },
    "avif": { "quality": 85, "speed": 6 }
  },
  "processing": {
    "maxThreads": 4,
    "enableParallelProcessing": true,
    "maxDimensions": { "width": 2048, "height": 2048 }
  },
  "output": {
    "preserveStructure": true,
    "createBackup": false
  }
}
```

### Configuration Priority

Configuration is loaded in the following priority order:

1. **Function Parameters** (highest priority)
2. **User Configuration File**
3. **Default Configuration**
4. **Hardcoded Fallbacks** (lowest priority)

### Custom Configuration Files

Create custom configuration files for different scenarios:

```powershell
# Use a custom configuration file
$customConfig = Get-Content "my-config.json" | ConvertFrom-Json
Optimize-WebImages -Path "C:\Images" -Settings $customConfig.defaultSettings
```

## Examples

### Example 1: Web Development Workflow

Optimize images for a web project:

```powershell
# Optimize all images in the assets directory
Optimize-WebImages -Path ".\src\assets\images" -OutputPath ".\dist\assets\images" -CreateBackup

# Custom settings for web optimization
$webSettings = @{
    jpeg = @{ quality = 80; progressive = $true }
    png = @{ compression = 7; stripMetadata = $true }
    webp = @{ quality = 85; method = 6 }
}

Optimize-WebImages -Path ".\src\assets" -OutputPath ".\dist\assets" -Settings $webSettings
```

### Example 2: Batch Processing with Filtering

Process only large images and exclude thumbnails:

```powershell
# Process only JPEG files, exclude thumbnails
Optimize-WebImages -Path "C:\Photos" -IncludeFormats @('.jpg', '.jpeg') -ExcludePatterns @('*thumb*', '*_sm*', '*_xs*')
```

### Example 3: Performance Optimization

Optimize for maximum performance:

```powershell
# Use all available CPU cores for parallel processing
$perfSettings = @{
    jpeg = @{ quality = 85; progressive = $true }
    png = @{ compression = 6; stripMetadata = $true }
}

Optimize-WebImages -Path "C:\LargeImageSet" -Settings $perfSettings -CreateBackup
```

### Example 4: E-commerce Image Processing

Optimize product images for e-commerce:

```powershell
# E-commerce optimized settings
$ecommerceSettings = @{
    jpeg = @{ quality = 85; progressive = $true; stripMetadata = $true }
    png = @{ compression = 6; stripMetadata = $true; optimize = $true }
    webp = @{ quality = 90; method = 6; stripMetadata = $true }
}

# Process product images with backup
Optimize-WebImages -Path ".\product-images" -OutputPath ".\optimized-products" -Settings $ecommerceSettings -CreateBackup

# Generate performance report
Invoke-WebImageBenchmark -Path ".\optimized-products" -BenchmarkType "Speed" -OutputFormat "JSON" -OutputPath ".\performance-report.json"
```

### Example 5: Content Management System Integration

Integrate with CMS workflows:

```powershell
# CMS upload optimization workflow
function Optimize-CMSImages {
    param(
        [string]$UploadPath,
        [string]$ProcessedPath
    )

    $cmsSettings = @{
        jpeg = @{ quality = 80; progressive = $true }
        png = @{ compression = 7; stripMetadata = $true }
        webp = @{ quality = 85; method = 6 }
    }

    $result = Optimize-WebImages -Path $UploadPath -OutputPath $ProcessedPath -Settings $cmsSettings -CreateBackup

    Write-Host "CMS Images Processed: $($result.ProcessedFiles)"
    Write-Host "Total Size Reduction: $([math]::Round($result.TotalSizeReduction / 1MB, 2)) MB"

    return $result
}

# Usage
Optimize-CMSImages -UploadPath "C:\CMS\uploads" -ProcessedPath "C:\CMS\processed"
```

## Best Practices

### 1. Always Create Backups

For important image collections, always use the `-CreateBackup` parameter:

```powershell
Optimize-WebImages -Path "C:\ImportantImages" -CreateBackup
```

### 2. Test with WhatIf First

Preview changes before applying them:

```powershell
Optimize-WebImages -Path "C:\Images" -WhatIf
```

### 3. Use Appropriate Quality Settings

- **JPEG**: 75-85 quality for most web images
- **PNG**: Compression level 6-8 for good balance
- **WebP**: 85-90 quality for high-quality web images
- **AVIF**: 80-85 quality for next-generation format

### 4. Leverage parallel processing

For large image sets, parallel processing significantly improves performance:

```powershell
# The module automatically uses parallel processing when beneficial
Optimize-WebImages -Path "C:\LargeImageSet"
```

### 5. Monitor Performance

Use the benchmarking function to monitor performance:

```powershell
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Speed"
```

## Troubleshooting

For common issues and solutions, see the [Troubleshooting Guide](Troubleshooting.md).

## Next Steps

- Review the [API Reference](API.md) for detailed function documentation
- Explore the [Configuration Guide](Configuration.md) for advanced configuration options
- Check the [Troubleshooting Guide](Troubleshooting.md) for common issues and solutions
