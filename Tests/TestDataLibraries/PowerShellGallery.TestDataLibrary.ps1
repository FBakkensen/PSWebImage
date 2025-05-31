# PowerShell Gallery Test Data Library
# Centralized test data creation for WebImageOptimizer PowerShell Gallery preparation testing
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates PowerShell Gallery publication readiness test scenario and validation data.

.DESCRIPTION
    Creates comprehensive test scenarios for validating PowerShell Gallery publication readiness,
    including license validation, manifest compliance, release notes validation, and overall
    gallery publication requirements.

.PARAMETER TestRootPath
    The root path where the PowerShell Gallery test scenario should be created.

.OUTPUTS
    [PSCustomObject] Information about the PowerShell Gallery readiness validation criteria.

.EXAMPLE
    $galleryScenario = New-PowerShellGalleryTestScenario -TestRootPath "C:\temp\gallerytest"
#>
function New-PowerShellGalleryTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating PowerShell Gallery test scenario at: $TestRootPath"

        # Create test directory structure
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        # Define PowerShell Gallery requirements
        $galleryRequirements = @{
            LicenseFile = @{
                FileName = "LICENSE"
                Path = Join-Path $testDir "LICENSE"
                RequiredContent = @(
                    "MIT License",
                    "Copyright",
                    "Permission is hereby granted",
                    "THE SOFTWARE IS PROVIDED"
                )
                LicenseType = "MIT"
            }
            ManifestRequirements = @{
                RequiredFields = @(
                    "ModuleVersion",
                    "GUID", 
                    "Author",
                    "Description",
                    "PowerShellVersion",
                    "FunctionsToExport"
                )
                PSDataRequirements = @(
                    "Tags",
                    "LicenseUri",
                    "ProjectUri",
                    "ReleaseNotes"
                )
                RequiredTags = @(
                    "Image",
                    "Web", 
                    "Optimization",
                    "PowerShell"
                )
                MinimumTags = 3
                VersionPattern = '^\d+\.\d+\.\d+$'
                GuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
            }
            ReleaseNotes = @{
                FileName = "RELEASE_NOTES.md"
                Path = Join-Path $testDir "RELEASE_NOTES.md"
                RequiredSections = @(
                    "# Release Notes",
                    "## Version 1.0.0",
                    "### Features",
                    "### Requirements",
                    "### Installation"
                )
                RequiredContent = @(
                    "PowerShell 7",
                    "ImageMagick",
                    "Optimize-WebImages",
                    "Invoke-WebImageBenchmark",
                    "parallel processing",
                    "cross-platform"
                )
            }
        }

        # Create validation criteria
        $validationCriteria = New-PowerShellGalleryValidationCriteria

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            GalleryRequirements = $galleryRequirements
            ValidationCriteria = $validationCriteria
            LicenseFilePath = $galleryRequirements.LicenseFile.Path
            ReleaseNotesPath = $galleryRequirements.ReleaseNotes.Path
            RequiredLicenseContent = $galleryRequirements.LicenseFile.RequiredContent
            RequiredManifestFields = $galleryRequirements.ManifestRequirements.RequiredFields
            RequiredPSDataFields = $galleryRequirements.ManifestRequirements.PSDataRequirements
        }
    }
    catch {
        Write-Error "Failed to create PowerShell Gallery test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates validation criteria for PowerShell Gallery publication readiness.

.DESCRIPTION
    Defines comprehensive validation criteria for PowerShell Gallery publication including
    manifest validation, license requirements, documentation standards, and technical requirements.

.OUTPUTS
    [PSCustomObject] Validation criteria for PowerShell Gallery readiness testing.
#>
function New-PowerShellGalleryValidationCriteria {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return [PSCustomObject]@{
        # License validation
        LicenseValidation = @{
            RequiredLicenseFile = $true
            AcceptedLicenseTypes = @('MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause')
            LicenseUriRequired = $true
            CopyrightRequired = $true
        }
        
        # Manifest validation
        ManifestValidation = @{
            TestModuleManifestRequired = $true
            SemanticVersioningRequired = $true
            PowerShellVersionMinimum = '7.0'
            CompatiblePSEditions = @('Core')
            MinimumTagCount = 3
            MaximumTagCount = 20
            DescriptionMinLength = 50
            DescriptionMaxLength = 500
        }
        
        # Documentation validation
        DocumentationValidation = @{
            ReadmeRequired = $true
            InstallationInstructionsRequired = $true
            UsageExamplesRequired = $true
            MinimumExamples = 3
            APIDocumentationRequired = $true
        }
        
        # Technical validation
        TechnicalValidation = @{
            NoSyntaxErrorsRequired = $true
            FunctionsExportedCorrectly = $true
            ModuleImportsSuccessfully = $true
            AllTestsPassRequired = $true
        }
        
        # Release notes validation
        ReleaseNotesValidation = @{
            ReleaseNotesRequired = $true
            VersionDocumented = $true
            FeaturesDocumented = $true
            RequirementsDocumented = $true
            InstallationDocumented = $true
            MinimumSections = 4
        }
    }
}

<#
.SYNOPSIS
    Gets the expected MIT license content for validation.

.DESCRIPTION
    Returns the standard MIT license text that should be present in the LICENSE file
    for PowerShell Gallery publication.

.OUTPUTS
    [string] The expected MIT license content.
#>
function Get-ExpectedMITLicenseContent {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return @"
MIT License

Copyright (c) 2025 PowerShell Web Image Optimizer Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
}

<#
.SYNOPSIS
    Validates PowerShell Gallery manifest requirements.

.DESCRIPTION
    Performs comprehensive validation of a PowerShell module manifest against
    PowerShell Gallery publication requirements.

.PARAMETER ManifestPath
    Path to the module manifest file to validate.

.PARAMETER ValidationCriteria
    Validation criteria to apply.

.OUTPUTS
    [PSCustomObject] Validation results with success status and details.
#>
function Test-PowerShellGalleryManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ValidationCriteria
    )

    $result = [PSCustomObject]@{
        ManifestPath = $ManifestPath
        ManifestExists = $false
        PassesTestModuleManifest = $false
        HasRequiredFields = $false
        HasValidVersion = $false
        HasValidGuid = $false
        HasRequiredPSData = $false
        HasValidTags = $false
        HasValidDescription = $false
        ValidationErrors = @()
        ValidationWarnings = @()
        ManifestData = $null
    }

    try {
        # Check if manifest exists
        if (-not (Test-Path $ManifestPath)) {
            $result.ValidationErrors += "Manifest file does not exist: $ManifestPath"
            return $result
        }

        $result.ManifestExists = $true

        # Test module manifest validation
        try {
            $manifestData = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
            $result.PassesTestModuleManifest = $true
            $result.ManifestData = $manifestData
        }
        catch {
            $result.ValidationErrors += "Test-ModuleManifest failed: $($_.Exception.Message)"
            return $result
        }

        # Load manifest content for detailed validation
        $manifestContent = Import-PowerShellDataFile -Path $ManifestPath

        # Validate required fields
        $missingFields = @()
        foreach ($field in $ValidationCriteria.ManifestValidation.RequiredFields) {
            if (-not $manifestContent.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($manifestContent[$field])) {
                $missingFields += $field
            }
        }

        if ($missingFields.Count -eq 0) {
            $result.HasRequiredFields = $true
        } else {
            $result.ValidationErrors += "Missing required manifest fields: $($missingFields -join ', ')"
        }

        # Validate version format
        if ($manifestContent.ModuleVersion -match $ValidationCriteria.ManifestValidation.VersionPattern) {
            $result.HasValidVersion = $true
        } else {
            $result.ValidationErrors += "Invalid version format: $($manifestContent.ModuleVersion)"
        }

        # Validate GUID format
        if ($manifestContent.GUID -match $ValidationCriteria.ManifestValidation.GuidPattern) {
            $result.HasValidGuid = $true
        } else {
            $result.ValidationErrors += "Invalid GUID format: $($manifestContent.GUID)"
        }

        # Validate PSData section
        if ($manifestContent.PrivateData -and $manifestContent.PrivateData.PSData) {
            $psData = $manifestContent.PrivateData.PSData
            $missingPSDataFields = @()
            
            foreach ($field in $ValidationCriteria.ManifestValidation.PSDataRequirements) {
                if (-not $psData.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($psData[$field])) {
                    $missingPSDataFields += $field
                }
            }

            if ($missingPSDataFields.Count -eq 0) {
                $result.HasRequiredPSData = $true
            } else {
                $result.ValidationErrors += "Missing required PSData fields: $($missingPSDataFields -join ', ')"
            }

            # Validate tags
            if ($psData.Tags -and $psData.Tags.Count -ge $ValidationCriteria.ManifestValidation.MinimumTagCount) {
                $result.HasValidTags = $true
            } else {
                $result.ValidationErrors += "Insufficient tags: $($psData.Tags.Count) (minimum: $($ValidationCriteria.ManifestValidation.MinimumTagCount))"
            }
        } else {
            $result.ValidationErrors += "Missing PrivateData.PSData section"
        }

        # Validate description
        $descLength = $manifestContent.Description.Length
        if ($descLength -ge $ValidationCriteria.ManifestValidation.DescriptionMinLength -and 
            $descLength -le $ValidationCriteria.ManifestValidation.DescriptionMaxLength) {
            $result.HasValidDescription = $true
        } else {
            $result.ValidationErrors += "Description length invalid: $descLength characters (required: $($ValidationCriteria.ManifestValidation.DescriptionMinLength)-$($ValidationCriteria.ManifestValidation.DescriptionMaxLength))"
        }

        return $result
    }
    catch {
        $result.ValidationErrors += "Error validating manifest: $($_.Exception.Message)"
        return $result
    }
}

<#
.SYNOPSIS
    Removes test data created by the PowerShell Gallery Test Data Library.

.DESCRIPTION
    Safely removes all test directories and files created by the PowerShell Gallery test data library.

.PARAMETER TestRootPath
    The root path of the test structure to remove.

.EXAMPLE
    Remove-PowerShellGalleryTestData -TestRootPath "C:\temp\gallerytest"
#>
function Remove-PowerShellGalleryTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        if (Test-Path $TestRootPath) {
            Write-Verbose "Removing PowerShell Gallery test data at: $TestRootPath"
            Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully removed PowerShell Gallery test data: $TestRootPath"
        } else {
            Write-Verbose "PowerShell Gallery test data directory does not exist: $TestRootPath"
        }
    }
    catch {
        Write-Warning "Failed to remove PowerShell Gallery test data '$TestRootPath': $($_.Exception.Message)"
    }
}
