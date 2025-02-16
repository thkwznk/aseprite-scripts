local DropShadow = dofile("./fx/DropShadow.lua")
local LCDScreen = dofile("./fx/LCDScreen.lua")
local Neon = dofile("./fx/Neon.lua")
local ParallaxDialog = dofile("./ParallaxDialog.lua")
local ThreeShearRotation = dofile("./fx/ThreeShearRotation.lua")
local ImageProcessor = dofile("./ImageProcessor.lua")
local PreviewCanvas = dofile("./PreviewCanvas.lua")
local ColorOutlineDialog = dofile("./ColorOutlineDialog.lua")
local FxSession = dofile("./FxSession.lua")

local function Directions()
    return {
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
end

local InitialXOffset = 2
local InitialYOffset = 2

local Sqrt2 = math.sqrt(2)

local function GetActiveSpritePreview()
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

local function RotateCel(cel, angle)
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
        onclick = function()
            local dialog = ParallaxDialog {
                title = "Parallax",
                sprite = app.activeSprite,
                session = FxSession
            }

            dialog:show()
        end
    }

    plugin:newCommand{
        id = "ThreeShearRotation",
        title = "Three Shear Rotation",
        group = "edit_fx",
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.cels > 0
        end,
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
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.cels > 0
        end,
        onclick = function()
            local sprite = app.activeSprite or app.sprite
            local previewImage, position = GetActiveSpritePreview()

            local dialog
            dialog = ColorOutlineDialog {
                opacity = FxSession:Get(sprite, "outline_opacity", 50),
                ignoreOutlineColor = FxSession:Get(sprite,
                                                   "outline_ignore_outline_color",
                                                   true),
                directions = FxSession:Get(sprite, "outline_directions",
                                           Directions()),
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
