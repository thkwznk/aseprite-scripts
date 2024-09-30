local DropShadow = dofile("./fx/DropShadow.lua")
local LCDScreen = dofile("./fx/LCDScreen.lua")
local Neon = dofile("./fx/Neon.lua")
local Parallax = dofile("./fx/Parallax.lua")
local ThreeShearRotation = dofile("./fx/ThreeShearRotation.lua")
local ImageProcessor = dofile("./ImageProcessor.lua")
local PreviewCanvas = dofile("./PreviewCanvas.lua")
local ColorOutlineDialog = dofile("./ColorOutlineDialog.lua")

local directions = {
    topLeft = {enabled = false, dx = 1, dy = 1},
    top = {enabled = true, dx = 0, dy = 1},
    topRight = {enabled = false, dx = -1, dy = 1},
    left = {enabled = true, dx = 1, dy = 0},
    center = {enabled = false, dx = 0, dy = 0},
    right = {enabled = true, dx = -1, dy = 0},
    bottomLeft = {enabled = false, dx = 1, dy = -1},
    bottom = {enabled = true, dx = 0, dy = -1},
    bottomRight = {enabled = false, dx = -1, dy = -1}
}

local InitialXOffset = 2
local InitialYOffset = 2

local FxSession = {}
local Sqrt2 = math.sqrt(2)

function FxSession:Get(sprite, key, defaultValue)
    if defaultValue ~= nil then
        if self[sprite.filename] then
            if self[sprite.filename][key] ~= nil then
                return self[sprite.filename][key]
            end
        else
            self[sprite.filename] = {}
        end

        self[sprite.filename][key] = defaultValue
        return defaultValue
    end

    if not self[sprite.filename] then return nil end

    return self[sprite.filename][key]
end

function FxSession:Set(sprite, key, value)
    if not self[sprite.filename] then self[sprite.filename] = {} end

    self[sprite.filename][key] = value
end

function GetActiveSpritePreview()
    local sprite = app.activeSprite
    local cels = {}

    -- Copy cels from the range to a table
    for _, cel in ipairs(app.range.cels) do table.insert(cels, cel) end

    table.sort(cels, function(a, b)
        return a.layer.stackIndex < b.layer.stackIndex
    end)

    local previewImage = Image(sprite.width, sprite.height, sprite.colorMode)
    local position = Point(sprite.width, sprite.height)

    for _, cel in ipairs(cels) do
        if cel.frame == app.activeFrame and cel.layer.isVisible then
            previewImage:drawImage(cel.image, cel.position)
            position.x = math.min(position.x, cel.position.x)
            position.y = math.min(position.y, cel.position.y)
        end
    end

    local bounds = previewImage:shrinkBounds()
    return Image(previewImage, bounds), position
end

function RotateCel(cel, angle)
    local image = cel.image

    if angle >= math.pi / 2 and angle <= math.pi * 1.5 then
        image:flip(FlipType.HORIZONTAL)
        image:flip(FlipType.VERTICAL)
    end

    local skewedImage = ThreeShearRotation(image, image, angle)
    local bounds = skewedImage:shrinkBounds()

    local dx = bounds.width - cel.image.width
    local dy = bounds.height - cel.image.height
    cel.position = Point(cel.position.x - dx / 2, cel.position.y - dy / 2)
    cel.image = Image(skewedImage, bounds)
end

-- TODO: Leaving this disabled for now due to poor UX
-- function RotationSelection(cel, angle)
--     local bounds = cel.sprite.selection.bounds
--     local existingImage = cel.image:clone()
--     local imagePart = Image(cel.image, bounds)
--     existingImage:clear(bounds)

--     if angle >= math.pi / 2 and angle <= math.pi * 1.5 then
--         imagePart:flip(FlipType.HORIZONTAL)
--         imagePart:flip(FlipType.VERTICAL)
--     end

--     local skewedImage = ThreeShearRotation(imagePart, imagePart, angle)

--     local dx = skewedImage.width - bounds.width
--     local dy = skewedImage.height - bounds.height
--     existingImage:drawImage(skewedImage,
--                             Point(bounds.x - dx / 2, bounds.y - dy / 2))
--     cel.image = existingImage

--     cel.sprite.selection:deselect()
-- end

function ParallaxOnClick()
    local sprite = app.activeSprite
    local dialog = Dialog {title = "Parallax"}

    local defaultSpeed = math.floor(math.sqrt(math.sqrt(sprite.width)))
    local defaultFrames = math.floor(sprite.width /
                                         math.max((defaultSpeed / 2), 1))

    local speedX = FxSession:Get(sprite, "speedX") or defaultSpeed
    local speedY = FxSession:Get(sprite, "speedY") or 0

    dialog:separator{text = "Distance"}

    function AddLayerWidgets(layersToProcess, groupIndex)
        for i = #layersToProcess, 1, -1 do
            local layer = layersToProcess[i]

            if not layer.isVisible then goto skipLayerWidget end

            if layer.isGroup then
                AddLayerWidgets(layer.layers, #layersToProcess - i)
            else
                local speed = defaultSpeed ^ (#layersToProcess - i)
                if groupIndex then
                    speed = defaultSpeed ^ groupIndex
                end

                if layer.isBackground then speed = 0 end

                -- Save the initial position of the layers
                local cel = layer.cels[1]

                -- If there's saved speed, use it
                if layer.data and #layer.data > 0 then
                    speed = tonumber(layer.data) or speed
                end

                local id = Parallax:_GetLayerId(layer)
                local label = Parallax:GetFullLayerName(layer)

                if cel then
                    dialog --
                    :number{
                        id = "distance-" .. id,
                        label = label,
                        decimals = 2,
                        text = tostring(speed),
                        enabled = not layer.isBackground,
                        visible = not layer.isBackground
                    }
                end
            end

            ::skipLayerWidget::
        end
    end

    AddLayerWidgets(sprite.layers)
    Parallax:InitPreview(sprite, app.activeFrame.frameNumber, dialog.data)

    dialog --
    :separator{text = "Movement"} --
    -- FUTURE: Enable different movement functions
    -- :combobox{
    --     id = "movementFunction",
    --     label = "Type",
    --     option = Parallax:GetDefaultMovementFunction(),
    --     options = Parallax:GetMovementFunctions()
    -- } --
    :number{
        id = "speedX",
        label = "Speed [X/Y]",
        text = tostring(speedX),
        onchange = function()
            FxSession:Set(sprite, "speedX", dialog.data.speedX)

            dialog:modify{
                id = "okButton",
                enabled = dialog.data.speedX ~= 0 or dialog.data.speedY ~= 0
            }
        end
    } --
    :number{
        id = "speedY",
        text = tostring(speedY),
        onchange = function()
            FxSession:Set(sprite, "speedY", dialog.data.speedY)

            dialog:modify{
                id = "okButton",
                enabled = dialog.data.speedX ~= 0 or dialog.data.speedY ~= 0
            }
        end
    } --
    :separator{text = "Preview"} --
    :slider{
        id = "shift",
        label = "Shift",
        min = 0,
        max = sprite.width,
        value = 0,
        onchange = function()
            Parallax:Preview(dialog.data)
            app.refresh()
        end
    } --
    :separator{text = "Output"} --
    :number{id = "frames", label = "Frames", text = tostring(defaultFrames)} --
    :separator() --
    :button{
        id = "okButton",
        text = "&OK",
        enabled = speedX ~= 0 or speedY ~= 0,
        onclick = function()
            Parallax:ClosePreview()
            dialog:close()

            -- Save the values in the layer data
            Parallax:_IterateOverLayers(sprite.layers, function(layer)
                local id = Parallax:_GetLayerId(layer)
                layer.data = dialog.data["distance-" .. id] or 0
            end)

            Parallax:Generate(sprite, dialog.data)
        end
    } --
    :button{
        text = "&Cancel",
        onclick = function()
            Parallax:ClosePreview()
            dialog:close()

            -- Set active sprite back to the originally open file
            app.activeSprite = sprite
        end
    }

    dialog:show()
end

function init(plugin)
    plugin:newCommand{
        id = "DropShadowFX",
        title = "Drop Shadow",
        group = "edit_fx",
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.cels > 0
        end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = Dialog("Drop shadow")
            dialog --
            :number{
                id = "xOffset",
                label = "X Offset",
                text = tostring(FxSession:Get(sprite, "dropShadowOffsetX") or
                                    InitialXOffset),
                onchange = function()
                    FxSession:Set(sprite, "dropShadowOffsetX",
                                  dialog.data.xOffset)
                end
            } --
            :number{
                id = "yOffset",
                label = "Y Offset",
                text = tostring(FxSession:Get(sprite, "dropShadowOffsetY") or
                                    InitialYOffset),
                onchange = function()
                    FxSession:Set(sprite, "dropShadowOffsetY",
                                  dialog.data.yOffset)
                end
            } --
            :color{
                id = "color",
                color = FxSession:Get(sprite, "dropShadowColor") or app.bgColor,
                onchange = function()
                    FxSession:Set(sprite, "dropShadowColor", dialog.data.color)
                end
            } --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    app.transaction(function()
                        DropShadow:Generate(dialog.data)
                    end)
                    dialog:close()
                end
            } --
            :button{text = "Cancel"}
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "LCDScreen",
        title = "LCD Screen",
        group = "edit_fx",
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.cels > 0
        end,
        onclick = function()
            local sprite = app.activeSprite
            local cel = app.activeCel
            local image = cel.image
            local selection = app.activeSprite.selection

            -- Get only image from selection
            if not selection.isEmpty then
                local rectangle = Rectangle(selection.bounds.x - cel.position.x,
                                            selection.bounds.y - cel.position.y,
                                            selection.bounds.width,
                                            selection.bounds.height)
                image = ImageProcessor:GetImagePart(image, rectangle)
            end

            local autoPixelWidth, autoPixelHeight =
                FxSession:Get(sprite, "lcdPixelWidth"),
                FxSession:Get(sprite, "lcdPixelHeight")

            if not autoPixelWidth or not autoPixelHeight then
                autoPixelWidth, autoPixelHeight =
                    ImageProcessor:CalculateScale(image)
            end

            local dialog = Dialog("LCD Screen")
            dialog --
            :separator{text = "LCD Pixel Size"} --
            :number{
                id = "pixel-width",
                label = "Width",
                text = tostring(autoPixelWidth),
                onchange = function()
                    FxSession:Set(sprite, "lcdPixelWidth",
                                  dialog.data["pixel-width"])
                    FxSession:Set(sprite, "lcdPixelHeight",
                                  dialog.data["pixel-height"])
                end
            } --
            :number{
                id = "pixel-height",
                label = "Height",
                text = tostring(autoPixelHeight),
                onchange = function()
                    FxSession:Set(sprite, "lcdPixelWidth",
                                  dialog.data["pixel-width"])
                    FxSession:Set(sprite, "lcdPixelHeight",
                                  dialog.data["pixel-height"])
                end
            } --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    local cels = app.range.cels
                    local pixelWidth = dialog.data["pixel-width"]
                    local pixelHeight = dialog.data["pixel-height"]

                    app.transaction(function()
                        LCDScreen:Generate(sprite, cels, pixelWidth, pixelHeight)
                    end)

                    dialog:close()
                end
            } --
            :button{text = "Cancel"} --
            :show()
        end
    }

    plugin:newCommand{
        id = "Neon",
        title = "Neon",
        group = "edit_fx",
        onenabled = function()
            -- Neon FX works only for a single cel at the moment
            return app.activeSprite ~= nil and #app.range.cels == 1
        end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = Dialog("Neon")
            dialog --
            :combobox{
                id = "strength",
                label = "Strength",
                option = FxSession:Get(sprite, "neonStrength") or "3",
                options = {"1", "2", "3", "4", "5"},
                onchange = function()
                    FxSession:Set(sprite, "neonStrength", dialog.data.strength)
                end
            }:separator() --
            :button{
                text = "OK",
                onclick = function()
                    app.transaction(function()
                        Neon:Generate(dialog.data)
                    end)
                    dialog:close()
                end
            } --
            :button{text = "Cancel"} --
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "Parallax",
        title = "Parallax",
        group = "edit_fx",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = ParallaxOnClick
    }

    plugin:newCommand{
        id = "ThreeShearRotation",
        title = "Three Shear Rotation",
        group = "edit_fx",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local previewImage, position = GetActiveSpritePreview()

            -- Precalculate a flipped image
            local previewImageFlipped = previewImage:clone()
            previewImageFlipped:flip(FlipType.HORIZONTAL)
            previewImageFlipped:flip(FlipType.VERTICAL)

            local dialog = Dialog {title = "Three Shear Rotation"}
            local canvasSize = math.max(previewImage.width * Sqrt2,
                                        previewImage.height * Sqrt2)
            local RedrawPreview = PreviewCanvas(dialog, canvasSize, canvasSize,
                                                sprite, previewImage, position)

            dialog --
            :separator() --
            :slider{
                id = "angle",
                label = "Angle:",
                min = 0,
                max = 360,
                value = 0,
                onchange = function()
                    local angle = math.rad(dialog.data.angle)
                    local skewedImage = ThreeShearRotation(previewImage,
                                                           previewImageFlipped,
                                                           angle)

                    local bounds = skewedImage:shrinkBounds()
                    skewedImage = Image(skewedImage, bounds)

                    local newPosition = Point(position.x -
                                                  (bounds.width -
                                                      previewImage.width) / 2,
                                              position.y -
                                                  (bounds.height -
                                                      previewImage.height) / 2)
                    RedrawPreview(skewedImage, newPosition)
                end
            } --
            :button{
                text = "&OK",
                onclick = function()
                    app.transaction(function()
                        local cels = app.range.cels

                        for _, cel in ipairs(cels) do
                            if cel.image ~= nil and cel.layer.isEditable then
                                local angle = math.rad(dialog.data.angle)
                                RotateCel(cel, angle)
                            end
                        end

                        local selection = app.activeSprite.selection

                        if not selection.isEmpty then
                            selection:deselect()
                        end
                    end)

                    dialog:close()
                    app.refresh()
                end
            } --
            :button{text = "&Cancel"}

            dialog:show()
        end
    }

    plugin:newCommand{
        id = "ColorOutline",
        title = "Color Outline",
        group = "edit_fx",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite or app.sprite
            local previewImage, position = GetActiveSpritePreview()

            local dialog
            dialog = ColorOutlineDialog {
                opacity = FxSession:Get(sprite, "outline_opacity", 50),
                ignoreOutlineColor = FxSession:Get(sprite,
                                                   "outline_ignore_outline_color",
                                                   true),
                directions = directions, -- TODO: Use the session
                previewImage = previewImage,
                previewPosition = position,
                onclose = function()
                    FxSession:Set(sprite, "outline_opacity", dialog.data.opacity)
                    FxSession:Set(sprite, "outline_ignore_outline_color",
                                  dialog.data.ignoreOutlineColor)
                    FxSession:Set(sprite, "outline_dialog_bounds", dialog.bounds)
                end
            }
            dialog:modify{id = "color", color = app.fgColor}

            local bounds = FxSession:Get(sprite, "outline_dialog_bounds")

            -- Check if bounds are valid, just in case
            if app.apiVersion >= 25 and bounds ~= nil then
                if (bounds.x + bounds.width) < 30 or
                    (app.window.width - bounds.x) < 30 or bounds.y < 0 or
                    (app.window.height - bounds.y) < 30 then
                    bounds = nil
                    FxSession:Set(sprite, "outline_dialog_bounds", nil)
                end
            end

            dialog:show{bounds = bounds}
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end

-- TODO: Display all visible layers on the preview canvas
