# Image File Discovery Engine for WebImageOptimizer
# Recursively discovers image files with filtering capabilities
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Recursively discovers image files in a directory with filtering capabilities.

.DESCRIPTION
    Scans directories for image files, supporting recursive traversal, include/exclude pattern filtering,
    and automatic format detection. Returns structured file information including metadata.

.PARAMETER Path
    The root directory path to scan for image files.

.PARAMETER Recurse
    When specified, recursively scans all subdirectories.

.PARAMETER IncludePatterns
    Array of wildcard patterns to include. Only files matching these patterns will be returned.

.PARAMETER ExcludePatterns
    Array of wildcard patterns to exclude. Files matching these patterns will be filtered out.

.PARAMETER SupportedFormats
    Array of supported image file extensions. Defaults to common web image formats.

.OUTPUTS
    [System.IO.FileInfo[]] Array of FileInfo objects representing discovered image files.

.EXAMPLE
    Get-ImageFiles -Path "C:\Images" -Recurse
    Recursively finds all image files in C:\Images and subdirectories.

.EXAMPLE
    Get-ImageFiles -Path "C:\Images" -IncludePatterns "photo_*" -ExcludePatterns "*backup*"
    Finds image files starting with "photo_" but excludes any containing "backup".

.EXAMPLE
    Get-ImageFiles -Path "C:\Images" -SupportedFormats @('.jpg', '.png', '.webp')
    Finds only JPEG, PNG, and WebP files.
#>
function Get-ImageFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [string[]]$IncludePatterns,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns,

        [Parameter(Mandatory = $false)]
        [string[]]$SupportedFormats = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp')
    )

    begin {
        Write-Verbose "Starting image file discovery in path: $Path"
        Write-Verbose "Recursive scan: $($Recurse.IsPresent)"
        Write-Verbose "Supported formats: $($SupportedFormats -join ', ')"

        if ($IncludePatterns) {
            Write-Verbose "Include patterns: $($IncludePatterns -join ', ')"
        }

        if ($ExcludePatterns) {
            Write-Verbose "Exclude patterns: $($ExcludePatterns -join ', ')"
        }

        # Normalize supported formats to lowercase for case-insensitive comparison
        $normalizedFormats = $SupportedFormats | ForEach-Object { $_.ToLower() }
    }

    process {
        try {
            # Validate and resolve input path
            if (-not (Test-Path -Path $Path)) {
                Write-Warning "Path does not exist: $Path"
                return @()
            }

            $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
            if (-not (Test-Path -Path $resolvedPath -PathType Container)) {
                Write-Warning "Path is not a directory: $Path"
                return @()
            }

            # Use resolved path for consistency
            $Path = $resolvedPath.Path

            # Get all files based on recursion setting
            $searchParams = @{
                Path = $Path
                File = $true
                ErrorAction = 'SilentlyContinue'
            }

            if ($Recurse) {
                $searchParams.Recurse = $true
            }

            Write-Verbose "Scanning for files..."
            $allFiles = Get-ChildItem @searchParams

            if (-not $allFiles) {
                Write-Verbose "No files found in the specified path"
                return @()
            }

            Write-Verbose "Found $($allFiles.Count) total files"

            # Filter by supported image formats (case-insensitive)
            $imageFiles = $allFiles | Where-Object {
                $extension = $_.Extension.ToLower()
                $normalizedFormats -contains $extension
            }

            Write-Verbose "Found $($imageFiles.Count) image files after format filtering"

            if (-not $imageFiles) {
                Write-Verbose "No image files found matching supported formats"
                return @()
            }

            # Apply include patterns if specified (optimized with Where-Object)
            if ($IncludePatterns) {
                $imageFiles = $imageFiles | Where-Object {
                    $fileName = $_.Name
                    $IncludePatterns | Where-Object { $fileName -like $_ } | Select-Object -First 1
                }
                Write-Verbose "Found $($imageFiles.Count) image files after include pattern filtering"
            }

            # Apply exclude patterns if specified (optimized with Where-Object)
            if ($ExcludePatterns) {
                $imageFiles = $imageFiles | Where-Object {
                    $fileName = $_.Name
                    -not ($ExcludePatterns | Where-Object { $fileName -like $_ } | Select-Object -First 1)
                }
                Write-Verbose "Found $($imageFiles.Count) image files after exclude pattern filtering"
            }

            # Return the filtered image files
            Write-Verbose "Image file discovery completed. Returning $($imageFiles.Count) files"
            return $imageFiles
        }
        catch {
            Write-Error "Error during image file discovery: $($_.Exception.Message)"
            return @()
        }
    }

    end {
        Write-Verbose "Image file discovery process completed"
    }
}

<#
.SYNOPSIS
    Gets detailed metadata information for image files.

.DESCRIPTION
    Extracts detailed metadata from image files including dimensions, format information,
    and file properties. This function complements Get-ImageFiles by providing additional
    metadata beyond basic file system information.

.PARAMETER ImageFiles
    Array of FileInfo objects representing image files to analyze.

.OUTPUTS
    [PSCustomObject[]] Array of objects containing detailed image metadata.

.EXAMPLE
    $images = Get-ImageFiles -Path "C:\Images" -Recurse
    $metadata = Get-ImageFileMetadata -ImageFiles $images
    Gets detailed metadata for all discovered image files.
#>
function Get-ImageFileMetadata {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.FileInfo[]]$ImageFiles
    )

    begin {
        Write-Verbose "Starting image metadata extraction"
        $results = @()
    }

    process {
        foreach ($file in $ImageFiles) {
            try {
                Write-Verbose "Extracting metadata for: $($file.Name)"

                # Create metadata object with basic file information
                $metadata = [PSCustomObject]@{
                    FullName = $file.FullName
                    Name = $file.Name
                    Extension = $file.Extension
                    Length = $file.Length
                    LengthKB = [Math]::Round($file.Length / 1KB, 2)
                    LengthMB = [Math]::Round($file.Length / 1MB, 2)
                    CreationTime = $file.CreationTime
                    LastWriteTime = $file.LastWriteTime
                    Directory = $file.Directory.FullName
                    RelativePath = $file.FullName.Replace($file.Directory.Root.FullName, '')
                    Format = $file.Extension.TrimStart('.').ToUpper()
                    IsReadOnly = $file.IsReadOnly
                }

                # TODO: Add image-specific metadata extraction (dimensions, color depth, etc.)
                # This would require image processing libraries and will be implemented in later tasks

                $results += $metadata
            }
            catch {
                Write-Warning "Failed to extract metadata for file '$($file.FullName)': $($_.Exception.Message)"

                # Create minimal metadata object for failed files
                $metadata = [PSCustomObject]@{
                    FullName = $file.FullName
                    Name = $file.Name
                    Extension = $file.Extension
                    Length = $file.Length
                    Error = $_.Exception.Message
                }

                $results += $metadata
            }
        }
    }

    end {
        Write-Verbose "Image metadata extraction completed for $($results.Count) files"
        return $results
    }
}
