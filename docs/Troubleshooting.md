# Troubleshooting Guide

This guide helps you resolve common issues when using the WebImageOptimizer module.

## Common Issues

### Module Import Issues

#### Problem: Module not found after installation

**Error Message**: `Import-Module : The specified module 'WebImageOptimizer' was not loaded because no valid module file was found`

**Solution**:
1. Verify installation:
   ```powershell
   Get-Module WebImageOptimizer -ListAvailable
   ```
2. Check module path:
   ```powershell
   $env:PSModulePath -split ';'
   ```
3. Reinstall if necessary:
   ```powershell
   Install-Module WebImageOptimizer -Force -Scope CurrentUser
   ```

#### Problem: PowerShell version compatibility

**Error Message**: `This module requires PowerShell 7.0 or higher`

**Solution**:
1. Check PowerShell version:
   ```powershell
   $PSVersionTable.PSVersion
   ```
2. Install PowerShell 7:
   - Windows: Download from [PowerShell GitHub releases](https://github.com/PowerShell/PowerShell/releases)
   - Linux: Use package manager (apt, yum, etc.)
   - macOS: Use Homebrew `brew install powershell`

### Dependency Problems

#### Problem: ImageMagick not detected

**Error Message**: `ImageMagick not found. Using .NET fallback processing.`

**Solution**:
1. Install ImageMagick:
   - **Windows**: 
     ```powershell
     winget install ImageMagick.ImageMagick
     # or
     choco install imagemagick
     # or
     scoop install imagemagick
     ```
   - **Linux**: 
     ```bash
     sudo apt-get install imagemagick  # Ubuntu/Debian
     sudo yum install ImageMagick      # CentOS/RHEL
     ```
   - **macOS**: 
     ```bash
     brew install imagemagick
     ```

2. Verify installation:
   ```powershell
   magick -version
   ```

3. Test dependency detection:
   ```powershell
   Test-ImageProcessingDependencies
   ```

#### Problem: .NET image processing issues

**Error Message**: `System.Drawing.Common is not supported on this platform`

**Solution**:
1. Install required .NET runtime:
   ```powershell
   # Check .NET version
   dotnet --version
   ```
2. On Linux, install additional packages:
   ```bash
   sudo apt-get install libc6-dev libgdiplus
   ```

### Performance Issues

#### Problem: Slow processing speed

**Symptoms**: Processing takes much longer than expected

**Solutions**:
1. **Enable parallel processing** (if not already enabled):
   ```powershell
   # Parallel processing is enabled by default
   Optimize-WebImages -Path "C:\Images" -Verbose
   ```

2. **Adjust thread count** based on CPU cores:
   ```powershell
   $settings = @{
       processing = @{
           maxThreads = [Environment]::ProcessorCount
       }
   }
   ```

3. **Use ImageMagick** instead of .NET fallback:
   ```powershell
   # Ensure ImageMagick is installed and detected
   Test-ImageProcessingDependencies
   ```

4. **Process smaller batches**:
   ```powershell
   # Process subdirectories separately for very large sets
   Get-ChildItem "C:\LargeImageSet" -Directory | ForEach-Object {
       Optimize-WebImages -Path $_.FullName
   }
   ```

#### Problem: High memory usage

**Symptoms**: System becomes unresponsive during processing

**Solutions**:
1. **Reduce parallel threads**:
   ```powershell
   $settings = @{
       processing = @{
           maxThreads = 2
           enableParallelProcessing = $true
       }
   }
   ```

2. **Process in smaller batches**:
   ```powershell
   # Process files in groups
   $files = Get-ChildItem "C:\Images" -File -Recurse
   $batchSize = 50
   for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
       $batch = $files[$i..($i + $batchSize - 1)]
       # Process batch
   }
   ```

### Error Messages

#### "Access to the path is denied"

**Cause**: Insufficient permissions to read/write files

**Solution**:
1. Run PowerShell as Administrator (Windows)
2. Check file permissions:
   ```powershell
   Get-Acl "C:\Images" | Format-List
   ```
3. Use different output directory:
   ```powershell
   Optimize-WebImages -Path "C:\Images" -OutputPath "C:\Temp\Optimized"
   ```

#### "The process cannot access the file because it is being used by another process"

**Cause**: File is locked by another application

**Solution**:
1. Close applications that might be using the files
2. Use backup mode to avoid conflicts:
   ```powershell
   Optimize-WebImages -Path "C:\Images" -CreateBackup
   ```
3. Process to different output directory:
   ```powershell
   Optimize-WebImages -Path "C:\Images" -OutputPath "C:\Optimized"
   ```

#### "Invalid image format or corrupted file"

**Cause**: Unsupported or corrupted image files

**Solution**:
1. Use exclude patterns to skip problematic files:
   ```powershell
   Optimize-WebImages -Path "C:\Images" -ExcludePatterns @('*corrupted*', '*invalid*')
   ```
2. Check supported formats:
   ```powershell
   # Supported: .jpg, .jpeg, .png, .webp, .avif, .bmp, .tiff
   ```

## FAQ

### Q: Which image formats are supported?

**A**: WebImageOptimizer supports:
- **Input formats**: JPEG, PNG, WebP, AVIF, BMP, TIFF, GIF
- **Output formats**: JPEG, PNG, WebP, AVIF (with fallback options)

### Q: How do I optimize only specific file types?

**A**: Use the `-IncludeFormats` parameter:
```powershell
Optimize-WebImages -Path "C:\Images" -IncludeFormats @('.jpg', '.png')
```

### Q: Can I undo optimizations?

**A**: Yes, if you created backups:
```powershell
# Always use -CreateBackup for important images
Optimize-WebImages -Path "C:\Images" -CreateBackup
```

Backups are stored in timestamped directories with manifest files for restoration.

### Q: How do I check processing performance?

**A**: Use the benchmarking function:
```powershell
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Comprehensive"
```

### Q: What's the difference between ImageMagick and .NET processing?

**A**: 
- **ImageMagick**: Superior quality, more formats, better performance
- **.NET**: Built-in fallback, limited formats, basic optimization

### Q: How do I configure custom quality settings?

**A**: Use the `-Settings` parameter:
```powershell
$settings = @{
    jpeg = @{ quality = 75 }
    png = @{ compression = 8 }
}
Optimize-WebImages -Path "C:\Images" -Settings $settings
```

### Q: Can I process images on network drives?

**A**: Yes, but performance may be slower:
```powershell
Optimize-WebImages -Path "\\server\share\images" -OutputPath "C:\Local\Optimized"
```

### Q: How do I exclude certain files or directories?

**A**: Use the `-ExcludePatterns` parameter:
```powershell
Optimize-WebImages -Path "C:\Images" -ExcludePatterns @('*temp*', '*backup*', '*_original*')
```

### Q: What happens if processing is interrupted?

**A**: 
- Completed files remain optimized
- Incomplete files are left unchanged
- Backups (if created) remain intact
- You can safely restart processing

### Q: How do I optimize for web performance?

**A**: Use web-optimized settings:
```powershell
$webSettings = @{
    jpeg = @{ quality = 80; progressive = $true; stripMetadata = $true }
    png = @{ compression = 7; stripMetadata = $true }
    webp = @{ quality = 85; method = 6 }
}
Optimize-WebImages -Path "C:\Images" -Settings $webSettings
```

## Getting Help

### Enable Verbose Output

For detailed processing information:
```powershell
Optimize-WebImages -Path "C:\Images" -Verbose
```

### Check Module Information

```powershell
Get-Module WebImageOptimizer
Get-Command -Module WebImageOptimizer
Get-Help Optimize-WebImages -Full
```

### Performance Analysis

```powershell
# Run comprehensive benchmarks
Invoke-WebImageBenchmark -Path "C:\TestImages" -BenchmarkType "Comprehensive"

# Check system resources
Get-Process | Where-Object { $_.ProcessName -like "*powershell*" }
```

### Report Issues

If you encounter issues not covered in this guide:

1. **Gather information**:
   - PowerShell version: `$PSVersionTable`
   - Module version: `Get-Module WebImageOptimizer`
   - Error messages and stack traces
   - System information: OS, available memory, CPU cores

2. **Create minimal reproduction case**:
   ```powershell
   # Test with a single image
   Optimize-WebImages -Path "C:\SingleTestImage" -Verbose
   ```

3. **Check dependencies**:
   ```powershell
   Test-ImageProcessingDependencies
   ```

For additional support, consult the module documentation or community resources.
