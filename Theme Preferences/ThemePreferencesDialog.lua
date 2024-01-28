return function(options)
    local title = "Theme Preferences: " .. options.name
    local titleModified = title .. " (modified)"

    local isModified = options.isModified
    local colors = options.colors

    local dialog = Dialog {
        title = isModified and titleModified or title,
        onclose = options.onclose
    }

    function MarkThemeAsModified()
        if isModified then return end
        isModified = true

        dialog --
        :modify{id = "save-configuration", enabled = true} --
        :modify{title = title .. " (modified)"}
    end

    function ThemeColor(widgetOptions)
        dialog:color{
            id = widgetOptions.id,
            label = widgetOptions.label,
            color = colors[widgetOptions.id],
            visible = widgetOptions.visible,
            onchange = function()
                local color = dialog.data[widgetOptions.id]
                colors[widgetOptions.id] = color

                if widgetOptions.onchange then
                    widgetOptions.onchange(color)
                end

                MarkThemeAsModified()
            end
        }
    end

    dialog --
    :radio{
        id = "mode-simple",
        label = "Mode",
        text = "Simple",
        selected = true,
        onclick = function() ChangeMode() end
    } --
    :radio{
        id = "mode-advanced",
        text = "Advanced",
        selected = false,
        onclick = function() ChangeMode() end
    }

    dialog:separator{text = "Text"}

    ThemeColor {label = "Active/Regular", id = "text_active", visible = true}
    ThemeColor {
        id = "text_regular",
        visible = true,
        onchange = function(color)
            if dialog.data["mode-simple"] then
                SetThemeColor("editor_icons", color)
            end
        end
    }
    ThemeColor {label = "Link/Separator", id = "text_link", visible = false}
    ThemeColor {id = "text_separator", visible = false}

    dialog:color{
        id = "simple-link",
        label = "Link/Separator",
        color = colors["text_link"],
        onchange = function()
            local color = dialog.data["simple-link"]

            SetThemeColor("text_link", color)
            SetThemeColor("text_separator", color)

            MarkThemeAsModified()
        end
    }

    dialog:separator{text = "Input Fields"}

    ThemeColor {label = "Highlight", id = "field_highlight", visible = true}

    -- FUTURE: Allow for separate chaning of the "field_background"
    -- dialog:color{
    --     id = "simple-field",
    --     label = "Background",
    --     color = colors["field_background"],
    --     onchange = function()
    --         local color = dialog.data["simple-field"]

    --         local shadowColor = Color {
    --             red = ShiftRGB(color.red, -57),
    --             green = ShiftRGB(color.green, -57),
    --             blue = ShiftRGB(color.blue, -57),
    --             alpha = color.alpha
    --         }

    --         local cornerShadowColor = Color {
    --             red = ShiftRGB(color.red, -74),
    --             green = ShiftRGB(color.green, -74),
    --             blue = ShiftRGB(color.blue, -74),
    --             alpha = color.alpha
    --         }

    --         colors["field_background"] = color
    --         colors["field_shadow"] = shadowColor
    --         colors["field_corner_shadow"] = cornerShadowColor
    --     end
    -- }

    dialog:separator{text = "Editor"}

    ThemeColor {
        label = "Background",
        id = "editor_background",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -36, -20, -53)
            colors["editor_background_shadow"] = shadowColor
        end
    }

    ThemeColor {label = "Icons", id = "editor_icons", visible = false}

    ThemeColor {
        label = "Tooltip",
        id = "editor_tooltip",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -100, -90, -32)
            local cornerShadowColor = ShiftColor(color, -125, -152, -94)

            colors["editor_tooltip_shadow"] = shadowColor
            colors["editor_tooltip_corner_shadow"] = cornerShadowColor
        end
    }

    dialog --
    :color{
        id = "editor_cursor",
        label = "Cursor",
        color = colors["editor_cursor"],
        onchange = function() ChangeCursorColors() end
    } --
    :color{
        id = "editor_cursor_outline",
        color = colors["editor_cursor_outline"],
        onchange = function() ChangeCursorColors() end
    }

    dialog:separator{text = "Button"}

    ThemeColor {id = "button_highlight", visible = false}
    ThemeColor {id = "button_background", visible = false}
    ThemeColor {id = "button_shadow", visible = false}

    dialog:color{
        id = "simple-button",
        color = colors["button_background"],
        onchange = function()
            local color = dialog.data["simple-button"]
            local highlightColor = ShiftColor(color, 57, 57, 57)
            local shadowColor = ShiftColor(color, -74, -74, -74)

            SetThemeColor("button_highlight", highlightColor)
            SetThemeColor("button_background", color)
            SetThemeColor("button_shadow", shadowColor)

            MarkThemeAsModified()
        end
    }

    ThemeColor {label = "Selected", id = "button_selected", visible = true}

    dialog:separator{text = "Tab"}

    ThemeColor {id = "tab_corner_highlight", visible = false}
    ThemeColor {id = "tab_highlight", visible = false}
    ThemeColor {id = "tab_background", visible = false}
    ThemeColor {id = "tab_shadow", visible = false}

    dialog:color{
        id = "simple-tab",
        color = colors["tab_background"],
        onchange = function()
            local color = dialog.data["simple-tab"]
            local cornerHighlightColor = ShiftColor(color, 131, 110, 98)
            local highlightColor = ShiftColor(color, 49, 57, 65)
            local shadowColor = ShiftColor(color, -24, -61, -61)

            SetThemeColor("tab_corner_highlight", cornerHighlightColor)
            SetThemeColor("tab_highlight", highlightColor)
            SetThemeColor("tab_background", color)
            SetThemeColor("tab_shadow", shadowColor)

            MarkThemeAsModified()
        end
    }

    dialog:separator{text = "Window"}

    ThemeColor {
        id = "window_highlight",
        visible = false,
        onchange = function(color)
            colors["window_highlight"] = color

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(color, -57, -57, -57)
            local filedCornerShadowColor = ShiftColor(color, -74, -74, -74)

            colors["field_background"] = color
            colors["field_shadow"] = fieldShadowColor
            colors["field_corner_shadow"] = filedCornerShadowColor
        end
    }

    ThemeColor {id = "window_background", visible = false}

    ThemeColor {
        id = "window_shadow",
        visible = false,
        onchange = function(color)
            local cornerShadowColor = ShiftColor(color, -49, -44, -20)
            SetThemeColor("window_corner_shadow", cornerShadowColor)
        end
    }

    dialog:color{
        id = "simple-window",
        color = colors["window_background"],
        onchange = function()
            local color = dialog.data["simple-window"]
            local highlightColor = ShiftColor(color, 45, 54, 66)
            local shadowColor = ShiftColor(color, -61, -73, -73)
            local cornerShadowColor = ShiftColor(color, -110, -117, -93)

            SetThemeColor("window_highlight", highlightColor)
            SetThemeColor("window_background", color)
            SetThemeColor("window_shadow", shadowColor)
            SetThemeColor("window_corner_shadow", cornerShadowColor)

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(highlightColor, -57, -57, -57)
            local filedCornerShadowColor =
                ShiftColor(highlightColor, -74, -74, -74)

            colors["field_background"] = highlightColor
            colors["field_shadow"] = fieldShadowColor
            colors["field_corner_shadow"] = filedCornerShadowColor

            MarkThemeAsModified()
        end
    } --

    ThemeColor {label = "Hover", id = "window_hover", visible = true}

    dialog --
    :separator() --
    :button{
        id = "save-configuration",
        label = "Configuration",
        text = "Save",
        enabled = isModified, -- Only allows saving of a modified theme
        -- TODO: Add SaveAs option
        onclick = function() options.onsave() end
    } --
    :button{text = "Load", onclick = function() options.onload() end} --
    :button{text = "Font", onclick = function() options.onfont() end}

    dialog --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            options.onok()
            dialog:close()
        end
    } --
    :button{text = "Apply", onclick = function() options.onok() end} -- 
    :button{text = "Cancel", onclick = function() dialog:close() end} --

    return dialog
end
