# Test suite for WebImageOptimizer Core Image Optimization Engine (Task 6)
# BDD/TDD implementation following Given-When-Then structure

Describe "WebImageOptimizer Core Image Optimization Engine" {

    BeforeAll {
        # Define the module root path - use absolute path for reliability in tests
        $script:ModuleRoot = "D:\repos\PSWebImage"
        $script:ModulePath = Join-Path $script:ModuleRoot "WebImageOptimizer"
        $script:PrivatePath = Join-Path $script:ModulePath "Private"
        $script:ConfigPath = Join-Path $script:ModulePath "Config"
        $script:DependenciesPath = Join-Path $script:ModulePath "Dependencies"

        # Define paths to the functions we're testing
        $script:ImageOptimizationPath = Join-Path $script:PrivatePath "Invoke-ImageOptimization.ps1"
        $script:ConfigManagerPath = Join-Path $script:PrivatePath "ConfigurationManager.ps1"
        $script:DependencyCheckPath = Join-Path $script:DependenciesPath "Check-ImageMagick.ps1"
        $script:TestDataLibraryPath = Join-Path $script:ModuleRoot "Tests\TestDataLibraries\ImageOptimization.TestDataLibrary.ps1"

        # Import existing functions
        if (Test-Path $script:ConfigManagerPath) {
            . $script:ConfigManagerPath
        }
        if (Test-Path $script:DependencyCheckPath) {
            . $script:DependencyCheckPath
        }
        if (Test-Path $script:TestDataLibraryPath) {
            . $script:TestDataLibraryPath
        }

        # Import the image optimization function if it exists
        if (Test-Path $script:ImageOptimizationPath) {
            . $script:ImageOptimizationPath
        }

        # Set up test root directory
        $script:TestRoot = Join-Path $env:TEMP "WebImageOptimizer_ImageOptimization_Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
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

    Context "When testing basic image optimization functionality" {

        BeforeAll {
            # Create test images for basic functionality tests
            $script:BasicTestPath = Join-Path $script:TestRoot "BasicTests"
            if (Get-Command New-MinimalOptimizationTestImages -ErrorAction SilentlyContinue) {
                $script:BasicTestImages = New-MinimalOptimizationTestImages -TestRootPath $script:BasicTestPath
            }
        }

        It "Should have Invoke-ImageOptimization function available" {
            # Given: The image optimization engine is implemented
            # When: Checking for the Invoke-ImageOptimization function
            # Then: The function should be available for use

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue) {
                Get-Command Invoke-ImageOptimization | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented"
            }
        }

        It "Should accept required parameters for image optimization" {
            # Given: The image optimization function exists
            # When: Examining the function parameters
            # Then: It should accept InputPath, OutputPath, Settings, and ProcessingEngine parameters

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue) {
                $function = Get-Command Invoke-ImageOptimization
                $parameters = $function.Parameters.Keys

                $parameters | Should -Contain "InputPath"
                $parameters | Should -Contain "OutputPath"
                $parameters | Should -Contain "Settings"
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented"
            }
        }

        It "Should return optimization results with before/after metrics" {
            # Given: A test image file and optimization settings
            # When: Invoke-ImageOptimization is called
            # Then: It should return results with before/after file sizes and optimization metrics

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:BasicTestImages) {
                $testImage = $script:BasicTestImages.CreatedImages[0]
                $outputPath = Join-Path $script:BasicTestPath "optimized_test.jpg"

                $result = Invoke-ImageOptimization -InputPath $testImage -OutputPath $outputPath

                $result | Should -Not -BeNullOrEmpty
                $result.InputPath | Should -Be $testImage
                $result.OutputPath | Should -Be $outputPath
                $result.OriginalSize | Should -BeOfType [long]
                $result.OptimizedSize | Should -BeOfType [long]
                $result.CompressionRatio | Should -BeOfType [double]
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should handle non-existent input file gracefully" {
            # Given: A non-existent input file path
            # When: Invoke-ImageOptimization is called
            # Then: It should handle the error gracefully without throwing

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue) {
                $nonExistentPath = Join-Path $script:TestRoot "nonexistent.jpg"
                $outputPath = Join-Path $script:TestRoot "output.jpg"

                { Invoke-ImageOptimization -InputPath $nonExistentPath -OutputPath $outputPath -ErrorAction SilentlyContinue } | Should -Not -Throw
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented"
            }
        }
    }

    Context "When testing JPEG optimization with quality settings" {

        BeforeAll {
            # Create JPEG test images
            $script:JpegTestPath = Join-Path $script:TestRoot "JpegTests"
            if (Get-Command New-ImageOptimizationTestImages -ErrorAction SilentlyContinue) {
                $script:JpegTestImages = New-ImageOptimizationTestImages -TestRootPath $script:JpegTestPath
            }
        }

        It "Should optimize JPEG images with specified quality settings" {
            # Given: A JPEG image and quality settings
            # When: Invoke-ImageOptimization is called with JPEG quality settings
            # Then: The optimization should apply the specified quality level

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $jpegImage = $script:JpegTestImages.CreatedImages | Where-Object { $_ -like "*.jpg" } | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "optimized_quality.jpg"

                $settings = @{
                    jpeg = @{
                        quality = 75
                        progressive = $true
                        stripMetadata = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $jpegImage -OutputPath $outputPath -Settings $settings

                $result.Format | Should -Be "JPEG"
                $result.QualityApplied | Should -Be 75
                $result.ProgressiveEncoding | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should enable progressive encoding for JPEG images when specified" {
            # Given: A JPEG image and progressive encoding setting
            # When: Invoke-ImageOptimization is called with progressive = true
            # Then: The output should use progressive encoding

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $jpegImage = $script:JpegTestImages.CreatedImages | Where-Object { $_ -like "*.jpg" } | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "progressive.jpg"

                $settings = @{
                    jpeg = @{
                        quality = 85
                        progressive = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $jpegImage -OutputPath $outputPath -Settings $settings

                $result.ProgressiveEncoding | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should strip metadata from JPEG images when specified" {
            # Given: A JPEG image with metadata and stripMetadata setting
            # When: Invoke-ImageOptimization is called with stripMetadata = true
            # Then: The output should have metadata removed

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $jpegWithMetadata = $script:JpegTestImages.ImageMetadata | Where-Object { $_.HasMetadata -eq $true -and $_.Format -eq "JPEG" } | Select-Object -First 1
                if ($jpegWithMetadata) {
                    $outputPath = Join-Path $script:JpegTestPath "no_metadata.jpg"

                    $settings = @{
                        jpeg = @{
                            quality = 85
                            stripMetadata = $true
                        }
                    }

                    $result = Invoke-ImageOptimization -InputPath $jpegWithMetadata.Path -OutputPath $outputPath -Settings $settings

                    $result.MetadataRemoved | Should -Be $true
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }

    Context "When testing PNG optimization with compression settings" {

        BeforeAll {
            # Use the same test images for PNG testing
            $script:PngTestPath = $script:JpegTestPath
        }

        It "Should optimize PNG images with specified compression level" {
            # Given: A PNG image and compression settings
            # When: Invoke-ImageOptimization is called with PNG compression settings
            # Then: The optimization should apply the specified compression level

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $pngImage = $script:JpegTestImages.CreatedImages | Where-Object { $_ -like "*.png" } | Select-Object -First 1
                $outputPath = Join-Path $script:PngTestPath "optimized_compression.png"

                $settings = @{
                    png = @{
                        compression = 6
                        stripMetadata = $true
                        optimize = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $pngImage -OutputPath $outputPath -Settings $settings

                $result.Format | Should -Be "PNG"
                $result.CompressionLevel | Should -Be 6
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should maintain transparency in PNG images during optimization" {
            # Given: A PNG image with transparency
            # When: Invoke-ImageOptimization is called
            # Then: The output should preserve transparency

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $pngImage = $script:JpegTestImages.CreatedImages | Where-Object { $_ -like "*.png" } | Select-Object -First 1
                $outputPath = Join-Path $script:PngTestPath "transparency_preserved.png"

                $settings = @{
                    png = @{
                        compression = 6
                        optimize = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $pngImage -OutputPath $outputPath -Settings $settings

                $result.TransparencyPreserved | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }

    Context "When testing WebP and AVIF optimization" {

        It "Should optimize images to WebP format with specified quality" {
            # Given: An image and WebP optimization settings
            # When: Invoke-ImageOptimization is called with WebP settings
            # Then: The output should be in WebP format with specified quality

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "optimized.webp"

                $settings = @{
                    webp = @{
                        quality = 90
                        method = 6
                        stripMetadata = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath -Settings $settings

                $result.Format | Should -Be "WebP"
                $result.QualityApplied | Should -Be 90
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should optimize images to AVIF format with specified quality" {
            # Given: An image and AVIF optimization settings
            # When: Invoke-ImageOptimization is called with AVIF settings
            # Then: The output should be in AVIF format with specified quality

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "optimized.avif"

                $settings = @{
                    avif = @{
                        quality = 85
                        speed = 6
                        stripMetadata = $true
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath -Settings $settings

                $result.Format | Should -Be "AVIF"
                $result.QualityApplied | Should -Be 85
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }

    Context "When testing processing engine selection and fallback" {

        It "Should use ImageMagick as primary processing engine when available" {
            # Given: ImageMagick is available on the system
            # When: Invoke-ImageOptimization is called without specifying engine
            # Then: It should use ImageMagick as the processing engine

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "imagemagick_processed.jpg"

                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath

                if ($result.ProcessingEngine) {
                    # If ImageMagick is available, it should be preferred
                    if ((Test-ImageProcessingDependencies).ImageMagick.Found) {
                        $result.ProcessingEngine | Should -Be "ImageMagick"
                    }
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should fallback to .NET processing when ImageMagick is unavailable" {
            # Given: ImageMagick is not available but .NET processing is available
            # When: Invoke-ImageOptimization is called
            # Then: It should use .NET as the fallback processing engine

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "dotnet_processed.jpg"

                # Force .NET engine for testing
                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath -ProcessingEngine "DotNet"

                $result.ProcessingEngine | Should -Be "DotNet"
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should handle case when no processing engines are available" {
            # Given: No image processing engines are available
            # When: Invoke-ImageOptimization is called
            # Then: It should return an appropriate error message

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "no_engine.jpg"

                # Force no engine for testing
                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath -ProcessingEngine "None"

                $result.Success | Should -Be $false
                $result.ErrorMessage | Should -Match "No.*processing.*engine.*available"
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }

    Context "When testing aspect ratio preservation during resizing" {

        It "Should maintain aspect ratio when resizing images" {
            # Given: An oversized image and resize settings
            # When: Invoke-ImageOptimization is called with max dimensions
            # Then: The output should maintain the original aspect ratio

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $oversizedImage = $script:JpegTestImages.ImageMetadata | Where-Object { $_.Size -eq "Oversized" } | Select-Object -First 1
                if ($oversizedImage) {
                    $outputPath = Join-Path $script:JpegTestPath "resized_aspect_preserved.jpg"

                    $settings = @{
                        processing = @{
                            maxDimensions = @{
                                width = 1920
                                height = 1080
                            }
                        }
                        jpeg = @{
                            quality = 85
                        }
                    }

                    $result = Invoke-ImageOptimization -InputPath $oversizedImage.Path -OutputPath $outputPath -Settings $settings

                    $result.AspectRatioPreserved | Should -Be $true
                    $result.OutputWidth | Should -BeLessOrEqual 1920
                    $result.OutputHeight | Should -BeLessOrEqual 1080
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should not resize images that are already within max dimensions" {
            # Given: An image that is already within the max dimensions
            # When: Invoke-ImageOptimization is called with max dimensions
            # Then: The image should not be resized

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $smallImage = $script:JpegTestImages.ImageMetadata | Where-Object { $_.Size -eq "Small" } | Select-Object -First 1
                if ($smallImage) {
                    $outputPath = Join-Path $script:JpegTestPath "no_resize_needed.jpg"

                    $settings = @{
                        processing = @{
                            maxDimensions = @{
                                width = 1920
                                height = 1080
                            }
                        }
                        jpeg = @{
                            quality = 85
                        }
                    }

                    $result = Invoke-ImageOptimization -InputPath $smallImage.Path -OutputPath $outputPath -Settings $settings

                    $result.WasResized | Should -Be $false
                    $result.OutputWidth | Should -Be $smallImage.Width
                    $result.OutputHeight | Should -Be $smallImage.Height
                }
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }

    Context "When testing error handling and edge cases" {

        It "Should handle corrupted or invalid image files gracefully" {
            # Given: A corrupted or invalid image file
            # When: Invoke-ImageOptimization is called
            # Then: It should handle the error gracefully and return appropriate error information

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue) {
                $corruptedImagePath = Join-Path $script:TestRoot "corrupted.jpg"
                Set-Content -Path $corruptedImagePath -Value "This is not a valid image file" -Encoding UTF8
                $outputPath = Join-Path $script:TestRoot "output_corrupted.jpg"

                $result = Invoke-ImageOptimization -InputPath $corruptedImagePath -OutputPath $outputPath -ErrorAction SilentlyContinue

                $result.Success | Should -Be $false
                $result.ErrorMessage | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented"
            }
        }

        It "Should handle invalid output path gracefully" {
            # Given: A valid input image and an invalid output path
            # When: Invoke-ImageOptimization is called
            # Then: It should handle the error gracefully

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $invalidOutputPath = "Z:\NonExistent\Path\output.jpg"

                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $invalidOutputPath -ErrorAction SilentlyContinue

                $result.Success | Should -Be $false
                $result.ErrorMessage | Should -Match "path|directory|access"
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }

        It "Should validate configuration settings and provide meaningful errors" {
            # Given: Invalid configuration settings
            # When: Invoke-ImageOptimization is called with invalid settings
            # Then: It should validate settings and provide meaningful error messages

            if (Get-Command Invoke-ImageOptimization -ErrorAction SilentlyContinue -and $script:JpegTestImages) {
                $inputImage = $script:JpegTestImages.CreatedImages | Select-Object -First 1
                $outputPath = Join-Path $script:JpegTestPath "invalid_settings.jpg"

                $invalidSettings = @{
                    jpeg = @{
                        quality = 150  # Invalid quality (should be 0-100)
                    }
                }

                $result = Invoke-ImageOptimization -InputPath $inputImage -OutputPath $outputPath -Settings $invalidSettings -ErrorAction SilentlyContinue

                $result.Success | Should -Be $false
                $result.ErrorMessage | Should -Match "quality|setting|invalid"
            } else {
                Set-ItResult -Pending -Because "Invoke-ImageOptimization function not yet implemented or test images not available"
            }
        }
    }
}