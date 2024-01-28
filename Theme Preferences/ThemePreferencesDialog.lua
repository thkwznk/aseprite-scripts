function ShiftColor(color, redModifier, greenModifer, blueModifier)
    return Color {
        red = ShiftRGB(color.red, redModifier),
        green = ShiftRGB(color.green, greenModifer),
        blue = ShiftRGB(color.blue, blueModifier),
        alpha = color.alpha
    }
end

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
                if widgetOptions.onchange then
                    local color = dialog.data[widgetOptions.id]
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
                dialog:modify{id = "editor_icons", color = color}
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

            dialog:modify{id = "text_link", color = color}
            dialog:modify{id = "text_separator", color = color}

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
            dialog:modify{
                id = "editor_background_shadow",
                color = ShiftColor(color, -36, -20, -53)
            }
        end
    }

    ThemeColor {id = "editor_tooltip_shadow", visible = false}
    ThemeColor {id = "editor_tooltip_corner_shadow", visible = false}
    ThemeColor {id = "editor_background_shadow", visible = false}

    ThemeColor {label = "Icons", id = "editor_icons", visible = false}

    ThemeColor {
        label = "Tooltip",
        id = "editor_tooltip",
        onchange = function(color)
            dialog:modify{
                id = "editor_tooltip_shadow",
                color = ShiftColor(color, -100, -90, -32)
            }
            dialog:modify{
                id = "editor_tooltip_corner_shadow",
                color = ShiftColor(color, -125, -152, -94)
            }
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

            dialog:modify{
                id = "button_highlight",
                color = ShiftColor(color, 57, 57, 57)
            }
            dialog:modify{id = "button_background", color = color}
            dialog:modify{
                id = "button_shadow",
                color = ShiftColor(color, -74, -74, -74)
            }

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

            dialog:modify{
                id = "tab_corner_highlight",
                color = ShiftColor(color, 131, 110, 98)
            }
            dialog:modify{
                id = "tab_highlight",
                color = ShiftColor(color, 49, 57, 65)
            }
            dialog:modify{id = "tab_background", color = color}
            dialog:modify{
                id = "tab_shadow",
                color = ShiftColor(color, -24, -61, -61)
            }

            MarkThemeAsModified()
        end
    }

    dialog:separator{text = "Window"}

    ThemeColor {
        id = "window_highlight",
        visible = false,
        onchange = function(color)
            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(color, -57, -57, -57)
            local filedCornerShadowColor = ShiftColor(color, -74, -74, -74)

            dialog:modify{id = "field_background", color = color}
            dialog:modify{id = "field_shadow", color = fieldShadowColor}
            dialog:modify{
                id = "field_corner_shadow",
                color = filedCornerShadowColor
            }
        end
    }

    ThemeColor {id = "window_background", visible = false}

    ThemeColor {
        id = "window_shadow",
        visible = false,
        onchange = function(color)
            dialog:modify{
                id = "window_corner_shadow",
                color = ShiftColor(color, -49, -44, -20)
            }
        end
    }

    ThemeColor {id = "field_background", visible = false}
    ThemeColor {id = "field_shadow", visible = false}
    ThemeColor {id = "field_corner_shadow", visible = false}

    dialog:color{
        id = "simple-window",
        color = colors["window_background"],
        onchange = function()
            local color = dialog.data["simple-window"]
            local highlightColor = ShiftColor(color, 45, 54, 66)

            dialog:modify{id = "window_highlight", color = highlightColor}
            dialog:modify{id = "window_background", color = color}
            dialog:modify{
                id = "window_shadow",
                color = ShiftColor(color, -61, -73, -73)
            }
            dialog:modify{
                id = "window_corner_shadow",
                color = ShiftColor(color, -110, -117, -93)
            }

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(highlightColor, -57, -57, -57)
            local filedCornerShadowColor =
                ShiftColor(highlightColor, -74, -74, -74)

            dialog:modify{id = "field_background", color = highlightColor}
            dialog:modify{id = "field_shadow", color = fieldShadowColor}
            dialog:modify{
                id = "field_corner_shadow",
                color = filedCornerShadowColor
            }

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

-- TODO: Add SaveAs button
-- TODO: Add Reset button
