Compress-Archive -Path ".\SpriteAnalyzerExtension.lua", ".\SpriteAnalyzer.lua", ".\SpriteAnalyzerDialog.lua", ".\PreviewSpriteDrawer.lua", ".\PresetProvider.lua", ".\PreviewDirection.lua", ".\PaletteExtractionDialog.lua", ".\PaletteExtractor.lua", ".\DeepCopy.lua", ".\package.json" -DestinationPath ".\result.zip" -Update

if (Test-Path -Path ".\result.aseprite-extension") {
    Remove-Item -Path ".\result.aseprite-extension"
}

Rename-Item -Path ".\result.zip" -NewName ".\result.aseprite-extension"
.\result.aseprite-extension