local ModeProcessorProvider = dofile("./ModeProcessorProvider.lua")
local GetBoundsForPixels = dofile("./GetBoundsForPixels.lua")
local Mode = dofile("./Mode.lua")
local Tool = dofile("./Tool.lua")
local ColorContext = dofile("./ColorContext.lua")

-- Colors
local MagicPink = Color {red = 255, green = 0, blue = 255, alpha = 128}
local MagicTeal = Color {red = 0, green = 128, blue = 128, alpha = 128}

local ColorModels = {HSV = "HSV", HSL = "HSL", RGB = "RGB"}

local function RectangleContains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width - 1 and --
    y >= rect.y and y <= rect.y + rect.height - 1
end

local function GetButtonsPressed(pixels, previous, next)
    if #pixels == 0 then return end

    local leftPressed, rightPressed = false, false
    local old, new = nil, nil
    local pixel = pixels[1]

    local getPixel = next.image.getPixel

    if not RectangleContains(previous.bounds, pixel.x, pixel.y) then
        local newPixelValue = getPixel(next.image, pixel.x - next.position.x,
                                       pixel.y - next.position.y)
        local newPixelColor = ColorContext:Create(newPixelValue)

        if ColorContext:Compare(app.fgColor, newPixelColor) then
            leftPressed = true
        elseif ColorContext:Compare(app.bgColor, newPixelColor) then
            rightPressed = true
        end

        return leftPressed, rightPressed
    end

    old = ColorContext:Create(getPixel(previous.image,
                                       pixel.x - previous.position.x,
                                       pixel.y - previous.position.y))
    new = ColorContext:Create(getPixel(next.image, pixel.x - next.position.x,
                                       pixel.y - next.position.y))

    if old == nil or new == nil then return leftPressed, rightPressed end

    if ColorContext:IsTransparent(app.fgColor) and
        not ColorContext:IsTransparent(new) then
        return false, true
    elseif ColorContext:IsTransparent(app.bgColor) and
        not ColorContext:IsTransparent(new) then
        return true, false
    end

    local fgColorDistance = ColorContext:Distance(new, app.fgColor) -
                                ColorContext:Distance(old, app.fgColor)
    local bgColorDistance = ColorContext:Distance(new, app.bgColor) -
                                ColorContext:Distance(old, app.bgColor)

    if fgColorDistance < bgColorDistance then
        leftPressed = true
    else
        rightPressed = true
    end

    return leftPressed, rightPressed
end

local function CalculateChange(previous, next, canExtend)
    -- If size changed then it's a clear indicator of a change
    -- Pencil can only add which means the new image can only be bigger (not true, you COULD paint with color 0...)

    local pixels = {}
    local prevPixelValue = nil

    local getPixel = previous.image.getPixel

    -- It's faster without registering any local variables inside the loops
    if canExtend then -- Can extend, iterate over the new image
        local shift = {
            x = next.position.x - previous.position.x,
            y = next.position.y - previous.position.y
        }
        local shiftedX, shiftedY, nextPixelValue

        for x = 0, next.image.width - 1 do
            for y = 0, next.image.height - 1 do
                -- Save X and Y as canvas global
                shiftedX = x + shift.x
                shiftedY = y + shift.y

                prevPixelValue = getPixel(previous.image, shiftedX, shiftedY)
                nextPixelValue = getPixel(next.image, x, y)

                -- Out of bounds of the previous image or transparent
                if (shiftedX < 0 or shiftedX > previous.image.width - 1 or
                    shiftedY < 0 or shiftedY > previous.image.height - 1) then
                    if not ColorContext:IsTransparent(
                        ColorContext:Create(nextPixelValue)) then
                        table.insert(pixels, {
                            x = x + next.position.x,
                            y = y + next.position.y,
                            color = nil,
                            newColor = ColorContext:Create(nextPixelValue)
                        })
                    end
                elseif prevPixelValue ~= nextPixelValue then
                    table.insert(pixels, {
                        x = x + next.position.x,
                        y = y + next.position.y,
                        color = ColorContext:Create(prevPixelValue),
                        newColor = ColorContext:Create(nextPixelValue)
                    })
                end
            end
        end
    else -- Cannot extend, iterate over the previous image
        local shift = {
            x = previous.position.x - next.position.x,
            y = previous.position.y - next.position.y
        }

        for x = 0, previous.image.width - 1 do
            for y = 0, previous.image.height - 1 do
                prevPixelValue = getPixel(previous.image, x, y)

                -- Next image in some rare cases can be smaller
                if RectangleContains(next.bounds, x + previous.position.x,
                                     y + previous.position.y) then
                    -- Saving the new pixel's colors would be necessary for working with brushes, I think
                    local nextPixelValue =
                        getPixel(next.image, x + shift.x, y + shift.y)

                    if prevPixelValue ~= nextPixelValue then
                        -- Save X and Y as canvas global
                        table.insert(pixels, {
                            x = x + previous.position.x,
                            y = y + previous.position.y,
                            color = ColorContext:Create(prevPixelValue),
                            newColor = ColorContext:Create(nextPixelValue)
                        })
                    end
                end
            end
        end
    end

    local bounds = GetBoundsForPixels(pixels)
    local leftPressed, rightPressed = GetButtonsPressed(pixels, previous, next)

    return {
        pixels = pixels,
        bounds = bounds,
        leftPressed = leftPressed,
        rightPressed = rightPressed,
        sizeChanged = previous.bounds.width ~= next.bounds.width or
            previous.bounds.height ~= next.bounds.height
    }
end

local function MagicPencilDialog(options)
    local dialog
    local isRefresh = false
    local colorModel = ColorModels.HSV
    local selectedMode = Mode.Regular
    local sprite = app.activeSprite

    local lastKnownNumberOfCels, lastActiveCel, lastActiveLayer,
          lastActiveFrame, newCelFromEmpty, lastCelData

    local function RefreshDialog()
        -- Update dialog based only sprite's color mode
        local isRGB = sprite and sprite.colorMode == ColorMode.RGB
        local isIndexed = sprite and sprite.colorMode == ColorMode.INDEXED

        dialog --
        :modify{id = "transformSeparator", visible = isRGB} --
        :modify{id = Mode.Cut, visible = isRGB} --
        :modify{id = Mode.Merge, visible = isRGB} --
        :modify{id = Mode.Selection, visible = isRGB} --
        :modify{id = "mixSeparator", visible = isRGB} --
        :modify{id = Mode.Desaturate, visible = isRGB} --
        :modify{id = "MixMode", visible = isRGB} --
        :modify{id = "MixProportionalMode", visible = isRGB} --
        :modify{id = "changeSeparator", visible = isRGB or isIndexed} --
        :modify{id = Mode.Shift, visible = isRGB} --
        :modify{id = Mode.Colorize, visible = isRGB or isIndexed} --
        :modify{id = "indexedModeSeparator", visible = isRGB} --
        :modify{id = "indexedMode", visible = isRGB, enabled = isRGB}
    end

    local function UpdateLast()
        if sprite then lastKnownNumberOfCels = #sprite.cels end

        newCelFromEmpty = (lastActiveCel == nil) and
                              (lastActiveLayer == app.activeLayer) and
                              (lastActiveFrame == app.activeFrame)

        lastActiveLayer = app.activeLayer
        lastActiveFrame = app.activeFrame
        lastActiveCel = app.activeCel
        lastCelData = nil

        -- When creating a new layer or cel this can be triggered
        if lastActiveCel then
            lastCelData = {
                image = lastActiveCel.image:clone(),
                position = lastActiveCel.position,
                bounds = lastActiveCel.bounds,
                sprite = sprite
            }
        end
    end

    UpdateLast()

    local skip = false

    local onBeforeCommand = function(ev) skip = true end

    local onAfterCommand = function(ev)
        skip = false
        UpdateLast()

        if ev.name == "ChangePixelFormat" then RefreshDialog() end
    end

    local onSpriteChange = function(ev)
        -- Skip change, usually when a command is being run
        if skip then return end

        -- If there is no active cel, do nothing
        if app.activeCel == nil then return end

        if not Tool:IsSupported(app.tool.id) or -- Only react to supported tools
        selectedMode == Mode.Regular or -- If it's the regular mode then ignore
        sprite.colorMode == ColorMode.TILEMAP or -- Tilemap Mode is not supported
        app.activeLayer.isTilemap or -- If a layer is a tilemap
        lastKnownNumberOfCels ~= #sprite.cels or -- If last layer/frame/cel was removed then ignore
        lastActiveCel ~= app.activeCel or -- If it's just a layer/frame/cel change then ignore
        lastActiveCel == nil or -- If a cel was created where previously was none or cel was copied
        (app.apiVersion >= 21 and ev.fromUndo) -- From API v21, ignore all changes from undo/redo
        then
            UpdateLast()
            return
        end

        local modeProcessor = ModeProcessorProvider:Get(selectedMode)
        local celData = newCelFromEmpty and {
            image = Image(0, 0),
            position = Point(0, 0),
            bounds = Rectangle(0, 0, 0, 0),
            sprite = app.activeSprite
        } or lastCelData

        local change = CalculateChange(celData, app.activeCel,
                                       modeProcessor.canExtend)

        -- Mode Processor can cause the data about the last cel update, we calcualate it here to mitigate issues  
        local deleteCel = newCelFromEmpty and modeProcessor.deleteOnEmptyCel

        -- If no pixel was changed, but the size changed then revert to original
        if #change.pixels == 0 then
            if change.sizeChanged and modeProcessor.canExtend and lastCelData then
                -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
                -- sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                --               lastCel.image, lastCel.position)
                app.activeCel.image = lastCelData.image
                app.activeCel.position = lastCelData.position
            end
            -- Otherwise, do nothing
        elseif not change.leftPressed and not change.rightPressed then
            -- Not a user change - most probably an undo action, do nothing
        else
            modeProcessor:Process(change, sprite, celData, dialog.data)
        end

        if deleteCel then app.activeSprite:deleteCel(app.activeCel) end

        app.refresh()
        UpdateLast()

        -- v This just crashes Aseprite
        -- app.undo()
    end

    local onBeforeCommandListener = app.events:on('beforecommand',
                                                  onBeforeCommand)
    local onAfterCommandListener = app.events:on('aftercommand', onAfterCommand)
    local onChangeListener = sprite.events:on('change', onSpriteChange)
    local onSiteChange = app.events:on('sitechange', function()
        -- If sprite stayed the same then do nothing
        if app.activeSprite == sprite then
            UpdateLast()
            return
        end

        -- Unsubscribe from changes on the previous sprite
        if sprite then
            sprite.events:off(onChangeListener)
            sprite = nil
        end

        -- Subscribe to change on the new sprite
        if app.activeSprite then
            sprite = app.activeSprite
            onChangeListener = sprite.events:on('change', onSpriteChange)

            UpdateLast()
        end

        -- Update dialog based on new sprite's color mode
        RefreshDialog()
    end)

    local lastFgColor = ColorContext:Copy(app.fgColor)
    local lastBgColor = ColorContext:Copy(app.bgColor)

    local function SelectMode(mode, skipColor)
        selectedMode = mode

        local useMaskColor =
            ModeProcessorProvider:Get(selectedMode).useMaskColor

        if not skipColor then
            if useMaskColor then
                app.fgColor = MagicPink
                app.bgColor = MagicTeal
            else
                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
            end
        end

        dialog --
        :modify{id = "outlineColor", visible = selectedMode == Mode.OutlineLive} --
        :modify{id = "outlineSize", visible = selectedMode == Mode.OutlineLive} --
        :modify{id = "graffitiPower", visible = selectedMode == Mode.Graffiti} --
        :modify{
            id = "graffitiSpeckEnabled",
            visible = selectedMode == Mode.Graffiti
        } --
        :modify{
            id = "graffitiSpeckPower",
            visible = selectedMode == Mode.Graffiti and
                dialog.data.graffitiSpeckEnabled
        } --
        :modify{id = "colorModel", visible = selectedMode == Mode.Shift} --
        :modify{id = "shiftFirstOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftFirstPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftFirstOption
        } --
        :modify{id = "shiftSecondOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftSecondPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftSecondOption
        } --
        :modify{id = "shiftThirdOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftThirdPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftThirdOption
        } --
    end

    local resetColors = false
    local resetColorsTimer = Timer {
        interval = 1 / 6, -- fps
        ontick = function()
            -- This is the only reliable way
            -- There's no option to change colors within a color change event without causing issue 
            if resetColors then
                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
                resetColors = false
            end
        end
    }

    local onFgColorChange = function()
        local modeProcessor = ModeProcessorProvider:Get(selectedMode)
        local isMagicColor = app.fgColor.rgbaPixel == MagicPink.rgbaPixel

        if not isMagicColor then
            if modeProcessor.useMaskColor then
                dialog:modify{id = "RegularMode", selected = true}
                SelectMode("RegularMode", true) -- Skip setting colors here to avoid issue with changing colors from within an event

                resetColors = true
            end

            lastFgColor = ColorContext:Copy(app.fgColor)
        end
    end

    local onBgColorChange = function()
        local modeProcessor = ModeProcessorProvider:Get(selectedMode)
        local isMagicColor = app.bgColor.rgbaPixel == MagicTeal.rgbaPixel

        if not isMagicColor then
            if modeProcessor.useMaskColor then
                dialog:modify{id = "RegularMode", selected = true}
                SelectMode("RegularMode", true) -- Skip setting colors here to avoid issue with changing colors from within an event

                resetColors = true
            end

            lastBgColor = ColorContext:Copy(app.bgColor)
        end
    end

    local onFgColorListener = app.events:on('fgcolorchange', onFgColorChange)
    local onBgColorListener = app.events:on('bgcolorchange', onBgColorChange)

    dialog = Dialog {
        title = "Magic Pencil",
        onclose = function()
            if isRefresh then
                isRefresh = false
                return
            end

            if sprite then sprite.events:off(onChangeListener) end

            app.events:off(onSiteChange)
            app.events:off(onFgColorListener)
            app.events:off(onBgColorListener)

            app.fgColor = lastFgColor
            app.bgColor = lastBgColor

            app.events:off(onBeforeCommandListener)
            app.events:off(onAfterCommandListener)

            resetColorsTimer:stop()

            options.onclose()
        end
    }

    local function AddMode(mode, text, visible, selected)
        dialog:radio{
            id = mode,
            text = text,
            selected = selected,
            visible = visible,
            onclick = function() SelectMode(mode) end
        }:newrow() --
    end

    AddMode(Mode.Regular, "Disable", true, true)

    dialog:separator{text = "Effect"}

    AddMode(Mode.Graffiti, "Graffiti", true)
    dialog --
    :slider{
        id = "graffitiPower",
        visible = false,
        min = 0,
        max = 100,
        value = 50
    } --
    :check{
        id = "graffitiSpeckEnabled",
        visible = false,
        selected = true,
        text = "Speck",
        onclick = function()
            dialog:modify{
                id = "graffitiSpeckPower",
                visible = dialog.data.graffitiSpeckEnabled
            }
        end
    } --
    :slider{
        id = "graffitiSpeckPower",
        visible = false,
        min = 0,
        max = 100,
        value = 50
    }
    AddMode(Mode.OutlineLive, "Outline")
    dialog --
    :color{
        id = "outlineColor",
        visible = false,
        color = Color {gray = 0, alpha = 255}
    } --
    :number{id = "outlineSize", visible = false, text = "1", decimals = 0}

    dialog:separator{id = "transformSeparator", text = "Transform"} --
    AddMode(Mode.Cut, "Lift")
    AddMode(Mode.Merge, "Merge")
    AddMode(Mode.Selection, "Selection")

    -- self.dialog:separator{text = "Forbidden"} --
    -- AddMode(Mode.Yeet, "Yeet", false)

    dialog:separator{id = "mixSeparator", text = "Mix"}
    AddMode(Mode.Mix, "Unique")
    AddMode(Mode.MixProportional, "Proportional")

    dialog:separator{id = "changeSeparator", text = "Change"} --
    AddMode(Mode.Outline, "Outline")
    AddMode(Mode.Colorize, "Colorize")
    AddMode(Mode.Desaturate, "Desaturate")
    AddMode(Mode.Shift, "Shift")

    local onShiftOptionClick = function()
        dialog --
        :modify{
            id = "shiftFirstPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftFirstOption
        } --
        :modify{
            id = "shiftSecondPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftSecondOption
        } --
        :modify{
            id = "shiftThirdPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftThirdOption
        } --
    end

    dialog --
    :combobox{
        id = "colorModel",
        options = ColorModels,
        option = colorModel,
        visible = false,
        onchange = function()
            colorModel = dialog.data.colorModel

            local firstOption = "Red"
            local secondOption = "Green"
            local thirdOption = "Blue"

            if colorModel == ColorModels.HSV then
                firstOption = "Hue"
                secondOption = "Saturation"
                thirdOption = "Value"
            elseif colorModel == ColorModels.HSL then
                firstOption = "Hue"
                secondOption = "Saturation"
                thirdOption = "Lightness"
            end

            dialog --
            :modify{id = "shiftFirstOption", text = firstOption} --
            :modify{id = "shiftSecondOption", text = secondOption} --
            :modify{id = "shiftThirdOption", text = thirdOption}
        end
    } --
    :check{
        id = "shiftFirstOption",
        text = "Hue",
        selected = true,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftFirstPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :check{
        id = "shiftSecondOption",
        text = "Saturation",
        selected = false,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftSecondPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :check{
        id = "shiftThirdOption",
        text = "Value",
        selected = false,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftThirdPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :separator{id = "indexedModeSeparator"} --
    :check{id = "indexedMode", text = "Indexed Mode"}

    -- Show the dialog just to update widget visibility correctly
    dialog:show{wait = false}
    isRefresh = true
    RefreshDialog()
    dialog:close()

    resetColorsTimer:start()

    return dialog
end

return MagicPencilDialog
