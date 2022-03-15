Compress-Archive -Path ".\package.json", ".\NxPAStudio.lua", ".\color-analyzer", ".\scale", ".\tween", ".\shared" -DestinationPath ".\NxPA Studio.zip" -Update

if (Test-Path -Path ".\NxPA Studio.aseprite-extension") {
    Remove-Item -Path ".\NxPA Studio.aseprite-extension"
}

Rename-Item -Path ".\NxPA Studio.zip" -NewName ".\NxPA Studio.aseprite-extension"
& '.\NxPA Studio.aseprite-extension'