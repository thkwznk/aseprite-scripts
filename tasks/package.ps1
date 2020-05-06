param ($profilePath, $scriptsDirectory, $outputFilename = "package")

if (([string]::IsNullOrEmpty($profilePath)) -or (Test-Path -Path $profilePath) -eq $false) {
    Write-Host "Profile ${profilePath} does not exist" 
}

function Resolve-NewPath($path) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
}

# Load JSON profile/configuration
$profileConfiguration = Get-Content $profilePath -Encoding UTF8 | ConvertFrom-Json
$packageConfigurationPath = Resolve-NewPath ".\package.json"

Copy-Item -Path $profilePath -Destination $packageConfigurationPath

$scripts = $profileConfiguration.contributes.scripts | ForEach-Object { Join-Path $scriptsDirectory $_.path | Resolve-Path }

# Create ZIP archive
$outputPath = Resolve-NewPath ".\${outputFilename}.zip"
$compress = @{
    Path            = $scripts, $packageConfigurationPath
    DestinationPath = $outputPath
}
Compress-Archive @compress -Force

# Rename ZIP to ASEPRITE-EXTENSION
$extensionPath = Resolve-NewPath ".\${outputFilename}.aseprite-extension"
Move-Item $outputPath $extensionPath -Force

# Remove package.json created before
Remove-Item $packageConfigurationPath