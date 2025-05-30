# Define the module root path
$ModuleRoot = "d:\repos\PSWebImage"
$ModulePath = Join-Path $ModuleRoot "WebImageOptimizer"

Describe "WebImageOptimizer Module Structure" {
    Context "When setting up the module structure" {
        It "Should create the main module directory" {
            # Given: A PowerShell project workspace
            # When: The module structure is created
            # Then: The main WebImageOptimizer directory should exist
            Test-Path $ModulePath | Should -Be $true
        }
          It "Should create the main module file (.psm1)" {
            # Given: The module directory exists
            # When: Basic module files are created
            # Then: The main module file should exist
            $ModuleFile = Join-Path $ModulePath "WebImageOptimizer.psm1"
            Test-Path $ModuleFile | Should -Be $true
        }

        It "Should create the module manifest file (.psd1)" {
            # Given: The module directory exists
            # When: Basic module files are created
            # Then: The module manifest file should exist
            $ManifestFile = Join-Path $ModulePath "WebImageOptimizer.psd1"
            Test-Path $ManifestFile | Should -Be $true
        }

        It "Should create the Private functions directory" {
            # Given: The module directory exists
            # When: Directory structure is created
            # Then: The Private directory should exist
            $PrivateDir = Join-Path $ModulePath "Private"
            Test-Path $PrivateDir | Should -Be $true
        }

        It "Should create the Public functions directory" {
            # Given: The module directory exists
            # When: Directory structure is created
            # Then: The Public directory should exist
            $PublicDir = Join-Path $ModulePath "Public"
            Test-Path $PublicDir | Should -Be $true
        }

        It "Should create the Config directory" {
            # Given: The module directory exists
            # When: Directory structure is created
            # Then: The Config directory should exist
            $ConfigDir = Join-Path $ModulePath "Config"
            Test-Path $ConfigDir | Should -Be $true
        }

        It "Should create the Dependencies directory" {
            # Given: The module directory exists
            # When: Directory structure is created
            # Then: The Dependencies directory should exist
            $DependenciesDir = Join-Path $ModulePath "Dependencies"
            Test-Path $DependenciesDir | Should -Be $true
        }
    }

    Context "When validating module files content" {
          It "Should have a valid module manifest that can be tested" {
            # Given: The module manifest file exists
            # When: Testing the manifest structure
            # Then: Test-ModuleManifest should pass without errors
            $ManifestFile = Join-Path $ModulePath "WebImageOptimizer.psd1"
            if (Test-Path $ManifestFile) {
                { Test-ModuleManifest -Path $ManifestFile } | Should -Not -Throw
            }
        }
          It "Should have a main module file with basic structure" {
            # Given: The main module file exists
            # When: Reading the module file content
            # Then: It should contain basic PowerShell module structure
            $ModuleFile = Join-Path $ModulePath "WebImageOptimizer.psm1"
            if (Test-Path $ModuleFile) {
                $Content = Get-Content $ModuleFile -Raw
                $Content | Should -Not -BeNullOrEmpty
                # Should contain some basic module structure elements
                $Content | Should -Match "#.*WebImageOptimizer.*Module"
            }
        }
    }

    Context "When testing module import functionality" {
          It "Should be able to import the module without errors" {
            # Given: The module structure is complete
            # When: Attempting to import the module
            # Then: Import-Module should succeed without throwing errors
            $TestModulePath = Join-Path $ModuleRoot "WebImageOptimizer"
            if (Test-Path $TestModulePath) {
                { Import-Module $TestModulePath -Force } | Should -Not -Throw

                # Clean up - remove the module after testing
                if (Get-Module -Name WebImageOptimizer) {
                    Remove-Module WebImageOptimizer -Force
                }
            }
        }
    }
}

Describe "WebImageOptimizer Module Structure Compliance" {
    Context "When validating PRD specification compliance" {
          BeforeAll {
            # Expected directory structure based on PRD
            $script:ExpectedDirectories = @(
                "Private",
                "Public",
                "Config",
                "Dependencies"
            )

            $script:ExpectedFiles = @(
                "WebImageOptimizer.psm1",
                "WebImageOptimizer.psd1"
            )

            $script:TestModulePath = Join-Path "d:\repos\PSWebImage" "WebImageOptimizer"
        }
          It "Should contain all required directories from PRD specification" {
            # Given: The PRD specifies a specific directory structure
            # When: Validating the created structure
            # Then: All required directories should exist
            foreach ($dir in $script:ExpectedDirectories) {
                $DirPath = Join-Path $script:TestModulePath $dir
                Test-Path $DirPath | Should -Be $true -Because "Directory '$dir' is required by PRD specification"
            }
        }

        It "Should contain all required files from PRD specification" {
            # Given: The PRD specifies required module files
            # When: Validating the created files
            # Then: All required files should exist
            foreach ($file in $script:ExpectedFiles) {
                $FilePath = Join-Path $script:TestModulePath $file
                Test-Path $FilePath | Should -Be $true -Because "File '$file' is required by PRD specification"
            }
        }

        It "Should have proper directory structure hierarchy" {
            # Given: The module directory exists
            # When: Checking the directory structure
            # Then: The structure should match the expected hierarchy
            $ModuleItems = Get-ChildItem $script:TestModulePath
            $ActualDirectories = $ModuleItems | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name
            $ActualFiles = $ModuleItems | Where-Object { -not $_.PSIsContainer } | Select-Object -ExpandProperty Name

            # Verify we have the expected directories
            foreach ($expectedDir in $script:ExpectedDirectories) {
                $ActualDirectories | Should -Contain $expectedDir
            }

            # Verify we have the expected files
            foreach ($expectedFile in $script:ExpectedFiles) {
                $ActualFiles | Should -Contain $expectedFile
            }
        }
    }
}
