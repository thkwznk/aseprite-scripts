Drawer = dofile("../shared/Drawer.lua")
Logger = dofile("../shared/Logger.lua")

local GuideLayer = {}

function GuideLayer:Create(o)
    o = o or {
        sprite = nil,
        layer = nil,
        backgroundImage = nil,
        backgroundColor = Color {r = 0, g = 0, b = 0, a = 255},
        guideColor = Color {r = 255, g = 255, b = 255, a = 255}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function GuideLayer:Init(sprite)
    app.transaction(function()
        self.sprite = sprite
        self.layer = self:_CreateLayer(self.sprite)

        -- Create a background image and put it into the first cel, otherwise the link won't be created
        self.backgroundImage = self:_CreateBackgroundImage(self.sprite)
        self.sprite:newCel(self.layer, 1, self.backgroundImage, Point(0, 0))
        self:_LinkLayerCels()
    end)
end

function GuideLayer:_CreateLayer(sprite)
    local layer = sprite:newLayer()
    layer.name = "Importing Animation..."
    layer.color = self.backgroundColor
    layer.opacity = 128

    return layer
end

function GuideLayer:_CreateBackgroundImage(sprite)
    local image = Image(sprite.width, sprite.height, sprite.colorMode)

    for x = 0, sprite.width - 1 do
        for y = 0, sprite.height - 1 do
            image:drawPixel(x, y, self.backgroundColor)
        end
    end

    return image
end

function GuideLayer:_LinkLayerCels()
    app.range.layers = {self.layer}
    local frames = {}
    for frameNumber, _ in ipairs(self.sprite.frames) do
        table.insert(frames, frameNumber)
    end
    app.range.frames = frames
    app.command.LinkCels()
    app.range:clear()
end

function GuideLayer:_RevertLastUpdate()
    -- Save active frame
    local savedActiveFrame = app.activeFrame

    if self.updated then app.undo() end
    self.updated = true

    -- Restore active frame
    app.activeFrame = savedActiveFrame
end

function GuideLayer:Update(imageProvider, positionCalculator)
    self:_RevertLastUpdate()

    local timer = Logger:StartTimer("Updating Guide Layer")

    if self.layer == nil then return end

    local drawImageTimer = Logger:StartTimer("Drawing new background image")

    local newImage = self.backgroundImage:clone()

    local firstX = nil
    local firstY = nil
    local lastX = 0
    local lastY = 0

    -- Draw a guide to show how the sprite will move
    for x, y in positionCalculator:GetPositions() do
        firstX = firstX or x
        firstY = firstY or y
        lastX = x
        lastY = y

        newImage:drawPixel(x, y, self.guideColor)
    end

    -- Draw source sprite preview
    if firstX ~= nil and firstY ~= nil then
        local previewImage = imageProvider:GetPreviewImage()

        if previewImage ~= nil then
            local previewX = firstX - (previewImage.width / 2)
            local previewY = firstY - (previewImage.height / 2)

            newImage:drawImage(previewImage, Point(previewX, previewY))

            Drawer:DrawRectangle(newImage, previewX - 2, previewY - 2,
                                 previewImage.width + 4,
                                 previewImage.height + 4, self.guideColor)
        end
    end

    -- Draw the sprite center crosshair
    if firstX ~= nil and firstY ~= nil then
        Drawer:DrawCrosshair(newImage, firstX, firstY, self.guideColor,
                             self.backgroundColor)
    end

    -- Draw the "end on" line
    local endOn = positionCalculator:GetEndOnValue()
    if endOn ~= nil then
        Drawer:DrawDashLine(newImage, positionCalculator.endOn.Axis, endOn,
                            self.guideColor)
    end

    -- Draw the last position crosshair
    Drawer:DrawCrosshair(newImage, lastX, lastY, self.guideColor,
                         self.backgroundColor)

    Logger:EndTimer(drawImageTimer)

    app.transaction(function() self.layer.cels[1].image = newImage end)

    Logger:EndTimer(timer)

    app.refresh()
end

return GuideLayer
