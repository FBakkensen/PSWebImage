# Optimize-WebImages Main Function for WebImageOptimizer
# Primary exported function that orchestrates all processing components
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Optimizes images for web usage with comprehensive processing capabilities.

.DESCRIPTION
    The main function that orchestrates image optimization processing using multiple
    engines and advanced features. Supports batch processing, parallel execution,
    backup creation, and comprehensive reporting. Leverages PowerShell 7's enhanced
    parameter features and cross-platform capabilities.

.PARAMETER Path
    The path to the directory containing images to optimize. This parameter is mandatory.

.PARAMETER OutputPath
    The path where optimized images should be saved. If not specified, images are
    optimized in place or according to configuration settings.

.PARAMETER Settings
    Hashtable containing optimization settings that override default configuration.
    Supports format-specific settings for JPEG, PNG, WebP, and AVIF.

.PARAMETER IncludeFormats
    Array of file extensions to include in processing. If not specified, all
    supported formats are processed.

.PARAMETER ExcludePatterns
    Array of file name patterns to exclude from processing.

.PARAMETER CreateBackup
    If specified, creates timestamped backups of original images before optimization.

.OUTPUTS
    [PSCustomObject] Processing results including success/error counts, timing, and summary information.

.EXAMPLE
    Optimize-WebImages -Path "C:\Images"
    Optimizes all supported images in the specified directory using default settings.

.EXAMPLE
    Optimize-WebImages -Path "C:\Images" -OutputPath "C:\Optimized" -CreateBackup
    Optimizes images to a different directory and creates backups of originals.

.EXAMPLE
    $settings = @{ jpeg = @{ quality = 75 }; png = @{ compression = 8 } }
    Optimize-WebImages -Path "C:\Images" -Settings $settings -WhatIf
    Shows what would be optimized with custom quality settings.

.NOTES
    Requires PowerShell 7.0 or higher for optimal performance and cross-platform support.
    Supports ImageMagick and .NET fallback processing engines.
#>
function Optimize-WebImages {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $false)]
        [string[]]$IncludeFormats,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )

    begin {
        Write-Verbose "Starting Optimize-WebImages function"
        $startTime = Get-Date

        # Initialize result object
        $result = [PSCustomObject]@{
            Success = $false
            FilesProcessed = 0
            FilesSkipped = 0
            ErrorCount = 0
            ProcessingTime = [timespan]::Zero
            TotalProcessingTime = [timespan]::Zero
            ConfigurationUsed = $null
            BackupCreated = $false
            BackupPath = $null
            Summary = $null
            Errors = @()
            ProcessingEngine = "Auto"
            Platform = if ($PSVersionTable.PSVersion.Major -ge 6) {
                if ($IsWindows) { "Windows" }
                elseif ($IsLinux) { "Linux" }
                elseif ($IsMacOS) { "macOS" }
                else { "Unknown" }
            } else { "Windows" }
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            ProcessingMode = "Sequential"
        }
    }

    process {
        try {
            # Step 1: Validate input path
            Write-Verbose "Validating input path: $Path"
            if (-not (Test-Path -Path $Path -PathType Container)) {
                throw "Input path does not exist or is not a directory: $Path"
            }

            $resolvedInputPath = Resolve-Path -Path $Path
            Write-Verbose "Resolved input path: $resolvedInputPath"

            # Step 2: Load and merge configuration
            Write-Verbose "Loading configuration"
            try {
                $defaultConfig = Get-DefaultConfiguration
                $parameterConfig = @{}

                if ($Settings) {
                    $parameterConfig.defaultSettings = $Settings
                }

                $mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -ParameterConfig $parameterConfig
                $result.ConfigurationUsed = $mergedConfig
                Write-Verbose "Configuration loaded and merged successfully"
            }
            catch {
                Write-Warning "Failed to load configuration, using fallback settings: $($_.Exception.Message)"
                $mergedConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 85; progressive = $true }
                        png = @{ compression = 6; stripMetadata = $true }
                    }
                    processing = @{
                        maxThreads = 4
                        enableParallelProcessing = $true
                    }
                    output = @{
                        createBackup = $CreateBackup.IsPresent
                        preserveStructure = $true
                    }
                }
                $result.ConfigurationUsed = $mergedConfig
            }

            # Step 3: Test dependencies
            Write-Verbose "Testing image processing dependencies"
            try {
                $dependencyInfo = Test-ImageProcessingDependencies
                $processingEngine = $dependencyInfo.RecommendedEngine
                $result.ProcessingEngine = $processingEngine
                Write-Verbose "Using processing engine: $processingEngine"
            }
            catch {
                Write-Warning "Dependency detection failed, using fallback: $($_.Exception.Message)"
                $processingEngine = "Auto"
                $result.ProcessingEngine = $processingEngine
            }

            # Step 4: Discover image files
            Write-Verbose "Discovering image files"
            $discoveryParams = @{
                Path = $resolvedInputPath
                Recurse = $true
            }

            if ($IncludeFormats) {
                $discoveryParams.SupportedFormats = $IncludeFormats
            }

            if ($ExcludePatterns) {
                $discoveryParams.ExcludePatterns = $ExcludePatterns
            }

            $imageFiles = Get-ImageFiles @discoveryParams

            if (-not $imageFiles -or $imageFiles.Count -eq 0) {
                Write-Warning "No image files found in the specified path"
                $result.Success = $true  # Not an error, just no files to process
                $result.Summary = "No image files found to process"
                # Don't return here - let it fall through to the end block
            }
            else {
                Write-Verbose "Found $($imageFiles.Count) image files to process"

            # Convert FileInfo objects to the format expected by parallel processing
            $imageFileObjects = $imageFiles | ForEach-Object {
                # Calculate relative path from input directory to preserve structure
                try {
                    # Use PowerShell 7's GetRelativePath for robust path calculation
                    $relativePath = [System.IO.Path]::GetRelativePath($resolvedInputPath, $_.FullName)
                } catch {
                    # Fallback for older PowerShell versions or path issues
                    $inputPathString = $resolvedInputPath.ToString().TrimEnd('\', '/')
                    if ($_.FullName.StartsWith($inputPathString)) {
                        $relativePath = $_.FullName.Substring($inputPathString.Length).TrimStart('\', '/')
                    } else {
                        $relativePath = $_.Name
                    }
                }
                [PSCustomObject]@{
                    FullName = $_.FullName
                    Name = $_.Name
                    Extension = $_.Extension
                    Length = $_.Length
                    RelativePath = $relativePath
                }
            }

            # Step 5: Determine output path
            $effectiveOutputPath = if ($OutputPath) {
                $OutputPath
            } elseif ($mergedConfig.output.outputDirectory) {
                $mergedConfig.output.outputDirectory
            } else {
                $resolvedInputPath  # In-place optimization
            }

            Write-Verbose "Using output path: $effectiveOutputPath"

            # Step 6: Create backup if requested
            if ($CreateBackup -or $mergedConfig.output.createBackup) {
                if ($PSCmdlet.ShouldProcess("Original images", "Create backup")) {
                    Write-Verbose "Creating backup of original images"
                    try {
                        $backupResult = Backup-OriginalImages -FilePaths ($imageFiles | ForEach-Object { $_.FullName }) -Configuration $mergedConfig
                        if ($backupResult.Success) {
                            $result.BackupCreated = $true
                            $result.BackupPath = $backupResult.BackupDirectory
                            Write-Verbose "Backup created successfully at: $($result.BackupPath)"
                        }
                    }
                    catch {
                        Write-Warning "Backup creation failed: $($_.Exception.Message)"
                        # Continue processing even if backup fails
                    }
                }
            }

            # Step 7: Process images
            if ($PSCmdlet.ShouldProcess("$($imageFiles.Count) image files", "Optimize")) {
                Write-Verbose "Starting image processing"

                # Prepare processing parameters
                $processingParams = @{
                    ImageFiles = $imageFileObjects
                    OutputPath = $effectiveOutputPath
                    Settings = $mergedConfig.defaultSettings
                    ProcessingEngine = $processingEngine
                }

                # Add parallel processing settings if enabled
                if ($mergedConfig.processing.enableParallelProcessing) {
                    $processingParams.ThrottleLimit = $mergedConfig.processing.maxThreads
                    $result.ProcessingMode = "Parallel"
                }

                # Execute processing
                $processingResult = Invoke-ParallelImageProcessing @processingParams

                # Update result with processing information
                $result.FilesProcessed = $processingResult.SuccessCount
                $result.FilesSkipped = $processingResult.SkippedCount
                $result.ErrorCount = $processingResult.ErrorCount
                $result.Errors = $processingResult.Errors
                $result.Success = $processingResult.SuccessCount -gt 0

                Write-Verbose "Processing completed: $($result.FilesProcessed) processed, $($result.ErrorCount) errors"
            }
            else {
                # WhatIf mode - just report what would be done
                Write-Host "What if: Would process $($imageFiles.Count) image files" -ForegroundColor Yellow
                Write-Host "What if: Input path: $resolvedInputPath" -ForegroundColor Yellow
                Write-Host "What if: Output path: $effectiveOutputPath" -ForegroundColor Yellow
                Write-Host "What if: Processing engine: $processingEngine" -ForegroundColor Yellow
                Write-Host "What if: Backup would be created: $($CreateBackup -or $mergedConfig.output.createBackup)" -ForegroundColor Yellow

                $result.Success = $true
                $result.FilesProcessed = 0
                $result.Summary = "WhatIf: Would process $($imageFiles.Count) image files"
                # Don't return here - let it fall through to the end block
            }

            # Step 8: Generate summary report
            Write-Verbose "Generating summary report"
            try {
                if ($result.FilesProcessed -gt 0) {
                    # Create processing results for reporting (simplified for main function)
                    $reportResults = @(
                        [PSCustomObject]@{
                            FileName = "Summary"
                            Success = $result.Success
                            ProcessingTime = $result.ProcessingTime
                            FilesProcessed = $result.FilesProcessed
                            ErrorCount = $result.ErrorCount
                        }
                    )

                    $summaryReport = Write-OptimizationReport -ProcessingResults $reportResults -OutputFormat 'Console'
                    $result.Summary = $summaryReport
                }
                else {
                    $result.Summary = "No files were processed"
                }
            }
            catch {
                Write-Warning "Failed to generate summary report: $($_.Exception.Message)"
                $result.Summary = "Processing completed but summary generation failed"
            }

            } # End of else block for processing files
        }
        catch {
            $result.Success = $false
            $result.Errors += $_.Exception.Message
            Write-Error "Optimize-WebImages failed: $($_.Exception.Message)"
            throw
        }
        finally {
            $result.ProcessingTime = (Get-Date) - $startTime
            $result.TotalProcessingTime = $result.ProcessingTime
            Write-Verbose "Total processing time: $($result.ProcessingTime.TotalSeconds) seconds"
        }
    }

    end {
        Write-Verbose "Optimize-WebImages function completed"
        return $result
    }
}
