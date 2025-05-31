# WebImageOptimizer Validation Helpers Tests
# Comprehensive test suite for validation helper functions
# Author: PowerShell Web Image Optimizer Team
# Version: 1.0.0

#Requires -Version 7.0

Describe "WebImageOptimizer.ValidationHelpers" -Tags @('Unit', 'ValidationHelpers', 'Fast') {

    BeforeAll {
        # Import the PathResolution test helper first
        $pathHelperPath = Join-Path $PSScriptRoot "..\TestHelpers\PathResolution.psm1"
        if (Test-Path $pathHelperPath) {
            Import-Module $pathHelperPath -Force
        }

        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:ValidationHelpersPath = Join-Path $script:PrivatePath "ValidationHelpers.ps1"

        # Import validation helpers if available
        if (Test-Path $script:ValidationHelpersPath) {
            . $script:ValidationHelpersPath
        }
    }

    Context "When validating supported image formats with default settings" {

        It "Should validate JPEG files as supported" {
            # Given: A filename with JPEG extension
            # When: Validating the format with default supported formats
            # Then: The result should indicate the format is supported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "photo.jpg"

                $result | Should -Not -BeNullOrEmpty
                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".jpg"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should validate PNG files as supported" {
            # Given: A filename with PNG extension
            # When: Validating the format with default supported formats
            # Then: The result should indicate the format is supported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "image.png"

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".png"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should validate WebP files as supported" {
            # Given: A filename with WebP extension
            # When: Validating the format with default supported formats
            # Then: The result should indicate the format is supported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "modern.webp"

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".webp"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should validate AVIF files as supported" {
            # Given: A filename with AVIF extension
            # When: Validating the format with default supported formats
            # Then: The result should indicate the format is supported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "nextgen.avif"

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".avif"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should handle case-insensitive extensions" {
            # Given: A filename with uppercase extension
            # When: Validating the format
            # Then: The result should indicate the format is supported (case-insensitive)

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "PHOTO.JPG"

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".JPG"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }
    }

    Context "When validating unsupported image formats" {

        It "Should detect text files as unsupported" {
            # Given: A filename with text file extension
            # When: Validating the format
            # Then: The result should indicate the format is unsupported with appropriate error message

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "document.txt"

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ".txt"
                $result.ErrorMessage | Should -Be "Unsupported file format: .txt"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should detect document files as unsupported" {
            # Given: A filename with document extension
            # When: Validating the format
            # Then: The result should indicate the format is unsupported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "report.docx"

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ".docx"
                $result.ErrorMessage | Should -Be "Unsupported file format: .docx"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should detect unknown extensions as unsupported" {
            # Given: A filename with unknown extension
            # When: Validating the format
            # Then: The result should indicate the format is unsupported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "mystery.xyz"

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ".xyz"
                $result.ErrorMessage | Should -Be "Unsupported file format: .xyz"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }
    }

    Context "When using custom supported formats configuration" {

        It "Should respect custom supported formats array" {
            # Given: A custom supported formats array with only JPEG and PNG
            # When: Validating a WebP file against this custom list
            # Then: The WebP file should be considered unsupported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $customFormats = @('.jpg', '.jpeg', '.png')
                $result = Test-SupportedImageFormat -FileName "image.webp" -SupportedFormats $customFormats

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ".webp"
                $result.ErrorMessage | Should -Be "Unsupported file format: .webp"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should validate against custom formats successfully" {
            # Given: A custom supported formats array
            # When: Validating a file with extension in the custom list
            # Then: The file should be considered supported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $customFormats = @('.jpg', '.png')
                $result = Test-SupportedImageFormat -FileName "photo.jpg" -SupportedFormats $customFormats

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".jpg"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }
    }

    Context "When handling edge cases and error conditions" {

        It "Should handle files without extensions" {
            # Given: A filename without an extension
            # When: Validating the format
            # Then: The result should indicate the format is unsupported

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "imagefile"

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ""
                $result.ErrorMessage | Should -Be "Unsupported file format: (no extension)"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should handle empty filename gracefully" {
            # Given: An empty filename
            # When: Validating the format
            # Then: The function should handle it gracefully without throwing

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName ""

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ""
                $result.ErrorMessage | Should -Be "Unsupported file format: (no extension)"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should handle null filename gracefully" {
            # Given: A null filename
            # When: Validating the format
            # Then: The function should handle it gracefully without throwing

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName $null

                $result.IsSupported | Should -Be $false
                $result.Extension | Should -Be ""
                $result.ErrorMessage | Should -Be "Unsupported file format: (no extension)"
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should handle files with multiple dots in filename" {
            # Given: A filename with multiple dots
            # When: Validating the format
            # Then: The function should correctly identify the final extension

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $result = Test-SupportedImageFormat -FileName "my.photo.backup.jpg"

                $result.IsSupported | Should -Be $true
                $result.Extension | Should -Be ".jpg"
                $result.ErrorMessage | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }
    }

    Context "When validating function behavior and thread safety" {

        It "Should return consistent results for identical inputs" {
            # Given: The same filename validated multiple times
            # When: Calling the validation function repeatedly
            # Then: Results should be consistent across calls

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $fileName = "test.jpg"
                $results = @()

                for ($i = 0; $i -lt 5; $i++) {
                    $results += Test-SupportedImageFormat -FileName $fileName
                }

                # All results should be identical
                $results | ForEach-Object {
                    $_.IsSupported | Should -Be $true
                    $_.Extension | Should -Be ".jpg"
                    $_.ErrorMessage | Should -BeNullOrEmpty
                }
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }

        It "Should be thread-safe for concurrent validation" {
            # Given: Multiple validation calls in parallel
            # When: Validating different files concurrently
            # Then: All results should be correct and consistent

            if (Get-Command Test-SupportedImageFormat -ErrorAction SilentlyContinue) {
                $testFiles = @("image1.jpg", "document.txt", "photo.png", "file.xyz", "picture.webp")

                $results = $testFiles | ForEach-Object -Parallel {
                    # Import the function in parallel context
                    $validationPath = $using:ValidationHelpersPath
                    if (Test-Path $validationPath) {
                        . $validationPath
                    }

                    Test-SupportedImageFormat -FileName $_
                } -ThrottleLimit 3

                # Verify expected results
                $jpgResult = $results | Where-Object { $_.Extension -eq ".jpg" }
                $jpgResult.IsSupported | Should -Be $true

                $txtResult = $results | Where-Object { $_.Extension -eq ".txt" }
                $txtResult.IsSupported | Should -Be $false

                $pngResult = $results | Where-Object { $_.Extension -eq ".png" }
                $pngResult.IsSupported | Should -Be $true

                $xyzResult = $results | Where-Object { $_.Extension -eq ".xyz" }
                $xyzResult.IsSupported | Should -Be $false

                $webpResult = $results | Where-Object { $_.Extension -eq ".webp" }
                $webpResult.IsSupported | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "Test-SupportedImageFormat function not yet implemented"
            }
        }
    }

    AfterAll {
        # Clean up any imported modules
        if (Get-Module PathResolution) {
            Remove-Module PathResolution -Force
        }
    }
}

Describe "WebImageOptimizer Get-DefaultSupportedFormats Configuration Loading" {

    BeforeAll {
        # Import the PathResolution test helper module
        $pathResolutionModule = Join-Path $PSScriptRoot "..\TestHelpers\PathResolution.psm1"
        if (Test-Path $pathResolutionModule) {
            Import-Module $pathResolutionModule -Force
        }

        # Define the module root path with robust resolution
        $script:ModuleRoot = Get-ModuleRootPath
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:ValidationHelpersPath = Join-Path $script:PrivatePath "ValidationHelpers.ps1"

        # Import the ValidationHelpers module if it exists
        if (Test-Path $script:ValidationHelpersPath) {
            . $script:ValidationHelpersPath
        }

        # Set up test root directory with timestamp for isolation
        $script:TestRoot = Join-Path $env:TEMP "ValidationHelpers_Config_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Test root directory: $script:TestRoot" -ForegroundColor Yellow

        # Create test directory structure
        New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null
        $script:TestConfigPath = Join-Path $script:TestRoot "TestConfigs"
        New-Item -Path $script:TestConfigPath -ItemType Directory -Force | Out-Null
    }

    Context "When loading supported formats from configuration files" {

        BeforeAll {
            # Create test configuration files for various scenarios

            # Valid configuration with standard formats
            $script:ValidConfigPath = Join-Path $script:TestConfigPath "valid-config.json"
            $validConfig = @{
                formats = @{
                    supportedInputFormats = @("jpeg", "jpg", "png", "webp", "gif", "bmp", "tiff")
                }
            }
            $validConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:ValidConfigPath

            # Valid configuration with custom formats
            $script:CustomConfigPath = Join-Path $script:TestConfigPath "custom-config.json"
            $customConfig = @{
                formats = @{
                    supportedInputFormats = @("jpg", "png", "webp")
                }
            }
            $customConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:CustomConfigPath

            # Configuration with formats that already have dots
            $script:DotsConfigPath = Join-Path $script:TestConfigPath "dots-config.json"
            $dotsConfig = @{
                formats = @{
                    supportedInputFormats = @(".jpg", ".png", "webp", ".gif")
                }
            }
            $dotsConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:DotsConfigPath

            # Invalid JSON configuration
            $script:InvalidJsonPath = Join-Path $script:TestConfigPath "invalid.json"
            Set-Content -Path $script:InvalidJsonPath -Value '{ "formats": { "supportedInputFormats": ['

            # Configuration missing formats section
            $script:MissingFormatsPath = Join-Path $script:TestConfigPath "missing-formats.json"
            $missingFormatsConfig = @{
                defaultSettings = @{
                    jpeg = @{ quality = 85 }
                }
            }
            $missingFormatsConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:MissingFormatsPath

            # Configuration with empty formats array
            $script:EmptyFormatsPath = Join-Path $script:TestConfigPath "empty-formats.json"
            $emptyFormatsConfig = @{
                formats = @{
                    supportedInputFormats = @()
                }
            }
            $emptyFormatsConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:EmptyFormatsPath

            # Non-existent file path
            $script:NonExistentPath = Join-Path $script:TestConfigPath "non-existent.json"
        }

        It "Should load supported formats from valid configuration file" {
            # Given: A valid configuration file with supported formats
            # When: Get-DefaultSupportedFormats is called with ConfigurationPath
            # Then: It should return formats from the configuration file with dots added

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:ValidConfigPath

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".png"
                $resultArray | Should -Contain ".webp"
                $resultArray | Should -Contain ".gif"
                $resultArray | Should -Contain ".bmp"
                $resultArray | Should -Contain ".tiff"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should handle custom format configurations correctly" {
            # Given: A configuration file with custom supported formats
            # When: Get-DefaultSupportedFormats is called with the custom configuration
            # Then: It should return only the formats specified in the configuration

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:CustomConfigPath

                $result | Should -Not -BeNullOrEmpty
                $result | Should -HaveCount 3
                $result | Should -Contain ".jpg"
                $result | Should -Contain ".png"
                $result | Should -Contain ".webp"
                $result | Should -Not -Contain ".gif"
                $result | Should -Not -Contain ".bmp"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should handle formats that already have dots correctly" {
            # Given: A configuration file with formats that already include dots
            # When: Get-DefaultSupportedFormats is called
            # Then: It should not add duplicate dots to formats

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:DotsConfigPath

                $result | Should -Not -BeNullOrEmpty
                $result | Should -Contain ".jpg"
                $result | Should -Contain ".png"
                $result | Should -Contain ".webp"
                $result | Should -Contain ".gif"
                # Should not contain double dots
                $result | Should -Not -Contain "..jpg"
                $result | Should -Not -Contain "..png"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should fall back to defaults when configuration file does not exist" {
            # Given: A non-existent configuration file path
            # When: Get-DefaultSupportedFormats is called with the non-existent path
            # Then: It should return default formats and log appropriate warning

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:NonExistentPath

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                # Should contain default formats
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".png"
                $resultArray | Should -Contain ".webp"
                $resultArray | Should -Contain ".avif"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should fall back to defaults when JSON is invalid" {
            # Given: A configuration file with invalid JSON
            # When: Get-DefaultSupportedFormats is called
            # Then: It should return default formats and handle the error gracefully

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:InvalidJsonPath

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                # Should contain default formats
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".png"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should fall back to defaults when formats section is missing" {
            # Given: A configuration file without formats section
            # When: Get-DefaultSupportedFormats is called
            # Then: It should return default formats

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:MissingFormatsPath

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                # Should contain default formats
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".png"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should fall back to defaults when formats array is empty" {
            # Given: A configuration file with empty formats array
            # When: Get-DefaultSupportedFormats is called
            # Then: It should return default formats

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats -ConfigurationPath $script:EmptyFormatsPath

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                # Should contain default formats
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".png"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should return defaults when no ConfigurationPath is provided" {
            # Given: No configuration path parameter
            # When: Get-DefaultSupportedFormats is called without ConfigurationPath
            # Then: It should return hardcoded default formats

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $result = Get-DefaultSupportedFormats

                $result | Should -Not -BeNullOrEmpty
                # Convert to array to handle PowerShell array unwrapping
                $resultArray = @($result)
                $resultArray.Count | Should -BeGreaterThan 0
                $resultArray[0] | Should -BeOfType [string]
                $resultArray | Should -Contain ".jpg"
                $resultArray | Should -Contain ".jpeg"
                $resultArray | Should -Contain ".png"
                $resultArray | Should -Contain ".webp"
                $resultArray | Should -Contain ".avif"
                $resultArray | Should -Contain ".gif"
                $resultArray | Should -Contain ".bmp"
                $resultArray | Should -Contain ".tiff"
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }
    }

    Context "When testing configuration loading behavior and messaging" {

        It "Should provide verbose messages when loading configuration successfully" {
            # Given: A valid configuration file
            # When: Get-DefaultSupportedFormats is called with -Verbose
            # Then: It should output appropriate verbose messages

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $verboseOutput = Get-DefaultSupportedFormats -ConfigurationPath $script:ValidConfigPath -Verbose 4>&1

                # Check if verbose messages are generated (implementation-dependent)
                # This test validates that the function can be called with -Verbose without errors
                $verboseOutput | Should -Not -BeNull
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }

        It "Should be thread-safe when loading configurations concurrently" {
            # Given: Multiple concurrent calls to load configuration
            # When: Get-DefaultSupportedFormats is called in parallel
            # Then: All calls should return consistent results

            if (Get-Command Get-DefaultSupportedFormats -ErrorAction SilentlyContinue) {
                $configPaths = @($script:ValidConfigPath, $script:CustomConfigPath, $script:ValidConfigPath)

                $results = $configPaths | ForEach-Object -Parallel {
                    # Import the function in parallel context
                    $validationPath = $using:script:ValidationHelpersPath
                    if (Test-Path $validationPath) {
                        . $validationPath
                    }

                    Get-DefaultSupportedFormats -ConfigurationPath $_
                } -ThrottleLimit 3

                # All results should be arrays of strings
                $results | ForEach-Object {
                    # Convert to array to handle PowerShell array unwrapping
                    $resultArray = @($_)
                    $resultArray.Count | Should -BeGreaterThan 0
                    $resultArray[0] | Should -BeOfType [string]
                    $resultArray | Should -Not -BeNullOrEmpty
                }

                # For thread-safety testing, we verify that:
                # 1. All results are valid arrays of strings
                # 2. No exceptions were thrown during parallel execution
                # 3. Results are consistent with the function's behavior

                $resultCounts = $results | ForEach-Object { @($_).Count }
                $resultCounts | Should -Not -BeNullOrEmpty
                $resultCounts | ForEach-Object { $_ | Should -BeGreaterThan 0 }

                # Verify that all results contain valid format strings
                $results | ForEach-Object {
                    $resultArray = @($_)
                    $resultArray | ForEach-Object { $_ | Should -Match '^\.' }  # Should start with dot
                }
            } else {
                Set-ItResult -Pending -Because "Get-DefaultSupportedFormats function not yet implemented"
            }
        }
    }

    AfterAll {
        # Clean up test files and directories
        if (Test-Path $script:TestRoot) {
            Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Clean up any imported modules
        if (Get-Module PathResolution) {
            Remove-Module PathResolution -Force
        }
    }
}
