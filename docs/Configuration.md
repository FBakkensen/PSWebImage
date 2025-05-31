# Configuration Guide

This guide explains how to configure the WebImageOptimizer module for optimal performance and customization.

## Overview

WebImageOptimizer uses a flexible JSON-based configuration system that allows you to customize optimization settings, processing behavior, and output options. The configuration system supports multiple sources with a clear priority hierarchy.

## Default Settings

The module includes a comprehensive default configuration file located at `WebImageOptimizer/Config/default-settings.json`:

```json
{
  "defaultSettings": {
    "jpeg": {
      "quality": 85,
      "progressive": true,
      "stripMetadata": true,
      "optimize": true
    },
    "png": {
      "compression": 6,
      "stripMetadata": true,
      "optimize": true,
      "interlace": false
    },
    "webp": {
      "quality": 90,
      "method": 6,
      "stripMetadata": true,
      "lossless": false
    },
    "avif": {
      "quality": 85,
      "speed": 6,
      "stripMetadata": true,
      "lossless": false
    }
  },
  "processing": {
    "maxThreads": 4,
    "maxDimensions": {
      "width": 2048,
      "height": 2048
    },
    "minFileSizeKB": 10,
    "enableParallelProcessing": true,
    "processingTimeout": 300,
    "retryAttempts": 3
  },
  "output": {
    "preserveStructure": true,
    "namingPattern": "{name}_optimized.{ext}",
    "createBackup": false,
    "backupDirectory": "backup",
    "overwriteOriginal": false,
    "outputDirectory": null
  }
}
```

## Configuration File Structure

### Default Settings Section

The `defaultSettings` section contains format-specific optimization parameters:

#### JPEG Settings

- **quality** (0-100): Compression quality level (default: 85)
- **progressive** (boolean): Enable progressive encoding (default: true)
- **stripMetadata** (boolean): Remove EXIF data (default: true)
- **optimize** (boolean): Enable optimization (default: true)

#### PNG Settings

- **compression** (0-9): Compression level (default: 6)
- **stripMetadata** (boolean): Remove metadata (default: true)
- **optimize** (boolean): Enable optimization (default: true)
- **interlace** (boolean): Enable interlacing (default: false)

#### WebP Settings

- **quality** (0-100): Compression quality (default: 90)
- **method** (0-6): Compression method (default: 6)
- **stripMetadata** (boolean): Remove metadata (default: true)
- **lossless** (boolean): Use lossless compression (default: false)

#### AVIF Settings

- **quality** (0-100): Compression quality (default: 85)
- **speed** (0-10): Encoding speed vs quality tradeoff (default: 6)
- **stripMetadata** (boolean): Remove metadata (default: true)
- **lossless** (boolean): Use lossless compression (default: false)

### Processing Section

Controls how images are processed:

- **maxThreads** (integer): Maximum parallel threads (default: 4)
- **maxDimensions** (object): Maximum image dimensions
  - **width** (integer): Maximum width in pixels (default: 2048)
  - **height** (integer): Maximum height in pixels (default: 2048)
- **minFileSizeKB** (integer): Minimum file size to process (default: 10)
- **enableParallelProcessing** (boolean): Enable parallel processing (default: true)
- **processingTimeout** (integer): Timeout in seconds (default: 300)
- **retryAttempts** (integer): Number of retry attempts (default: 3)

### Output Section

Controls output behavior:

- **preserveStructure** (boolean): Maintain directory structure (default: true)
- **namingPattern** (string): File naming pattern (default: "{name}_optimized.{ext}")
- **createBackup** (boolean): Create backups by default (default: false)
- **backupDirectory** (string): Backup directory name (default: "backup")
- **overwriteOriginal** (boolean): Overwrite original files (default: false)
- **outputDirectory** (string): Default output directory (default: null)

## Loading Priority

Configuration is loaded in the following priority order (highest to lowest):

1. **Function Parameters** - Settings passed directly to Optimize-WebImages
2. **User Configuration File** - Custom configuration files
3. **Default Configuration** - Built-in default-settings.json
4. **Hardcoded Fallbacks** - Emergency fallback values

## Custom Configuration

### Creating Custom Configuration Files

Create custom configuration files for different scenarios:

#### Web Development Configuration

```json
{
  "defaultSettings": {
    "jpeg": {
      "quality": 80,
      "progressive": true,
      "stripMetadata": true
    },
    "png": {
      "compression": 7,
      "stripMetadata": true,
      "optimize": true
    },
    "webp": {
      "quality": 85,
      "method": 6,
      "stripMetadata": true
    }
  },
  "processing": {
    "maxThreads": 8,
    "enableParallelProcessing": true
  },
  "output": {
    "preserveStructure": true,
    "createBackup": true
  }
}
```

#### High-Quality Configuration

```json
{
  "defaultSettings": {
    "jpeg": {
      "quality": 95,
      "progressive": true,
      "stripMetadata": false
    },
    "png": {
      "compression": 3,
      "stripMetadata": false,
      "optimize": true
    },
    "webp": {
      "quality": 95,
      "method": 6,
      "lossless": false
    }
  },
  "processing": {
    "maxThreads": 2,
    "enableParallelProcessing": false
  }
}
```

### Using Custom Configuration

#### Method 1: Function Parameters

```powershell
$customSettings = @{
    jpeg = @{ quality = 75; progressive = $true }
    png = @{ compression = 8; stripMetadata = $true }
}

Optimize-WebImages -Path "C:\Images" -Settings $customSettings
```

#### Method 2: Configuration File

```powershell
# Load custom configuration from file
$config = Get-Content "custom-config.json" | ConvertFrom-Json
Optimize-WebImages -Path "C:\Images" -Settings $config.defaultSettings
```

## Examples

### Example 1: Performance-Optimized Configuration

For maximum processing speed:

```powershell
$perfConfig = @{
    jpeg = @{ quality = 85; progressive = $true }
    png = @{ compression = 6; stripMetadata = $true }
}

Optimize-WebImages -Path "C:\Images" -Settings $perfConfig
```

### Example 2: Quality-Focused Configuration

For maximum image quality:

```powershell
$qualityConfig = @{
    jpeg = @{ quality = 95; progressive = $true; stripMetadata = $false }
    png = @{ compression = 3; stripMetadata = $false }
    webp = @{ quality = 95; method = 6 }
}

Optimize-WebImages -Path "C:\Images" -Settings $qualityConfig
```

### Example 3: Size-Optimized Configuration

For maximum file size reduction:

```powershell
$sizeConfig = @{
    jpeg = @{ quality = 70; progressive = $true; stripMetadata = $true }
    png = @{ compression = 9; stripMetadata = $true }
    webp = @{ quality = 80; method = 6 }
}

Optimize-WebImages -Path "C:\Images" -Settings $sizeConfig
```

### Example 4: Batch Processing Configuration

For large batch operations:

```powershell
$batchConfig = @{
    jpeg = @{ quality = 80; progressive = $true }
    png = @{ compression = 7; stripMetadata = $true }
}

# Process with parallel processing enabled
Optimize-WebImages -Path "C:\LargeImageSet" -Settings $batchConfig
```

## Configuration Validation

The module automatically validates configuration settings and provides fallbacks for invalid values:

- **Quality values** are clamped to valid ranges (0-100)
- **Compression levels** are validated for each format
- **Thread counts** are limited to available CPU cores
- **Invalid settings** trigger warnings and use defaults

## Best Practices

### 1. Test Configuration Changes

Always test configuration changes with a small set of images first:

```powershell
Optimize-WebImages -Path "C:\TestImages" -Settings $newConfig -WhatIf
```

### 2. Use Format-Appropriate Settings

- **JPEG**: Focus on quality vs file size balance
- **PNG**: Optimize compression for file type (photos vs graphics)
- **WebP**: Leverage superior compression for web delivery
- **AVIF**: Use for next-generation web applications

### 3. Consider Processing Resources

Adjust parallel processing settings based on available system resources:

```powershell
# For systems with limited resources
$lightConfig = @{
    processing = @{
        maxThreads = 2
        enableParallelProcessing = $true
    }
}
```

### 4. Backup Important Images

Always enable backups for irreplaceable image collections:

```powershell
$safeConfig = @{
    output = @{
        createBackup = $true
        preserveStructure = $true
    }
}
```

## Troubleshooting Configuration

For configuration-related issues, see the [Troubleshooting Guide](Troubleshooting.md#configuration-issues).
