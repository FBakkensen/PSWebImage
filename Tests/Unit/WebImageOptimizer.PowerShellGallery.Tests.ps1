# WebImageOptimizer PowerShell Gallery Preparation Tests
# Comprehensive BDD tests for PowerShell Gallery publication readiness
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

BeforeAll {
    # Import required modules and test helpers
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $TestHelpersPath = Join-Path $ModuleRoot "Tests\TestHelpers"

    # Import test helpers
    if (Test-Path (Join-Path $TestHelpersPath "PathResolution.psm1")) {
        Import-Module (Join-Path $TestHelpersPath "PathResolution.psm1") -Force
    }

    # Import test data library
    $TestDataLibraryPath = Join-Path $ModuleRoot "Tests\TestDataLibraries\PowerShellGallery.TestDataLibrary.ps1"
    if (Test-Path $TestDataLibraryPath) {
        . $TestDataLibraryPath
    }

    # Set up test paths
    $script:ModuleRoot = Get-ModuleRootPath
    $script:ManifestPath = Join-Path $script:ModuleRoot "WebImageOptimizer\WebImageOptimizer.psd1"
    $script:LicensePath = Join-Path $script:ModuleRoot "LICENSE"
    $script:ReleaseNotesPath = Join-Path $script:ModuleRoot "RELEASE_NOTES.md"
    $script:ReadmePath = Join-Path $script:ModuleRoot "README.md"

    # Create test scenario
    $script:TestRootPath = Join-Path ([System.IO.Path]::GetTempPath()) "PSWebImage_PowerShellGallery_Tests_$(Get-Random)"
    $script:GalleryScenario = New-PowerShellGalleryTestScenario -TestRootPath $script:TestRootPath
}

AfterAll {
    # Clean up test data
    if ($script:TestRootPath -and (Test-Path $script:TestRootPath)) {
        Remove-PowerShellGalleryTestData -TestRootPath $script:TestRootPath
    }
}

Describe "WebImageOptimizer PowerShell Gallery Preparation" -Tags @('Unit', 'PowerShellGallery', 'Publication') {

    Context "Given a PowerShell module ready for PowerShell Gallery publication" {

        BeforeAll {
            # Verify test scenario is properly set up
            $script:GalleryScenario | Should -Not -BeNull
            $script:GalleryScenario.ValidationCriteria | Should -Not -BeNull
        }

        It "Should have a valid test scenario with validation criteria" {
            # Given: A PowerShell Gallery test scenario
            # When: Checking the test scenario setup
            # Then: All required validation criteria should be defined
            $script:GalleryScenario.ValidationCriteria | Should -Not -BeNull
            $script:GalleryScenario.ValidationCriteria.LicenseValidation | Should -Not -BeNull
            $script:GalleryScenario.ValidationCriteria.ManifestValidation | Should -Not -BeNull
            $script:GalleryScenario.ValidationCriteria.DocumentationValidation | Should -Not -BeNull
        }
    }

    Context "When checking licensing requirements for PowerShell Gallery" {

        It "Should have a LICENSE file in the module root" {
            # Given: A module ready for PowerShell Gallery publication
            # When: Checking for licensing requirements
            # Then: A LICENSE file should exist in the module root
            Test-Path $script:LicensePath | Should -Be $true -Because "PowerShell Gallery requires a LICENSE file"
        }

        It "Should have MIT license content in the LICENSE file" {
            # Given: An existing LICENSE file
            # When: Validating the license content
            # Then: The file should contain proper MIT license text
            if (Test-Path $script:LicensePath) {
                $licenseContent = Get-Content -Path $script:LicensePath -Raw
                $expectedContent = Get-ExpectedMITLicenseContent

                # Check for key MIT license components
                $licenseContent | Should -Match "MIT License" -Because "LICENSE file should specify MIT License"
                $licenseContent | Should -Match "Copyright.*2025.*PowerShell Web Image Optimizer Team" -Because "LICENSE should have proper copyright"
                $licenseContent | Should -Match "Permission is hereby granted" -Because "LICENSE should contain MIT permission clause"
                $licenseContent | Should -Match "THE SOFTWARE IS PROVIDED" -Because "LICENSE should contain MIT warranty disclaimer"
            }
        }

        It "Should have valid license URI in module manifest" {
            # Given: A module manifest configured for PowerShell Gallery
            # When: Checking the license URI
            # Then: The manifest should have a valid license URI
            if (Test-Path $script:ManifestPath) {
                $manifestContent = Import-PowerShellDataFile -Path $script:ManifestPath
                $manifestContent.PrivateData.PSData.LicenseUri | Should -Not -BeNullOrEmpty -Because "PowerShell Gallery requires license URI"
                $manifestContent.PrivateData.PSData.LicenseUri | Should -Match "LICENSE" -Because "License URI should reference LICENSE file"
            }
        }
    }

    Context "When validating module manifest for PowerShell Gallery compliance" {

        BeforeAll {
            # Load manifest data for testing
            if (Test-Path $script:ManifestPath) {
                $script:ManifestData = Import-PowerShellDataFile -Path $script:ManifestPath
            }
        }

        It "Should pass Test-ModuleManifest validation" {
            # Given: A PowerShell module manifest
            # When: Running Test-ModuleManifest validation
            # Then: The manifest should pass validation without errors
            Test-Path $script:ManifestPath | Should -Be $true
            { Test-ModuleManifest -Path $script:ManifestPath } | Should -Not -Throw -Because "Manifest must pass PowerShell Gallery validation"
        }

        It "Should have all required manifest fields for PowerShell Gallery" {
            # Given: A module manifest for PowerShell Gallery publication
            # When: Checking required fields
            # Then: All required fields should be present and valid
            $script:ManifestData | Should -Not -BeNull

            $requiredFields = $script:GalleryScenario.RequiredManifestFields
            foreach ($field in $requiredFields) {
                $script:ManifestData.$field | Should -Not -BeNullOrEmpty -Because "PowerShell Gallery requires $field"
            }
        }

        It "Should have valid semantic version number" {
            # Given: A module manifest with version information
            # When: Checking the version format
            # Then: Version should follow semantic versioning (x.y.z)
            $script:ManifestData.ModuleVersion | Should -Match '^\d+\.\d+\.\d+$' -Because "PowerShell Gallery requires semantic versioning"
        }

        It "Should have valid GUID format" {
            # Given: A module manifest with GUID
            # When: Checking the GUID format
            # Then: GUID should be properly formatted
            $script:ManifestData.GUID | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' -Because "PowerShell Gallery requires valid GUID"
        }

        It "Should have all required PSData fields for PowerShell Gallery" {
            # Given: A module manifest with PSData section
            # When: Checking PSData requirements
            # Then: All required PSData fields should be present
            $script:ManifestData.PrivateData.PSData | Should -Not -BeNull -Because "PowerShell Gallery requires PSData section"

            $requiredPSDataFields = $script:GalleryScenario.RequiredPSDataFields
            foreach ($field in $requiredPSDataFields) {
                $script:ManifestData.PrivateData.PSData.$field | Should -Not -BeNullOrEmpty -Because "PowerShell Gallery requires PSData.$field"
            }
        }

        It "Should have appropriate tags for PowerShell Gallery discovery" {
            # Given: A module manifest with tags
            # When: Checking tag requirements
            # Then: Should have sufficient relevant tags
            $tags = $script:ManifestData.PrivateData.PSData.Tags
            $tags | Should -Not -BeNull -Because "PowerShell Gallery requires tags for discovery"
            $tags.Count | Should -BeGreaterOrEqual 3 -Because "PowerShell Gallery recommends multiple tags"

            # Check for relevant tags
            $tags | Should -Contain "Image" -Because "Module is for image processing"
            $tags | Should -Contain "Web" -Because "Module is for web optimization"
            $tags | Should -Contain "Optimization" -Because "Module performs optimization"
        }

        It "Should have meaningful description for PowerShell Gallery" {
            # Given: A module manifest with description
            # When: Checking description requirements
            # Then: Description should be meaningful and appropriate length
            $description = $script:ManifestData.Description
            $description | Should -Not -BeNullOrEmpty -Because "PowerShell Gallery requires description"
            $description.Length | Should -BeGreaterOrEqual 50 -Because "Description should be meaningful"
            $description.Length | Should -BeLessOrEqual 500 -Because "Description should not be too long"
            $description | Should -Match "optim.*image" -Because "Description should mention image optimization"
        }

        It "Should specify PowerShell 7.0+ requirement" {
            # Given: A module designed for PowerShell 7
            # When: Checking PowerShell version requirements
            # Then: Should specify PowerShell 7.0 or higher
            $script:ManifestData.PowerShellVersion | Should -Be '7.0' -Because "Module requires PowerShell 7.0+"
            $script:ManifestData.CompatiblePSEditions | Should -Contain 'Core' -Because "PowerShell 7 uses Core edition"
        }

        It "Should have proper function exports" {
            # Given: A module with public functions
            # When: Checking function exports
            # Then: Should export the correct public functions
            $script:ManifestData.FunctionsToExport | Should -Not -BeNull -Because "Module should export functions"
            $script:ManifestData.FunctionsToExport | Should -Contain "Optimize-WebImages" -Because "Main function should be exported"
            $script:ManifestData.FunctionsToExport | Should -Contain "Invoke-WebImageBenchmark" -Because "Benchmark function should be exported"
        }
    }

    Context "When validating release notes for PowerShell Gallery" {

        It "Should have comprehensive release notes file" {
            # Given: A module ready for publication
            # When: Checking for release notes documentation
            # Then: A comprehensive release notes file should exist
            Test-Path $script:ReleaseNotesPath | Should -Be $true -Because "PowerShell Gallery benefits from detailed release notes"
        }

        It "Should have release notes in manifest" {
            # Given: A module manifest for PowerShell Gallery
            # When: Checking manifest release notes
            # Then: Release notes should be present and meaningful
            if (Test-Path $script:ManifestPath) {
                $manifestContent = Import-PowerShellDataFile -Path $script:ManifestPath
                $manifestContent.PrivateData.PSData.ReleaseNotes | Should -Not -BeNullOrEmpty -Because "PowerShell Gallery displays release notes"
                $manifestContent.PrivateData.PSData.ReleaseNotes.Length | Should -BeGreaterThan 50 -Because "Release notes should be meaningful"
            }
        }

        It "Should document key features in release notes" {
            # Given: Existing release notes file
            # When: Validating release notes content
            # Then: Key features should be documented
            if (Test-Path $script:ReleaseNotesPath) {
                $releaseContent = Get-Content -Path $script:ReleaseNotesPath -Raw
                $releaseContent | Should -Match "PowerShell 7" -Because "Release notes should mention PowerShell 7 requirement"
                $releaseContent | Should -Match "ImageMagick" -Because "Release notes should mention ImageMagick dependency"
                $releaseContent | Should -Match "parallel.*processing" -Because "Release notes should mention parallel processing"
                $releaseContent | Should -Match "cross-platform" -Because "Release notes should mention cross-platform support"
            }
        }
    }

    Context "When validating overall PowerShell Gallery publication readiness" {

        It "Should have comprehensive documentation for users" {
            # Given: A module for PowerShell Gallery publication
            # When: Checking documentation completeness
            # Then: All required documentation should be present
            Test-Path $script:ReadmePath | Should -Be $true -Because "PowerShell Gallery requires README"

            if (Test-Path $script:ReadmePath) {
                $readmeContent = Get-Content -Path $script:ReadmePath -Raw
                $readmeContent | Should -Match "Install-Module" -Because "README should include installation instructions"
                $readmeContent | Should -Match "PowerShell Gallery" -Because "README should mention PowerShell Gallery"
                $readmeContent | Should -Match "Optimize-WebImages.*-Path" -Because "README should include usage examples"
            }
        }

        It "Should pass comprehensive PowerShell Gallery manifest validation" {
            # Given: A complete module manifest
            # When: Running comprehensive PowerShell Gallery validation
            # Then: All validation checks should pass
            $validationResult = Test-PowerShellGalleryManifest -ManifestPath $script:ManifestPath -ValidationCriteria $script:GalleryScenario.ValidationCriteria

            $validationResult.ManifestExists | Should -Be $true -Because "Manifest file must exist"
            $validationResult.PassesTestModuleManifest | Should -Be $true -Because "Manifest must pass Test-ModuleManifest"
            $validationResult.HasRequiredFields | Should -Be $true -Because "All required fields must be present"
            $validationResult.HasValidVersion | Should -Be $true -Because "Version must be valid semantic version"
            $validationResult.HasValidGuid | Should -Be $true -Because "GUID must be properly formatted"
            $validationResult.HasRequiredPSData | Should -Be $true -Because "PSData section must be complete"
            $validationResult.HasValidTags | Should -Be $true -Because "Tags must be appropriate and sufficient"
            $validationResult.HasValidDescription | Should -Be $true -Because "Description must be meaningful"

            if ($validationResult.ValidationErrors.Count -gt 0) {
                Write-Host "Validation Errors:" -ForegroundColor Red
                $validationResult.ValidationErrors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            }

            $validationResult.ValidationErrors.Count | Should -Be 0 -Because "No validation errors should exist for PowerShell Gallery publication"
        }

        It "Should be ready for Publish-Module command" {
            # Given: A complete PowerShell module
            # When: Checking overall publication readiness
            # Then: Module should be ready for Publish-Module command

            # Check all critical files exist
            Test-Path $script:ManifestPath | Should -Be $true -Because "Manifest is required for publication"
            Test-Path $script:LicensePath | Should -Be $true -Because "License is required for publication"
            Test-Path $script:ReadmePath | Should -Be $true -Because "README is required for publication"

            # Check manifest passes validation
            { Test-ModuleManifest -Path $script:ManifestPath } | Should -Not -Throw -Because "Manifest must be valid for publication"

            # Check module can be imported
            $modulePath = Split-Path $script:ManifestPath
            { Import-Module $modulePath -Force } | Should -Not -Throw -Because "Module must import successfully for publication"

            # Clean up module import
            if (Get-Module -Name WebImageOptimizer) {
                Remove-Module WebImageOptimizer -Force
            }
        }
    }
}
