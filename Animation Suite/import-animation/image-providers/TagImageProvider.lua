ImageConverter = dofile("../../shared/ImageConverter.lua")
ImageProvider = dofile("./ImageProvider.lua")
Logger = dofile("../../shared/Logger.lua")
SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local TagImageProvider = ImageProvider:Create()

function TagImageProvider:GetPreviewImage()
    Logger:Trace("\n=== Getting Preview Image... ===\n")
    Logger:Trace("Sprite = " .. self.sprite.filename)
    Logger:Trace("Tag = " .. (self.sourceParams.Tag or "Unknown"))

    if self.cachedPreviewImage ~= nil then return self.cachedPreviewImage end

    local tag = SpriteHelper:GetTagByName(self.sprite, self.sourceParams.Tag)
    if tag == nil then return nil end

    self.cachedPreviewImage = self:_GetImage(tag.fromFrame.frameNumber)

    return self.cachedPreviewImage
end

function TagImageProvider:_GetImages()
    local images = {}

    local tag = SpriteHelper:GetTagByName(self.sprite, self.sourceParams.Tag)
    if tag == nil then return images end

    for frameNumber = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
        local image = self:_GetImage(frameNumber)
        table.insert(images, image)
    end

    return images
end

function TagImageProvider:_GetImage(frameNumber)
    local image = Image(self.sprite.width, self.sprite.height,
                        self.sprite.colorMode)
    image:drawSprite(self.sprite, frameNumber)
    image = ImageConverter:Convert(image, self.sprite.palettes[1],
                                   self.targetSprite.palettes[1],
                                   self.targetSprite.colorMode)

    local fh = self.sourceParams.FlipHorizontal
    local fv = self.sourceParams.FlipVertical
    if fh or fv then image = ImageConverter:Flip(image, fh, fv) end

    return image
end

return TagImageProvider
