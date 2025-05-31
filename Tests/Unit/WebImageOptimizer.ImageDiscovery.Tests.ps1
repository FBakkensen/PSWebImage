# Test suite for WebImageOptimizer Image File Discovery Engine (Task 5)
# BDD/TDD implementation following Given-When-Then structure

# Import test helper for path resolution
$testHelperPath = Join-Path (Split-Path $PSScriptRoot -Parent) "TestHelpers\PathResolution.psm1"
if (Test-Path $testHelperPath) {
    Import-Module $testHelperPath -Force
} else {
    throw "Test helper module not found: $testHelperPath"
}

Describe "WebImageOptimizer Image File Discovery Engine" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:GetImageFilesPath = Join-Path $script:PrivatePath "Get-ImageFiles.ps1"
        $script:TestDataLibraryPath = Join-Path $script:ModuleRoot "Tests\TestDataLibraries\ImageDiscovery.TestDataLibrary.ps1"

        # Import the test data library
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        }

        # Import the Get-ImageFiles function if it exists
        if (Test-Path $script:GetImageFilesPath) {
            . $script:GetImageFilesPath
        }

        # Set up test root directory
        $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_ImageDiscovery_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Test root directory: $script:TestRoot" -ForegroundColor Yellow
    }

    AfterAll {
        # Cleanup test data
        if ($script:TestRoot -and (Test-Path $script:TestRoot)) {
            try {
                Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Cleaned up test directory: $script:TestRoot" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to cleanup test directory: $($_.Exception.Message)"
            }
        }
    }

    Context "When testing basic image file discovery functionality" {

        BeforeAll {
            # Create test structure for basic functionality tests
            $script:BasicTestPath = Join-Path $script:TestRoot "BasicTests"
            if (Get-Command New-MinimalImageTestStructure -ErrorAction SilentlyContinue) {
                $script:BasicTestStructure = New-MinimalImageTestStructure -TestRootPath $script:BasicTestPath
            }
        }

        It "Should discover image files in a directory" {
            # Given: A directory containing image files
            # When: Get-ImageFiles is called on the directory
            # Then: It should return all image files found

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:BasicTestPath
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterThan 0
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should return file objects with required properties" {
            # Given: A directory containing image files
            # When: Get-ImageFiles is called
            # Then: Each returned object should have required properties (FullName, Extension, Length, etc.)

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:BasicTestPath
                if ($result) {
                    $firstFile = $result[0]
                    $firstFile.FullName | Should -Not -BeNullOrEmpty
                    $firstFile.Extension | Should -Not -BeNullOrEmpty
                    $firstFile.Length | Should -BeOfType [long]
                    $firstFile.Name | Should -Not -BeNullOrEmpty
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should handle non-existent directory gracefully" {
            # Given: A non-existent directory path
            # When: Get-ImageFiles is called on the path
            # Then: It should handle the error gracefully without throwing

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $nonExistentPath = Join-Path $script:TestRoot "NonExistent"
                { Get-ImageFiles -Path $nonExistentPath -ErrorAction SilentlyContinue } | Should -Not -Throw
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }

    Context "When testing recursive directory traversal" {

        BeforeAll {
            # Create comprehensive test structure for recursive tests
            $script:RecursiveTestPath = Join-Path $script:TestRoot "RecursiveTests"
            if (Get-Command New-ImageDiscoveryTestStructure -ErrorAction SilentlyContinue) {
                $script:RecursiveTestStructure = New-ImageDiscoveryTestStructure -TestRootPath $script:RecursiveTestPath
            }
        }

        It "Should discover images in subdirectories when Recurse is enabled" {
            # Given: A directory structure with images in multiple subdirectories
            # When: Get-ImageFiles is called with -Recurse parameter
            # Then: It should find images in all subdirectories

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                if ($script:RecursiveTestStructure) {
                    $result.Count | Should -BeGreaterOrEqual $script:RecursiveTestStructure.TotalImageFiles
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should only scan root directory when Recurse is disabled" {
            # Given: A directory structure with images in multiple subdirectories
            # When: Get-ImageFiles is called without -Recurse parameter
            # Then: It should only find images in the root directory

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath
                # Should find fewer files than recursive scan
                $recursiveResult = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                if ($recursiveResult) {
                    $result.Count | Should -BeLessOrEqual $recursiveResult.Count
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should handle deeply nested directory structures" {
            # Given: A deeply nested directory structure with images
            # When: Get-ImageFiles is called with -Recurse
            # Then: It should find images even in deeply nested folders

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                # Should find the deep nested image
                $deepImage = $result | Where-Object { $_.FullName -like "*very\deep\nested\structure*" }
                $deepImage | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }

    Context "When testing supported image format detection" {

        BeforeAll {
            # Use the comprehensive test structure for format testing
            $script:FormatTestPath = $script:RecursiveTestPath
        }

        It "Should detect JPEG files with .jpg extension" {
            # Given: A directory containing JPEG files with .jpg extension
            # When: Get-ImageFiles is called
            # Then: It should include .jpg files in the results

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:FormatTestPath -Recurse
                $jpgFiles = $result | Where-Object { $_.Extension -eq '.jpg' }
                $jpgFiles | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should detect JPEG files with .jpeg extension" {
            # Given: A directory containing JPEG files with .jpeg extension
            # When: Get-ImageFiles is called
            # Then: It should include .jpeg files in the results

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:FormatTestPath -Recurse
                $jpegFiles = $result | Where-Object { $_.Extension -eq '.jpeg' }
                $jpegFiles | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should detect PNG files" {
            # Given: A directory containing PNG files
            # When: Get-ImageFiles is called
            # Then: It should include .png files in the results

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:FormatTestPath -Recurse
                $pngFiles = $result | Where-Object { $_.Extension -eq '.png' }
                $pngFiles | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should detect all supported image formats" {
            # Given: A directory containing various supported image formats
            # When: Get-ImageFiles is called
            # Then: It should detect files with extensions: .jpg, .jpeg, .png, .gif, .bmp, .tiff, .webp

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:FormatTestPath -Recurse
                $supportedExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp')

                # Verify that files with supported extensions are found
                $foundExtensions = @()
                foreach ($ext in $supportedExtensions) {
                    $filesWithExt = $result | Where-Object { $_.Extension -eq $ext }
                    if ($filesWithExt) {
                        $foundExtensions += $ext
                    }
                }

                # Should find at least some supported formats
                $foundExtensions.Count | Should -BeGreaterThan 0

                # Should find multiple different formats
                $uniqueExtensions = ($result | Select-Object -ExpandProperty Extension | Sort-Object -Unique)
                $uniqueExtensions.Count | Should -BeGreaterThan 1
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should exclude non-image files" {
            # Given: A directory containing both image and non-image files
            # When: Get-ImageFiles is called
            # Then: It should only return image files and exclude text, JSON, PDF, etc.

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:FormatTestPath -Recurse
                $nonImageExtensions = @('.txt', '.json', '.pdf', '.csv')

                foreach ($ext in $nonImageExtensions) {
                    $nonImageFiles = $result | Where-Object { $_.Extension -eq $ext }
                    $nonImageFiles | Should -BeNullOrEmpty
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }

    Context "When testing include and exclude pattern filtering" {

        BeforeAll {
            # Create pattern-specific test structure
            $script:PatternTestPath = Join-Path $script:TestRoot "PatternTests"
            if (Get-Command New-PatternTestStructure -ErrorAction SilentlyContinue) {
                $script:PatternTestStructure = New-PatternTestStructure -TestRootPath $script:PatternTestPath
            }
        }

        It "Should include files matching include patterns" {
            # Given: A directory with files that match specific patterns
            # When: Get-ImageFiles is called with -IncludePatterns
            # Then: It should only return files matching the include patterns

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $includePattern = "test_*"
                $result = Get-ImageFiles -Path $script:PatternTestPath -Recurse -IncludePatterns $includePattern

                foreach ($file in $result) {
                    $file.Name | Should -BeLike $includePattern
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should exclude files matching exclude patterns" {
            # Given: A directory with files that should be excluded
            # When: Get-ImageFiles is called with -ExcludePatterns
            # Then: It should not return files matching the exclude patterns

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $excludePattern = "*backup*"
                $result = Get-ImageFiles -Path $script:PatternTestPath -Recurse -ExcludePatterns $excludePattern

                foreach ($file in $result) {
                    $file.Name | Should -Not -BeLike $excludePattern
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should handle multiple include patterns" {
            # Given: A directory with files matching different patterns
            # When: Get-ImageFiles is called with multiple -IncludePatterns
            # Then: It should return files matching any of the include patterns

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $includePatterns = @("test_*", "regular_*")
                $result = Get-ImageFiles -Path $script:PatternTestPath -Recurse -IncludePatterns $includePatterns

                foreach ($file in $result) {
                    $matchesAnyPattern = $false
                    foreach ($pattern in $includePatterns) {
                        if ($file.Name -like $pattern) {
                            $matchesAnyPattern = $true
                            break
                        }
                    }
                    $matchesAnyPattern | Should -Be $true
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }

    Context "When testing file metadata extraction" {

        It "Should return file size information" {
            # Given: Image files with different sizes
            # When: Get-ImageFiles is called
            # Then: Each file object should include size information

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                if ($result) {
                    foreach ($file in $result) {
                        $file.Length | Should -BeOfType [long]
                        $file.Length | Should -BeGreaterOrEqual 0
                    }
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should return file path information" {
            # Given: Image files in various directories
            # When: Get-ImageFiles is called
            # Then: Each file object should include full path and relative path information

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                if ($result) {
                    foreach ($file in $result) {
                        $file.FullName | Should -Not -BeNullOrEmpty
                        $file.Name | Should -Not -BeNullOrEmpty
                        Test-Path $file.FullName | Should -Be $true
                    }
                }
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }

    Context "When testing error handling and edge cases" {

        It "Should handle empty directories gracefully" {
            # Given: An empty directory
            # When: Get-ImageFiles is called on the empty directory
            # Then: It should return an empty result without errors

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $emptyDir = Join-Path $script:TestRoot "EmptyDirectory"
                New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null

                $result = Get-ImageFiles -Path $emptyDir
                $result | Should -BeNullOrEmpty -Or @()
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should handle special characters in file paths" {
            # Given: Files with special characters in their paths
            # When: Get-ImageFiles is called
            # Then: It should handle special characters correctly

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                $specialCharFile = $result | Where-Object { $_.FullName -like "*ñáéíóú*" }
                $specialCharFile | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }

        It "Should handle case-insensitive file extensions" {
            # Given: Image files with mixed case extensions (.PNG, .Jpg, etc.)
            # When: Get-ImageFiles is called
            # Then: It should detect images regardless of extension case

            if (Get-Command Get-ImageFiles -ErrorAction SilentlyContinue) {
                $result = Get-ImageFiles -Path $script:RecursiveTestPath -Recurse
                $mixedCaseFile = $result | Where-Object { $_.Extension -eq '.PNG' }
                $mixedCaseFile | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Get-ImageFiles function not yet implemented"
            }
        }
    }
}
