param ($profile)

if ([string]::IsNullOrEmpty($profile)) {
    Write-Host Error
}

$profilePath = "../publish-profiles/${profile}.json"
$profileExists = Test-Path -Path $profilePath

if ($profileExists -eq $false) {
    Write-Host "Profile ${profile} does not exist" 
    return
}

$profileConfiguration = Get-Content $profilePath -Encoding UTF8 | ConvertFrom-Json

Write-Host ($profileConfiguration.contributes.scripts | ForEach-Object { Split-Path -Path $_.path -Leaf })

ConvertTo-Json $profileConfiguration | Out-File -FilePath "../output/package.json" -Encoding UTF8

$scripts = $profileConfiguration.contributes.scripts | ForEach-Object { Join-Path ((Get-Location).Path) (Split-Path -Path $_.path -Leaf) }

Write-Host $scripts

# $s = []

$compress = @{
    Path             = $scripts
    CompressionLevel = "Fastest"
    DestinationPath  = "./${profile}"
}
Compress-Archive @compress

# Write-Host $compress.Path

# Create ZIP
# Rename ZIP extension


