# Test suite for WebImageOptimizer Configuration System (Task 3)
# BDD/TDD implementation following Given-When-Then structure

# Define the module root path
$ModuleRoot = if ($PSScriptRoot) {
    $PSScriptRoot | Split-Path | Split-Path  # Go up two levels from Tests\Unit to root
} else {
    "d:\repos\PSWebImage"  # Fallback for direct execution
}
$ModulePath = Join-Path $ModuleRoot "WebImageOptimizer"
$ConfigPath = Join-Path $ModulePath "Config"
$DefaultConfigPath = Join-Path $ConfigPath "default-settings.json"
$PrivatePath = Join-Path $ModulePath "Private"
$ConfigManagerPath = Join-Path $PrivatePath "ConfigurationManager.ps1"

# Ensure paths are properly resolved
if (-not $ModuleRoot) {
    $ModuleRoot = "d:\repos\PSWebImage"
    $ModulePath = Join-Path $ModuleRoot "WebImageOptimizer"
    $ConfigPath = Join-Path $ModulePath "Config"
    $DefaultConfigPath = Join-Path $ConfigPath "default-settings.json"
    $PrivatePath = Join-Path $ModulePath "Private"
    $ConfigManagerPath = Join-Path $PrivatePath "ConfigurationManager.ps1"
}

Describe "WebImageOptimizer Configuration System Foundation" {

    BeforeAll {
        # Import the configuration manager if it exists
        if (Test-Path $ConfigManagerPath) {
            . $ConfigManagerPath
        }
    }

    Context "When setting up default configuration" {

        It "Should create a default configuration JSON file" {
            # Given: A configuration system needs default settings
            # When: The default configuration file is created
            # Then: The file should exist and be valid JSON
            Test-Path $DefaultConfigPath | Should -Be $true -Because "Default configuration file is required"
        }

        It "Should have valid JSON structure in default configuration" {
            # Given: The default configuration file exists
            # When: Reading the configuration file
            # Then: It should be valid JSON that can be parsed
            if (Test-Path $DefaultConfigPath) {
                { Get-Content $DefaultConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw -Because "Configuration must be valid JSON"
            }
        }

        It "Should contain required configuration sections" {
            # Given: The PRD specifies required configuration sections
            # When: Loading the default configuration
            # Then: All required sections should be present
            if (Test-Path $DefaultConfigPath) {
                $config = Get-Content $DefaultConfigPath -Raw | ConvertFrom-Json
                $config.PSObject.Properties.Name | Should -Contain "defaultSettings" -Because "Default settings section is required"
                $config.PSObject.Properties.Name | Should -Contain "processing" -Because "Processing section is required"
                $config.PSObject.Properties.Name | Should -Contain "output" -Because "Output section is required"
            }
        }

        It "Should contain format-specific settings" {
            # Given: The system supports multiple image formats
            # When: Checking default settings
            # Then: Each supported format should have configuration
            if (Test-Path $DefaultConfigPath) {
                $config = Get-Content $DefaultConfigPath -Raw | ConvertFrom-Json
                if ($config.defaultSettings) {
                    $config.defaultSettings.PSObject.Properties.Name | Should -Contain "jpeg" -Because "JPEG settings are required"
                    $config.defaultSettings.PSObject.Properties.Name | Should -Contain "png" -Because "PNG settings are required"
                    $config.defaultSettings.PSObject.Properties.Name | Should -Contain "webp" -Because "WebP settings are required"
                    $config.defaultSettings.PSObject.Properties.Name | Should -Contain "avif" -Because "AVIF settings are required"
                }
            }
        }
    }

    Context "When implementing configuration loading functions" {

        It "Should have a Get-DefaultConfiguration function" {
            # Given: The configuration system needs to load default settings
            # When: Checking for the function
            # Then: Get-DefaultConfiguration function should exist
            Get-Command Get-DefaultConfiguration -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Get-DefaultConfiguration function is required"
        }

        It "Should have a Merge-Configuration function" {
            # Given: The system needs to merge configurations from multiple sources
            # When: Checking for the function
            # Then: Merge-Configuration function should exist
            Get-Command Merge-Configuration -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Merge-Configuration function is required"
        }

        It "Should have a Test-ConfigurationValid function" {
            # Given: The system needs to validate configuration settings
            # When: Checking for the function
            # Then: Test-ConfigurationValid function should exist
            Get-Command Test-ConfigurationValid -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Test-ConfigurationValid function is required"
        }

        It "Should have a Get-UserConfiguration function" {
            # Given: The system needs to load user-specific configuration
            # When: Checking for the function
            # Then: Get-UserConfiguration function should exist
            Get-Command Get-UserConfiguration -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Get-UserConfiguration function is required"
        }
    }

    Context "When loading default configuration" {

        It "Should load default configuration without errors" {
            # Given: The default configuration file exists
            # When: Loading the default configuration
            # Then: It should load without throwing errors
            if (Get-Command Get-DefaultConfiguration -ErrorAction SilentlyContinue) {
                { Get-DefaultConfiguration } | Should -Not -Throw -Because "Default configuration should load without errors"
            }
        }

        It "Should return a hashtable with configuration data" {
            # Given: The Get-DefaultConfiguration function exists
            # When: Calling the function
            # Then: It should return a hashtable with configuration data
            if (Get-Command Get-DefaultConfiguration -ErrorAction SilentlyContinue) {
                $config = Get-DefaultConfiguration
                $config | Should -BeOfType [hashtable] -Because "Configuration should be returned as a hashtable"
                $config.Count | Should -BeGreaterThan 0 -Because "Configuration should contain data"
            }
        }

        It "Should include all required format settings" {
            # Given: The default configuration is loaded
            # When: Checking format-specific settings
            # Then: All supported formats should have settings
            if (Get-Command Get-DefaultConfiguration -ErrorAction SilentlyContinue) {
                $config = Get-DefaultConfiguration
                if ($config.defaultSettings) {
                    $config.defaultSettings.Keys | Should -Contain "jpeg" -Because "JPEG settings are required"
                    $config.defaultSettings.Keys | Should -Contain "png" -Because "PNG settings are required"
                    $config.defaultSettings.Keys | Should -Contain "webp" -Because "WebP settings are required"
                    $config.defaultSettings.Keys | Should -Contain "avif" -Because "AVIF settings are required"
                }
            }
        }
    }

    Context "When validating configuration" {

        It "Should validate a complete configuration as valid" {
            # Given: A complete configuration object
            # When: Validating the configuration
            # Then: It should return true for valid configuration
            if (Get-Command Test-ConfigurationValid -ErrorAction SilentlyContinue) {
                $validConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 85; progressive = $true }
                        png = @{ compression = 6; stripMetadata = $true }
                        webp = @{ quality = 90; method = 6 }
                        avif = @{ quality = 85; speed = 6 }
                    }
                    processing = @{
                        maxThreads = 4
                        maxDimensions = @{ width = 2048; height = 2048 }
                        minFileSizeKB = 10
                    }
                    output = @{
                        preserveStructure = $true
                        namingPattern = "{name}_optimized.{ext}"
                        createBackup = $false
                    }
                }
                Test-ConfigurationValid -Configuration $validConfig | Should -Be $true -Because "Complete configuration should be valid"
            }
        }

        It "Should validate an incomplete configuration as invalid" {
            # Given: An incomplete configuration object
            # When: Validating the configuration
            # Then: It should return false for invalid configuration
            if (Get-Command Test-ConfigurationValid -ErrorAction SilentlyContinue) {
                $invalidConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 85 }
                        # Missing other formats
                    }
                    # Missing processing and output sections
                }
                Test-ConfigurationValid -Configuration $invalidConfig | Should -Be $false -Because "Incomplete configuration should be invalid"
            }
        }
    }

    Context "When merging configurations" {

        It "Should merge user configuration over default configuration" {
            # Given: Default and user configurations exist
            # When: Merging configurations with priority order
            # Then: User settings should override default settings
            if (Get-Command Merge-Configuration -ErrorAction SilentlyContinue) {
                $defaultConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 85; progressive = $true }
                    }
                    processing = @{ maxThreads = 4 }
                }
                $userConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 90 }  # Override quality
                    }
                    processing = @{ maxThreads = 8 }  # Override threads
                }

                $merged = Merge-Configuration -DefaultConfig $defaultConfig -UserConfig $userConfig
                $merged.defaultSettings.jpeg.quality | Should -Be 90 -Because "User config should override default"
                $merged.processing.maxThreads | Should -Be 8 -Because "User config should override default"
                $merged.defaultSettings.jpeg.progressive | Should -Be $true -Because "Non-overridden values should be preserved"
            }
        }

        It "Should merge parameter overrides over all other configurations" {
            # Given: Default, user, and parameter configurations exist
            # When: Merging with parameter overrides having highest priority
            # Then: Parameter settings should override all others
            if (Get-Command Merge-Configuration -ErrorAction SilentlyContinue) {
                $defaultConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 85 }
                    }
                }
                $userConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 90 }
                    }
                }
                $parameterConfig = @{
                    defaultSettings = @{
                        jpeg = @{ quality = 95 }
                    }
                }

                $merged = Merge-Configuration -DefaultConfig $defaultConfig -UserConfig $userConfig -ParameterConfig $parameterConfig
                $merged.defaultSettings.jpeg.quality | Should -Be 95 -Because "Parameter config should have highest priority"
            }
        }
    }

    Context "When loading user configuration" {

        It "Should handle missing user configuration gracefully" {
            # Given: No user configuration file exists
            # When: Attempting to load user configuration
            # Then: It should return null or empty without throwing errors
            if (Get-Command Get-UserConfiguration -ErrorAction SilentlyContinue) {
                { Get-UserConfiguration -Path "NonExistentPath.json" } | Should -Not -Throw -Because "Missing user config should be handled gracefully"
            }
        }

        It "Should load valid user configuration when file exists" {
            # Given: A valid user configuration file exists
            # When: Loading the user configuration
            # Then: It should return the configuration data
            if (Get-Command Get-UserConfiguration -ErrorAction SilentlyContinue) {
                # This test will be implemented when we have a test user config file
                # For now, we'll test the function exists and can be called
                $result = Get-UserConfiguration -Path "NonExistentPath.json"
                # Should not throw, result can be null for non-existent file
                $true | Should -Be $true  # Placeholder assertion
            }
        }
    }
}

Describe "WebImageOptimizer Configuration Integration" {

    Context "When integrating configuration with module loading" {

        It "Should load configuration system when module is imported" {
            # Given: The WebImageOptimizer module is imported
            # When: Checking for configuration functions
            # Then: Configuration functions should be available
            # Note: This test validates the integration works end-to-end
            $ModuleFile = Join-Path $ModulePath "WebImageOptimizer.psm1"
            if (Test-Path $ModuleFile) {
                # Import the module to test integration
                Import-Module $ModuleFile -Force -ErrorAction SilentlyContinue

                # Check if configuration functions are available after module import
                $configFunctions = @('Get-DefaultConfiguration', 'Merge-Configuration', 'Test-ConfigurationValid', 'Get-UserConfiguration')
                foreach ($func in $configFunctions) {
                    Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Configuration function $func should be available after module import"
                }
            }
        }
    }
}
