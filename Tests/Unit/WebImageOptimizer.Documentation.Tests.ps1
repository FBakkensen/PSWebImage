# WebImageOptimizer Documentation Tests
# Comprehensive BDD tests for documentation completeness and quality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

# Import required modules and test helpers
BeforeAll {
    # Import the test helper module for path resolution
    Import-Module (Join-Path $PSScriptRoot ".." "TestHelpers" "PathResolution.psm1") -Force

    # Import the test data library
    . (Join-Path $PSScriptRoot ".." "TestDataLibraries" "Documentation.TestDataLibrary.ps1")

    # Define the module root path with robust resolution
    $script:ModuleRoot = Get-ModuleRootPath

    # Define test paths
    $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_DocTests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:DocumentationScenario = $null
}

# Clean up after all tests
AfterAll {
    if ($script:DocumentationScenario -and $script:DocumentationScenario.TestRootPath) {
        Remove-DocumentationTestData -TestRootPath $script:DocumentationScenario.TestRootPath
    }
}

Describe "WebImageOptimizer Documentation Structure" -Tag @('Unit', 'Documentation', 'Structure') {

    BeforeAll {
        # Create documentation test scenario
        $script:DocumentationScenario = New-DocumentationTestScenario -TestRootPath $script:TestRoot
    }

    Context "When validating documentation file structure" {

        It "Should have expected documentation files defined in test scenario" {
            # Given: A documentation test scenario
            # When: Checking the expected files
            # Then: All required documentation files should be defined
            $script:DocumentationScenario.ExpectedFiles | Should -Not -BeNullOrEmpty
            $script:DocumentationScenario.ExpectedFiles.Count | Should -BeGreaterThan 0
            $script:DocumentationScenario.TotalFiles | Should -Be 5
        }

        It "Should define validation criteria for documentation quality" {
            # Given: A documentation test scenario
            # When: Checking validation criteria
            # Then: Comprehensive validation criteria should be defined
            $criteria = $script:DocumentationScenario.ValidationCriteria
            $criteria | Should -Not -BeNullOrEmpty
            $criteria.MinimumSections | Should -BeGreaterThan 0
            $criteria.MinimumExamples | Should -BeGreaterThan 0
            $criteria.RequiredCodeBlocks | Should -Not -BeNullOrEmpty
        }

        It "Should have required sections defined for each documentation file" {
            # Given: Expected documentation files
            # When: Checking required sections
            # Then: Each file should have required sections defined
            foreach ($file in $script:DocumentationScenario.ExpectedFiles) {
                $file.RequiredSections | Should -Not -BeNullOrEmpty
                $file.RequiredSections.Count | Should -BeGreaterThan 3
            }
        }

        It "Should have required content defined for each documentation file" {
            # Given: Expected documentation files
            # When: Checking required content
            # Then: Each file should have required content defined
            foreach ($file in $script:DocumentationScenario.ExpectedFiles) {
                $file.RequiredContent | Should -Not -BeNullOrEmpty
                $file.RequiredContent.Count | Should -BeGreaterThan 2
            }
        }
    }
}

Describe "WebImageOptimizer Documentation Content Validation" -Tag @('Unit', 'Documentation', 'Content') {

    BeforeAll {
        # Ensure documentation scenario exists
        if (-not $script:DocumentationScenario) {
            $script:DocumentationScenario = New-DocumentationTestScenario -TestRootPath $script:TestRoot
        }
    }

    Context "When validating README.md documentation" {

        BeforeAll {
            $script:ReadmeFile = $script:DocumentationScenario.ExpectedFiles | Where-Object { $_.Name -eq "README.md" }
            $script:ReadmePath = Join-Path $script:ModuleRoot "README.md"
        }

        It "Should exist in the module root directory" {
            # Given: The WebImageOptimizer module
            # When: Looking for README.md in the root directory
            # Then: README.md should exist
            Test-Path $script:ReadmePath | Should -Be $true
        }

        It "Should contain all required sections for main README" {
            # Given: An existing README.md file
            # When: Validating the content structure
            # Then: All required sections should be present
            if (Test-Path $script:ReadmePath) {
                $validation = Test-DocumentationContent -FilePath $script:ReadmePath -ExpectedFile $script:ReadmeFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredSections | Should -Be $true -Because "README should contain all required sections: $($script:ReadmeFile.RequiredSections -join ', ')"
            }
        }

        It "Should contain required content for PowerShell module documentation" {
            # Given: An existing README.md file
            # When: Validating the content
            # Then: Required content should be present
            if (Test-Path $script:ReadmePath) {
                $validation = Test-DocumentationContent -FilePath $script:ReadmePath -ExpectedFile $script:ReadmeFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredContent | Should -Be $true -Because "README should contain required content: $($script:ReadmeFile.RequiredContent -join ', ')"
            }
        }

        It "Should have sufficient examples and usage information" {
            # Given: An existing README.md file
            # When: Validating examples
            # Then: Sufficient examples should be present
            if (Test-Path $script:ReadmePath) {
                $validation = Test-DocumentationContent -FilePath $script:ReadmePath -ExpectedFile $script:ReadmeFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.ExampleCount | Should -BeGreaterOrEqual $script:DocumentationScenario.ValidationCriteria.MinimumExamples
            }
        }
    }

    Context "When validating User Guide documentation" {

        BeforeAll {
            $script:UserGuideFile = $script:DocumentationScenario.ExpectedFiles | Where-Object { $_.Name -eq "UserGuide.md" }
            $script:UserGuidePath = Join-Path $script:ModuleRoot "docs" "UserGuide.md"
        }

        It "Should exist in the docs directory" {
            # Given: The WebImageOptimizer module
            # When: Looking for UserGuide.md in the docs directory
            # Then: UserGuide.md should exist
            Test-Path $script:UserGuidePath | Should -Be $true
        }

        It "Should contain comprehensive user guidance sections" {
            # Given: An existing UserGuide.md file
            # When: Validating the content structure
            # Then: All required sections should be present
            if (Test-Path $script:UserGuidePath) {
                $validation = Test-DocumentationContent -FilePath $script:UserGuidePath -ExpectedFile $script:UserGuideFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredSections | Should -Be $true -Because "User Guide should contain all required sections: $($script:UserGuideFile.RequiredSections -join ', ')"
            }
        }

        It "Should contain detailed usage examples and best practices" {
            # Given: An existing UserGuide.md file
            # When: Validating the content
            # Then: Required content should be present
            if (Test-Path $script:UserGuidePath) {
                $validation = Test-DocumentationContent -FilePath $script:UserGuidePath -ExpectedFile $script:UserGuideFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredContent | Should -Be $true -Because "User Guide should contain required content: $($script:UserGuideFile.RequiredContent -join ', ')"
            }
        }
    }

    Context "When validating API Reference documentation" {

        BeforeAll {
            $script:APIFile = $script:DocumentationScenario.ExpectedFiles | Where-Object { $_.Name -eq "API.md" }
            $script:APIPath = Join-Path $script:ModuleRoot "docs" "API.md"
        }

        It "Should exist in the docs directory" {
            # Given: The WebImageOptimizer module
            # When: Looking for API.md in the docs directory
            # Then: API.md should exist
            Test-Path $script:APIPath | Should -Be $true
        }

        It "Should document all public functions with parameters and examples" {
            # Given: An existing API.md file
            # When: Validating the API documentation
            # Then: All public functions should be documented
            if (Test-Path $script:APIPath) {
                $validation = Test-DocumentationContent -FilePath $script:APIPath -ExpectedFile $script:APIFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredSections | Should -Be $true -Because "API documentation should contain all required sections: $($script:APIFile.RequiredSections -join ', ')"
                $validation.HasRequiredContent | Should -Be $true -Because "API documentation should contain required content: $($script:APIFile.RequiredContent -join ', ')"
            }
        }
    }

    Context "When validating Configuration Guide documentation" {

        BeforeAll {
            $script:ConfigFile = $script:DocumentationScenario.ExpectedFiles | Where-Object { $_.Name -eq "Configuration.md" }
            $script:ConfigPath = Join-Path $script:ModuleRoot "docs" "Configuration.md"
        }

        It "Should exist in the docs directory" {
            # Given: The WebImageOptimizer module
            # When: Looking for Configuration.md in the docs directory
            # Then: Configuration.md should exist
            Test-Path $script:ConfigPath | Should -Be $true
        }

        It "Should provide comprehensive configuration guidance" {
            # Given: An existing Configuration.md file
            # When: Validating the configuration documentation
            # Then: Comprehensive configuration guidance should be present
            if (Test-Path $script:ConfigPath) {
                $validation = Test-DocumentationContent -FilePath $script:ConfigPath -ExpectedFile $script:ConfigFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredSections | Should -Be $true -Because "Configuration guide should contain all required sections: $($script:ConfigFile.RequiredSections -join ', ')"
                $validation.HasRequiredContent | Should -Be $true -Because "Configuration guide should contain required content: $($script:ConfigFile.RequiredContent -join ', ')"
            }
        }
    }

    Context "When validating Troubleshooting Guide documentation" {

        BeforeAll {
            $script:TroubleshootingFile = $script:DocumentationScenario.ExpectedFiles | Where-Object { $_.Name -eq "Troubleshooting.md" }
            $script:TroubleshootingPath = Join-Path $script:ModuleRoot "docs" "Troubleshooting.md"
        }

        It "Should exist in the docs directory" {
            # Given: The WebImageOptimizer module
            # When: Looking for Troubleshooting.md in the docs directory
            # Then: Troubleshooting.md should exist
            Test-Path $script:TroubleshootingPath | Should -Be $true
        }

        It "Should provide comprehensive troubleshooting guidance and FAQ" {
            # Given: An existing Troubleshooting.md file
            # When: Validating the troubleshooting documentation
            # Then: Comprehensive troubleshooting guidance should be present
            if (Test-Path $script:TroubleshootingPath) {
                $validation = Test-DocumentationContent -FilePath $script:TroubleshootingPath -ExpectedFile $script:TroubleshootingFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                $validation.HasRequiredSections | Should -Be $true -Because "Troubleshooting guide should contain all required sections: $($script:TroubleshootingFile.RequiredSections -join ', ')"
                $validation.HasRequiredContent | Should -Be $true -Because "Troubleshooting guide should contain required content: $($script:TroubleshootingFile.RequiredContent -join ', ')"
            }
        }
    }
}

Describe "WebImageOptimizer Documentation Quality Assurance" -Tag @('Unit', 'Documentation', 'Quality') {

    BeforeAll {
        # Ensure documentation scenario exists
        if (-not $script:DocumentationScenario) {
            $script:DocumentationScenario = New-DocumentationTestScenario -TestRootPath $script:TestRoot
        }
    }

    Context "When validating overall documentation completeness" {

        It "Should have all required documentation files present" {
            # Given: The WebImageOptimizer module
            # When: Checking for all required documentation files
            # Then: All documentation files should exist
            $missingFiles = @()
            foreach ($expectedFile in $script:DocumentationScenario.ExpectedFiles) {
                $actualPath = if ($expectedFile.Name -eq "README.md") {
                    Join-Path $script:ModuleRoot $expectedFile.Name
                } else {
                    Join-Path $script:ModuleRoot "docs" $expectedFile.Name
                }
                
                if (-not (Test-Path $actualPath)) {
                    $missingFiles += $expectedFile.Name
                }
            }
            
            $missingFiles | Should -BeNullOrEmpty -Because "All documentation files should exist: $($missingFiles -join ', ')"
        }

        It "Should have consistent documentation structure across all files" {
            # Given: All documentation files
            # When: Validating structure consistency
            # Then: All files should follow consistent structure patterns
            $structureIssues = @()
            foreach ($expectedFile in $script:DocumentationScenario.ExpectedFiles) {
                $actualPath = if ($expectedFile.Name -eq "README.md") {
                    Join-Path $script:ModuleRoot $expectedFile.Name
                } else {
                    Join-Path $script:ModuleRoot "docs" $expectedFile.Name
                }
                
                if (Test-Path $actualPath) {
                    $validation = Test-DocumentationContent -FilePath $actualPath -ExpectedFile $expectedFile -ValidationCriteria $script:DocumentationScenario.ValidationCriteria
                    if ($validation.ValidationErrors.Count -gt 0) {
                        $structureIssues += "$($expectedFile.Name): $($validation.ValidationErrors -join '; ')"
                    }
                }
            }
            
            $structureIssues | Should -BeNullOrEmpty -Because "All documentation should have consistent structure: $($structureIssues -join ' | ')"
        }
    }
}
