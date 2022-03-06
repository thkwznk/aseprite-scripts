Logger = dofile("../../shared/Logger.lua")
SourceType = dofile("../source-type/SourceType.lua")
LayerImageProvider = dofile("./LayerImageProvider.lua")
TagImageProvider = dofile("./TagImageProvider.lua")
SelectionImageProvider = dofile("./SelectionImageProvider.lua")

local ImageProviderFactory = {}

function ImageProviderFactory:CreateImageProvider(sourceSprite, targetSprite,
                                                  sourceType, sourceParams)
    Logger:Trace("\n===ImageProviderFactory===\n")
    Logger:Trace("Source sprite: " .. sourceSprite.filename)
    Logger:Trace("Source type: " .. sourceType)
    Logger:Trace("Target sprite: " .. targetSprite.filename)
    Logger:Trace("Target color mode: " .. targetSprite.colorMode)

    local imageProvider = nil

    if sourceType == SourceType.Selection then
        imageProvider = SelectionImageProvider:Create()
    end

    if sourceType == SourceType.Layer then
        imageProvider = LayerImageProvider:Create()
    end

    if sourceType == SourceType.Tag then
        imageProvider = TagImageProvider:Create()
    end

    imageProvider:Init(sourceSprite, targetSprite, sourceParams)

    return imageProvider
end

return ImageProviderFactory
