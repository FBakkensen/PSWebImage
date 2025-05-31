# PathResolution Test Helper Module
# Provides common path resolution utilities for WebImageOptimizer test files
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Resolves the module root path with configurable override options.

.DESCRIPTION
    This function provides a robust path resolution strategy for test files with multiple fallback options:
    1. Parameter Override - Manual path via -OverridePath parameter
    2. Environment Variable - Uses $env:PSWEBIMAGE_ROOT for CI/CD scenarios
    3. Calculated Path - Uses $PSScriptRoot to automatically determine repository root
    4. Fallback Path - Original hardcoded path for backward compatibility

.PARAMETER OverridePath
    Optional path to override the automatic path resolution.

.PARAMETER EnvironmentVariable
    Name of the environment variable to check for the module root path.
    Defaults to 'PSWEBIMAGE_ROOT'.

.OUTPUTS
    [string] The resolved module root path.

.EXAMPLE
    $moduleRoot = Get-ModuleRootPath
    # Uses automatic path resolution based on test file location

.EXAMPLE
    $moduleRoot = Get-ModuleRootPath -OverridePath "C:\MyCustomPath\PSWebImage"
    # Uses the specified override path

.EXAMPLE
    $env:PSWEBIMAGE_ROOT = "C:\MyPath\PSWebImage"
    $moduleRoot = Get-ModuleRootPath
    # Uses the environment variable path

.NOTES
    This function is designed to be called from test files located in Tests\Unit\
    and will calculate the repository root as two levels up from the test file location.
#>
function Get-ModuleRootPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$OverridePath,

        [Parameter()]
        [string]$EnvironmentVariable = 'PSWEBIMAGE_ROOT'
    )

    Write-Verbose "Starting module root path resolution..."

    # Priority order: Parameter > Environment Variable > Calculated from $PSScriptRoot > Fallback
    if ($OverridePath -and (Test-Path $OverridePath)) {
        Write-Verbose "Using override path: $OverridePath"
        return $OverridePath
    }

    # Check environment variable
    $envPath = [Environment]::GetEnvironmentVariable($EnvironmentVariable)
    if ($envPath -and (Test-Path $envPath)) {
        Write-Verbose "Using environment variable path: $envPath"
        return $envPath
    }

    # Calculate from test file location (Tests\Unit\*.Tests.ps1 -> repository root)
    # We need to go up from the calling test file's location
    $callerPath = (Get-PSCallStack)[1].ScriptName
    if ($callerPath) {
        $testFileDir = Split-Path $callerPath -Parent
        $calculatedRoot = Split-Path (Split-Path $testFileDir -Parent) -Parent
        if (Test-Path $calculatedRoot) {
            Write-Verbose "Using calculated path from caller location: $calculatedRoot"
            return $calculatedRoot
        }
    }

    # Fallback: try to calculate from this module's location
    # This module is in Tests\TestHelpers, so repository root is two levels up
    $moduleDir = Split-Path $PSScriptRoot -Parent
    $calculatedRoot = Split-Path $moduleDir -Parent
    if (Test-Path $calculatedRoot) {
        Write-Verbose "Using calculated path from module location: $calculatedRoot"
        return $calculatedRoot
    }

    # Final fallback: derive path from this module's location as last resort
    # This module is in Tests\TestHelpers, so try going up two levels again but with more flexibility
    $derivedFallbackPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    if ($derivedFallbackPath -and (Test-Path $derivedFallbackPath)) {
        Write-Warning "Using derived fallback path: $derivedFallbackPath. Consider setting $EnvironmentVariable environment variable for more reliable path resolution."
        return $derivedFallbackPath
    }

    throw "Unable to determine module root path. Please provide a valid path via -OverridePath parameter or set $EnvironmentVariable environment variable."
}

# Export the function for use by test files
Export-ModuleMember -Function Get-ModuleRootPath
