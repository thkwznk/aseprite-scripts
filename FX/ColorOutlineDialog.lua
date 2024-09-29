local PreviewCanvas = dofile("./PreviewCanvas.lua")

function GetNewBounds(image, directions)
    local x, y = 0, 0
    local w, h = image.width, image.height

    if directions["left"].enabled or directions["topLeft"].enabled or
        directions["bottomLeft"].enabled then
        x = x + 1
        w = w + 1
    end

    if directions["right"].enabled or directions["topRight"].enabled or
        directions["bottomRight"].enabled then w = w + 1 end

    if directions["top"].enabled or directions["topLeft"].enabled or
        directions["topRight"].enabled then
        y = y + 1
        h = h + 1
    end

    if directions["bottom"].enabled or directions["bottomLeft"].enabled or
        directions["bottomRight"].enabled then h = h + 1 end

    return {x = x, y = y, width = w, height = h}
end

function GetOutlinePixels(sprite, cel, originalImage, newBounds, image,
                          directions)
    local result = {}
    local getPixel = image.getPixel
    local pixelColorCache = {}

    local selection = sprite.selection

    local IsTransparent = (sprite.colorMode == ColorMode.INDEXED or
                              sprite.colorMode == ColorMode.GRAY) and
                              function(c) return c.index == 0 end or
                              function(c) return c.alpha == 0 end

    function GetPixel(x, y)
        if x < newBounds.x or y < newBounds.y or x > originalImage.width +
            newBounds.x - 1 or y > originalImage.height + newBounds.y - 1 then
            return Color(0)
        end

        if pixelColorCache[x] and pixelColorCache[x][y] then
            return pixelColorCache[x][y]
        end
        if not pixelColorCache[x] then pixelColorCache[x] = {} end

        -- Shift on X and Y to adjust for the additional size of the result image
        local value = getPixel(originalImage, x - newBounds.x, y - newBounds.y)
        local pixelColor = Color(value)
        pixelColorCache[x][y] = pixelColor

        return pixelColor
    end

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local originalColor = GetPixel(x, y)

            -- If the pixel has color, then skip it
            if IsTransparent(originalColor) and
                (selection.isEmpty or
                    selection:contains(Point(x + cel.position.x - newBounds.x,
                                             y + cel.position.y - newBounds.y))) then
                local pixel = {x = x, y = y}

                for key, direction in pairs(directions) do
                    pixel[key] = GetPixel(x + direction.dx, y + direction.dy)
                end

                table.insert(result, pixel)
            end
        end
    end

    return result
end

function DrawOutlinePixels(image, pixels, directions, color, opacity,
                           ignoreOutlineColor)
    local drawPixel = image.drawPixel
    local colorCache = {}

    local IsTransparent = (image.colorMode == ColorMode.INDEXED or
                              image.colorMode == ColorMode.GRAY) and
                              function(c) return c.index == 0 end or
                              function(c) return c.alpha == 0 end

    function GetOutlineColor(c)
        local id = tostring(c.rgbaPixel)

        if colorCache[id] then return colorCache[id] end

        local outlineColor = Color {
            red = c.red + (color.red - c.red) * opacity,
            green = c.green + (color.green - c.green) * opacity,
            blue = c.blue + (color.blue - c.blue) * opacity,
            alpha = c.alpha
        }

        colorCache[id] = outlineColor
        return outlineColor
    end

    for _, pixel in ipairs(pixels) do
        local colors = {}

        for key, direction in pairs(directions) do
            if direction.enabled then
                table.insert(colors, pixel[key])
            end
        end

        local c

        for _, directionColor in ipairs(colors) do
            if not IsTransparent(directionColor) and
                (not ignoreOutlineColor or directionColor.rgbaPixel ~=
                    color.rgbaPixel) then
                if c == nil or directionColor.value > c.value then
                    c = directionColor
                end
            end
        end

        if c ~= nil then
            drawPixel(image, pixel.x, pixel.y, GetOutlineColor(c))
        else
            drawPixel(image, pixel.x, pixel.y, 0)
        end
    end
end

function XYZ(sprite, cel, originalImage, newBounds, image, directions, color,
             opacity, ignoreOutlineColor)
    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local pixelColorCache = {}

    local selection = sprite.selection

    local IsTransparent = (sprite.colorMode == ColorMode.INDEXED or
                              sprite.colorMode == ColorMode.GRAY) and
                              function(c) return c.index == 0 end or
                              function(c) return c.alpha == 0 end

    function GetPixel(x, y)
        if x < newBounds.x or y < newBounds.y or x > originalImage.width +
            newBounds.x - 1 or y > originalImage.height + newBounds.y - 1 then
            return Color(0)
        end

        if pixelColorCache[x] and pixelColorCache[x][y] then
            return pixelColorCache[x][y]
        end
        if not pixelColorCache[x] then pixelColorCache[x] = {} end

        -- Shift on X and Y to adjust for the additional size of the result image
        local value = getPixel(originalImage, x - newBounds.x, y - newBounds.y)
        local pixelColor = Color(value)
        pixelColorCache[x][y] = pixelColor

        return pixelColor
    end

    local colorCache = {}

    function GetOutlineColor(c)
        local id = tostring(c.rgbaPixel)

        if colorCache[id] then return colorCache[id] end

        local outlineColor = Color {
            red = c.red + (color.red - c.red) * opacity,
            green = c.green + (color.green - c.green) * opacity,
            blue = c.blue + (color.blue - c.blue) * opacity,
            alpha = c.alpha
        }

        colorCache[id] = outlineColor
        return outlineColor
    end

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local originalColor = GetPixel(x, y)

            -- If the pixel has color, then skip it
            if IsTransparent(originalColor) and
                (selection.isEmpty or
                    selection:contains(Point(x + cel.position.x - newBounds.x,
                                             y + cel.position.y - newBounds.y))) then
                -- Check pixels in four main directions
                local colors = {}

                for _, direction in pairs(directions) do
                    if direction.enabled then
                        local directionColor =
                            GetPixel(x + direction.dx, y + direction.dy)
                        table.insert(colors, directionColor)
                    end
                end

                local outlineColor

                for _, directionColor in ipairs(colors) do
                    if not IsTransparent(directionColor) and
                        (not ignoreOutlineColor or directionColor.rgbaPixel ~=
                            color.rgbaPixel) then
                        if outlineColor == nil or directionColor.value >
                            outlineColor.value then
                            outlineColor = directionColor
                        end
                    end
                end

                if outlineColor ~= nil then
                    drawPixel(image, x, y, GetOutlineColor(outlineColor))
                end
            end
        end
    end

    cel.image = image
end

function ColorOutline(cel, opacity, color, directions, ignoreOutlineColor)
    local sprite = cel.sprite
    local originalImage = cel.image
    local newBounds = GetNewBounds(originalImage, directions)
    local image = Image(newBounds.width, newBounds.height, sprite.colorMode)
    image:drawImage(cel.image, newBounds.x, newBounds.y)

    XYZ(sprite, cel, originalImage, newBounds, image, directions, color,
        opacity, ignoreOutlineColor)

    cel.position = Point(cel.position.x - newBounds.x,
                         cel.position.y - newBounds.y)
end

function ColorOutlineDialog(directions)
    -- TODO: Calculate for all directions (add directions data to pixel data)
    local newBounds = GetNewBounds(app.activeCel.image, {
        left = {enabled = true},
        right = {enabled = true},
        top = {enabled = true},
        bottom = {enabled = true}
    })
    local previewImage = Image(newBounds.width, newBounds.height,
                               app.activeSprite.colorMode)
    previewImage:drawImage(app.activeCel.image, newBounds.x, newBounds.y)

    local outlinePixels = GetOutlinePixels(app.activeSprite, app.activeCel,
                                           app.activeCel.image, newBounds,
                                           previewImage, directions)

    local RepaintPreviewImage

    local dialog = Dialog("Color Outline")

    function RefreshPreviewImage()
        -- TODO: Directions
        DrawOutlinePixels(previewImage, outlinePixels, directions,
                          dialog.data.color, dialog.data.opacity / 100,
                          dialog.data.ignoreOutlineColor)
        RepaintPreviewImage(previewImage)
    end

    function SetDirection(direction, value)
        direction.enabled = value
        direction.button.icon = direction.enabled and "outline_full_pixel" or
                                    "outline_empty_pixel"
    end

    dialog --
    :slider{
        id = "opacity",
        label = "Opacity:",
        min = 1,
        max = 100,
        value = 50,
        onchange = function() RefreshPreviewImage() end
    } --
    :color{
        id = "color",
        label = "Color:",
        color = app.fgColor,
        onchange = function() RefreshPreviewImage() end
    } --

    local ButtonState = {
        normal = {part = "button_normal", color = "button_normal_text"},
        hot = {part = "button_hot", color = "button_hot_text"},
        selected = {part = "button_selected", color = "button_selected_text"},
        focused = {part = "button_focused", color = "button_normal_text"}
    }

    local outlineCircleButton = {
        bounds = Rectangle(0, 0, 20, 22),
        state = ButtonState,
        icon = "outline_circle",
        iconSize = Size(13, 15),
        onclick = function()
            SetDirection(directions.topLeft, false)
            SetDirection(directions.top, true)
            SetDirection(directions.topRight, false)

            SetDirection(directions.left, true)
            SetDirection(directions.center, false)
            SetDirection(directions.right, true)

            SetDirection(directions.bottomLeft, false)
            SetDirection(directions.bottom, true)
            SetDirection(directions.bottomRight, false)

            RefreshPreviewImage()
            dialog:repaint()
        end
    }

    local outlineSquareButton = {
        bounds = Rectangle(19, 0, 20, 22),
        state = ButtonState,
        icon = "outline_square",
        iconSize = Size(13, 15),
        onclick = function()
            SetDirection(directions.topLeft, true)
            SetDirection(directions.top, true)
            SetDirection(directions.topRight, true)

            SetDirection(directions.left, true)
            SetDirection(directions.center, false)
            SetDirection(directions.right, true)

            SetDirection(directions.bottomLeft, true)
            SetDirection(directions.bottom, true)
            SetDirection(directions.bottomRight, true)

            RefreshPreviewImage()
            dialog:repaint()
        end
    }

    local outlineHorizontalButton = {
        bounds = Rectangle(0, 19, 20, 22),
        state = ButtonState,
        icon = "outline_horizontal",
        iconSize = Size(13, 15),
        onclick = function()
            SetDirection(directions.topLeft, false)
            SetDirection(directions.top, false)
            SetDirection(directions.topRight, false)

            SetDirection(directions.left, true)
            SetDirection(directions.center, false)
            SetDirection(directions.right, true)

            SetDirection(directions.bottomLeft, false)
            SetDirection(directions.bottom, false)
            SetDirection(directions.bottomRight, false)

            RefreshPreviewImage()
            dialog:repaint()
        end
    }

    local outlineVerticalButton = {
        bounds = Rectangle(19, 19, 20, 22),
        state = ButtonState,
        icon = "outline_vertical",
        iconSize = Size(13, 15),
        onclick = function()
            SetDirection(directions.topLeft, false)
            SetDirection(directions.top, true)
            SetDirection(directions.topRight, false)

            SetDirection(directions.left, false)
            SetDirection(directions.center, false)
            SetDirection(directions.right, false)

            SetDirection(directions.bottomLeft, false)
            SetDirection(directions.bottom, true)
            SetDirection(directions.bottomRight, false)

            RefreshPreviewImage()
            dialog:repaint()
        end
    }

    local mouse = {position = Point(0, 0), leftClick = false}

    local focusedWidget = nil

    local customWidgets = {
        outlineCircleButton, outlineSquareButton, outlineHorizontalButton,
        outlineVerticalButton
    }

    function AddDirectionButtton(direction, x, y)
        direction.button = {
            bounds = Rectangle(x, y, 20, 22),
            state = ButtonState,
            icon = direction.enabled and "outline_full_pixel" or
                "outline_empty_pixel",
            iconSize = Size(5, 5),
            onclick = function()
                SetDirection(direction, not direction.enabled)
                RefreshPreviewImage()
                dialog:repaint()
            end
        }

        table.insert(customWidgets, direction.button)
    end

    AddDirectionButtton(directions.topLeft, 57, 0)
    AddDirectionButtton(directions.top, 76, 0)
    AddDirectionButtton(directions.topRight, 95, 0)

    AddDirectionButtton(directions.left, 57, 19)
    AddDirectionButtton(directions.center, 76, 19)
    AddDirectionButtton(directions.right, 95, 19)

    AddDirectionButtton(directions.bottomLeft, 57, 38)
    AddDirectionButtton(directions.bottom, 76, 38)
    AddDirectionButtton(directions.bottomRight, 95, 38)

    dialog --
    :newrow() --
    :canvas{
        id = "canvas",
        width = 160,
        height = 38 + 22,
        onpaint = function(ev)
            local ctx = ev.context

            local mouseOver = false

            -- Draw each custom widget
            for _, widget in ipairs(customWidgets) do
                local state = widget.state.normal

                if widget == focusedWidget then
                    state = widget.state.focused
                end

                local isMouseOver = widget.bounds:contains(mouse.position)

                if isMouseOver and not mouseOver then
                    state = widget.state.hot or state

                    if mouse.leftClick then
                        state = widget.state.selected
                    end
                end
                mouseOver = mouseOver or isMouseOver

                ctx:drawThemeRect(state.part, widget.bounds)

                local center = Point(widget.bounds.x + widget.bounds.width / 2,
                                     widget.bounds.y + widget.bounds.height / 2)

                if widget.icon then
                    -- Assuming default icon size of 16x16 pixels
                    local size = widget.iconSize or Rectangle(0, 0, 16, 16)

                    ctx:drawThemeImage(widget.icon, center.x - size.width / 2,
                                       center.y - size.height / 2)
                elseif widget.text then
                    local size = ctx:measureText(widget.text)

                    ctx.color = app.theme.color[state.color]
                    ctx:fillText(widget.text, center.x - size.width / 2,
                                 center.y - size.height / 2)
                end
            end
        end,
        onmousemove = function(ev)
            -- Update the mouse position
            mouse.position = Point(ev.x, ev.y)

            dialog:repaint()
        end,
        onmousedown = function(ev)
            -- Update information about left mouse button being pressed
            mouse.leftClick = ev.button == MouseButton.LEFT

            dialog:repaint()
        end,
        onmouseup = function(ev)
            -- When releasing left mouse button over a widget, call `onclick` method
            if mouse.leftClick then
                for _, widget in ipairs(customWidgets) do
                    local isMouseOver = widget.bounds:contains(mouse.position)

                    if isMouseOver then
                        widget.onclick()

                        -- Last clicked widget has focus on it
                        focusedWidget = widget

                        break
                    end
                end
            end

            -- Update information about left mouse button being released
            mouse.leftClick = false

            dialog:repaint()
        end
    } --
    :check{
        id = "ignoreOutlineColor",
        text = "Ignore pixels in the outline color",
        selected = false,
        onclick = function()
            RefreshPreviewImage()
            dialog:repaint()

        end
    } --

    RepaintPreviewImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                        previewImage, Point(
                                            app.activeCel.position.x - 1,
                                            app.activeCel.position.y - 1))

    -- Initialize the preview image
    RefreshPreviewImage()

    dialog --
    :button{
        text = "&OK",
        focus = true,
        onclick = function()
            local color = dialog.data.color
            local opacity = dialog.data.opacity / 100

            app.transaction(function()
                for _, cel in ipairs(app.range.cels) do
                    if cel.layer.isEditable then
                        ColorOutline(cel, opacity, color, directions,
                                     dialog.data.ignoreOutlineColor)
                    end
                end
            end)

            dialog:close()
            app.refresh()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

return ColorOutlineDialog
