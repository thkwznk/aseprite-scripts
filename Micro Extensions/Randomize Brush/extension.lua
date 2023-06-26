local Option = {
    None = "Static",
    Grow = "Grow",
    Shrink = "Shrink",
    Rotate = "Rotate",
    Next = "Next",
    Previous = "Previous",
    Random = "Random [Range]",
    RandomSet = "Random [Set]"
}

local SplitString = function(string, separator)
    local result = {}

    local partial = ""
    for i = 1, #string do
        local c = string:sub(i, i)
        if c ~= separator then
            partial = partial .. c
        else
            table.insert(result, partial)
            partial = ""
        end
    end

    if #partial > 0 then table.insert(result, partial) end

    return result
end

local GetToolPreferences = function(toolId)
    return app.preferences.tool(toolId or app.activeTool)
end

local sizeOption, angleOption, colorOption = Option.None, Option.None,
                                             Option.None

local dialog
local isDialogOpen = false
local sprite = app.activeSprite
local onChangeListener, onSiteChangeListener, onColorChangeListener

local OnChange = function(ev)
    if not isDialogOpen then return end
    if ev.fromUndo then return end

    local data = dialog.data
    local toolPreferences = GetToolPreferences()

    if sizeOption == Option.Grow or sizeOption == Option.Shrink then
        local variable = data["size-variable"] or 0
        local size = toolPreferences.brush.size

        if sizeOption == Option.Grow then size = size + variable end
        if sizeOption == Option.Shrink then size = size - variable end

        toolPreferences.brush.size = math.max(size, 1)
    end

    if sizeOption == Option.Random then
        local min = data["size-random-min"] or 1
        local max = data["size-random-max"] or min

        toolPreferences.brush.size = math.max(math.random(min, max), 1)
    end

    if sizeOption == Option.RandomSet then
        local set = data["size-random-set"]
        if set then
            local rawValues = SplitString(set, ",")
            local values = {}

            for _, rawValue in ipairs(rawValues) do
                table.insert(values, tonumber(rawValue))
            end

            local size = values[math.random(1, #values)]
            size = math.abs(math.ceil(size)) -- Size needs to be a positive, non-zero value

            toolPreferences.brush.size = size
        end
    end

    local angleSet = data["angle-random-set"]

    if angleOption == Option.Rotate then
        local variable = data["angle-variable"] or 0
        local angle = toolPreferences.brush.angle + variable

        toolPreferences.brush.angle = (angle % 360) - 180
    end

    if angleOption == Option.Random then
        local angleMin = data["angle-random-min"]
        local angleMax = data["angle-random-max"]

        local smallerValue = math.min(angleMin, angleMax)
        local biggerValue = math.max(angleMin, angleMax)

        local d = math.min(biggerValue - smallerValue,
                           360 + smallerValue - biggerValue)

        toolPreferences.brush.angle = ((angleMin + math.random(0, d)) % 360) -
                                          180
    end

    if angleOption == Option.RandomSet and angleSet then
        local rawValues = SplitString(angleSet, ",")
        local values = {}

        for _, rawValue in ipairs(rawValues) do
            table.insert(values, tonumber(rawValue))
        end

        toolPreferences.brush.angle = values[math.random(1, #values)]
    end

    local colorRange = data["color-range"]

    if #colorRange == 0 then
        local palette = sprite.palettes[1]
        colorRange = {}

        for i = 0, #palette - 1 do
            table.insert(colorRange, palette:getColor(i))
        end
    end

    if colorOption == Option.Next or colorOption == Option.Previous then
        local index

        for i = 1, #colorRange do
            index = i
            if app.fgColor.rgbaPixel == colorRange[i].rgbaPixel then
                break
            end
        end

        if colorOption == Option.Next then
            index = math.min(index + 1, #colorRange)
        end
        if colorOption == Option.Previous then
            index = math.max(index - 1, 1)
        end

        app.fgColor = colorRange[index]
    end

    if colorOption == Option.RandomSet then
        local randomIndex = math.random(1, #colorRange)
        app.fgColor = colorRange[randomIndex]
    end
end

local OnSiteChange = function()
    local previousSprite = sprite

    -- If the sprite hasn't changed do nothing
    if previousSprite == app.activeSprite then return end

    -- If the previous sprite wasn't nil stop listening for changes
    if previousSprite then previousSprite.events:off(onChangeListener) end

    -- Update the saved sprite
    sprite = app.activeSprite

    -- If the new sprite isn't nil start listening for changes
    if sprite then onChangeListener = sprite.events:on('change', OnChange) end

    -- If the dialog was open and the focus is back on any sprite, show the dialog
    if not previousSprite and sprite and isDialogOpen then
        dialog:show{wait = false}
    end

    -- If the dialog was open and the focus is away from any sprite, close the dialog
    if previousSprite and not sprite and isDialogOpen then
        dialog:close()
        isDialogOpen = true -- Mark it is open again
    end
end

local OnColorChange = function()
    if isDialogOpen and colorOption ~= Option.None and #app.range.colors > 1 then
        local palette = sprite.palettes[1]
        local colors = {}

        for _, colorIndex in ipairs(app.range.colors) do
            table.insert(colors, palette:getColor(colorIndex))
        end

        dialog --
        :modify{id = "color-range", colors = colors} --
        :modify{id = "color-reset", visible = true}
    end
end

dialog = Dialog {
    title = "Brush Properties", -- Randomize Brush in Aseprite 
    onclose = function() isDialogOpen = false end
}

dialog --
:separator{text = "Size:"} --
:combobox{
    id = "size",
    label = "Option:",
    options = {
        Option.None, Option.Grow, Option.Shrink, Option.Random, Option.RandomSet
    },
    Option = sizeOption,
    onchange = function()
        sizeOption = dialog.data.size
        local toolPreferences = GetToolPreferences()

        dialog --
        :modify{
            id = "size-variable",
            visible = sizeOption == Option.Grow or sizeOption == Option.Shrink
        } --
        :modify{
            id = "size-random-min",
            visible = sizeOption == Option.Random,
            text = tostring(math.floor(toolPreferences.brush.size * 0.5))
        } --
        :modify{
            id = "size-random-max",
            visible = sizeOption == Option.Random,
            text = tostring(math.ceil(toolPreferences.brush.size * 1.5))
        } --
        :modify{
            id = "size-random-set",
            visible = sizeOption == Option.RandomSet
        }
    end
} --
:number{id = "size-variable", label = "Value:", text = "1", visible = false} --
:number{
    id = "size-random-min",
    label = "Min/Max:",
    text = "1",
    visible = false,
    decimals = 0
} --
:number{id = "size-random-max", text = "10", visible = false, decimals = 0} --
:entry{
    id = "size-random-set",
    label = "Values:",
    text = "1,2,3",
    visible = false
}

dialog --
:separator{text = "Angle:"} --
:combobox{
    id = "angle",
    label = "Option:",
    options = {Option.None, Option.Rotate, Option.Random, Option.RandomSet},
    Option = angleOption,
    onchange = function()
        angleOption = dialog.data.angle
        local toolPreferences = GetToolPreferences()

        dialog --
        :modify{id = "angle-variable", visible = angleOption == Option.Rotate} --
        :modify{
            id = "angle-random-min",
            visible = angleOption == Option.Random,
            text = tostring(math.floor(toolPreferences.brush.angle * 0.5))
        } --
        :modify{
            id = "angle-random-max",
            visible = angleOption == Option.Random,
            text = tostring(math.ceil(toolPreferences.brush.angle * 1.5))
        } --
        :modify{
            id = "angle-random-set",
            visible = angleOption == Option.RandomSet
        }
    end
} --
:slider{
    id = "angle-variable",
    label = "Value:",
    visible = false,
    min = -180,
    max = 180,
    value = 30
} --
:slider{
    id = "angle-random-min",
    label = "Min:",
    visible = false,
    min = -180,
    max = 180,
    value = 0
} --
:slider{
    id = "angle-random-max",
    label = "Max:",
    visible = false,
    min = -180,
    max = 180,
    value = 180
} --
:entry{
    id = "angle-random-set",
    label = "Values:",
    text = "15,30,45",
    visible = false
}

dialog --
:separator{text = "Color:"} --
:combobox{
    id = "color",
    label = "Option:",
    options = {Option.None, Option.Next, Option.Previous, Option.RandomSet},
    option = colorOption,
    onchange = function()
        colorOption = dialog.data.color

        dialog --
        :modify{id = "color-range", visible = colorOption ~= Option.None} --
        :modify{
            id = "color-reset",
            visible = colorOption ~= Option.None and #dialog.data["color-range"] >
                0
        } --
    end
} --
:shades{
    id = "color-range",
    label = "Range:",
    mode = "sort",
    visible = false,
    colors = {},
    onclick = function(ev)
        if ev.color and ev.button == MouseButton.LEFT then
            app.fgColor = ev.color
        end
    end
} --
:button{
    id = "color-reset",
    text = "Reset",
    visible = false,
    onclick = function()
        dialog --
        :modify{id = "color-range", colors = {}} --
        :modify{id = "color-reset", visible = false} --
    end
}

function init(plugin)
    -- Listen for a site change to monitor the sprite changes
    onSiteChangeListener = app.events:on('sitechange', OnSiteChange)

    -- Listen for a color change as a trigger to check if there are colors selected
    onColorChangeListener = app.events:on('fgcolorchange', OnColorChange)

    plugin:newCommand{
        id = "RandomizeBrush",
        title = "Brush Properties",
        group = "edit_transform",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            isDialogOpen = true

            dialog:show{wait = false}
        end
    }
end

function exit(plugin)
    if sprite then sprite.events:off(onChangeListener) end
    app.events:off(onSiteChangeListener)
    app.events:off(onColorChangeListener)
end
