# Test ImageMagick optimization directly
cd d:\repos\PSWebImage

# Import the module
Import-Module .\WebImageOptimizer\WebImageOptimizer.psd1 -Force

# Import the private function
. .\WebImageOptimizer\Private\Invoke-ImageOptimization.ps1
. .\WebImageOptimizer\Dependencies\Check-ImageMagick.ps1

# Test the ImageMagick optimization function directly
Write-Host "Testing ImageMagick optimization..."

$result = Invoke-ImageMagickOptimization -InputPath "test-large.png" -OutputPath "test-direct.png" -Settings @{} -FormatSettings @{} -Verbose

Write-Host "Result: $($result | ConvertTo-Json -Depth 3)"

# Check file sizes
Write-Host "`nFile sizes:"
Get-ChildItem test-large.png, test-direct.png -ErrorAction SilentlyContinue | Select-Object Name, Length
