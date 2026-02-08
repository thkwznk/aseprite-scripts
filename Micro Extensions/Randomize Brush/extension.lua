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

local function SplitString(string, separator)
    local result = {}

    if type(string) ~= "string" or type(separator) ~= "string" then
        return result
    end

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

local function GetToolPreferences(toolId)
    return app.preferences.tool(toolId or app.activeTool)
end

local propertiesDialog
local isDialogOpen = false
local sprite = app.activeSprite
local onChangeListener, onSiteChangeListener, onColorChangeListener

local OnChange = function(ev)
    if not isDialogOpen then return end

    -- From v1.3-rc1, skip changes from undo
    if app.apiVersion >= 21 and ev.fromUndo then return end

    -- TODO: Refactor this so that the settings are saved in a global table
    local data = propertiesDialog.data
    local tool = GetToolPreferences()

    if data.sizeOption == Option.Grow or data.sizeOption == Option.Shrink then
        local variable = data.sizeVariable or 0
        local size = tool.brush.size

        if data.sizeOption == Option.Grow then size = size + variable end
        if data.sizeOption == Option.Shrink then size = size - variable end

        tool.brush.size = math.max(size, 1)
    end

    if data.sizeOption == Option.Random then
        local sizeMin = data.sizeRandomMin or 1
        local sizeMax = data.sizeRandomMax or sizeMin

        local min = math.min(sizeMin, sizeMax)
        local max = math.max(sizeMin, sizeMax)

        tool.brush.size = math.max(math.random(min, max), 1)
    end

    if data.sizeOption == Option.RandomSet then
        local rawValues = SplitString(data.sizeRandomSet, ",")
        local values = {}

        for _, rawValue in ipairs(rawValues) do
            table.insert(values, tonumber(rawValue))
        end

        if #values == 0 then return end

        local size = values[math.random(1, #values)]
        size = math.abs(math.ceil(size)) -- Size needs to be a positive, non-zero value

        tool.brush.size = size
    end

    if data.angleOption == Option.Rotate then
        local variable = data.angleVariable or 0
        local angle = tool.brush.angle + variable

        tool.brush.angle = (angle % 360) - 180
    end

    if data.angleOption == Option.Random then
        local smallerValue = math.min(data.angleRandomMin, data.angleRandomMax)
        local biggerValue = math.max(data.angleRandomMin, data.angleRandomMax)

        local d = math.min(biggerValue - smallerValue,
                           360 + smallerValue - biggerValue)

        tool.brush.angle = ((data.angleRandomMin + math.random(0, d)) % 360) -
                               180
    end

    if data.angleOption == Option.RandomSet then
        local rawValues = SplitString(data.angleRandomSet, ",")
        local values = {}

        for _, rawValue in ipairs(rawValues) do
            table.insert(values, tonumber(rawValue))
        end

        tool.brush.angle = values[math.random(1, #values)]
    end

    local colorRange = data.colorRange

    if #colorRange == 0 then
        local palette = sprite.palettes[1]
        colorRange = {}

        for i = 0, #palette - 1 do
            table.insert(colorRange, palette:getColor(i))
        end
    end

    if data.colorOption == Option.Next or data.colorOption == Option.Previous then
        local index

        for i = 1, #colorRange do
            index = i
            if app.fgColor.rgbaPixel == colorRange[i].rgbaPixel then
                break
            end
        end

        if data.colorOption == Option.Next then
            index = math.min(index + 1, #colorRange)
        end
        if data.colorOption == Option.Previous then
            index = math.max(index - 1, 1)
        end

        app.fgColor = colorRange[index]
    end

    if data.colorOption == Option.RandomSet then
        local randomIndex = math.random(1, #colorRange)
        app.fgColor = colorRange[randomIndex]
    end
end

local OnSiteChange = function()
    local previousSprite = sprite

    -- If the sprite hasn't changed do nothing
    if previousSprite == app.activeSprite then return end

    -- If the previous sprite wasn't nil stop listening for changes
    if previousSprite and onChangeListener then
        previousSprite.events:off(onChangeListener)
    end

    -- Update the saved sprite
    sprite = app.activeSprite

    -- If the new sprite isn't nil start listening for changes
    if sprite then onChangeListener = sprite.events:on('change', OnChange) end

    -- If the dialog was open and the focus is back on any sprite, show the dialog
    if not previousSprite and sprite and isDialogOpen then
        propertiesDialog:show{wait = false}
    end

    -- If the dialog was open and the focus is away from any sprite, close the dialog
    if previousSprite and not sprite and isDialogOpen then
        propertiesDialog:close()
        isDialogOpen = true -- Mark it is open again
    end
end

local function OnColorChange()
    if isDialogOpen and propertiesDialog.data.colorOption ~= Option.None and
        #app.range.colors > 1 then
        local palette = sprite.palettes[1]
        local colors = {}

        for _, colorIndex in ipairs(app.range.colors) do
            table.insert(colors, palette:getColor(colorIndex))
        end

        propertiesDialog --
        :modify{id = "colorRange", colors = colors} --
        :modify{id = "colorReset", visible = true}
    end
end

local function BrushPropertiesDialog()
    local dialog = Dialog {
        title = "Brush Properties",
        onclose = function() isDialogOpen = false end
    }

    dialog --
    :separator{text = "Size:"} --
    :combobox{
        id = "sizeOption",
        label = "Option:",
        options = {
            Option.None, Option.Grow, Option.Shrink, Option.Random,
            Option.RandomSet
        },
        Option = Option.None,
        onchange = function()
            local option = dialog.data.sizeOption
            local tool = GetToolPreferences()

            dialog --
            :modify{
                id = "sizeVariable",
                visible = option == Option.Grow or option == Option.Shrink
            } --
            :modify{
                id = "sizeRandomMin",
                visible = option == Option.Random,
                text = tostring(math.floor(tool.brush.size * 0.5))
            } --
            :modify{
                id = "sizeRandomMax",
                visible = option == Option.Random,
                text = tostring(math.ceil(tool.brush.size * 1.5))
            } --
            :modify{id = "sizeRandomSet", visible = option == Option.RandomSet}
        end
    } --
    :number{id = "sizeVariable", label = "Value:", text = "1", visible = false} --
    :number{
        id = "sizeRandomMin",
        label = "Min/Max:",
        text = "1",
        visible = false,
        decimals = 0
    } --
    :number{id = "sizeRandomMax", text = "10", visible = false, decimals = 0} --
    :entry{
        id = "sizeRandomSet",
        label = "Values:",
        text = "1,2,3",
        visible = false
    }

    dialog --
    :separator{text = "Angle:"} --
    :combobox{
        id = "angleOption",
        label = "Option:",
        options = {Option.None, Option.Rotate, Option.Random, Option.RandomSet},
        Option = Option.None,
        onchange = function()
            local option = dialog.data.angleOption
            local tool = GetToolPreferences()

            dialog --
            :modify{id = "angleVariable", visible = option == Option.Rotate} --
            :modify{
                id = "angleRandomMin",
                visible = option == Option.Random,
                text = tostring(math.floor(tool.brush.angle * 0.5))
            } --
            :modify{
                id = "angleRandomMax",
                visible = option == Option.Random,
                text = tostring(math.ceil(tool.brush.angle * 1.5))
            } --
            :modify{id = "angleRandomSet", visible = option == Option.RandomSet}
        end
    } --
    :slider{
        id = "angleVariable",
        label = "Value:",
        visible = false,
        min = -180,
        max = 180,
        value = 30
    } --
    :slider{
        id = "angleRandomMin",
        label = "Min:",
        visible = false,
        min = -180,
        max = 180,
        value = 0
    } --
    :slider{
        id = "angleRandomMax",
        label = "Max:",
        visible = false,
        min = -180,
        max = 180,
        value = 180
    } --
    :entry{
        id = "angleRandomSet",
        label = "Values:",
        text = "15,30,45",
        visible = false
    }

    dialog --
    :separator{text = "Color:"} --
    :combobox{
        id = "colorOption",
        label = "Option:",
        options = {Option.None, Option.Next, Option.Previous, Option.RandomSet},
        option = Option.None,
        onchange = function()
            local option = dialog.data.colorOption
            local hasColorRange = #dialog.data.colorRange > 0

            dialog --
            :modify{id = "colorRange", visible = option ~= Option.None} --
            :modify{
                id = "colorReset",
                visible = option ~= Option.None and hasColorRange
            } --
        end
    } --
    :shades{
        id = "colorRange",
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
        id = "colorReset",
        text = "Reset",
        visible = false,
        onclick = function()
            dialog --
            :modify{id = "colorRange", colors = {}} --
            :modify{id = "colorReset", visible = false} --
        end
    }

    return dialog
end

function init(plugin)
    if not app.isUIAvailable then return end

    -- Only setup the dialog if the UI is available
    propertiesDialog = BrushPropertiesDialog()

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

            propertiesDialog:show{wait = false}
        end
    }
end

function exit(plugin)
    if sprite then sprite.events:off(onChangeListener) end
    app.events:off(onSiteChangeListener)
    app.events:off(onColorChangeListener)
end

-- TODO: Add an option to loop selected colors
