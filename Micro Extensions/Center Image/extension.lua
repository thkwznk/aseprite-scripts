function CanCenterImage()
    -- If there's no active sprite
    if app.activeSprite == nil then return false end

    -- If there's no cels in range
    if #app.range.cels == 0 then return false end

    return true
end

function CenterImageInActiveSprite(options)
    if options == nil or (not options.xAxis and not options.yAxis) then
        return
    end

    app.transaction(function()
        local sprite = app.activeSprite

        if not sprite.selection.isEmpty then
            CenterSelection(options, sprite)
        else
            CenterCels(options, sprite)
        end
    end)

    app.refresh()
end

function CenterSelection(options, sprite)
    local selection = sprite.selection.bounds

    for _, cel in ipairs(app.range.cels) do
        local outerImage, centeredImage, centertedImageBounds = CutImagePart(
                                                                    cel,
                                                                    selection)
        local imageCenter = GetImageCenter(centeredImage, options)

        local x = centertedImageBounds.x
        local y = centertedImageBounds.y

        if options.xAxis then
            x = selection.x + math.floor(selection.width / 2) - imageCenter.x
        end

        if options.yAxis then
            y = selection.y + math.floor(selection.height / 2) - imageCenter.y
        end

        local contentNewBounds = Rectangle(x, y, centeredImage.width,
                                           centeredImage.height)

        local newImageBounds = contentNewBounds:union(cel.bounds)
        local newImage = Image(newImageBounds.width, newImageBounds.height,
                               sprite.colorMode)

        newImage:drawImage(outerImage, Point(cel.position.x - newImageBounds.x,
                                             cel.position.y - newImageBounds.y))
        newImage:drawImage(centeredImage,
                           Point(x - newImageBounds.x, y - newImageBounds.y))

        local trimmedImage, trimmedPosition =
            TrimImage(newImage, Point(newImageBounds.x, newImageBounds.y))

        sprite:newCel(cel.layer, cel.frameNumber, trimmedImage, trimmedPosition)
    end
end

function GetImageCenter(image, options)
    local getPixel = image.getPixel
    local centerX = 0

    if options.weighted then
        local total = 0
        local rows = {}

        for x = 0, image.width do
            for y = 0, image.height do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(rows, total)
        end

        local centerValue = total / 2
        centerX = 0

        for i = 1, #rows do
            if rows[i] >= centerValue then
                centerX = i - 1
                break
            end
        end
    else
        centerX = math.floor(image.width / 2)
    end

    local centerY = 0

    if options.weighted then
        local total = 0
        local columns = {}

        for y = 0, image.height do
            for x = 0, image.width do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(columns, total)
        end

        local centerValue = total / 2
        centerY = 0

        for i = 1, #columns do
            if columns[i] >= centerValue then
                centerY = i - 1
                break
            end
        end
    else
        centerY = math.floor(image.height / 2)
    end

    return Point(centerX, centerY)
end

function CenterCels(options, sprite)
    for _, cel in ipairs(app.range.cels) do
        local x = cel.bounds.x
        local y = cel.bounds.y

        if options.weighted then
            local imageCenter = GetImageCenter(cel.image, options)

            if options.xAxis then
                x = math.floor(sprite.width / 2) - imageCenter.x
            end

            if options.yAxis then
                y = math.floor(sprite.height / 2) - imageCenter.y
            end
        else
            if options.xAxis then
                x = math.floor(sprite.width / 2) -
                        math.floor(cel.bounds.width / 2)
            end

            if options.yAxis then
                y = math.floor(sprite.height / 2) -
                        math.floor(cel.bounds.height / 2)
            end
        end

        cel.position = Point(x, y)
    end
end

function GetContentBounds(cel, selection)
    local imageSelection = Rectangle(selection.x - cel.bounds.x,
                                     selection.y - cel.bounds.y,
                                     selection.width, selection.height)

    -- Calculate selection content bounds
    local minX, maxX, minY, maxY = math.maxinteger, math.mininteger,
                                   math.maxinteger, math.mininteger

    for pixel in cel.image:pixels(imageSelection) do
        if pixel() > 0 then
            minX = math.min(minX, pixel.x)
            maxX = math.max(maxX, pixel.x)

            minY = math.min(minY, pixel.y)
            maxY = math.max(maxY, pixel.y)
        end
    end

    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

function CutImagePart(cel, selection)
    local contentBounds = GetContentBounds(cel, selection)

    local oldImage = Image(cel.image)
    local imagePart = Image(cel.image, contentBounds)

    -- TODO: Fix for Aseprite v1.3-rc2
    -- Draw an empty image to erase the part
    -- oldImage:drawImage(Image(contentBounds.width, contentBounds.height),
    --                    Point(contentBounds.x, contentBounds.y))

    for pixel in oldImage:pixels(contentBounds) do
        imagePart:drawPixel(pixel.x - contentBounds.x,
                            pixel.y - contentBounds.y, pixel())
        pixel(0)
    end

    return oldImage, imagePart,
           Rectangle(cel.bounds.x + contentBounds.x,
                     cel.bounds.y + contentBounds.y, contentBounds.width,
                     contentBounds.height)
end

function TrimImage(image, position)
    -- TODO: Use Image:shrinkBounds() for apiVersion >= 21
    local found, left, top, right, bottom

    -- Left
    found = false

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                left = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Top
    found = false

    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                top = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Right
    found = false

    for x = image.width - 1, 0, -1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                right = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Bottom
    found = false

    for y = image.height - 1, 0, -1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                bottom = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Trim image
    local trimmedImage = Image(right - left + 1, bottom - top + 1,
                               image.colorMode)
    trimmedImage:drawImage(image, Point(-left, -top))

    return trimmedImage, Point(position.x + left, position.y + top)
end

function init(plugin)
    if app.apiVersion < 22 then
        plugin:newCommand{
            id = "Center",
            title = "Center",
            group = "edit_transform",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, yAxis = true}
            end
        }

        plugin:newCommand{
            id = "CenterX",
            title = "Center X",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, yAxis = false}
            end
        }

        plugin:newCommand{
            id = "CenterY",
            title = "Center Y",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = false, yAxis = true}
            end
        }

        plugin:newCommand{
            id = "CenterWeighted",
            title = "Center (Weighted)",
            group = "edit_transform",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {
                    xAxis = true,
                    yAxis = true,
                    weighted = true
                }
            end
        }

        plugin:newCommand{
            id = "CenterXWeighted",
            title = "Center X (Weighted)",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, weighted = true}
            end
        }

        plugin:newCommand{
            id = "CenterYWeighted",
            title = "Center Y (Weighted)",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {yAxis = true, weighted = true}
            end
        }
    else
        plugin:newMenuGroup{
            id = "edit_center",
            title = "Center",
            group = "edit_transform"
        }

        plugin:newCommand{
            id = "Center",
            title = "Center",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, yAxis = true}
            end
        }

        plugin:newCommand{
            id = "CenterX",
            title = "Center X",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, yAxis = false}
            end
        }

        plugin:newCommand{
            id = "CenterY",
            title = "Center Y",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = false, yAxis = true}
            end
        }

        plugin:newMenuSeparator{group = "edit_center"}

        plugin:newCommand{
            id = "CenterWeighted",
            title = "Center (Weighted)",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {
                    xAxis = true,
                    yAxis = true,
                    weighted = true
                }
            end
        }

        plugin:newCommand{
            id = "CenterXWeighted",
            title = "Center X (Weighted)",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {xAxis = true, weighted = true}
            end
        }

        plugin:newCommand{
            id = "CenterYWeighted",
            title = "Center Y (Weighted)",
            group = "edit_center",
            onenabled = CanCenterImage,
            onclick = function()
                CenterImageInActiveSprite {yAxis = true, weighted = true}
            end
        }

        -- plugin:newMenuSeparator{group = "edit_center"}

        -- plugin:newCommand{
        --     id = "CenterWeightedAlpha",
        --     title = "Center (Weighted + Alpha)",
        --     group = "edit_center",
        --     onenabled = CanCenterImage,
        --     onclick = function()
        --         CenterImageInActiveSprite {
        --             xAxis = true,
        --             yAxis = true,
        --             weighted = true,
        --             alpha = true
        --         }
        --     end
        -- }

        -- plugin:newCommand{
        --     id = "CenterXWeighted",
        --     title = "Center X (Weighted + Alpha)",
        --     group = "edit_center",
        --     onenabled = CanCenterImage,
        --     onclick = function()
        --         CenterImageInActiveSprite {
        --             xAxis = true,
        --             weighted = true,
        --             alpha = true
        --         }
        --     end
        -- }

        -- plugin:newCommand{
        --     id = "CenterYWeighted",
        --     title = "Center Y (Weighted + Alpha)",
        --     group = "edit_center",
        --     onenabled = CanCenterImage,
        --     onclick = function()
        --         CenterImageInActiveSprite {
        --             yAxis = true,
        --             weighted = true,
        --             alpha = true
        --         }
        --     end
        -- }
    end
end

function exit(plugin) end

-- TODO: Implement Weighted + Alpha centering
