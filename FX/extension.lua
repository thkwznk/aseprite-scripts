local DropShadow = dofile("./fx/DropShadow.lua")
local LCDScreen = dofile("./fx/LCDScreen.lua")
local Neon = dofile("./fx/Neon.lua")
local Parallax = dofile("./fx/Parallax.lua")
local ImageProcessor = dofile("./ImageProcessor.lua")

local InitialXOffset = 2
local InitialYOffset = 2

local FxSession = {}

function FxSession:Get(sprite, key)
    if not self[sprite.filename] then return nil end

    return self[sprite.filename][key]
end

function FxSession:Set(sprite, key, value)
    if not self[sprite.filename] then self[sprite.filename] = {} end

    self[sprite.filename][key] = value
end

function ParallaxOnClick()
    local sprite = app.activeSprite
    local dialog = Dialog {title = "Parallax"}

    local defaultSpeed = math.floor(math.sqrt(math.sqrt(sprite.width)))
    local defaultFrames = math.floor(sprite.width /
                                         math.max((defaultSpeed / 2), 1))

    local speedX = FxSession:Get(sprite, "speedX") or defaultSpeed
    local speedY = FxSession:Get(sprite, "speedY") or 0

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
            local dialog = Dialog("Drop shadow")
            dialog --
            :number{
                id = "xOffset",
                label = "X Offset",
                text = tostring(InitialXOffset)
            } --
            :number{
                id = "yOffset",
                label = "Y Offset",
                text = tostring(InitialYOffset)
            } --
            :color{id = "color", color = app.bgColor} --
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
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
