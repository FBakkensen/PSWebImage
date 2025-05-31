# WebImageOptimizer Module
# Main module file for the Web Image Optimizer PowerShell module
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

# Module initialization and setup
Write-Verbose "Loading WebImageOptimizer module..."

# Get all public, private, and dependency function files
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$DependencyFunctions = @(Get-ChildItem -Path $PSScriptRoot\Dependencies\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($Import in @($PublicFunctions + $PrivateFunctions + $DependencyFunctions)) {
    try {
        . $Import.FullName
        Write-Verbose "Imported function: $($Import.BaseName)"
    }
    catch {
        Write-Error "Failed to import function $($Import.FullName): $($_)"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName

Write-Verbose "WebImageOptimizer module loaded successfully."
