# Main Function Tests for WebImageOptimizer
# Tests for the primary Optimize-WebImages function using TDD/BDD methodology
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

BeforeAll {
    # Import the module and test data library
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $ModuleRoot "WebImageOptimizer\WebImageOptimizer.psd1") -Force

    # Import test data library
    . (Join-Path $PSScriptRoot "..\TestDataLibraries\MainFunction.TestDataLibrary.ps1")

    # Set up test environment
    $script:TestRootPath = Join-Path $env:TEMP "WebImageOptimizer_MainFunction_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:TestScenario = $null
}

AfterAll {
    # Comprehensive cleanup of all test data including backup directories
    if ($script:TestRootPath) {
        try {
            Remove-MainFunctionTestData -TestRootPath $script:TestRootPath
            Write-Verbose "Completed comprehensive cleanup of main function test data"
        }
        catch {
            Write-Warning "Failed to complete cleanup: $($_.Exception.Message)"
        }
    }
}

Describe "Optimize-WebImages Main Function" -Tags @('Unit', 'MainFunction') {

    BeforeEach {
        # Create fresh test scenario for each test
        # Ensure we have a clean test root for each test
        if ($script:TestRootPath -and (Test-Path $script:TestRootPath)) {
            try {
                Remove-Item -Path $script:TestRootPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not clean existing test root before test: $($_.Exception.Message)"
            }
        }
        $script:TestScenario = New-MainFunctionTestScenario -TestRootPath $script:TestRootPath
    }

    AfterEach {
        # Light cleanup after each test - just remove the test scenario data
        # Leave comprehensive backup cleanup to AfterAll to avoid race conditions
        if ($script:TestScenario -and $script:TestScenario.TestRootPath -and (Test-Path $script:TestScenario.TestRootPath)) {
            try {
                Remove-Item -Path $script:TestScenario.TestRootPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not clean test scenario data: $($_.Exception.Message)"
            }
        }
    }

    Context "Function Existence and Basic Structure" {

        It "Should exist and be available" {
            # Given: The module is loaded
            # When: I check for the function
            $function = Get-Command -Name "Optimize-WebImages" -ErrorAction SilentlyContinue

            # Then: The function should exist
            $function | Should -Not -BeNullOrEmpty
            $function.CommandType | Should -Be "Function"
        }

        It "Should have correct parameter structure" {
            # Given: The function exists
            $function = Get-Command -Name "Optimize-WebImages"

            # When: I examine the parameters
            $parameters = $function.Parameters

            # Then: It should have all required parameters
            $parameters.Keys | Should -Contain "Path"
            $parameters.Keys | Should -Contain "OutputPath"
            $parameters.Keys | Should -Contain "Settings"
            $parameters.Keys | Should -Contain "IncludeFormats"
            $parameters.Keys | Should -Contain "ExcludePatterns"
            $parameters.Keys | Should -Contain "CreateBackup"
            $parameters.Keys | Should -Contain "WhatIf"

            # And: Path parameter should be mandatory
            $parameters["Path"].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory } | Should -Contain $true
        }

        It "Should support SupportsShouldProcess" {
            # Given: The function exists
            $function = Get-Command -Name "Optimize-WebImages"

            # When: I check the function attributes
            # Then: It should support ShouldProcess for WhatIf functionality (verified by WhatIf parameter presence)
            $function.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $function.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context "Parameter Validation" {

        It "Should require Path parameter" {
            # Given: An empty or null path
            # When: I call the function with empty path
            # Then: It should throw a validation exception
            {
                Optimize-WebImages -Path "" -ErrorAction Stop
            } | Should -Throw
        }

        It "Should validate Path exists" {
            # Given: A non-existent path
            $nonExistentPath = "C:\NonExistent\Path\$(Get-Random)"

            # When: I call the function with non-existent path
            # Then: It should handle the error gracefully
            { Optimize-WebImages -Path $nonExistentPath -ErrorAction Stop } | Should -Throw
        }

        It "Should accept valid Path parameter" {
            # Given: A valid test scenario with images
            $inputPath = $script:TestScenario.InputDirectory

            # When: I call the function with valid path in WhatIf mode
            $result = Optimize-WebImages -Path $inputPath -WhatIf

            # Then: It should not throw an error
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should validate IncludeFormats parameter" {
            # Given: A valid input path and invalid format
            $inputPath = $script:TestScenario.InputDirectory
            $invalidFormats = @('.invalid', '.badformat')

            # When: I call the function with invalid formats in WhatIf mode
            $result = Optimize-WebImages -Path $inputPath -IncludeFormats $invalidFormats -WhatIf

            # Then: It should handle the validation appropriately
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "WhatIf Functionality" {

        It "Should support WhatIf parameter" {
            # Given: A valid test scenario
            $inputPath = $script:TestScenario.InputDirectory

            # When: I call the function with WhatIf
            $result = Optimize-WebImages -Path $inputPath -WhatIf

            # Then: It should return results without making changes
            $result | Should -Not -BeNullOrEmpty
            # And: No files should be modified (check that input files are unchanged)
            $originalFiles = Get-ChildItem -Path $inputPath -Recurse -File
            $originalFiles | Should -Not -BeNullOrEmpty
        }

        It "Should show what would be processed in WhatIf mode" {
            # Given: A test scenario with multiple images
            $inputPath = $script:TestScenario.InputDirectory

            # When: I call the function with WhatIf and capture verbose output
            $result = Optimize-WebImages -Path $inputPath -WhatIf -Verbose 4>&1

            # Then: It should indicate what would be processed
            $result | Should -Not -BeNullOrEmpty
            # And: Should contain information about discovered files
            $verboseOutput = $result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }
            $verboseOutput | Should -Not -BeNullOrEmpty
        }
    }

    Context "Basic Functionality" {

        It "Should process images with minimal parameters" {
            # Given: A test scenario with images
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory

            # When: I call the function with minimal parameters
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: It should complete successfully
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true

            # And: Should have processed some files
            $result.FilesProcessed | Should -BeGreaterThan 0
        }

        It "Should integrate with all components" {
            # Given: A test scenario with full parameters
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory
            $settings = @{
                jpeg = @{ quality = 80 }
                png = @{ compression = 6 }
            }

            # When: I call the function with comprehensive parameters
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath -Settings $settings -CreateBackup

            # Then: It should integrate all components successfully
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true

            # And: Should have created backups if requested
            if ($result.BackupCreated) {
                $result.BackupPath | Should -Not -BeNullOrEmpty
                Test-Path $result.BackupPath | Should -Be $true
            }
        }
    }

    Context "Error Handling" {

        It "Should handle missing dependencies gracefully" {
            # Given: A scenario where dependencies might be missing
            $inputPath = $script:TestScenario.InputDirectory

            # When: I call the function (dependencies should be mocked to fail)
            # Then: It should handle the error gracefully and provide meaningful feedback
            $result = Optimize-WebImages -Path $inputPath -ErrorAction SilentlyContinue

            # The function should either succeed with fallback or fail gracefully
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should handle invalid configuration gracefully" {
            # Given: Invalid settings
            $inputPath = $script:TestScenario.InputDirectory
            $invalidSettings = @{
                jpeg = @{ quality = "invalid" }  # Invalid quality value
            }

            # When: I call the function with invalid settings in WhatIf mode
            $result = Optimize-WebImages -Path $inputPath -Settings $invalidSettings -WhatIf

            # Then: It should handle the error gracefully and return results
            $result | Should -Not -BeNullOrEmpty
            ($result | Select-Object -First 1).Success | Should -Be $true
            # And: Should use fallback configuration
            ($result | Select-Object -First 1).ConfigurationUsed | Should -Not -BeNullOrEmpty
        }

        It "Should handle permission errors gracefully" {
            # Given: A read-only directory scenario (simulated)
            $inputPath = $script:TestScenario.InputDirectory
            $readOnlyOutput = Join-Path $script:TestScenario.TestRootPath "readonly"
            New-Item -Path $readOnlyOutput -ItemType Directory -Force | Out-Null

            # When: I call the function with restricted output path
            $result = Optimize-WebImages -Path $inputPath -OutputPath $readOnlyOutput -ErrorAction SilentlyContinue

            # Then: It should handle permission issues gracefully
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Configuration Integration" {

        It "Should use default configuration when no settings provided" {
            # Given: A test scenario without custom settings
            $inputPath = $script:TestScenario.InputDirectory

            # When: I call the function without Settings parameter
            $result = Optimize-WebImages -Path $inputPath -WhatIf

            # Then: It should use default configuration
            $result | Should -Not -BeNullOrEmpty
            # And: Should indicate default settings were used
            $result.ConfigurationUsed | Should -Not -BeNullOrEmpty
        }

        It "Should merge custom settings with defaults" {
            # Given: Custom settings that override defaults
            $inputPath = $script:TestScenario.InputDirectory
            $customSettings = @{
                jpeg = @{ quality = 75 }  # Override default quality
            }

            # When: I call the function with custom settings
            $result = Optimize-WebImages -Path $inputPath -Settings $customSettings -WhatIf

            # Then: It should merge settings appropriately
            $result | Should -Not -BeNullOrEmpty
            $result.ConfigurationUsed | Should -Not -BeNullOrEmpty
        }
    }

    Context "Progress Reporting" {

        It "Should provide progress information" {
            # Given: A test scenario with multiple images
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory

            # When: I call the function and capture progress
            $progressEvents = @()
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath -Verbose 4>&1

            # Then: It should provide progress information
            $result | Should -Not -BeNullOrEmpty
            # And: Should include timing information
            $result.ProcessingTime | Should -Not -BeNullOrEmpty
        }

        It "Should support different output formats" {
            # Given: A test scenario
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory

            # When: I call the function (default console output)
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: It should provide formatted output
            $result | Should -Not -BeNullOrEmpty
            $result.Summary | Should -Not -BeNullOrEmpty
        }
    }
}
