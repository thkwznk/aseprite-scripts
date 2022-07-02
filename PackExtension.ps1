param ($Path)

$Package = Get-Content (Join-Path -Path $Path -ChildPath "package.json") | Out-String | ConvertFrom-Json
$PackageName = "$($Package.displayName) v$($Package.version)"

$ArchiveFiles = Get-ChildItem -Recurse -Name -Path $Path -Exclude "*.md", "*.zip", "*.ps1", "*.itch-toml", "*.aseprite-extension", "\readme-images\*", "*.gif" | ForEach-Object{".\$Path\$_"}

Compress-Archive -Path $ArchiveFiles -DestinationPath ".\Output\$PackageName.zip" -Update

if (Test-Path -Path ".\Output\$PackageName.aseprite-extension") {
    Remove-Item -Path ".\Output\$PackageName.aseprite-extension"
}

Rename-Item -Path ".\Output\$PackageName.zip" -NewName "$PackageName.aseprite-extension"

& ".\Output\$PackageName.aseprite-extension"