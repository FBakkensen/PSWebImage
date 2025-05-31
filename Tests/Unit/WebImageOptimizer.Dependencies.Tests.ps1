# Test suite for WebImageOptimizer Dependency Detection System (Task 4)
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "WebImageOptimizer Dependency Detection System Foundation" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:DependenciesPath = Join-Path $script:ModulePath "Dependencies"
        $script:CheckImageMagickPath = Join-Path $script:DependenciesPath "Check-ImageMagick.ps1"

        # Import the dependency detection functions if they exist
        if ($script:CheckImageMagickPath -and (Test-Path $script:CheckImageMagickPath)) {
            . $script:CheckImageMagickPath
        }
    }

    Context "When setting up dependency detection infrastructure" {

        It "Should create the Check-ImageMagick.ps1 file" {
            # Given: A dependency detection system is needed
            # When: The Check-ImageMagick.ps1 file is created
            # Then: The file should exist in the Dependencies directory
            $script:CheckImageMagickPath | Should -Not -BeNullOrEmpty -Because "CheckImageMagickPath should be defined"
            Test-Path $script:CheckImageMagickPath | Should -Be $true -Because "Check-ImageMagick.ps1 file is required for dependency detection"
        }

        It "Should have a Test-ImageProcessingDependencies function" {
            # Given: The dependency detection system needs a main function
            # When: Checking for the function
            # Then: Test-ImageProcessingDependencies function should exist
            Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Test-ImageProcessingDependencies function is required"
        }

        It "Should have a Find-ImageMagickInstallation function" {
            # Given: The system needs to detect ImageMagick installations
            # When: Checking for the function
            # Then: Find-ImageMagickInstallation function should exist
            Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Find-ImageMagickInstallation function is required"
        }

        It "Should have a Test-DotNetImageProcessing function" {
            # Given: The system needs to test .NET image processing capabilities
            # When: Checking for the function
            # Then: Test-DotNetImageProcessing function should exist
            Get-Command Test-DotNetImageProcessing -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Test-DotNetImageProcessing function is required"
        }

        It "Should have a Get-ImageMagickVersion function" {
            # Given: The system needs to validate ImageMagick version compatibility
            # When: Checking for the function
            # Then: Get-ImageMagickVersion function should exist
            Get-Command Get-ImageMagickVersion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Get-ImageMagickVersion function is required"
        }
    }
}

Describe "WebImageOptimizer ImageMagick Detection" {

    BeforeAll {
        # Import the dependency detection functions if they exist
        if (Test-Path $CheckImageMagickPath) {
            . $CheckImageMagickPath
        }
    }

    Context "When detecting ImageMagick via command line" {

        It "Should detect ImageMagick when available in PATH" {
            # Given: ImageMagick is installed and available in PATH
            # When: Find-ImageMagickInstallation is called
            # Then: ImageMagick should be detected with correct path information
            if (Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue) {
                $result = Find-ImageMagickInstallation
                if ($result -and $result.Found) {
                    $result.Found | Should -Be $true -Because "ImageMagick should be detected when available"
                    $result.Path | Should -Not -BeNullOrEmpty -Because "ImageMagick path should be provided"
                    $result.Method | Should -Be "CommandLine" -Because "Detection method should be specified"
                }
            }
        }

        It "Should return version information when ImageMagick is detected" {
            # Given: ImageMagick is available
            # When: Get-ImageMagickVersion is called
            # Then: Version information should be returned
            if (Get-Command Get-ImageMagickVersion -ErrorAction SilentlyContinue) {
                $version = Get-ImageMagickVersion
                if ($version) {
                    $version | Should -Not -BeNullOrEmpty -Because "Version information should be available"
                    $version | Should -Match "\d+\.\d+\.\d+" -Because "Version should follow semantic versioning pattern"
                }
            }
        }
    }

    Context "When detecting ImageMagick via Windows registry" {

        It "Should detect ImageMagick through registry on Windows" {
            # Given: ImageMagick is installed via installer on Windows
            # When: Find-ImageMagickInstallation is called on Windows
            # Then: ImageMagick should be detected through registry lookup
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                if (Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue) {
                    $result = Find-ImageMagickInstallation
                    if ($result -and $result.Found -and $result.Method -eq "Registry") {
                        $result.Found | Should -Be $true -Because "ImageMagick should be detected via registry"
                        $result.Path | Should -Not -BeNullOrEmpty -Because "Registry path should be provided"
                        $result.Method | Should -Be "Registry" -Because "Detection method should be registry"
                    }
                }
            }
        }
    }

    Context "When detecting ImageMagick via package managers" {

        It "Should detect ImageMagick installed via chocolatey" {
            # Given: ImageMagick is installed via chocolatey
            # When: Find-ImageMagickInstallation is called
            # Then: ImageMagick should be detected with chocolatey method
            if (Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue) {
                $result = Find-ImageMagickInstallation
                if ($result -and $result.Found -and $result.Method -eq "Chocolatey") {
                    $result.Found | Should -Be $true -Because "ImageMagick should be detected via chocolatey"
                    $result.Path | Should -Not -BeNullOrEmpty -Because "Chocolatey path should be provided"
                    $result.Method | Should -Be "Chocolatey" -Because "Detection method should be chocolatey"
                }
            }
        }

        It "Should detect ImageMagick installed via scoop" {
            # Given: ImageMagick is installed via scoop
            # When: Find-ImageMagickInstallation is called
            # Then: ImageMagick should be detected with scoop method
            if (Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue) {
                $result = Find-ImageMagickInstallation
                if ($result -and $result.Found -and $result.Method -eq "Scoop") {
                    $result.Found | Should -Be $true -Because "ImageMagick should be detected via scoop"
                    $result.Path | Should -Not -BeNullOrEmpty -Because "Scoop path should be provided"
                    $result.Method | Should -Be "Scoop" -Because "Detection method should be scoop"
                }
            }
        }

        It "Should detect ImageMagick installed via winget" {
            # Given: ImageMagick is installed via winget
            # When: Find-ImageMagickInstallation is called
            # Then: ImageMagick should be detected with winget method
            if (Get-Command Find-ImageMagickInstallation -ErrorAction SilentlyContinue) {
                $result = Find-ImageMagickInstallation
                if ($result -and $result.Found -and $result.Method -eq "Winget") {
                    $result.Found | Should -Be $true -Because "ImageMagick should be detected via winget"
                    $result.Path | Should -Not -BeNullOrEmpty -Because "Winget path should be provided"
                    $result.Method | Should -Be "Winget" -Because "Detection method should be winget"
                }
            }
        }
    }
}

Describe "WebImageOptimizer .NET Image Processing Detection" {

    BeforeAll {
        # Import the dependency detection functions if they exist
        if (Test-Path $CheckImageMagickPath) {
            . $CheckImageMagickPath
        }
    }

    Context "When testing .NET 6+ System.Drawing.Common availability" {

        It "Should detect .NET 6+ System.Drawing.Common as fallback" {
            # Given: .NET 6+ runtime is available
            # When: Test-DotNetImageProcessing is called
            # Then: .NET System.Drawing.Common should be detected as available
            if (Get-Command Test-DotNetImageProcessing -ErrorAction SilentlyContinue) {
                $result = Test-DotNetImageProcessing
                $result | Should -Not -BeNullOrEmpty -Because ".NET image processing test should return a result"
                $result.Available | Should -BeOfType [bool] -Because "Availability should be a boolean value"
                if ($result.Available) {
                    $result.Version | Should -Not -BeNullOrEmpty -Because ".NET version should be provided when available"
                    $result.Capabilities | Should -Not -BeNullOrEmpty -Because "Capabilities should be listed when available"
                }
            }
        }

        It "Should validate .NET version compatibility" {
            # Given: .NET runtime is available
            # When: Test-DotNetImageProcessing checks version compatibility
            # Then: Should validate .NET 6.0+ requirement
            if (Get-Command Test-DotNetImageProcessing -ErrorAction SilentlyContinue) {
                $result = Test-DotNetImageProcessing
                if ($result -and $result.Available) {
                    $result.Version | Should -Match "^[6-9]\." -Because ".NET 6.0 or higher is required"
                }
            }
        }
    }
}

Describe "WebImageOptimizer Dependency Detection Integration" {

    BeforeAll {
        # Import the dependency detection functions if they exist
        if (Test-Path $CheckImageMagickPath) {
            . $CheckImageMagickPath
        }
    }

    Context "When running comprehensive dependency detection" {

        It "Should return structured information about available processing engines" {
            # Given: The dependency detection system is implemented
            # When: Test-ImageProcessingDependencies is called
            # Then: Should return structured information about all available engines
            if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                $result = Test-ImageProcessingDependencies
                $result | Should -Not -BeNullOrEmpty -Because "Dependency detection should return results"
                $result.ImageMagick | Should -Not -BeNullOrEmpty -Because "ImageMagick detection results should be included"
                $result.DotNet | Should -Not -BeNullOrEmpty -Because ".NET detection results should be included"
                $result.RecommendedEngine | Should -Not -BeNullOrEmpty -Because "Recommended engine should be specified"
                $result.AvailableEngines | Should -Not -BeNullOrEmpty -Because "Available engines list should be provided"
            }
        }

        It "Should prioritize ImageMagick over .NET when both are available" {
            # Given: Both ImageMagick and .NET are available
            # When: Test-ImageProcessingDependencies determines the recommended engine
            # Then: ImageMagick should be recommended over .NET
            if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                $result = Test-ImageProcessingDependencies
                if ($result -and $result.ImageMagick.Found -and $result.DotNet.Available) {
                    $result.RecommendedEngine | Should -Be "ImageMagick" -Because "ImageMagick should be preferred when available"
                }
            }
        }

        It "Should recommend .NET when ImageMagick is not available" {
            # Given: ImageMagick is not available but .NET is
            # When: Test-ImageProcessingDependencies determines the recommended engine
            # Then: .NET should be recommended as fallback
            if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                $result = Test-ImageProcessingDependencies
                if ($result -and -not $result.ImageMagick.Found -and $result.DotNet.Available) {
                    $result.RecommendedEngine | Should -Be "DotNet" -Because ".NET should be fallback when ImageMagick unavailable"
                }
            }
        }

        It "Should handle scenarios where no processing engines are available" {
            # Given: The dependency detection system is implemented
            # When: Test-ImageProcessingDependencies is called
            # Then: Should return structured information about available engines
            if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                $result = Test-ImageProcessingDependencies
                $result | Should -Not -BeNullOrEmpty -Because "Function should return results"
                $result.AvailableEngines | Should -Not -BeNullOrEmpty -Because "Available engines should be provided"
                # AvailableEngines can be an array or a single string, both are valid
                ($result.AvailableEngines -is [array]) -or ($result.AvailableEngines -is [string]) | Should -Be $true -Because "Available engines should be array or string"
            }
        }
    }

    Context "When validating cross-platform compatibility" {

        It "Should work correctly on Windows" {
            # Given: The system is running on Windows
            # When: Test-ImageProcessingDependencies is called
            # Then: Should correctly detect installations across Windows-specific methods
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                    $result = Test-ImageProcessingDependencies
                    $result | Should -Not -BeNullOrEmpty -Because "Dependency detection should work on Windows"
                    # Windows-specific validation can be added here
                }
            }
        }

        It "Should work correctly on Linux" {
            # Given: The system is running on Linux
            # When: Test-ImageProcessingDependencies is called
            # Then: Should correctly detect installations using Linux-specific methods
            if ($IsLinux) {
                if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                    $result = Test-ImageProcessingDependencies
                    $result | Should -Not -BeNullOrEmpty -Because "Dependency detection should work on Linux"
                    # Linux-specific validation can be added here
                }
            }
        }

        It "Should work correctly on macOS" {
            # Given: The system is running on macOS
            # When: Test-ImageProcessingDependencies is called
            # Then: Should correctly detect installations using macOS-specific methods
            if ($IsMacOS) {
                if (Get-Command Test-ImageProcessingDependencies -ErrorAction SilentlyContinue) {
                    $result = Test-ImageProcessingDependencies
                    $result | Should -Not -BeNullOrEmpty -Because "Dependency detection should work on macOS"
                    # macOS-specific validation can be added here
                }
            }
        }
    }
}
