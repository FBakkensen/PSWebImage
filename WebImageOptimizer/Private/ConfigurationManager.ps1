# Configuration Management System for WebImageOptimizer
# Handles loading, validation, and merging of configuration from multiple sources
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Loads the default configuration from the JSON file.

.DESCRIPTION
    Reads the default-settings.json file and returns the configuration as a hashtable.
    This function provides the base configuration that can be overridden by user settings.

.OUTPUTS
    [hashtable] The default configuration settings

.EXAMPLE
    $defaultConfig = Get-DefaultConfiguration
    Write-Host "Default JPEG quality: $($defaultConfig.defaultSettings.jpeg.quality)"
#>
function Get-DefaultConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    try {
        # Get the path to the default configuration file
        $configPath = Join-Path $PSScriptRoot "..\Config\default-settings.json"
        $resolvedPath = Resolve-Path $configPath -ErrorAction Stop

        Write-Verbose "Loading default configuration from: $resolvedPath"

        # Read and parse the JSON configuration
        $jsonContent = Get-Content -Path $resolvedPath -Raw -ErrorAction Stop
        $configObject = $jsonContent | ConvertFrom-Json -ErrorAction Stop

        # Convert PSCustomObject to hashtable for easier manipulation
        $config = ConvertTo-Hashtable -InputObject $configObject

        Write-Verbose "Successfully loaded default configuration with $($config.Keys.Count) sections"
        return $config
    }
    catch {
        Write-Error "Failed to load default configuration: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Loads user-specific configuration from a JSON file.

.DESCRIPTION
    Attempts to load configuration from a user-specified JSON file.
    Returns null if the file doesn't exist or cannot be parsed.

.PARAMETER Path
    The path to the user configuration JSON file.

.OUTPUTS
    [hashtable] The user configuration settings, or $null if file doesn't exist

.EXAMPLE
    $userConfig = Get-UserConfiguration -Path "C:\Users\John\.webimageoptimizer\config.json"
#>
function Get-UserConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "User configuration file not found: $Path"
            return $null
        }

        Write-Verbose "Loading user configuration from: $Path"

        # Read and parse the JSON configuration
        $jsonContent = Get-Content -Path $Path -Raw -ErrorAction Stop
        $configObject = $jsonContent | ConvertFrom-Json -ErrorAction Stop

        # Convert PSCustomObject to hashtable
        $config = ConvertTo-Hashtable -InputObject $configObject

        Write-Verbose "Successfully loaded user configuration with $($config.Keys.Count) sections"
        return $config
    }
    catch {
        Write-Warning "Failed to load user configuration from '$Path': $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Validates that a configuration object contains all required settings.

.DESCRIPTION
    Checks that the configuration hashtable contains all required sections and settings
    needed for the image optimization process.

.PARAMETER Configuration
    The configuration hashtable to validate.

.OUTPUTS
    [bool] True if the configuration is valid, false otherwise

.EXAMPLE
    $isValid = Test-ConfigurationValid -Configuration $config
    if (-not $isValid) { throw "Invalid configuration" }
#>
function Test-ConfigurationValid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )

    try {
        Write-Verbose "Validating configuration structure"

        # Check for required top-level sections
        $requiredSections = @('defaultSettings', 'processing', 'output')
        foreach ($section in $requiredSections) {
            if (-not $Configuration.ContainsKey($section)) {
                Write-Verbose "Missing required section: $section"
                return $false
            }
        }

        # Check for required format settings
        if ($Configuration.defaultSettings) {
            $requiredFormats = @('jpeg', 'png', 'webp', 'avif')
            foreach ($format in $requiredFormats) {
                if (-not $Configuration.defaultSettings.ContainsKey($format)) {
                    Write-Verbose "Missing required format settings: $format"
                    return $false
                }
            }
        }

        # Check for required processing settings
        if ($Configuration.processing) {
            $requiredProcessingSettings = @('maxThreads', 'maxDimensions', 'minFileSizeKB')
            foreach ($setting in $requiredProcessingSettings) {
                if (-not $Configuration.processing.ContainsKey($setting)) {
                    Write-Verbose "Missing required processing setting: $setting"
                    return $false
                }
            }
        }

        # Check for required output settings
        if ($Configuration.output) {
            $requiredOutputSettings = @('preserveStructure', 'namingPattern', 'createBackup')
            foreach ($setting in $requiredOutputSettings) {
                if (-not $Configuration.output.ContainsKey($setting)) {
                    Write-Verbose "Missing required output setting: $setting"
                    return $false
                }
            }
        }

        Write-Verbose "Configuration validation passed"
        return $true
    }
    catch {
        Write-Error "Configuration validation failed: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Merges multiple configuration sources with proper priority order.

.DESCRIPTION
    Combines default, user, and parameter configurations following the priority order:
    1. Parameter overrides (highest priority)
    2. User configuration
    3. Default configuration (lowest priority)

.PARAMETER DefaultConfig
    The default configuration hashtable.

.PARAMETER UserConfig
    The user configuration hashtable (optional).

.PARAMETER ParameterConfig
    The parameter override configuration hashtable (optional).

.OUTPUTS
    [hashtable] The merged configuration

.EXAMPLE
    $merged = Merge-Configuration -DefaultConfig $default -UserConfig $user -ParameterConfig $params
#>
function Merge-Configuration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DefaultConfig,

        [Parameter(Mandatory = $false)]
        [hashtable]$UserConfig = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$ParameterConfig = @{}
    )

    try {
        Write-Verbose "Merging configurations with priority: Parameters > User > Default"

        # Start with a deep copy of the default configuration
        $mergedConfig = Copy-Hashtable -Source $DefaultConfig

        # Merge user configuration over default
        if ($UserConfig -and $UserConfig.Count -gt 0) {
            Write-Verbose "Merging user configuration"
            $mergedConfig = Merge-Hashtable -Target $mergedConfig -Source $UserConfig
        }

        # Merge parameter configuration over everything else
        if ($ParameterConfig -and $ParameterConfig.Count -gt 0) {
            Write-Verbose "Merging parameter configuration"
            $mergedConfig = Merge-Hashtable -Target $mergedConfig -Source $ParameterConfig
        }

        Write-Verbose "Configuration merge completed successfully"
        return $mergedConfig
    }
    catch {
        Write-Error "Failed to merge configurations: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Converts a PSCustomObject to a hashtable recursively.

.DESCRIPTION
    Helper function to convert JSON objects (PSCustomObject) to hashtables
    for easier manipulation and merging.

.PARAMETER InputObject
    The PSCustomObject to convert.

.OUTPUTS
    [hashtable] The converted hashtable

.EXAMPLE
    $hashtable = ConvertTo-Hashtable -InputObject $jsonObject
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$InputObject
    )

    $hashtable = @{}

    foreach ($property in $InputObject.PSObject.Properties) {
        $value = $property.Value

        if ($value -is [PSCustomObject]) {
            # Recursively convert nested objects
            $hashtable[$property.Name] = ConvertTo-Hashtable -InputObject $value
        }
        elseif ($value -is [Array]) {
            # Handle arrays that might contain objects
            $arrayValues = @()
            foreach ($item in $value) {
                if ($item -is [PSCustomObject]) {
                    $arrayValues += ConvertTo-Hashtable -InputObject $item
                }
                else {
                    $arrayValues += $item
                }
            }
            $hashtable[$property.Name] = $arrayValues
        }
        else {
            # Simple value
            $hashtable[$property.Name] = $value
        }
    }

    return $hashtable
}

<#
.SYNOPSIS
    Creates a deep copy of a hashtable.

.DESCRIPTION
    Helper function to create a deep copy of a hashtable to avoid reference issues
    when merging configurations.

.PARAMETER Source
    The source hashtable to copy.

.OUTPUTS
    [hashtable] A deep copy of the source hashtable

.EXAMPLE
    $copy = Copy-Hashtable -Source $originalHashtable
#>
function Copy-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Source
    )

    $copy = @{}

    foreach ($key in $Source.Keys) {
        $value = $Source[$key]

        if ($value -is [hashtable]) {
            # Recursively copy nested hashtables
            $copy[$key] = Copy-Hashtable -Source $value
        }
        elseif ($value -is [Array]) {
            # Copy arrays
            $copy[$key] = $value.Clone()
        }
        else {
            # Simple value
            $copy[$key] = $value
        }
    }

    return $copy
}

<#
.SYNOPSIS
    Merges a source hashtable into a target hashtable.

.DESCRIPTION
    Helper function to merge hashtables recursively, with source values
    overriding target values.

.PARAMETER Target
    The target hashtable to merge into.

.PARAMETER Source
    The source hashtable to merge from.

.OUTPUTS
    [hashtable] The merged hashtable

.EXAMPLE
    $merged = Merge-Hashtable -Target $target -Source $source
#>
function Merge-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Target,

        [Parameter(Mandatory = $true)]
        [hashtable]$Source
    )

    foreach ($key in $Source.Keys) {
        $sourceValue = $Source[$key]

        if ($Target.ContainsKey($key) -and $Target[$key] -is [hashtable] -and $sourceValue -is [hashtable]) {
            # Recursively merge nested hashtables
            $Target[$key] = Merge-Hashtable -Target $Target[$key] -Source $sourceValue
        }
        else {
            # Override with source value
            $Target[$key] = $sourceValue
        }
    }

    return $Target
}
