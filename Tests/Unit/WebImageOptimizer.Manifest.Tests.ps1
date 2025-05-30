# Test suite for WebImageOptimizer Module Manifest Configuration (Task 2)
# BDD/TDD implementation following Given-When-Then structure

# Define the module root path
$ModuleRoot = if ($PSScriptRoot) {
    $PSScriptRoot | Split-Path | Split-Path  # Go up two levels from Tests\Unit to root
} else {
    "d:\repos\PSWebImage"  # Fallback for direct execution
}
$ModulePath = Join-Path $ModuleRoot "WebImageOptimizer"
$ManifestPath = Join-Path $ModulePath "WebImageOptimizer.psd1"

Describe "WebImageOptimizer Module Manifest Configuration" {

    BeforeAll {
        # Ensure we have the module manifest available for testing
        $script:ManifestData = $null
        if (Test-Path $ManifestPath) {
            $script:ManifestData = Test-ModuleManifest -Path $ManifestPath
        }
    }

    Context "When configuring module manifest metadata" {

        It "Should have a valid manifest that passes Test-ModuleManifest validation" {
            # Given: A PowerShell module manifest file exists
            # When: Running Test-ModuleManifest validation
            # Then: The manifest should pass validation without errors
            Test-Path $ManifestPath | Should -Be $true
            { Test-ModuleManifest -Path $ManifestPath } | Should -Not -Throw
        }

        It "Should specify PowerShell version requirement of 7.0 or higher" {
            # Given: The module is designed for PowerShell 7.0+
            # When: Checking the PowerShell version requirement
            # Then: PowerShellVersion should be set to 7.0
            $script:ManifestData.PowerShellVersion | Should -Be '7.0'
        }

        It "Should declare .NET 6.0+ compatibility through CompatiblePSEditions" {
            # Given: The module requires .NET 6.0+ for image processing capabilities
            # When: Checking CompatiblePSEditions configuration
            # Then: Should specify Core edition for .NET 6.0+ compatibility
            $script:ManifestData.CompatiblePSEditions | Should -Contain 'Core' -Because ".NET 6.0+ requires PowerShell Core edition"
        }

        It "Should have proper module description matching PRD objectives" {
            # Given: PRD specifies module objectives for web image optimization
            # When: Checking module description
            # Then: Description should match PRD requirements and be comprehensive
            $script:ManifestData.Description | Should -Not -BeNullOrEmpty
            $script:ManifestData.Description | Should -Match "optim.*image.*web" -Because "Description should reflect web image optimization purpose"
            $script:ManifestData.Description | Should -Match "batch.*process" -Because "Description should mention batch processing capability"
        }

        It "Should have proper module description matching PRD objectives" {
            # Given: The PRD specifies module objectives for web image optimization
            # When: Checking the module description
            # Then: Description should mention web image optimization and batch processing
            $description = $script:ManifestData.Description
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "optim.*image.*web" -Because "Description should mention web image optimization"
            $description | Should -Match "batch.*process" -Because "Description should mention batch processing capabilities"
        }

        It "Should declare .NET 6.0+ compatibility through CompatiblePSEditions" {
            # Given: The module requires .NET 6.0+ compatibility
            # When: Checking CompatiblePSEditions
            # Then: Should include Core edition for .NET 6+ compatibility
            $script:ManifestData.CompatiblePSEditions | Should -Contain 'Core' -Because ".NET 6+ requires PowerShell Core edition"
        }

        It "Should have proper author information" {
            # Given: The module needs proper attribution
            # When: Checking author metadata
            # Then: Author should be properly specified
            $script:ManifestData.Author | Should -Not -BeNullOrEmpty
            $script:ManifestData.Author | Should -Be 'PowerShell Web Image Optimizer Team'
        }

        It "Should have a valid GUID for module identification" {
            # Given: PowerShell modules require unique identification
            # When: Checking the module GUID
            # Then: GUID should be a valid format and not empty
            $script:ManifestData.Guid | Should -Not -BeNullOrEmpty
            $script:ManifestData.Guid.ToString() | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        }

        It "Should have proper module version" {
            # Given: The module is in version 1.0.0 development
            # When: Checking the module version
            # Then: Version should be properly formatted
            $script:ManifestData.Version | Should -Not -BeNullOrEmpty
            $script:ManifestData.Version.ToString() | Should -Match '^\d+\.\d+\.\d+$'
        }

        It "Should have proper copyright information" {
            # Given: The module needs proper copyright attribution
            # When: Checking copyright information
            # Then: Copyright should be properly formatted
            $script:ManifestData.Copyright | Should -Not -BeNullOrEmpty
            $script:ManifestData.Copyright | Should -Match 'PowerShell Web Image Optimizer Team'
        }
    }

    Context "When configuring exported functions" {

        It "Should properly declare exported functions instead of using wildcards" {
            # Given: Best practices recommend explicit function exports over wildcards
            # When: Checking FunctionsToExport
            # Then: Should not use wildcard exports for production modules
            # Note: This test will initially fail and guide implementation
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Not -Match "FunctionsToExport\s*=\s*'\*'" -Because "Production modules should explicitly declare exported functions"
        }

        It "Should have empty or explicit cmdlet exports" {
            # Given: The module doesn't export cmdlets, only functions
            # When: Checking CmdletsToExport
            # Then: Should be an empty array or not use wildcards
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Not -Match "CmdletsToExport\s*=\s*'\*'" -Because "Module should explicitly declare cmdlet exports"
        }

        It "Should have empty or explicit variable exports" {
            # Given: The module should not export variables by default
            # When: Checking VariablesToExport
            # Then: Should be an empty array or not use wildcards
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Not -Match "VariablesToExport\s*=\s*'\*'" -Because "Module should not export variables by default"
        }

        It "Should have empty or explicit alias exports" {
            # Given: The module may not need to export aliases
            # When: Checking AliasesToExport
            # Then: Should be explicitly declared, not wildcarded
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Not -Match "AliasesToExport\s*=\s*'\*'" -Because "Module should explicitly declare alias exports"
        }
    }

    Context "When configuring PowerShell Gallery metadata" {

        It "Should have proper tags for PowerShell Gallery discovery" {
            # Given: The module will be published to PowerShell Gallery
            # When: Checking PSData tags
            # Then: Should include relevant tags for image processing and web optimization
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Match "Tags\s*=\s*@\(" -Because "Module should have tags for gallery discovery"

            # Check for relevant tags in the content
            $manifestContent | Should -Match "Image|Web|Optim|Batch" -Because "Tags should include relevant keywords"
        }

        It "Should have project URI for PowerShell Gallery" {
            # Given: PowerShell Gallery modules should have project information
            # When: Checking ProjectUri
            # Then: Should be configured or prepared for configuration
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Match "ProjectUri\s*=" -Because "Module should have project URI configured"
        }

        It "Should have license URI for PowerShell Gallery" {
            # Given: PowerShell Gallery modules should specify licensing
            # When: Checking LicenseUri
            # Then: Should be configured or prepared for configuration
            $manifestContent = Get-Content $ManifestPath -Raw
            $manifestContent | Should -Match "LicenseUri\s*=" -Because "Module should have license URI configured"
        }
    }

    Context "When validating module loading and metadata display" {

        It "Should load correctly and display proper metadata" {
            # Given: The module manifest is properly configured
            # When: Importing the module and checking metadata
            # Then: Module should load with correct information displayed

            # Clean up any existing module
            if (Get-Module -Name WebImageOptimizer) {
                Remove-Module WebImageOptimizer -Force
            }

            # Import and test
            { Import-Module $ModulePath -Force } | Should -Not -Throw

            $module = Get-Module -Name WebImageOptimizer
            $module | Should -Not -BeNull
            $module.Description | Should -Not -BeNullOrEmpty
            $module.Version | Should -Not -BeNull
            $module.PowerShellVersion | Should -Be '7.0'

            # Clean up
            Remove-Module WebImageOptimizer -Force
        }

        It "Should have consistent version information between manifest and displayed module" {
            # Given: Module version should be consistent
            # When: Comparing manifest version with loaded module version
            # Then: Versions should match exactly

            # Clean up any existing module
            if (Get-Module -Name WebImageOptimizer) {
                Remove-Module WebImageOptimizer -Force
            }

            Import-Module $ModulePath -Force
            $loadedModule = Get-Module -Name WebImageOptimizer

            $loadedModule.Version | Should -Be $script:ManifestData.Version

            # Clean up
            Remove-Module WebImageOptimizer -Force
        }
    }
}

Describe "WebImageOptimizer Module Manifest PRD Compliance" {

    Context "When validating PRD specification requirements" {

        It "Should meet all PRD metadata requirements" {
            # Given: The PRD specifies specific requirements for the module
            # When: Validating against PRD requirements
            # Then: All requirements should be met

            $manifestContent = Get-Content $ManifestPath -Raw

            # PowerShell 7.0+ requirement
            $manifestContent | Should -Match "PowerShellVersion\s*=\s*'7\.0'" -Because "PRD requires PowerShell 7.0+"

            # Description should match PRD objectives
            $script:ManifestData.Description | Should -Match "optim.*image" -Because "PRD focuses on image optimization"
            $script:ManifestData.Description | Should -Match "web" -Because "PRD is specifically for web image optimization"

            # Should support batch processing
            $script:ManifestData.Description | Should -Match "batch" -Because "PRD requires batch processing capabilities"
        }

        It "Should declare .NET 6.0+ compatibility as required by PRD" {
            # Given: PRD specifies .NET 6.0+ compatibility requirement
            # When: Checking module compatibility declarations
            # Then: Should indicate .NET 6.0+ support through Core edition
            $script:ManifestData.CompatiblePSEditions | Should -Contain 'Core' -Because "PRD requires .NET 6.0+ which needs PowerShell Core"
        }

        It "Should be configured for integration into PowerShell workflows" {
            # Given: PRD requires easy integration into PowerShell workflows
            # When: Checking module configuration
            # Then: Module should be properly configured for workflow integration
            $script:ManifestData.RootModule | Should -Be 'WebImageOptimizer.psm1'
            $script:ManifestData.PowerShellVersion | Should -Be '7.0'
        }
    }
}
