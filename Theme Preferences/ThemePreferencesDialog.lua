function ShiftRGB(value, modifier)
    return math.max(math.min(value + modifier, 255), 0)
end

function ShiftColor(color, redModifier, greenModifer, blueModifier)
    return Color {
        red = ShiftRGB(color.red, redModifier),
        green = ShiftRGB(color.green, greenModifer),
        blue = ShiftRGB(color.blue, blueModifier),
        alpha = color.alpha
    }
end

return function(options)
    local title = "Theme Preferences"
    local titleModified = title .. " (modified)"

    function UpdateTitle(name)
        title = "Theme Preferences: " .. name
        titleModified = title .. " (modified)"
    end

    UpdateTitle(options.name)

    local isModified = options.isModified
    local colors = options.colors
    local parameters = options.parameters

    local dialog = Dialog {
        title = isModified and titleModified or title,
        onclose = options.onclose
    }

    function GetParameters()
        return {
            isAdvanced = dialog.data["mode-advanced"],
            isModified = isModified
        }
    end

    function MarkAsModified(value)
        if isModified == value then return end

        isModified = value

        dialog --
        :modify{id = "save-configuration", enabled = value} --
        :modify{id = "save-as-configuration", enabled = value} --
        :modify{title = title .. (value and " (modified)" or "")}
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

                MarkAsModified(true)
            end
        }
    end

    function ChangeCursorColors()
        local color = dialog.data["editor_cursor"]
        local outlinecolor = dialog.data["editor_cursor_outline"]

        dialog:modify{
            id = "editor_cursor_shadow",
            color = Color {
                red = (color.red + outlinecolor.red) / 2,
                green = (color.green + outlinecolor.green) / 2,
                blue = (color.blue + outlinecolor.blue) / 2,
                alpha = color.alpha
            }
        }

        MarkAsModified(true)
    end

    function ChangeMode(options)
        -- Set default options
        options = options or {}
        options.force = options.force ~= nil and options.force or false

        local isSimple = dialog.data["mode-simple"]

        if isSimple then
            if not options.force then
                local confirmation = app.alert {
                    title = "Warning",
                    text = "Switching to Simple Mode will modify your theme, do you want to continue?",
                    buttons = {"Yes", "No"}
                }

                if confirmation == 2 then
                    dialog:modify{id = "mode-simple", selected = false}
                    dialog:modify{id = "mode-advanced", selected = true}
                    return
                end
            end

            -- Set new simple values when switching to Simple Mode
            dialog --
            :modify{id = "simple-link", color = dialog.data["text_link"]} --
            :modify{
                id = "simple-button",
                color = dialog.data["button_background"]
            } --
            :modify{id = "simple-tab", color = dialog.data["tab_background"]} --
            :modify{
                id = "simple-window",
                color = dialog.data["window_background"]
            } --
            :modify{id = "editor_icons", color = dialog.data["text_regular"]}
        end

        dialog --
        :modify{id = "simple-link", visible = isSimple} --
        :modify{id = "simple-button", visible = isSimple} --
        :modify{id = "simple-tab", visible = isSimple} --
        :modify{id = "simple-window", visible = isSimple}

        local advancedWidgetIds = {
            "button_highlight", "button_background", "button_shadow",
            "tab_corner_highlight", "tab_highlight", "tab_background",
            "tab_shadow", "window_highlight", "window_background",
            "window_shadow", "text_link", "text_separator", "editor_icons"
        }

        for _, id in ipairs(advancedWidgetIds) do
            dialog:modify{id = id, visible = dialog.data["mode-advanced"]}
        end

        if not options.force then MarkAsModified(true) end
    end

    dialog --
    :radio{
        id = "mode-simple",
        label = "Mode",
        text = "Simple",
        selected = not parameters.isAdvanced,
        onclick = function() ChangeMode() end
    } --
    :radio{
        id = "mode-advanced",
        text = "Advanced",
        selected = parameters.isAdvanced,
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

            MarkAsModified(true)
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

    ThemeColor {id = "editor_cursor_shadow", visible = false}

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

            MarkAsModified(true)
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

            MarkAsModified(true)
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
    ThemeColor {id = "window_corner_shadow", visible = false}

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

            MarkAsModified(true)
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
        onclick = function()
            options.onsave(dialog.data, GetParameters())
            MarkAsModified(false)
        end
    } --
    :button{
        id = "save-as-configuration",
        text = "Save As",
        enabled = isModified, -- Only allows saving of a modified theme
        onclick = function()
            local refreshTitle = function(name)
                UpdateTitle(name)
                MarkAsModified(false)
            end

            options.onsaveas(dialog.data, GetParameters(), refreshTitle)
        end
    } --
    :button{text = "Load", onclick = function() options.onload() end} --
    :separator() --
    :button{
        text = "Reset to Default",
        onclick = function() options.onreset() end
    } --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            options.onok(dialog.data, GetParameters())
            dialog:close()
        end
    } --
    :button{
        text = "Apply",
        onclick = function() options.onok(dialog.data, GetParameters()) end
    } -- 
    :button{text = "Cancel", onclick = function() dialog:close() end} --

    if parameters.isAdvanced then ChangeMode {force = true} end

    return dialog
end

-- TODO: Add Reset button
