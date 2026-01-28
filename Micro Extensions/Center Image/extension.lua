local function GetContentCenter(cel, selection, options)
    local imageSelection = Rectangle(selection.bounds.x - cel.bounds.x,
                                     selection.bounds.y - cel.bounds.y,
                                     selection.bounds.width,
                                     selection.bounds.height)

    -- Calculate selection content bounds
    local minX, maxX, minY, maxY = math.maxinteger, math.mininteger,
                                   math.maxinteger, math.mininteger

    local bgColorValue =
        options.ignoreBackgroundColor and app.bgColor.rgbaPixel or 0

    local rows, columns, pixels = {}, {}, {}
    local total = 0
    local hasAlpha = false

    for pixel in cel.image:pixels(imageSelection) do
        local x, y, value = pixel.x, pixel.y, pixel()
        local inSelection = selection:contains(x + cel.bounds.x,
                                               y + cel.bounds.y)

        if value == 0 and inSelection then hasAlpha = true end

        if value > 0 and value ~= bgColorValue and inSelection then
            minX = math.min(minX, x)
            maxX = math.max(maxX, x)

            minY = math.min(minY, y)
            maxY = math.max(maxY, y)

            table.insert(pixels, {x = x, y = y, value = value})

            rows[y] = (rows[y] or 0) + 1
            columns[x] = (columns[x] or 0) + 1
            total = total + 1
        end
    end

    local centerX = minX + (maxX - minX + 1) / 2
    local centerY = minY + (maxY - minY + 1) / 2

    if options.weighted then
        local centerValue = total / 2
        local rowsTotal, columnsTotal = 0, 0

        for y = imageSelection.y, imageSelection.y + imageSelection.height - 1 do
            if rows[y] then
                rowsTotal = rowsTotal + rows[y]
                if rowsTotal >= centerValue then
                    centerY = y - 1
                    break
                end
            end
        end

        for x = imageSelection.x, imageSelection.x + imageSelection.width - 1 do
            if columns[x] then
                columnsTotal = columnsTotal + columns[x]
                if columnsTotal >= centerValue then
                    centerX = x - 1
                    break
                end
            end
        end
    end

    return Point(centerX, centerY), pixels, hasAlpha
end

local function FindFirstGreaterOrEqual(collection, value)
    for i = 1, #collection do if collection[i] >= value then return i end end
end

local function GetSelectionCenter(selection, options)
    local bounds = selection.bounds
    local centerX, centerY = math.floor(bounds.width / 2),
                             math.floor(bounds.height / 2)

    if options.weightedSelectionCenter then
        local count = 0
        local rows, columns = {}, {}

        for x = bounds.x, bounds.x + bounds.width - 1 do
            for y = bounds.y, bounds.y + bounds.height - 1 do
                if selection:contains(x, y) then
                    count = count + 1
                end
            end

            table.insert(columns, count)
        end

        local centerValue = count / 2
        centerX = FindFirstGreaterOrEqual(columns, centerValue) - 1

        count = 0

        for y = bounds.y, bounds.y + bounds.height - 1 do
            for x = bounds.x, bounds.x + bounds.width - 1 do
                if selection:contains(x, y) then
                    count = count + 1
                end
            end

            table.insert(rows, count)
        end

        centerY = FindFirstGreaterOrEqual(rows, centerValue) - 1
    end

    return Point(bounds.x + centerX, bounds.y + centerY)
end

local function CenterSelectionWithSolid(cel, options, sprite)
    local selection = sprite.selection

    local imagePartBounds = Rectangle(selection.bounds)
    imagePartBounds.x = imagePartBounds.x - cel.bounds.x
    imagePartBounds.y = imagePartBounds.y - cel.bounds.y

    local drawPixel = cel.image.drawPixel
    local bgColorValue = app.bgColor.rgbaPixel

    local newImage = Image(cel.image)
    local center, pixels, hasAlpha = GetContentCenter(cel, selection, options)

    -- Use the mask color if at least one pixel in the selection is empty
    if hasAlpha then bgColorValue = 0 end

    local selectionCenter = GetSelectionCenter(selection, options)
    local shiftX, shiftY = 0, 0

    if options.xAxis then
        shiftX = (selectionCenter.x - cel.position.x) - center.x
    end
    if options.yAxis then
        shiftY = (selectionCenter.y - cel.position.y) - center.y
    end

    -- Clear pixels
    for _, pixel in ipairs(pixels) do
        drawPixel(newImage, pixel.x, pixel.y, bgColorValue)
    end

    -- Draw pixels in their new positions
    for _, pixel in ipairs(pixels) do
        local x = pixel.x
        local y = pixel.y

        if options.xAxis then x = x + shiftX end
        if options.yAxis then y = y + shiftY end

        drawPixel(newImage, x, y, pixel.value)
    end

    cel.image = newImage
end

local function GetImageCenter(image, options)
    local getPixel = image.getPixel
    local centerX = 0

    if options.weighted then
        local total = 0
        local columns = {}

        for x = 0, image.width do
            for y = 0, image.height do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(columns, total)
        end

        local centerValue = total / 2
        centerX = FindFirstGreaterOrEqual(columns, centerValue) - 1
    else
        centerX = math.floor(image.width / 2)
    end

    local centerY = 0

    if options.weighted then
        local total = 0
        local rows = {}

        for y = 0, image.height do
            for x = 0, image.width do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(rows, total)
        end

        local centerValue = total / 2
        centerY = FindFirstGreaterOrEqual(rows, centerValue) - 1
    else
        centerY = math.floor(image.height / 2)
    end

    return Point(centerX, centerY)
end

local function MoveContent(direction, quantity)
    app.command.MoveMask {
        target = "content",
        wrap = true,
        direction = direction,
        units = "pixel",
        quantity = quantity
    }
end

local function CenterSelection(cel, options, sprite)
    local selection = sprite.selection

    local imageCenter = GetContentCenter(cel, selection, options)
    local selectionCenter = GetSelectionCenter(selection, options)
    local x, y = 0, 0

    if options.xAxis then
        x = (selectionCenter.x - cel.position.x) - imageCenter.x
    end
    if options.yAxis then
        y = (selectionCenter.y - cel.position.y) - imageCenter.y
    end

    if x ~= 0 then MoveContent(x > 0 and "right" or "left", math.abs(x)) end
    if y ~= 0 then MoveContent(y > 0 and "down" or "up", math.abs(y)) end
end

local function GetCanvasCenter(sprite)
    return Point(math.floor(sprite.width / 2), math.floor(sprite.height / 2))
end

local function CenterCel(cel, options, sprite)
    local x = cel.bounds.x
    local y = cel.bounds.y

    local center = sprite.selection.isEmpty and GetCanvasCenter(sprite) or
                       GetSelectionCenter(sprite.selection, options)

    local imageCenter = GetImageCenter(cel.image, options)

    if options.xAxis then x = center.x - imageCenter.x end
    if options.yAxis then y = center.y - imageCenter.y end

    cel.position = Point(x, y)
end

local function CanCenterImage()
    -- If there's no active sprite
    if app.activeSprite == nil then return false end

    -- If there's no cels in range
    if #app.range.cels == 0 then return false end

    return true
end

local function CenterImageInActiveSprite(options)
    if options == nil or (not options.xAxis and not options.yAxis) then
        return
    end

    app.transaction("Center", function()
        local sprite = app.activeSprite
        local selection = sprite.selection

        for _, cel in ipairs(app.range.cels) do
            if cel.layer.isEditable then
                if selection.isEmpty or
                    (selection.bounds:contains(cel.bounds) and selection.bounds ~=
                        cel.bounds) then
                    CenterCel(cel, options, sprite)
                elseif options.ignoreBackgroundColor then
                    CenterSelectionWithSolid(cel, options, sprite)
                else
                    CenterSelection(cel, options, sprite)
                end
            end
        end
    end)

    if app.apiVersion >= 35 then app.tip("Image centered") end

    app.refresh()
end

function init(plugin)
    local parentGroup = "edit_transform"

    if app.apiVersion >= 22 then
        parentGroup = "edit_center"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Center",
            group = "edit_transform"
        }
    end

    plugin:newCommand{
        id = "Center",
        title = "Center",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                yAxis = true,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    plugin:newCommand{
        id = "CenterX",
        title = "Center X",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                yAxis = false,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    plugin:newCommand{
        id = "CenterY",
        title = "Center Y",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = false,
                yAxis = true,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    if app.apiVersion >= 22 then plugin:newMenuSeparator{group = parentGroup} end

    plugin:newCommand{
        id = "CenterWeighted",
        title = "Center (Weighted)",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                yAxis = true,
                weighted = true,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    plugin:newCommand{
        id = "CenterXWeighted",
        title = "Center X (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                weighted = true,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    plugin:newCommand{
        id = "CenterYWeighted",
        title = "Center Y (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                yAxis = true,
                weighted = true,
                weightedSelectionCenter = plugin.preferences
                    .weightedSelectionCenter,
                ignoreBackgroundColor = plugin.preferences.ignoreBackgroundColor
            }
        end
    }

    if app.apiVersion >= 35 then
        plugin:newMenuSeparator{group = parentGroup}

        plugin:newCommand{
            id = "WeightedSelectionCenterToggle",
            title = "Use Weighted Selection Center",
            group = parentGroup,
            onchecked = function()
                return plugin.preferences.weightedSelectionCenter
            end,
            onclick = function()
                plugin.preferences.weightedSelectionCenter =
                    not plugin.preferences.weightedSelectionCenter
            end
        }

        plugin:newCommand{
            id = "IgnoreBackgroundColorToggle",
            title = "Ignore Background Color",
            group = parentGroup,
            onchecked = function()
                return plugin.preferences.ignoreBackgroundColor
            end,
            onclick = function()
                plugin.preferences.ignoreBackgroundColor =
                    not plugin.preferences.ignoreBackgroundColor
            end
        }
    end
end

function exit(plugin) end
