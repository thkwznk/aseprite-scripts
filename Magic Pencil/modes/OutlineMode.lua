local GetBoundsForPixels = dofile("../GetBoundsForPixels.lua")

local OutlineMode = {canExtend = true, deleteOnEmptyCel = true}

function OutlineMode:Process(change, sprite, cel, parameters)
    -- Calculate outline pixels from the center of the change bound
    local selection = nil

    if not sprite.selection.isEmpty then
        local b = sprite.selection.bounds
        local localSelectionBounds = Rectangle(b.x - cel.bounds.x,
                                               b.y - cel.bounds.y, b.width,
                                               b.height)
        selection = Selection(localSelectionBounds)
    end

    local outlinePixels = self:_Outline(selection, change, cel)

    local bounds = GetBoundsForPixels(outlinePixels)

    if bounds then
        local boundsGlobal = Rectangle(bounds.x + cel.bounds.x,
                                       bounds.y + cel.bounds.y, bounds.width,
                                       bounds.height)
        local newImageBounds = cel.bounds:union(boundsGlobal)

        local shift = Point(cel.bounds.x - newImageBounds.x,
                            cel.bounds.y - newImageBounds.y)

        local newImage = Image(newImageBounds.width, newImageBounds.height,
                               cel.sprite.colorMode)
        newImage:drawImage(cel.image, shift)

        local outlineColor = change.leftPressed and app.fgColor or app.bgColor

        local drawPixel = newImage.drawPixel

        for _, pixel in ipairs(outlinePixels) do
            drawPixel(newImage, pixel.x + shift.x, pixel.y + shift.y,
                      outlineColor)
        end

        app.activeCel.image = newImage
        app.activeCel.position = Point(newImageBounds.x, newImageBounds.y)
    else
        app.activeCel.image = cel.image
        app.activeCel.position = cel.position
    end
end

function OutlineMode:_Outline(selection, change, cel)
    local outlinePixels = {}
    local visited = {}

    for _, pixel in ipairs(change.pixels) do
        local x = pixel.x - cel.position.x
        local y = pixel.y - cel.position.y
        local pixelCoordinate = tostring(x) .. ":" .. tostring(y)

        if not visited[pixelCoordinate] then
            self:_RecursiveOutline(selection, cel.image, x, y, outlinePixels,
                                   visited, true)
        end
    end

    return outlinePixels
end

function OutlineMode:_RecursiveOutline(selection, image, x, y, outlinePixels,
                                       visited, skip)
    -- Out of selection
    if selection then if not selection:Contains(x, y) then return end end

    if x < 0 or x > image.width - 1 or y < 0 or y > image.height - 1 or -- Out of bounds
        image:getPixel(x, y) == 0 -- Transparent
    then
        if not skip then table.insert(outlinePixels, {x = x, y = y}) end
        return
    end

    local pixelCoordinate = tostring(x) .. ":" .. tostring(y)
    -- Already visited
    if visited[pixelCoordinate] then return end
    -- Mark a pixel as visited
    visited[pixelCoordinate] = true

    self:_RecursiveOutline(selection, image, x - 1, y, outlinePixels, visited)
    self:_RecursiveOutline(selection, image, x + 1, y, outlinePixels, visited)
    self:_RecursiveOutline(selection, image, x, y - 1, outlinePixels, visited)
    self:_RecursiveOutline(selection, image, x, y + 1, outlinePixels, visited)
end

return OutlineMode
