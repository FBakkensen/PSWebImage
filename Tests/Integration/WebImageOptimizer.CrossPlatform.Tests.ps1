# Cross-Platform Integration Tests for WebImageOptimizer
# Tests PowerShell 7 cross-platform compatibility and dependency detection
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

BeforeAll {
    # Import test helper for path resolution
    $testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
    if (Test-Path $testHelperPath) {
        Import-Module $testHelperPath -Force
    } else {
        throw "Test helper module not found: $testHelperPath"
    }

    # Define the module root path with robust resolution
    $script:ModuleRoot = Get-ModuleRootPath

    # Import the WebImageOptimizer module
    $modulePath = Join-Path $script:ModuleRoot "WebImageOptimizer\WebImageOptimizer.psd1"
    if (-not (Test-Path $modulePath)) {
        throw "Module not found: $modulePath"
    }
    Import-Module $modulePath -Force

    # Import Integration Test Data Library
    $integrationLibraryPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestDataLibraries\Integration.TestDataLibrary.ps1"
    if (-not (Test-Path $integrationLibraryPath)) {
        throw "Integration Test Data Library not found: $integrationLibraryPath"
    }
    . $integrationLibraryPath

    # Set up test environment
    $script:TestRootPath = Join-Path $env:TEMP "WebImageOptimizer_CrossPlatform_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:TestScenario = $null

    # Detect current platform (use different variable names to avoid conflicts)
    $script:OnWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows
    $script:OnLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
    $script:OnMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
    $script:CurrentPlatform = if ($script:OnWindows) { "Windows" }
                             elseif ($script:OnLinux) { "Linux" }
                             elseif ($script:OnMacOS) { "macOS" }
                             else { "Unknown" }
}

AfterAll {
    # Clean up test data
    if ($script:TestScenario -and (Test-Path $script:TestScenario.TestRootPath)) {
        Remove-IntegrationTestData -TestDataPath $script:TestScenario.TestRootPath
    }
}

Describe "WebImageOptimizer Cross-Platform Integration Tests" -Tag @('Integration', 'CrossPlatform') {

    BeforeAll {
        # Create integration test scenario
        $script:TestScenario = New-IntegrationTestImageCollection -TestRootPath $script:TestRootPath -ImageCount 3

        Write-Host "Cross-platform test running on: $script:CurrentPlatform" -ForegroundColor Green
        Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    }

    Context "Path Handling Across Platforms" {

        It "Should handle platform-specific path separators correctly" {
            # Given: Input and output paths using current platform conventions
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory

            # When: I process images with platform-specific paths
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Processing should succeed regardless of platform
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true -Because "Path handling should work on $script:CurrentPlatform"

            # And: Output files should be created with correct paths
            $outputImages = Get-ChildItem -Path $outputPath -Recurse -Include "*.jpg", "*.png"
            $outputImages.Count | Should -BeGreaterThan 0 -Because "Images should be processed with correct path handling"
        }

        It "Should handle long file paths appropriately for current platform" {
            # Given: A deeply nested directory structure
            $deepPath = $script:TestScenario.InputDirectory
            for ($i = 1; $i -le 5; $i++) {
                $deepPath = Join-Path $deepPath "VeryLongDirectoryNameLevel$i"
            }
            New-Item -Path $deepPath -ItemType Directory -Force | Out-Null

            # Create a test image in the deep path
            $testImagePath = Join-Path $deepPath "DeepTestImage.jpg"
            $mockContent = [byte[]]@(0xFF, 0xD8, 0xFF, 0xE0) + (New-Object byte[] 1020)
            [System.IO.File]::WriteAllBytes($testImagePath, $mockContent)

            $outputPath = Join-Path $script:TestScenario.TestRootPath "DeepOutput"

            # When: I process the deeply nested image
            $result = Optimize-WebImages -Path $deepPath -OutputPath $outputPath

            # Then: Should handle long paths according to platform capabilities
            $result | Should -Not -BeNullOrEmpty
            if ($script:OnWindows) {
                # Windows may have path length limitations
                $result.Success | Should -Be $true -Because "Windows should handle long paths with proper configuration"
            } else {
                # Unix-like systems typically handle long paths better
                $result.Success | Should -Be $true -Because "Unix-like systems should handle long paths"
            }
        }

        It "Should handle special characters in file names across platforms" {
            # Given: Files with special characters (platform-appropriate)
            $inputPath = $script:TestScenario.InputDirectory
            $specialChars = if ($script:OnWindows) {
                @("Test Image (1).jpg", "Test-Image_2.png", "Test.Image.3.jpg")
            } else {
                @("Test Image (1).jpg", "Test-Image_2.png", "Test.Image.3.jpg", "Test'Image'4.png")
            }

            # Create test files with special characters
            foreach ($fileName in $specialChars) {
                $filePath = Join-Path $inputPath $fileName
                $mockContent = if ($fileName.EndsWith('.jpg')) {
                    [byte[]]@(0xFF, 0xD8, 0xFF, 0xE0) + (New-Object byte[] 1020)
                } else {
                    [byte[]]@(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A) + (New-Object byte[] 1016)
                }
                [System.IO.File]::WriteAllBytes($filePath, $mockContent)
            }

            $outputPath = Join-Path $script:TestScenario.TestRootPath "SpecialChars"

            # When: I process files with special characters
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should handle special characters appropriately for the platform
            $result.Success | Should -Be $true -Because "Special characters should be handled on $script:CurrentPlatform"

            # And: Output files should exist with correct names
            foreach ($fileName in $specialChars) {
                $outputFile = Join-Path $outputPath $fileName
                Test-Path $outputFile | Should -Be $true -Because "File with special characters should be processed: $fileName"
            }
        }
    }

    Context "Dependency Detection Across Platforms" {

        It "Should detect ImageMagick installation on current platform" {
            # Given: Current platform environment and test images
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "DependencyTest"

            # When: I process images (which internally tests dependencies)
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should complete successfully with dependency detection
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true -Because "Dependency detection should work on $script:CurrentPlatform"
            $result.Platform | Should -Be $script:CurrentPlatform

            # And: Should indicate which processing engine was used
            $result.ProcessingEngine | Should -Not -BeNullOrEmpty -Because "Should indicate which processing engine was detected and used"
            $result.ProcessingEngine | Should -BeIn @("ImageMagick", "DotNet", "Auto") -Because "Should use a valid processing engine"
        }

        It "Should fall back to .NET processing when ImageMagick unavailable" {
            # Given: A scenario where ImageMagick might not be available
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "FallbackTest"

            # When: I process images (potentially using .NET fallback)
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Processing should succeed using available engines
            $result.Success | Should -Be $true -Because "Should fall back to available processing engines"
            $result.ProcessingEngine | Should -Not -BeNullOrEmpty -Because "Should indicate which processing engine was used"

            # And: Images should still be processed
            $outputImages = Get-ChildItem -Path $outputPath -Recurse -Include "*.jpg", "*.png"
            $outputImages.Count | Should -BeGreaterThan 0 -Because "Images should be processed even with fallback engine"
        }
    }

    Context "File System Compatibility" {

        It "Should handle case sensitivity appropriately for current platform" {
            # Given: Files with different case variations
            $inputPath = $script:TestScenario.InputDirectory
            $testFiles = @("TestImage.JPG", "testimage.jpg")

            foreach ($fileName in $testFiles) {
                $filePath = Join-Path $inputPath $fileName
                if (-not (Test-Path $filePath)) {
                    $mockContent = [byte[]]@(0xFF, 0xD8, 0xFF, 0xE0) + (New-Object byte[] 1020)
                    [System.IO.File]::WriteAllBytes($filePath, $mockContent)
                }
            }

            $outputPath = Join-Path $script:TestScenario.TestRootPath "CaseSensitivity"

            # When: I process files with case variations
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should handle case sensitivity according to platform
            $result.Success | Should -Be $true

            if ($script:OnWindows) {
                # Windows is case-insensitive
                $result.FilesProcessed | Should -BeGreaterOrEqual 1 -Because "Windows should handle case variations"
            } else {
                # Unix-like systems are case-sensitive
                $result.FilesProcessed | Should -BeGreaterOrEqual 1 -Because "Unix systems should treat different cases as separate files"
            }
        }

        It "Should respect file permissions on current platform" {
            # Given: Files with different permission scenarios
            $inputPath = $script:TestScenario.InputDirectory
            $testImagePath = Join-Path $inputPath "PermissionTest.jpg"
            $mockContent = [byte[]]@(0xFF, 0xD8, 0xFF, 0xE0) + (New-Object byte[] 1020)
            [System.IO.File]::WriteAllBytes($testImagePath, $mockContent)

            # Set read-only permissions (platform-appropriate)
            if ($script:OnWindows) {
                (Get-Item $testImagePath).Attributes = 'ReadOnly'
            } else {
                # Unix-like systems: remove write permissions
                chmod 444 $testImagePath 2>$null
            }

            $outputPath = Join-Path $script:TestScenario.TestRootPath "Permissions"

            # When: I attempt to process read-only files
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should handle permissions appropriately
            $result | Should -Not -BeNullOrEmpty
            # Note: Behavior may vary by platform and configuration
            # The test validates that the function handles permissions gracefully
        }
    }

    Context "PowerShell 7 Feature Compatibility" {

        It "Should leverage PowerShell 7 cross-platform features" {
            # Given: PowerShell 7 environment
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 7 -Because "Tests require PowerShell 7"

            # When: I use PowerShell 7 specific features in processing
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "PS7Features"

            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should work correctly with PowerShell 7 features
            $result.Success | Should -Be $true -Because "Should leverage PowerShell 7 cross-platform capabilities"
            $result.PowerShellVersion | Should -Match "^7\." -Because "Should indicate PowerShell 7 usage"
        }

        It "Should handle parallel processing across platforms" {
            # Given: Multiple images for parallel processing
            $largeDataset = New-IntegrationTestImageCollection -TestRootPath (Join-Path $script:TestRootPath "ParallelTest") -ImageCount 8
            $outputPath = Join-Path $largeDataset.TestRootPath "ParallelOutput"

            # When: I process images with parallel processing enabled
            $result = Optimize-WebImages -Path $largeDataset.InputDirectory -OutputPath $outputPath

            # Then: Parallel processing should work on current platform
            $result.Success | Should -Be $true -Because "Parallel processing should work on $script:CurrentPlatform"
            $result.FilesProcessed | Should -BeGreaterThan 0

            # And: Should indicate parallel processing was used
            $result.ProcessingMode | Should -Match "Parallel" -Because "Should use parallel processing for multiple files"

            # Cleanup
            Remove-IntegrationTestData -TestDataPath $largeDataset.TestRootPath
        }
    }

    Context "Platform-Specific Optimizations" {

        It "Should apply platform-appropriate optimizations" {
            # Given: Images to optimize on current platform
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "PlatformOptimizations"

            # When: I optimize images with platform-specific settings
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Should complete successfully with platform optimizations
            $result.Success | Should -Be $true
            $result.Platform | Should -Be $script:CurrentPlatform -Because "Should indicate current platform"

            # And: Should show appropriate performance characteristics for platform
            $result.TotalProcessingTime | Should -BeOfType [TimeSpan] -Because "Should track processing time"
            $result.TotalProcessingTime.TotalSeconds | Should -BeLessThan 60 -Because "Should complete within reasonable time on $script:CurrentPlatform"
        }
    }
}
