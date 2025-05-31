# Documentation Test Data Library
# Centralized test data creation for WebImageOptimizer documentation testing
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates expected documentation structure and validation data for testing.

.DESCRIPTION
    Creates comprehensive test scenarios for validating documentation completeness,
    structure, content quality, and accuracy. Supports testing of README, user guides,
    API documentation, configuration references, and troubleshooting guides.

.PARAMETER TestRootPath
    The root path where the documentation test scenario should be created.

.OUTPUTS
    [PSCustomObject] Information about the expected documentation structure and validation criteria.

.EXAMPLE
    $docScenario = New-DocumentationTestScenario -TestRootPath "C:\temp\doctest"
#>
function New-DocumentationTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        Write-Verbose "Creating documentation test scenario at: $TestRootPath"

        # Create test directory structure
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force
        $docsDir = New-Item -Path (Join-Path $testDir "docs") -ItemType Directory -Force

        # Define expected documentation files and their requirements
        $expectedFiles = @(
            @{
                Name = "README.md"
                Path = Join-Path $testDir "README.md"
                Type = "MainReadme"
                RequiredSections = @(
                    "# WebImageOptimizer",
                    "## Installation",
                    "## Quick Start",
                    "## Features",
                    "## Requirements",
                    "## Usage Examples",
                    "## Documentation",
                    "## Contributing",
                    "## License"
                )
                RequiredContent = @(
                    "PowerShell 7",
                    "ImageMagick",
                    "Optimize-WebImages",
                    "Install-Module",
                    "PowerShell Gallery"
                )
            },
            @{
                Name = "UserGuide.md"
                Path = Join-Path $docsDir "UserGuide.md"
                Type = "UserGuide"
                RequiredSections = @(
                    "# User Guide",
                    "## Overview",
                    "## Getting Started",
                    "## Basic Usage",
                    "## Advanced Features",
                    "## Configuration",
                    "## Examples",
                    "## Best Practices"
                )
                RequiredContent = @(
                    "Optimize-WebImages",
                    "parameter",
                    "example",
                    "configuration",
                    "parallel processing"
                )
            },
            @{
                Name = "API.md"
                Path = Join-Path $docsDir "API.md"
                Type = "APIReference"
                RequiredSections = @(
                    "# API Reference",
                    "## Optimize-WebImages",
                    "## Invoke-WebImageBenchmark",
                    "### Parameters",
                    "### Examples",
                    "### Return Values"
                )
                RequiredContent = @(
                    "Optimize-WebImages",
                    "Invoke-WebImageBenchmark",
                    "Parameter",
                    "Mandatory",
                    "Example",
                    "PSCustomObject"
                )
            },
            @{
                Name = "Configuration.md"
                Path = Join-Path $docsDir "Configuration.md"
                Type = "ConfigurationGuide"
                RequiredSections = @(
                    "# Configuration Guide",
                    "## Overview",
                    "## Default Settings",
                    "## Configuration File Structure",
                    "## Loading Priority",
                    "## Custom Configuration",
                    "## Examples"
                )
                RequiredContent = @(
                    "default-settings.json",
                    "jpeg",
                    "png",
                    "webp",
                    "quality",
                    "compression"
                )
            },
            @{
                Name = "Troubleshooting.md"
                Path = Join-Path $docsDir "Troubleshooting.md"
                Type = "TroubleshootingGuide"
                RequiredSections = @(
                    "# Troubleshooting Guide",
                    "## Common Issues",
                    "## Dependency Problems",
                    "## Performance Issues",
                    "## Error Messages",
                    "## FAQ"
                )
                RequiredContent = @(
                    "ImageMagick",
                    "PowerShell 7",
                    "error",
                    "solution",
                    "performance"
                )
            }
        )

        # Create validation criteria for documentation quality
        $validationCriteria = New-DocumentationValidationCriteria

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            DocsDirectory = $docsDir.FullName
            ExpectedFiles = $expectedFiles
            TotalFiles = $expectedFiles.Count
            ValidationCriteria = $validationCriteria
            RequiredSections = ($expectedFiles | ForEach-Object { $_.RequiredSections }).Count
            RequiredContent = ($expectedFiles | ForEach-Object { $_.RequiredContent }).Count
        }
    }
    catch {
        Write-Error "Failed to create documentation test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates validation criteria for documentation quality testing.

.DESCRIPTION
    Defines comprehensive validation criteria including content requirements,
    structure validation, example syntax checking, and link validation.

.OUTPUTS
    [PSCustomObject] Validation criteria for documentation testing.
#>
function New-DocumentationValidationCriteria {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return [PSCustomObject]@{
        MinimumSections = 5
        MinimumExamples = 3
        RequiredCodeBlocks = @('powershell', 'json')
        RequiredLinks = @('PowerShell Gallery', 'GitHub')
        MaxLineLength = 120
        RequiredMetadata = @('Author', 'Version', 'Description')
        ExamplePatterns = @(
            'Optimize-WebImages\s+-Path',
            '\$\w+\s*=\s*Optimize-WebImages',
            'Import-Module\s+WebImageOptimizer'
        )
        LinkPatterns = @(
            'https?://[^\s\)]+',
            '\[.*\]\(.*\)'
        )
        CodeBlockPatterns = @(
            '```powershell',
            '```json',
            '```'
        )
    }
}

<#
.SYNOPSIS
    Validates documentation file content against expected criteria.

.DESCRIPTION
    Performs comprehensive validation of documentation files including structure,
    content completeness, example syntax, and link validation.

.PARAMETER FilePath
    Path to the documentation file to validate.

.PARAMETER ExpectedFile
    Expected file specification with requirements.

.PARAMETER ValidationCriteria
    Validation criteria to apply.

.OUTPUTS
    [PSCustomObject] Validation results with success status and details.
#>
function Test-DocumentationContent {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$ExpectedFile,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ValidationCriteria
    )

    $result = [PSCustomObject]@{
        FilePath = $FilePath
        FileExists = $false
        HasRequiredSections = $false
        HasRequiredContent = $false
        HasValidExamples = $false
        HasValidLinks = $false
        ValidationErrors = @()
        ValidationWarnings = @()
        SectionCount = 0
        ExampleCount = 0
        LinkCount = 0
    }

    try {
        # Check if file exists
        if (-not (Test-Path $FilePath)) {
            $result.ValidationErrors += "File does not exist: $FilePath"
            return $result
        }

        $result.FileExists = $true
        $content = Get-Content -Path $FilePath -Raw

        # Validate required sections
        $missingSections = @()
        foreach ($section in $ExpectedFile.RequiredSections) {
            if ($content -notmatch [regex]::Escape($section)) {
                $missingSections += $section
            }
        }

        if ($missingSections.Count -eq 0) {
            $result.HasRequiredSections = $true
        } else {
            $result.ValidationErrors += "Missing required sections: $($missingSections -join ', ')"
        }

        # Count sections
        $result.SectionCount = ($content | Select-String -Pattern '^#+\s+' -AllMatches).Matches.Count

        # Validate required content
        $missingContent = @()
        foreach ($contentItem in $ExpectedFile.RequiredContent) {
            if ($content -notmatch [regex]::Escape($contentItem)) {
                $missingContent += $contentItem
            }
        }

        if ($missingContent.Count -eq 0) {
            $result.HasRequiredContent = $true
        } else {
            $result.ValidationErrors += "Missing required content: $($missingContent -join ', ')"
        }

        # Validate examples
        $exampleMatches = 0
        foreach ($pattern in $ValidationCriteria.ExamplePatterns) {
            $matches = ($content | Select-String -Pattern $pattern -AllMatches).Matches
            $exampleMatches += $matches.Count
        }

        $result.ExampleCount = $exampleMatches
        if ($exampleMatches -ge $ValidationCriteria.MinimumExamples) {
            $result.HasValidExamples = $true
        } else {
            $result.ValidationWarnings += "Insufficient examples found: $exampleMatches (minimum: $($ValidationCriteria.MinimumExamples))"
        }

        # Validate links
        $linkMatches = 0
        foreach ($pattern in $ValidationCriteria.LinkPatterns) {
            $matches = ($content | Select-String -Pattern $pattern -AllMatches).Matches
            $linkMatches += $matches.Count
        }

        $result.LinkCount = $linkMatches
        if ($linkMatches -gt 0) {
            $result.HasValidLinks = $true
        } else {
            $result.ValidationWarnings += "No links found in documentation"
        }

        return $result
    }
    catch {
        $result.ValidationErrors += "Error validating file: $($_.Exception.Message)"
        return $result
    }
}

<#
.SYNOPSIS
    Removes test data created by the Documentation Test Data Library.

.DESCRIPTION
    Safely removes all test directories and files created by the documentation test data library.

.PARAMETER TestRootPath
    The root path of the test structure to remove.

.EXAMPLE
    Remove-DocumentationTestData -TestRootPath "C:\temp\doctest"
#>
function Remove-DocumentationTestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath
    )

    try {
        if (Test-Path $TestRootPath) {
            Write-Verbose "Removing documentation test data at: $TestRootPath"
            Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully removed documentation test data: $TestRootPath"
        } else {
            Write-Verbose "Documentation test data directory does not exist: $TestRootPath"
        }
    }
    catch {
        Write-Warning "Failed to remove documentation test data '$TestRootPath': $($_.Exception.Message)"
    }
}
