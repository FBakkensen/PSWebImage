# End-to-End Integration Tests for WebImageOptimizer
# Tests complete workflows with real image processing using TDD/BDD methodology
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
    $script:TestRootPath = Join-Path $env:TEMP "WebImageOptimizer_Integration_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $script:TestScenario = $null
}

AfterAll {
    # Clean up test data
    if ($script:TestScenario -and (Test-Path $script:TestScenario.TestRootPath)) {
        Remove-IntegrationTestData -TestDataPath $script:TestScenario.TestRootPath
    }
}

Describe "WebImageOptimizer End-to-End Integration Tests" -Tag @('Integration', 'EndToEnd') {

    BeforeAll {
        # Create integration test scenario with real images
        $script:TestScenario = New-IntegrationTestImageCollection -TestRootPath $script:TestRootPath -ImageCount 5

        # Verify test scenario was created successfully
        if (-not $script:TestScenario) {
            throw "Failed to create integration test scenario"
        }

        Write-Host "Integration test scenario created at: $($script:TestScenario.TestRootPath)" -ForegroundColor Green
        Write-Host "Created $($script:TestScenario.TotalImages) test images" -ForegroundColor Green
        Write-Host "Can create real images: $($script:TestScenario.CanCreateRealImages)" -ForegroundColor Green
    }

    Context "Basic End-to-End Processing Workflow" {

        It "Should process real images from input directory to output directory" {
            # Given: A directory containing real image files
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = $script:TestScenario.OutputDirectory

            # Verify input images exist
            $inputImages = Get-ChildItem -Path $inputPath -Recurse -Include "*.jpg", "*.png"
            $inputImages.Count | Should -BeGreaterThan 0 -Because "Test scenario should contain input images"

            # When: I call Optimize-WebImages with basic parameters
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath -Verbose

            # Then: The function should complete successfully
            $result | Should -Not -BeNullOrEmpty -Because "Function should return a result object"
            $result.Success | Should -Be $true -Because "Processing should complete successfully"

            # And: Output directory should contain optimized images
            $outputImages = Get-ChildItem -Path $outputPath -Recurse -Include "*.jpg", "*.png"
            $outputImages.Count | Should -BeGreaterThan 0 -Because "Output directory should contain processed images"

            # And: Processing metrics should be populated
            $result.FilesProcessed | Should -BeGreaterThan 0 -Because "Should have processed some files"
            $result.TotalProcessingTime | Should -BeOfType [TimeSpan] -Because "Should track processing time"
        }

        It "Should maintain directory structure in output" {
            # Given: Input directory with nested subdirectories
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "StructureTest"

            # Verify nested structure exists
            $nestedImages = Get-ChildItem -Path $inputPath -Recurse -Include "*.jpg", "*.png" | Where-Object { $_.Directory.Name -ne (Split-Path $inputPath -Leaf) }
            $nestedImages.Count | Should -BeGreaterThan 0 -Because "Should have images in subdirectories"

            # When: I process images with directory structure preservation
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: Output should maintain the same directory structure
            $result.Success | Should -Be $true

            # And: Subdirectories should exist in output
            $inputSubDirs = Get-ChildItem -Path $inputPath -Recurse -Directory
            foreach ($subDir in $inputSubDirs) {
                try {
                    # Use PowerShell 7's GetRelativePath for robust path calculation
                    $relativePath = [System.IO.Path]::GetRelativePath($inputPath, $subDir.FullName)
                } catch {
                    # Fallback for path issues
                    $inputPathString = $inputPath.TrimEnd('\', '/')
                    if ($subDir.FullName.StartsWith($inputPathString)) {
                        $relativePath = $subDir.FullName.Substring($inputPathString.Length).TrimStart('\', '/')
                    } else {
                        $relativePath = $subDir.Name
                    }
                }
                $expectedOutputDir = Join-Path $outputPath $relativePath
                Test-Path $expectedOutputDir | Should -Be $true -Because "Subdirectory structure should be preserved: $relativePath"
            }
        }

        It "Should handle mixed image formats correctly" {
            # Given: A directory with multiple image formats
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "MixedFormats"

            # Verify multiple formats exist
            $jpegFiles = Get-ChildItem -Path $inputPath -Recurse -Include "*.jpg"
            $pngFiles = Get-ChildItem -Path $inputPath -Recurse -Include "*.png"

            ($jpegFiles.Count + $pngFiles.Count) | Should -BeGreaterThan 1 -Because "Should have multiple image formats"

            # When: I process the mixed format directory
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath

            # Then: All formats should be processed successfully
            $result.Success | Should -Be $true
            $result.FilesProcessed | Should -Be ($jpegFiles.Count + $pngFiles.Count)

            # And: Output should contain files of the same formats
            $outputJpegFiles = Get-ChildItem -Path $outputPath -Recurse -Include "*.jpg"
            $outputPngFiles = Get-ChildItem -Path $outputPath -Recurse -Include "*.png"

            $outputJpegFiles.Count | Should -Be $jpegFiles.Count -Because "All JPEG files should be processed"
            $outputPngFiles.Count | Should -Be $pngFiles.Count -Because "All PNG files should be processed"
        }
    }

    Context "Error Handling and Edge Cases" {

        It "Should handle empty input directory gracefully" {
            # Given: An empty input directory
            $emptyInputPath = Join-Path $script:TestScenario.TestRootPath "EmptyInput"
            $outputPath = Join-Path $script:TestScenario.TestRootPath "EmptyOutput"
            New-Item -Path $emptyInputPath -ItemType Directory -Force | Out-Null

            # When: I process the empty directory
            $result = Optimize-WebImages -Path $emptyInputPath -OutputPath $outputPath

            # Then: Function should complete without errors
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true -Because "Empty directory should be handled gracefully"
            $result.FilesProcessed | Should -Be 0 -Because "No files should be processed from empty directory"
        }

        It "Should handle non-existent input directory appropriately" {
            # Given: A non-existent input directory
            $nonExistentPath = Join-Path $script:TestScenario.TestRootPath "NonExistent"
            $outputPath = Join-Path $script:TestScenario.TestRootPath "NonExistentOutput"

            # When: I attempt to process the non-existent directory
            # Then: Should throw an appropriate error
            { Optimize-WebImages -Path $nonExistentPath -OutputPath $outputPath } | Should -Throw -Because "Non-existent input directory should cause an error"
        }

        It "Should create output directory if it doesn't exist" {
            # Given: Input directory with images and non-existent output directory
            $inputPath = $script:TestScenario.InputDirectory
            $newOutputPath = Join-Path $script:TestScenario.TestRootPath "NewOutput"

            # Verify output directory doesn't exist
            Test-Path $newOutputPath | Should -Be $false -Because "Output directory should not exist initially"

            # When: I process images to the new output directory
            $result = Optimize-WebImages -Path $inputPath -OutputPath $newOutputPath

            # Then: Output directory should be created and processing should succeed
            $result.Success | Should -Be $true
            Test-Path $newOutputPath | Should -Be $true -Because "Output directory should be created automatically"

            # And: Images should be processed to the new directory
            $outputImages = Get-ChildItem -Path $newOutputPath -Recurse -Include "*.jpg", "*.png"
            $outputImages.Count | Should -BeGreaterThan 0 -Because "Images should be processed to new output directory"
        }
    }

    Context "Configuration and Settings" {

        It "Should respect custom quality settings" {
            # Given: Input images and custom quality settings
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "CustomQuality"

            $customSettings = @{
                jpeg = @{ quality = 75 }
                png = @{ compression = 9 }
            }

            # When: I process images with custom quality settings
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath -Settings $customSettings

            # Then: Processing should complete successfully with custom settings
            $result.Success | Should -Be $true
            $result.FilesProcessed | Should -BeGreaterThan 0

            # And: Output files should exist
            $outputImages = Get-ChildItem -Path $outputPath -Recurse -Include "*.jpg", "*.png"
            $outputImages.Count | Should -BeGreaterThan 0 -Because "Images should be processed with custom settings"
        }

        It "Should support WhatIf parameter for dry run" {
            # Given: Input directory with images
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "WhatIfTest"

            # When: I run with -WhatIf parameter
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath -WhatIf

            # Then: No actual processing should occur
            Test-Path $outputPath | Should -Be $false -Because "WhatIf should not create output directory"

            # And: Function should still return information about what would be processed
            $result | Should -Not -BeNullOrEmpty -Because "WhatIf should return information about planned operations"
        }
    }

    Context "Performance and Scalability" {

        It "Should process multiple images efficiently" {
            # Given: A collection of test images
            $inputPath = $script:TestScenario.InputDirectory
            $outputPath = Join-Path $script:TestScenario.TestRootPath "Performance"

            # When: I process the images and measure time
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Optimize-WebImages -Path $inputPath -OutputPath $outputPath
            $stopwatch.Stop()

            # Then: Processing should complete within reasonable time
            $result.Success | Should -Be $true
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 30000 -Because "Processing should complete within 30 seconds for small dataset"

            # And: All images should be processed
            $inputImages = Get-ChildItem -Path $inputPath -Recurse -Include "*.jpg", "*.png"
            $result.FilesProcessed | Should -Be $inputImages.Count -Because "All input images should be processed"
        }
    }
}
