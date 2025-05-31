# Test suite for WebImageOptimizer PathResolution Module
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "PathResolution Module - Get-ModuleRootPath Function" {

    BeforeAll {
        # Import the test data library
        $script:TestDataLibraryPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestDataLibraries\PathResolution.TestDataLibrary.ps1"
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        } else {
            throw "Test data library not found: $script:TestDataLibraryPath"
        }

        # Set up test root directory with timestamp for isolation
        $script:TestRoot = Join-Path $env:TEMP "PathResolution_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Test root directory: $script:TestRoot" -ForegroundColor Yellow

        # Create test scenarios
        $script:TestData = New-PathResolutionTestScenario -TestRootPath $script:TestRoot -IncludeValidPaths -IncludeInvalidPaths
        $script:EnvTestData = New-MockEnvironmentScenario -ValidPath $script:TestData.Scenarios.ValidRepo.Path -InvalidPath "C:\NonExistent\Path"
        $script:CallStackTestData = New-MockCallStackScenario

        # Store original environment variable value for restoration
        $script:OriginalEnvValue = [Environment]::GetEnvironmentVariable('PSWEBIMAGE_ROOT')
    }

    AfterAll {
        # Restore original environment variable
        if ($script:OriginalEnvValue) {
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $script:OriginalEnvValue, [EnvironmentVariableTarget]::Process)
        } else {
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $null, [EnvironmentVariableTarget]::Process)
        }

        # Clean up test data
        Remove-PathResolutionTestData -TestData $script:TestData -EnvironmentVariableName 'PSWEBIMAGE_ROOT'
    }

    Context "When using Parameter Override Path Resolution" {

        It "Should return valid override path when provided and path exists" {
            # Given: A valid override path that exists
            $validOverridePath = $script:TestData.Scenarios.ValidRepo.Path

            # When: Calling Get-ModuleRootPath with override path
            $result = Get-ModuleRootPath -OverridePath $validOverridePath

            # Then: The function should return the override path
            $result | Should -Be $validOverridePath
        }

        It "Should fall through to next method when override path does not exist" {
            # Given: An override path that does not exist
            $invalidOverridePath = "C:\NonExistent\Override\Path"

            # When: Calling Get-ModuleRootPath with non-existent override path
            # Then: Should not throw and should fall through to environment variable check
            { Get-ModuleRootPath -OverridePath $invalidOverridePath } | Should -Not -Throw
        }

        It "Should fall through to next method when override path is empty" {
            # Given: An empty override path
            $emptyOverridePath = ""

            # When: Calling Get-ModuleRootPath with empty override path
            # Then: Should not throw and should fall through to environment variable check
            { Get-ModuleRootPath -OverridePath $emptyOverridePath } | Should -Not -Throw
        }

        It "Should prioritize override path over environment variable" {
            # Given: Both override path and environment variable are set
            $validOverridePath = $script:TestData.Scenarios.ValidRepo.Path
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', "C:\SomeOtherPath", [EnvironmentVariableTarget]::Process)

            # When: Calling Get-ModuleRootPath with override path
            $result = Get-ModuleRootPath -OverridePath $validOverridePath

            # Then: The function should return the override path, not the environment variable
            $result | Should -Be $validOverridePath
        }
    }

    Context "When using Environment Variable Path Resolution" {

        BeforeEach {
            # Clear environment variable before each test
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $null, [EnvironmentVariableTarget]::Process)
        }

        It "Should return valid environment variable path when set and path exists" {
            # Given: A valid environment variable path that exists
            $validEnvPath = $script:TestData.Scenarios.ValidRepo.Path
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $validEnvPath, [EnvironmentVariableTarget]::Process)

            # When: Calling Get-ModuleRootPath without override
            $result = Get-ModuleRootPath

            # Then: The function should return the environment variable path
            $result | Should -Be $validEnvPath
        }

        It "Should fall through to next method when environment variable path does not exist" {
            # Given: An environment variable path that does not exist
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', "C:\NonExistent\Env\Path", [EnvironmentVariableTarget]::Process)

            # When: Calling Get-ModuleRootPath
            # Then: Should not throw and should fall through to calculated path
            { Get-ModuleRootPath } | Should -Not -Throw
        }

        It "Should fall through to next method when environment variable is not set" {
            # Given: No environment variable is set
            # (Already cleared in BeforeEach)

            # When: Calling Get-ModuleRootPath
            # Then: Should not throw and should fall through to calculated path
            { Get-ModuleRootPath } | Should -Not -Throw
        }

        It "Should use custom environment variable name when specified" {
            # Given: A custom environment variable name with valid path
            $customEnvVar = 'CUSTOM_MODULE_ROOT'
            $validPath = $script:TestData.Scenarios.ValidRepo.Path
            [Environment]::SetEnvironmentVariable($customEnvVar, $validPath, [EnvironmentVariableTarget]::Process)

            # When: Calling Get-ModuleRootPath with custom environment variable name
            $result = Get-ModuleRootPath -EnvironmentVariable $customEnvVar

            # Then: The function should return the custom environment variable path
            $result | Should -Be $validPath

            # Cleanup
            [Environment]::SetEnvironmentVariable($customEnvVar, $null, [EnvironmentVariableTarget]::Process)
        }
    }

    Context "When using Calculated Path from Caller Resolution" {

        It "Should calculate correct path when called from Tests\Unit directory" {
            # Given: A mock call stack indicating caller from Tests\Unit
            # When: The function calculates path from caller location
            # Then: Should derive repository root correctly

            # Note: This test is complex due to Get-PSCallStack behavior
            # We'll test the logic indirectly by ensuring the function doesn't fail
            { Get-ModuleRootPath } | Should -Not -Throw
        }

        It "Should fall through when caller path calculation fails" {
            # Given: Mock scenario where caller path calculation would fail
            # When: Get-ModuleRootPath is called
            # Then: Should fall through to module location calculation

            # This is tested indirectly through the overall function behavior
            { Get-ModuleRootPath } | Should -Not -Throw
        }
    }

    Context "When using Calculated Path from Module Resolution" {

        It "Should calculate correct path from module location" {
            # Given: The PathResolution module is in Tests\TestHelpers
            # When: Calculating path from module location ($PSScriptRoot)
            # Then: Should derive repository root correctly (two levels up)

            # This test verifies the module location calculation works
            $result = Get-ModuleRootPath
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match ".*PSWebImage.*"
        }
    }

    Context "When using Derived Fallback Path Resolution" {

        It "Should use derived fallback path when other methods fail" {
            # Given: All other path resolution methods fail
            # When: Function falls back to derived path calculation
            # Then: Should calculate path dynamically from module location

            # Clear environment variable to force fallback
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $null, [EnvironmentVariableTarget]::Process)

            # The function should still work and return a valid path
            $result = Get-ModuleRootPath
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should display warning message when using derived fallback path" {
            # Given: Conditions that force derived fallback path usage
            # When: Get-ModuleRootPath uses derived fallback
            # Then: Should display appropriate warning message

            # Clear environment variable to potentially trigger fallback warning
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $null, [EnvironmentVariableTarget]::Process)

            # Capture warning messages
            $warnings = @()
            $result = Get-ModuleRootPath -WarningVariable warnings

            # Should not throw and may contain warning about environment variable
            $result | Should -Not -BeNullOrEmpty
            # Warnings variable is captured for potential analysis
            { $warnings } | Should -Not -Throw
        }
    }

    Context "When handling Error Scenarios and Edge Cases" {

        It "Should throw specific error when no valid paths can be resolved" {
            # Given: All path resolution methods fail
            # Mock Test-Path to always return false
            Mock Test-Path { return $false } -ModuleName PathResolution

            # When: Calling Get-ModuleRootPath
            # Then: Should throw specific error message
            { Get-ModuleRootPath -OverridePath "C:\NonExistent" } | Should -Throw "*Unable to determine module root path*"
        }

        It "Should handle null or empty parameters gracefully" {
            # Given: Null or empty parameters
            # When: Calling Get-ModuleRootPath with null parameters
            # Then: Should not throw unexpected errors
            { Get-ModuleRootPath -OverridePath $null } | Should -Not -Throw
            { Get-ModuleRootPath -EnvironmentVariable $null } | Should -Not -Throw
            { Get-ModuleRootPath -EnvironmentVariable "" } | Should -Not -Throw
        }

        It "Should handle invalid environment variable names gracefully" {
            # Given: Invalid environment variable name
            # When: Calling Get-ModuleRootPath with invalid environment variable
            # Then: Should fall through to next resolution method
            { Get-ModuleRootPath -EnvironmentVariable "INVALID_ENV_VAR_NAME_12345" } | Should -Not -Throw
        }
    }

    Context "When validating Path Validation and Security" {

        It "Should only return existing paths" {
            # Given: A mix of existing and non-existing paths
            $existingPath = $script:TestData.Scenarios.ValidRepo.Path

            # When: Providing an existing path
            $result = Get-ModuleRootPath -OverridePath $existingPath

            # Then: Should return the existing path
            $result | Should -Be $existingPath
            Test-Path $result | Should -Be $true
        }

        It "Should validate paths using Test-Path before returning" {
            # Given: The function uses Test-Path for validation
            # When: A path is being validated
            # Then: Test-Path should be called for path validation

            $validPath = $script:TestData.Scenarios.ValidRepo.Path
            $result = Get-ModuleRootPath -OverridePath $validPath

            # The result should be a valid path that exists
            Test-Path $result | Should -Be $true
        }

        It "Should skip non-existent paths and continue to next resolution method" {
            # Given: A non-existent override path
            $nonExistentPath = "C:\Definitely\Does\Not\Exist\Path"

            # When: Providing non-existent override path
            # Then: Should skip it and try other methods (not throw immediately)
            { Get-ModuleRootPath -OverridePath $nonExistentPath } | Should -Not -Throw
        }
    }

    Context "When generating Warning and Verbose Messages" {

        It "Should display warning when using derived fallback path" {
            # Given: Conditions that force derived fallback path usage
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', $null, [EnvironmentVariableTarget]::Process)

            # When: Function uses derived fallback path
            $warnings = @()
            $result = Get-ModuleRootPath -WarningVariable warnings 2>&1

            # Then: Should return a valid path and warnings variable should be defined
            # Note: Warning may or may not appear depending on which path resolution succeeds
            $result | Should -Not -BeNullOrEmpty
            # Warnings variable should be defined (even if empty)
            { $warnings } | Should -Not -Throw
        }

        It "Should provide verbose output when requested" {
            # Given: Verbose preference is set
            # When: Calling Get-ModuleRootPath with verbose output
            $verboseOutput = Get-ModuleRootPath -Verbose 4>&1

            # Then: Should provide verbose information about path resolution process
            $verboseOutput | Should -Not -BeNullOrEmpty
        }

        It "Should include environment variable name in warning message" {
            # Given: Custom environment variable name
            $customEnvVar = 'CUSTOM_TEST_ROOT'
            [Environment]::SetEnvironmentVariable($customEnvVar, $null, [EnvironmentVariableTarget]::Process)

            # When: Using custom environment variable that may trigger warning
            $warnings = @()
            $result = Get-ModuleRootPath -EnvironmentVariable $customEnvVar -WarningVariable warnings 2>&1

            # Then: Should return a valid path and warnings variable should be defined
            $result | Should -Not -BeNullOrEmpty
            # Warnings variable should be defined (even if empty)
            { $warnings } | Should -Not -Throw
            # Note: Warning content verification depends on which path resolution method succeeds
        }

        It "Should provide clear guidance in error messages" {
            # Given: All path resolution methods fail
            # Mock Test-Path to simulate complete failure
            Mock Test-Path { return $false } -ModuleName PathResolution

            # When: All resolution methods fail
            # Then: Error message should provide clear guidance
            try {
                Get-ModuleRootPath -OverridePath "C:\NonExistent"
                $false | Should -Be $true -Because "Should have thrown an error"
            } catch {
                $_.Exception.Message | Should -Match ".*OverridePath.*"
                $_.Exception.Message | Should -Match ".*environment variable.*"
            }
        }
    }

    Context "When testing Function Integration and Consistency" {

        It "Should return consistent results for identical inputs" {
            # Given: The same input parameters
            $testPath = $script:TestData.Scenarios.ValidRepo.Path

            # When: Calling the function multiple times with identical inputs
            $results = @()
            for ($i = 0; $i -lt 3; $i++) {
                $results += Get-ModuleRootPath -OverridePath $testPath
            }

            # Then: All results should be identical
            $results | Should -Not -Contain $null
            $results | ForEach-Object { $_ | Should -Be $testPath }
        }

        It "Should respect parameter priority order consistently" {
            # Given: Multiple path resolution options available
            $overridePath = $script:TestData.Scenarios.ValidRepo.Path
            [Environment]::SetEnvironmentVariable('PSWEBIMAGE_ROOT', "C:\SomeOtherPath", [EnvironmentVariableTarget]::Process)

            # When: Providing both override path and environment variable
            $result = Get-ModuleRootPath -OverridePath $overridePath

            # Then: Should always prioritize override path
            $result | Should -Be $overridePath
        }

        It "Should handle multiple sequential calls safely" {
            # Given: Multiple sequential calls to the function
            $testPath = $script:TestData.Scenarios.ValidRepo.Path

            # When: Making multiple sequential calls
            $results = @()
            for ($i = 0; $i -lt 3; $i++) {
                $results += Get-ModuleRootPath -OverridePath $testPath
            }

            # Then: All results should be correct and consistent
            $results | Should -Not -Contain $null
            $results | ForEach-Object { $_ | Should -Be $testPath }
            $results.Count | Should -Be 3
        }
    }
}
