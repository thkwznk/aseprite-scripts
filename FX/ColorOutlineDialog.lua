local Transparent = Color(0)

function ColorOutline(cel, opacity, color, directions)
    local sprite = cel.sprite
    local originalImage = cel.image
    local image = Image(originalImage.width + 2, cel.image.height + 2,
                        sprite.colorMode)
    image:drawImage(cel.image, 1, 1)

    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local pixelColorCache = {}

    local selection = sprite.selection

    function GetOriginalPixel(x, y)
        if x <= 0 or y <= 0 or x > cel.image.width or y > cel.image.height then
            return Transparent
        end

        if pixelColorCache[x] and pixelColorCache[x][y] then
            return pixelColorCache[x][y]
        end
        if not pixelColorCache[x] then pixelColorCache[x] = {} end

        -- Shift 1 pixel on X and Y to adjust for the additional size of the result image
        local value = getPixel(originalImage, x - 1, y - 1)
        local pixelColor = Color(value)
        pixelColorCache[x][y] = pixelColor == 0 and Transparent or pixelColor -- TODO: Change to a better way to quickly detect transparency

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
            local originalColor = GetOriginalPixel(x, y)

            -- If the pixel has color, then skip it
            if (originalColor == Transparent or originalColor.alpha == 0) and
                (selection.isEmpty or
                    selection:contains(
                        Point(x + cel.position.x - 1, y + cel.position.y - 1))) then
                -- Check pixels in four main directions
                local colors = {}

                for _, d in pairs(directions) do
                    if d.enabled then
                        table.insert(colors,
                                     GetOriginalPixel(x + d.dx, y + d.dy))
                    end
                end

                local c

                for _, dc in ipairs(colors) do
                    if dc ~= Transparent and dc.alpha > 0 then
                        if c == nil or dc.value > c.value then
                            c = dc
                        end
                    end
                end

                if c ~= nil then
                    drawPixel(image, x, y, GetOutlineColor(c))
                end
            end
        end
    end

    cel.image = image
    cel.position = Point(cel.position.x - 1, cel.position.y - 1)
end

function ColorOutlineDialog(directions)
    local dialog = Dialog("Color Outline")

    function SetDirection(direction, value)
        direction.enabled = value
        direction.button.icon = direction.enabled and "outline_full_pixel" or
                                    "outline_empty_pixel"
    end

    dialog --
    :slider{id = "opacity", label = "Opacity:", min = 1, max = 100, value = 50} --
    :color{id = "color", label = "Color:", color = app.fgColor} --

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
    :button{
        text = "&OK",
        focus = true,
        onclick = function()
            local color = dialog.data.color
            local opacity = dialog.data.opacity / 100

            app.transaction(function()
                for _, cel in ipairs(app.range.cels) do
                    if cel.layer.isEditable then
                        ColorOutline(cel, opacity, color, directions)
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
