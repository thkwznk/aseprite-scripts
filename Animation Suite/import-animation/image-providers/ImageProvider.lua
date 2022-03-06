local ImageProvider = {}

function ImageProvider:Create(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ImageProvider:Init(sprite, targetSprite, sourceParams)
    self.sprite = sprite
    self.targetSprite = targetSprite
    self.sourceParams = sourceParams
end

function ImageProvider:GetPreviewImage() end

function ImageProvider:GetImagesIterator()
    local images = self:_GetImages()
    if #images == 0 then return function() return nil end end

    local index = -1

    return function()
        index = index + 1
        return images[(index % #images) + 1]
    end
end

return ImageProvider
