local DropShadow = dofile("./fx/DropShadow.lua")
local LCDScreen = dofile("./fx/LCDScreen.lua")
local Neon = dofile("./fx/Neon.lua")
local ImageProcessor = dofile("./ImageProcessor.lua")

local InitialXOffset = 2
local InitialYOffset = 2

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
                ImageProcessor:CalculateScale(image)

            local dialog = Dialog("LCD Screen")
            dialog --
            :separator{text = "LCD Pixel Size"} --
            :number{
                id = "pixel-width",
                label = "Width",
                text = tostring(autoPixelWidth)
            } --
            :number{
                id = "pixel-height",
                label = "Height",
                text = tostring(autoPixelHeight)
            } --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    local sprite = app.activeSprite
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
            local dialog = Dialog("Neon")
            dialog --
            :combobox{
                id = "strength",
                label = "Strength",
                option = "3",
                options = {"1", "2", "3", "4", "5"}
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
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
