# Validation Helpers for WebImageOptimizer
# Centralized validation functions to reduce code duplication
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Tests whether a file has a supported image format extension.

.DESCRIPTION
    Validates image file formats against a configurable list of supported extensions.
    This function centralizes format validation logic to reduce code duplication across
    the module and provides consistent error messaging.

.PARAMETER FileName
    The filename (with or without path) to validate. The function extracts and validates
    the file extension.

.PARAMETER SupportedFormats
    Array of supported file extensions including the dot (e.g., '.jpg', '.png').
    Defaults to common web image formats: JPEG, PNG, WebP, AVIF, GIF, BMP, TIFF.

.OUTPUTS
    [PSCustomObject] Validation result with the following properties:
    - IsSupported: Boolean indicating if the format is supported
    - Extension: The file extension that was validated
    - ErrorMessage: Error message if the format is unsupported (empty if supported)

.EXAMPLE
    $result = Test-SupportedImageFormat -FileName "photo.jpg"
    # Returns: IsSupported=$true, Extension=".jpg", ErrorMessage=""

.EXAMPLE
    $result = Test-SupportedImageFormat -FileName "document.txt"
    # Returns: IsSupported=$false, Extension=".txt", ErrorMessage="Unsupported file format: .txt"

.EXAMPLE
    $customFormats = @('.jpg', '.png')
    $result = Test-SupportedImageFormat -FileName "image.webp" -SupportedFormats $customFormats
    # Returns: IsSupported=$false, Extension=".webp", ErrorMessage="Unsupported file format: .webp"

.NOTES
    - Extension matching is case-insensitive
    - Files without extensions are considered unsupported
    - Thread-safe for use in parallel processing scenarios
    - Handles null/empty filenames gracefully
#>
function Test-SupportedImageFormat {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string[]]$SupportedFormats = @('.jpg', '.jpeg', '.png', '.webp', '.avif', '.gif', '.bmp', '.tiff')
    )

    try {
        # Handle null or empty filename
        if ([string]::IsNullOrEmpty($FileName)) {
            return [PSCustomObject]@{
                IsSupported = $false
                Extension = ""
                ErrorMessage = "Unsupported file format: (no extension)"
            }
        }

        # Extract file extension using System.IO.Path for reliability
        $extension = [System.IO.Path]::GetExtension($FileName)

        # Handle files without extensions
        if ([string]::IsNullOrEmpty($extension)) {
            return [PSCustomObject]@{
                IsSupported = $false
                Extension = ""
                ErrorMessage = "Unsupported file format: (no extension)"
            }
        }

        # Normalize supported formats to lowercase for case-insensitive comparison
        $normalizedSupportedFormats = $SupportedFormats | ForEach-Object { $_.ToLower() }
        $normalizedExtension = $extension.ToLower()

        # Check if the extension is in the supported formats list
        $isSupported = $normalizedExtension -in $normalizedSupportedFormats

        if ($isSupported) {
            return [PSCustomObject]@{
                IsSupported = $true
                Extension = $extension
                ErrorMessage = ""
            }
        } else {
            return [PSCustomObject]@{
                IsSupported = $false
                Extension = $extension
                ErrorMessage = "Unsupported file format: $extension"
            }
        }
    }
    catch {
        # Handle any unexpected errors gracefully
        Write-Verbose "Error in Test-SupportedImageFormat: $($_.Exception.Message)"
        return [PSCustomObject]@{
            IsSupported = $false
            Extension = ""
            ErrorMessage = "Error validating file format: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Gets the default supported image formats from configuration.

.DESCRIPTION
    Retrieves the default supported image formats, optionally from configuration files.
    This function provides a centralized way to manage supported formats across the module.

.PARAMETER ConfigurationPath
    Optional path to a configuration file containing supported formats.
    If not provided, returns hardcoded defaults.

.OUTPUTS
    [string[]] Array of supported file extensions including the dot.

.EXAMPLE
    $formats = Get-DefaultSupportedFormats
    # Returns: @('.jpg', '.jpeg', '.png', '.webp', '.avif', '.gif', '.bmp', '.tiff')

.NOTES
    - This function can be extended to read from configuration files
    - Provides a single source of truth for default supported formats
    - Used by Test-SupportedImageFormat when no custom formats are specified
#>
function Get-DefaultSupportedFormats {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationPath
    )

    # Default supported formats for web image optimization
    [string[]]$defaultFormats = @(
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.avif',
        '.gif',
        '.bmp',
        '.tiff'
    )

    # Try to load from configuration file if provided
    if ($ConfigurationPath -and (Test-Path $ConfigurationPath)) {
        try {
            Write-Verbose "Loading supported formats from configuration file: $ConfigurationPath"

            # Read and parse the JSON configuration file
            $jsonContent = Get-Content -Path $ConfigurationPath -Raw -ErrorAction Stop
            $configObject = $jsonContent | ConvertFrom-Json -ErrorAction Stop

            # Extract supported input formats from the configuration
            if ($configObject.formats -and ($configObject.formats.PSObject.Properties.Name -contains 'supportedInputFormats')) {
                $configFormats = $configObject.formats.supportedInputFormats

                # Validate that we have formats to work with
                if ($configFormats -and $configFormats.Count -gt 0) {
                    # Convert format names to include leading dots if not present
                    [string[]]$formatsWithDots = @()
                    foreach ($format in $configFormats) {
                        if ($format -and -not [string]::IsNullOrWhiteSpace($format)) {
                            # Add dot if not present, avoid double dots
                            if ($format.StartsWith('.')) {
                                $formatsWithDots += $format
                            } else {
                                $formatsWithDots += ".$format"
                            }
                        }
                    }

                    if ($formatsWithDots.Count -gt 0) {
                        Write-Verbose "Successfully loaded $($formatsWithDots.Count) supported formats from configuration"
                        return ,$formatsWithDots
                    } else {
                        Write-Warning "Configuration file contains empty or invalid formats. Using default formats."
                    }
                } else {
                    Write-Warning "Configuration file contains empty formats array. Using default formats."
                }
            } else {
                Write-Warning "Configuration file does not contain 'formats.supportedInputFormats' section. Using default formats."
            }
        }
        catch {
            Write-Warning "Failed to load configuration file '$ConfigurationPath': $($_.Exception.Message). Using default formats."
        }
    } elseif ($ConfigurationPath) {
        Write-Warning "Configuration file not found: $ConfigurationPath. Using default formats."
    }

    return ,$defaultFormats
}

<#
.SYNOPSIS
    Validates multiple files and returns a summary of format validation results.

.DESCRIPTION
    Batch validates multiple files against supported formats and provides
    summary statistics. Useful for preprocessing file collections before
    parallel processing operations.

.PARAMETER FileNames
    Array of filenames to validate.

.PARAMETER SupportedFormats
    Array of supported file extensions. Uses defaults if not specified.

.OUTPUTS
    [PSCustomObject] Summary with supported/unsupported counts and detailed results.

.EXAMPLE
    $files = @("photo.jpg", "document.txt", "image.png")
    $summary = Test-MultipleImageFormats -FileNames $files
    # Returns summary with counts and individual results

.NOTES
    - Useful for preprocessing before parallel operations
    - Provides both summary statistics and detailed per-file results
    - Thread-safe for concurrent usage
#>
function Test-MultipleImageFormats {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FileNames,

        [Parameter(Mandatory = $false)]
        [string[]]$SupportedFormats
    )

    $results = @()
    $supportedCount = 0
    $unsupportedCount = 0

    # Use default formats if none specified
    if (-not $SupportedFormats) {
        $SupportedFormats = Get-DefaultSupportedFormats
    }

    foreach ($fileName in $FileNames) {
        $result = Test-SupportedImageFormat -FileName $fileName -SupportedFormats $SupportedFormats
        $results += $result

        if ($result.IsSupported) {
            $supportedCount++
        } else {
            $unsupportedCount++
        }
    }

    return [PSCustomObject]@{
        TotalFiles = $FileNames.Count
        SupportedCount = $supportedCount
        UnsupportedCount = $unsupportedCount
        SupportedPercentage = if ($FileNames.Count -gt 0) {
            [math]::Round(($supportedCount / $FileNames.Count) * 100, 2)
        } else {
            0
        }
        Results = $results
        SupportedFormats = $SupportedFormats
    }
}
