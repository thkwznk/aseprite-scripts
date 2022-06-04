if (Test-Path -Path ".\result.aseprite-extension") {
    Remove-Item -Path ".\result.aseprite-extension"
}

Compress-Archive -Path ".\*" -DestinationPath ".\result.zip" -Update

Rename-Item -Path ".\result.zip" -NewName ".\result.aseprite-extension"
.\result.aseprite-extension