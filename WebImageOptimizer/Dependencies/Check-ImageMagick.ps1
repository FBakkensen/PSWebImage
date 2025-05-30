# ImageMagick and Image Processing Dependencies Detection System
# Detects and validates image processing dependencies across platforms
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Finds ImageMagick installation across different installation methods and platforms.

.DESCRIPTION
    Searches for ImageMagick installations using multiple detection methods:
    - Command line availability (PATH)
    - Windows Registry (Windows only)
    - Package manager installations (chocolatey, scoop, winget)
    - Common installation directories
    - Cross-platform package managers (brew on macOS, apt/yum on Linux)

.OUTPUTS
    [PSCustomObject] Object containing installation details:
    - Found: Boolean indicating if ImageMagick was found
    - Path: Full path to ImageMagick executable
    - Method: Detection method used
    - Version: Version string if available

.EXAMPLE
    $installation = Find-ImageMagickInstallation
    if ($installation.Found) {
        Write-Host "ImageMagick found at: $($installation.Path)"
    }
#>
function Find-ImageMagickInstallation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Verbose "Starting ImageMagick installation detection"

    # Initialize result object
    $result = [PSCustomObject]@{
        Found = $false
        Path = $null
        Method = $null
        Version = $null
    }

    # Method 1: Check if magick command is available in PATH
    Write-Verbose "Checking for ImageMagick in PATH"
    $magickCommand = Get-Command "magick" -ErrorAction SilentlyContinue
    if ($magickCommand) {
        $result.Found = $true
        $result.Path = $magickCommand.Source
        $result.Method = "CommandLine"
        Write-Verbose "ImageMagick found in PATH: $($result.Path)"
        return $result
    }

    # Method 2: Windows Registry detection
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Write-Verbose "Checking Windows Registry for ImageMagick"
        try {
            $registryPaths = @(
                "HKLM:\SOFTWARE\ImageMagick",
                "HKLM:\SOFTWARE\WOW6432Node\ImageMagick"
            )
            
            foreach ($regPath in $registryPaths) {
                if (Test-Path $regPath) {
                    $installPath = Get-ItemProperty -Path $regPath -Name "BinPath" -ErrorAction SilentlyContinue
                    if ($installPath -and $installPath.BinPath) {
                        $magickExe = Join-Path $installPath.BinPath "magick.exe"
                        if (Test-Path $magickExe) {
                            $result.Found = $true
                            $result.Path = $magickExe
                            $result.Method = "Registry"
                            Write-Verbose "ImageMagick found via registry: $($result.Path)"
                            return $result
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "Registry detection failed: $($_.Exception.Message)"
        }
    }

    # Method 3: Package manager detection
    Write-Verbose "Checking package manager installations"
    
    # Chocolatey detection (Windows)
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $chocoPath = "$env:ProgramData\chocolatey\lib\imagemagick\tools\magick.exe"
        if (Test-Path $chocoPath) {
            $result.Found = $true
            $result.Path = $chocoPath
            $result.Method = "Chocolatey"
            Write-Verbose "ImageMagick found via Chocolatey: $($result.Path)"
            return $result
        }

        # Scoop detection (Windows)
        $scoopPath = "$env:USERPROFILE\scoop\apps\imagemagick\current\magick.exe"
        if (Test-Path $scoopPath) {
            $result.Found = $true
            $result.Path = $scoopPath
            $result.Method = "Scoop"
            Write-Verbose "ImageMagick found via Scoop: $($result.Path)"
            return $result
        }

        # Winget detection (Windows) - check common installation paths
        $wingetPaths = @(
            "$env:ProgramFiles\ImageMagick-*\magick.exe",
            "${env:ProgramFiles(x86)}\ImageMagick-*\magick.exe"
        )
        foreach ($pattern in $wingetPaths) {
            $matches = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($matches) {
                $result.Found = $true
                $result.Path = $matches.FullName
                $result.Method = "Winget"
                Write-Verbose "ImageMagick found via Winget: $($result.Path)"
                return $result
            }
        }
    }

    # Homebrew detection (macOS)
    if ($IsMacOS) {
        $brewPath = "/opt/homebrew/bin/magick"
        if (Test-Path $brewPath) {
            $result.Found = $true
            $result.Path = $brewPath
            $result.Method = "Homebrew"
            Write-Verbose "ImageMagick found via Homebrew: $($result.Path)"
            return $result
        }
        
        # Intel Mac Homebrew path
        $brewIntelPath = "/usr/local/bin/magick"
        if (Test-Path $brewIntelPath) {
            $result.Found = $true
            $result.Path = $brewIntelPath
            $result.Method = "Homebrew"
            Write-Verbose "ImageMagick found via Homebrew (Intel): $($result.Path)"
            return $result
        }
    }

    # Linux package manager detection
    if ($IsLinux) {
        $linuxPaths = @(
            "/usr/bin/magick",
            "/usr/local/bin/magick",
            "/snap/bin/magick"
        )
        foreach ($path in $linuxPaths) {
            if (Test-Path $path) {
                $result.Found = $true
                $result.Path = $path
                $result.Method = "SystemPackage"
                Write-Verbose "ImageMagick found via system package: $($result.Path)"
                return $result
            }
        }
    }

    Write-Verbose "ImageMagick not found through any detection method"
    return $result
}

<#
.SYNOPSIS
    Gets the version of an installed ImageMagick instance.

.DESCRIPTION
    Executes the ImageMagick command to retrieve version information.
    Supports both the modern 'magick' command and legacy 'convert' command.

.PARAMETER MagickPath
    Optional path to the ImageMagick executable. If not provided, uses the system PATH.

.OUTPUTS
    [string] Version string in semantic versioning format, or $null if version cannot be determined.

.EXAMPLE
    $version = Get-ImageMagickVersion
    Write-Host "ImageMagick version: $version"
#>
function Get-ImageMagickVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$MagickPath
    )

    try {
        $command = if ($MagickPath) { $MagickPath } else { "magick" }
        
        Write-Verbose "Getting ImageMagick version using command: $command"
        
        # Execute magick -version command
        $versionOutput = & $command -version 2>$null
        
        if ($versionOutput) {
            # Parse version from output (typically first line contains "Version: ImageMagick x.y.z")
            $versionLine = $versionOutput | Select-Object -First 1
            if ($versionLine -match "ImageMagick\s+(\d+\.\d+\.\d+(?:-\d+)?)" ) {
                $version = $matches[1]
                Write-Verbose "ImageMagick version detected: $version"
                return $version
            }
        }
        
        Write-Verbose "Could not parse ImageMagick version from output"
        return $null
    }
    catch {
        Write-Verbose "Failed to get ImageMagick version: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Tests .NET 6+ System.Drawing.Common availability as a fallback image processing engine.

.DESCRIPTION
    Checks if .NET 6.0 or higher is available and if System.Drawing.Common can be used
    for basic image processing operations. This serves as a fallback when ImageMagick
    is not available.

.OUTPUTS
    [PSCustomObject] Object containing .NET image processing capabilities:
    - Available: Boolean indicating if .NET image processing is available
    - Version: .NET runtime version
    - Capabilities: Array of supported operations

.EXAMPLE
    $dotnetCapabilities = Test-DotNetImageProcessing
    if ($dotnetCapabilities.Available) {
        Write-Host ".NET image processing available with version: $($dotnetCapabilities.Version)"
    }
#>
function Test-DotNetImageProcessing {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Verbose "Testing .NET image processing capabilities"

    $result = [PSCustomObject]@{
        Available = $false
        Version = $null
        Capabilities = @()
    }

    try {
        # Check .NET version
        $dotnetVersion = [System.Environment]::Version
        $result.Version = $dotnetVersion.ToString()
        
        Write-Verbose ".NET version detected: $($result.Version)"
        
        # Check if .NET 6.0 or higher
        if ($dotnetVersion.Major -ge 6) {
            # Test System.Drawing.Common availability
            try {
                Add-Type -AssemblyName "System.Drawing.Common" -ErrorAction Stop
                $result.Available = $true
                $result.Capabilities = @("Resize", "Format Conversion", "Basic Compression")
                Write-Verbose ".NET image processing is available"
            }
            catch {
                Write-Verbose "System.Drawing.Common not available: $($_.Exception.Message)"
            }
        }
        else {
            Write-Verbose ".NET version $($result.Version) is below required 6.0"
        }
    }
    catch {
        Write-Verbose "Failed to test .NET capabilities: $($_.Exception.Message)"
    }

    return $result
}

<#
.SYNOPSIS
    Comprehensive test of all image processing dependencies.

.DESCRIPTION
    Performs a complete scan of available image processing engines including
    ImageMagick and .NET fallback capabilities. Returns structured information
    about all available options and recommendations.

.OUTPUTS
    [PSCustomObject] Comprehensive dependency information:
    - ImageMagick: ImageMagick detection results
    - DotNet: .NET capabilities results
    - RecommendedEngine: Recommended processing engine
    - AvailableEngines: Array of available engines

.EXAMPLE
    $dependencies = Test-ImageProcessingDependencies
    Write-Host "Recommended engine: $($dependencies.RecommendedEngine)"
    Write-Host "Available engines: $($dependencies.AvailableEngines -join ', ')"
#>
function Test-ImageProcessingDependencies {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Verbose "Starting comprehensive image processing dependency detection"

    # Test ImageMagick
    $imageMagickResult = Find-ImageMagickInstallation
    if ($imageMagickResult.Found) {
        $imageMagickResult.Version = Get-ImageMagickVersion -MagickPath $imageMagickResult.Path
    }

    # Test .NET capabilities
    $dotNetResult = Test-DotNetImageProcessing

    # Determine available engines and recommendation
    $availableEngines = @()
    $recommendedEngine = $null

    if ($imageMagickResult.Found) {
        $availableEngines += "ImageMagick"
        $recommendedEngine = "ImageMagick"  # Prefer ImageMagick when available
    }

    if ($dotNetResult.Available) {
        $availableEngines += "DotNet"
        if (-not $recommendedEngine) {
            $recommendedEngine = "DotNet"  # Use .NET as fallback
        }
    }

    if ($availableEngines.Count -eq 0) {
        $recommendedEngine = "None"
    }

    $result = [PSCustomObject]@{
        ImageMagick = $imageMagickResult
        DotNet = $dotNetResult
        RecommendedEngine = $recommendedEngine
        AvailableEngines = $availableEngines
    }

    Write-Verbose "Dependency detection complete. Recommended engine: $recommendedEngine"
    Write-Verbose "Available engines: $($availableEngines -join ', ')"

    return $result
}
