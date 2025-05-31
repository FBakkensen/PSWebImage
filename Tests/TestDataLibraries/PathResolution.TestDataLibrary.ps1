# PathResolution Test Data Library
# Centralized test data creation for PathResolution functionality
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

<#
.SYNOPSIS
    Creates a comprehensive test directory structure for testing path resolution functionality.

.DESCRIPTION
    Creates temporary directory structures that simulate various repository layouts
    for testing the Get-ModuleRootPath function's path resolution logic.

.PARAMETER TestRootPath
    The root path where the test directory structure should be created.

.PARAMETER IncludeValidPaths
    If specified, creates valid directory structures that should be found by path resolution.

.PARAMETER IncludeInvalidPaths
    If specified, creates invalid directory structures for negative testing.

.OUTPUTS
    [PSCustomObject] Information about the created test directory structure.

.EXAMPLE
    $testData = New-PathResolutionTestScenario -TestRootPath "C:\temp\pathtest"
#>
function New-PathResolutionTestScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestRootPath,

        [Parameter()]
        [switch]$IncludeValidPaths,

        [Parameter()]
        [switch]$IncludeInvalidPaths
    )

    try {
        Write-Verbose "Creating path resolution test scenario at: $TestRootPath"

        # Create the main test directory
        $testDir = New-Item -Path $TestRootPath -ItemType Directory -Force

        $testScenarios = @{}

        if ($IncludeValidPaths) {
            # Create valid repository structure scenarios
            $validRepoPath = Join-Path $testDir.FullName "ValidRepo"
            $validRepo = New-Item -Path $validRepoPath -ItemType Directory -Force

            # Create Tests\TestHelpers structure
            $testsDir = New-Item -Path (Join-Path $validRepo "Tests") -ItemType Directory -Force
            $testHelpersDir = New-Item -Path (Join-Path $testsDir "TestHelpers") -ItemType Directory -Force
            $unitTestsDir = New-Item -Path (Join-Path $testsDir "Unit") -ItemType Directory -Force

            # Create WebImageOptimizer module directory
            $moduleDir = New-Item -Path (Join-Path $validRepo "WebImageOptimizer") -ItemType Directory -Force

            # Create some test files to make it realistic
            New-Item -Path (Join-Path $testHelpersDir "PathResolution.psm1") -ItemType File -Force | Out-Null
            New-Item -Path (Join-Path $unitTestsDir "SampleTest.Tests.ps1") -ItemType File -Force | Out-Null
            New-Item -Path (Join-Path $moduleDir "WebImageOptimizer.psm1") -ItemType File -Force | Out-Null

            $testScenarios.ValidRepo = @{
                Path = $validRepo.FullName
                TestsPath = $testsDir.FullName
                TestHelpersPath = $testHelpersDir.FullName
                UnitTestsPath = $unitTestsDir.FullName
                ModulePath = $moduleDir.FullName
                Description = "Valid repository structure for positive testing"
            }
        }

        if ($IncludeInvalidPaths) {
            # Create invalid repository structure scenarios
            $invalidRepoPath = Join-Path $testDir.FullName "InvalidRepo"
            $invalidRepo = New-Item -Path $invalidRepoPath -ItemType Directory -Force

            # Create incomplete structure (missing key directories)
            $incompleteTestsDir = New-Item -Path (Join-Path $invalidRepo "Tests") -ItemType Directory -Force
            # Intentionally not creating TestHelpers or Unit directories

            $testScenarios.InvalidRepo = @{
                Path = $invalidRepo.FullName
                TestsPath = $incompleteTestsDir.FullName
                Description = "Invalid repository structure for negative testing"
            }

            # Create non-existent path scenario
            $nonExistentPath = Join-Path $testDir.FullName "NonExistentRepo"
            $testScenarios.NonExistentRepo = @{
                Path = $nonExistentPath
                Description = "Non-existent path for negative testing"
            }
        }

        return [PSCustomObject]@{
            TestRootPath = $testDir.FullName
            Scenarios = $testScenarios
            CreatedAt = Get-Date
            Description = "PathResolution test directory structure"
        }

    } catch {
        Write-Error "Failed to create path resolution test scenario: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Creates mock environment variable scenarios for testing environment-based path resolution.

.DESCRIPTION
    Sets up environment variable test scenarios and provides helper functions
    to manage environment variables during testing.

.PARAMETER EnvironmentVariableName
    The name of the environment variable to test (default: PSWEBIMAGE_ROOT).

.PARAMETER ValidPath
    A valid path to set as the environment variable value.

.PARAMETER InvalidPath
    An invalid path to set as the environment variable value for negative testing.

.OUTPUTS
    [PSCustomObject] Information about the environment variable test scenarios.

.EXAMPLE
    $envTest = New-MockEnvironmentScenario -ValidPath "C:\temp\valid" -InvalidPath "C:\temp\invalid"
#>
function New-MockEnvironmentScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$EnvironmentVariableName = 'PSWEBIMAGE_ROOT',

        [Parameter()]
        [string]$ValidPath,

        [Parameter()]
        [string]$InvalidPath
    )

    $scenarios = @{}

    if ($ValidPath) {
        $scenarios.ValidEnvironmentPath = @{
            VariableName = $EnvironmentVariableName
            Value = $ValidPath
            ShouldExist = $true
            Description = "Valid environment variable path scenario"
        }
    }

    if ($InvalidPath) {
        $scenarios.InvalidEnvironmentPath = @{
            VariableName = $EnvironmentVariableName
            Value = $InvalidPath
            ShouldExist = $false
            Description = "Invalid environment variable path scenario"
        }
    }

    $scenarios.MissingEnvironmentVariable = @{
        VariableName = $EnvironmentVariableName
        Value = $null
        ShouldExist = $false
        Description = "Missing environment variable scenario"
    }

    return [PSCustomObject]@{
        EnvironmentVariableName = $EnvironmentVariableName
        Scenarios = $scenarios
        CreatedAt = Get-Date
        Description = "Environment variable test scenarios"
    }
}

<#
.SYNOPSIS
    Creates mock call stack scenarios for testing caller-based path resolution.

.DESCRIPTION
    Provides mock call stack data to simulate different caller scenarios
    for testing the Get-PSCallStack-based path resolution logic.

.OUTPUTS
    [PSCustomObject] Mock call stack scenarios for testing.

.EXAMPLE
    $callStackTest = New-MockCallStackScenario
#>
function New-MockCallStackScenario {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $scenarios = @{
        ValidUnitTestCaller = @{
            ScriptName = "C:\TestRepo\Tests\Unit\SampleTest.Tests.ps1"
            ExpectedRoot = "C:\TestRepo"
            Description = "Valid unit test caller scenario"
        }
        ValidIntegrationTestCaller = @{
            ScriptName = "C:\TestRepo\Tests\Integration\SampleIntegration.Tests.ps1"
            ExpectedRoot = "C:\TestRepo"
            Description = "Valid integration test caller scenario"
        }
        InvalidCaller = @{
            ScriptName = "C:\SomeOtherLocation\RandomScript.ps1"
            ExpectedRoot = $null
            Description = "Invalid caller location scenario"
        }
        NoCaller = @{
            ScriptName = $null
            ExpectedRoot = $null
            Description = "No caller information scenario"
        }
    }

    return [PSCustomObject]@{
        Scenarios = $scenarios
        CreatedAt = Get-Date
        Description = "Mock call stack scenarios for testing"
    }
}

<#
.SYNOPSIS
    Removes test data created by PathResolution test functions.

.DESCRIPTION
    Cleans up temporary directories and resets environment variables
    created during PathResolution testing.

.PARAMETER TestData
    The test data object returned by New-PathResolutionTestScenario.

.PARAMETER EnvironmentVariableName
    The name of the environment variable to clean up.

.EXAMPLE
    Remove-PathResolutionTestData -TestData $testData -EnvironmentVariableName "PSWEBIMAGE_ROOT"
#>
function Remove-PathResolutionTestData {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCustomObject]$TestData,

        [Parameter()]
        [string]$EnvironmentVariableName = 'PSWEBIMAGE_ROOT'
    )

    try {
        # Clean up test directories
        if ($TestData -and $TestData.TestRootPath -and (Test-Path $TestData.TestRootPath)) {
            Write-Verbose "Removing test directory: $($TestData.TestRootPath)"
            Remove-Item -Path $TestData.TestRootPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Clean up environment variable
        if ($EnvironmentVariableName) {
            Write-Verbose "Cleaning up environment variable: $EnvironmentVariableName"
            [Environment]::SetEnvironmentVariable($EnvironmentVariableName, $null, [EnvironmentVariableTarget]::Process)
        }

        Write-Verbose "PathResolution test data cleanup completed"

    } catch {
        Write-Warning "Failed to clean up some test data: $($_.Exception.Message)"
    }
}

# Functions are available when dot-sourced - no Export-ModuleMember needed for dot-sourcing
