ActiveElementsCache = dofile("../../shared/ActiveElementsCache.lua")
ImageConverter = dofile("../../shared/ImageConverter.lua")
ImageProvider = dofile("./ImageProvider.lua")
Logger = dofile("../../shared/Logger.lua")
SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local SelectionImageProvider = ImageProvider:Create()

function SelectionImageProvider:GetPreviewImage()
    Logger:Trace("\n=== Getting Preview Image... ===\n")
    Logger:Trace("Sprite = " .. self.sprite.filename)
    Logger:Trace("Frame, Width = " .. self.sourceParams.Frame.width ..
                     ", Height = " .. self.sourceParams.Frame.height)

    if self.cachedPreviewImage == nil then
        self.cachedPreviewImage = self:_GetImage()
    end

    return self.cachedPreviewImage
end

function SelectionImageProvider:_GetSelectedImage()
    if self.cachedSelectedImage == nil then
        local cel = ActiveElementsCache:GetActiveCel(self.sprite)
        if cel == nil then return nil end

        local bounds = self.sprite.selection.bounds
        local origin = self.sprite.selection.origin

        -- Create a new Image to return
        local image = Image(bounds.width, bounds.height, self.sprite.colorMode)

        -- Draw the source, shifted so only the selected part is drawn
        image:drawImage(cel.image, Point(-origin.x + cel.position.x,
                                         -origin.y + cel.position.y))

        -- Convert image to target Color Mode
        image = ImageConverter:Convert(image, self.sprite.palettes[1],
                                       self.targetSprite.palettes[1],
                                       self.targetSprite.colorMode)

        self.cachedSelectedImage = image
    end

    return self.cachedSelectedImage
end

function SelectionImageProvider:_GetImages()
    local images = {}

    local numberOfFrames = self.sprite.selection.bounds.width /
                               self.sourceParams.Frame.width

    for i = 1, numberOfFrames do
        local image = self:_GetImage(i - 1)
        if image == nil then return images end
        table.insert(images, image)
    end

    return images
end

function SelectionImageProvider:_GetImage(index)
    local selectedImage = self:_GetSelectedImage()
    if selectedImage == nil then return nil end

    local positionDelta = (index or 0) * self.sourceParams.Frame.width

    local image = Image(self.sourceParams.Frame.width,
                        self.sourceParams.Frame.height,
                        self.targetSprite.colorMode)
    image:drawImage(selectedImage, Point(-positionDelta, 0))

    return image
end

return SelectionImageProvider
