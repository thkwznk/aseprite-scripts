param ($profilesDirectory, $scriptsDirectory, $profileName)

Write-Host "Packaging ${profileName}..."

$profilePath = Join-Path $profilesDirectory "${profileName}.json" | Resolve-Path

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
$archivePath = Resolve-NewPath ".\${profileName}.zip"
$compress = @{
    Path            = $scripts, $packageConfigurationPath
    DestinationPath = $archivePath
}
Compress-Archive @compress -Force

# Rename ZIP to ASEPRITE-EXTENSION
$extensionPath = Resolve-NewPath ".\${profileName}.aseprite-extension"
Move-Item $archivePath $extensionPath -Force

# Remove package.json created before
Remove-Item $packageConfigurationPath

Write-Host "Package ${profileName} created"