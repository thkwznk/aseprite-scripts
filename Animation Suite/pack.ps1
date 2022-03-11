Compress-Archive -Path ".\package.json", ".\AnimationSuite.lua", ".\import-animation", ".\loop", ".\shared" -DestinationPath ".\Animation Suite.zip" -Update

if (Test-Path -Path ".\Animation Suite.aseprite-extension") {
    Remove-Item -Path ".\Animation Suite.aseprite-extension"
}

Rename-Item -Path ".\Animation Suite.zip" -NewName ".\Animation Suite.aseprite-extension"
& '.\Animation Suite.aseprite-extension'