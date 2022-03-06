ImageConverter = dofile("../../shared/ImageConverter.lua")
ImageProvider = dofile("./ImageProvider.lua")
Logger = dofile("../../shared/Logger.lua")
SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local LayerImageProvider = ImageProvider:Create()

function LayerImageProvider:GetPreviewImage()
    Logger:Trace("\n=== Getting Preview Image... ===\n")
    Logger:Trace("Sprite = " .. self.sprite.filename)
    Logger:Trace("Layer = " .. self.sourceParams.Layer)

    if self.cachedPreviewImage ~= nil then return self.cachedPreviewImage end

    local layer = SpriteHelper:GetLayerByName(self.sprite,
                                              self.sourceParams.Layer)
    if layer == nil then return nil end

    local cel = self:_GetFirstCel(layer)
    if cel == nil then return nil end

    self.cachedPreviewImage = self:_GetImage(cel)

    return self.cachedPreviewImage
end

function LayerImageProvider:_GetFirstCel(layer)
    for _, cel in ipairs(layer.cels) do if cel ~= nil then return cel end end
end

function LayerImageProvider:_GetImages()
    local images = {}

    local layer = SpriteHelper:GetLayerByName(self.sprite,
                                              self.sourceParams.Layer)
    if layer == nil then return images end

    for _, cel in ipairs(layer.cels) do
        local image = self:_GetImage(cel)
        table.insert(images, image)
    end

    return images
end

function LayerImageProvider:_GetImage(cel)
    local convertedImage = ImageConverter:Convert(cel.image,
                                                  self.sprite.palettes[1],
                                                  self.targetSprite.palettes[1],
                                                  self.targetSprite.colorMode)

    local image = Image(self.sprite.width, self.sprite.height,
                        self.targetSprite.colorMode)
    image:drawImage(convertedImage, cel.position)

    return image
end

return LayerImageProvider
