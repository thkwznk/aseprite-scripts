Compress-Archive -Path ".\package.json", ".\OnScreenControls.lua", ".\Commands.lua", ".\ControlsDialog.lua", ".\KeyboardDialog.lua" -DestinationPath ".\result.zip" -Update

if (Test-Path -Path ".\result.aseprite-extension") {
    Remove-Item -Path ".\result.aseprite-extension"
}

Rename-Item -Path ".\result.zip" -NewName ".\result.aseprite-extension"
.\result.aseprite-extension