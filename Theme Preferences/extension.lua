local Theme = dofile("./Theme.lua")
local ThemeManager = dofile("./ThemeManager.lua")
local CopyColor = dofile("./CopyColor.lua")
local UpdateThemeFiles = dofile("./UpdateThemeFiles.lua")

local CUSTOM_THEME_ID = "custom"
local DIALOG_WIDTH = 240

local function ShiftRGB(value, modifier)
    return math.max(math.min(value + modifier, 255), 0)
end

local function ShiftColor(color, redModifier, greenModifer, blueModifier)
    return Color {
        red = ShiftRGB(color.red, redModifier),
        green = ShiftRGB(color.green, greenModifer),
        blue = ShiftRGB(color.blue, blueModifier),
        alpha = color.alpha
    }
end

local AdvancedWidgetIds = {
    "button_highlight", "button_background", "button_shadow",
    "tab_corner_highlight", "tab_highlight", "tab_background", "tab_shadow",
    "window_highlight", "window_background", "window_shadow", "text_link",
    "text_separator", "editor_icons"
}

local function ThemePreferencesDialog(options)
    local dialog
    local isModified = ThemeManager:GetIsThemeModified()

    -- Use the current theme saved in plugin preferences or the Default theme
    -- The latter is necessary for a fresh install to work correctly
    local currentTheme = ThemeManager:GetCurrentTheme() or Theme()

    local function ApplyToCurrentTheme()
        UpdateThemeFiles(currentTheme)
        ThemeManager:SetCurrentTheme(currentTheme)
        ThemeManager:SetIsThemeModified(isModified)

        -- Switch Aseprite to the custom theme
        if app.preferences.theme.selected ~= CUSTOM_THEME_ID then
            app.preferences.theme.selected = CUSTOM_THEME_ID
        end
    end

    local function GetDialogTitle()
        local title = "Theme Preferences: " .. currentTheme.name
        if isModified then title = title .. " (modified)" end

        return title
    end

    local function MarkThemeAsModified(value)
        isModified = value

        dialog --
        :modify{id = "save-configuration", enabled = value} --
        :modify{title = GetDialogTitle()}
    end

    local function ChangeMode(options)
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
            :modify{
                id = "simple-link",
                color = currentTheme.colors["text_link"]
            } --
            :modify{
                id = "simple-button",
                color = currentTheme.colors["button_background"]
            } --
            :modify{
                id = "simple-tab",
                color = currentTheme.colors["tab_background"]
            } --
            :modify{
                id = "simple-window",
                color = currentTheme.colors["window_background"]
            } --
            :modify{
                id = "editor_icons",
                color = currentTheme.colors["text_regular"]
            }
        end

        dialog --
        :modify{id = "simple-link", visible = isSimple} --
        :modify{id = "simple-button", visible = isSimple} --
        :modify{id = "simple-tab", visible = isSimple} --
        :modify{id = "simple-window", visible = isSimple}

        for _, id in ipairs(AdvancedWidgetIds) do
            dialog:modify{id = id, visible = dialog.data["mode-advanced"]}
        end

        currentTheme.parameters.isAdvanced = dialog.data["mode-advanced"]
    end

    local function SetThemeColor(id, color)
        currentTheme.colors[id] = color
        if dialog.data[id] then dialog:modify{id = id, color = color} end
    end

    local function LoadTheme(theme)
        -- Copy theme to the current theme
        currentTheme.name = theme.name
        currentTheme.parameters = theme.parameters

        -- Change mode
        dialog --
        :modify{id = "mode-simple", selected = not theme.parameters.isAdvanced} --
        :modify{id = "mode-advanced", selected = theme.parameters.isAdvanced}

        ChangeMode {force = true}

        -- Load simple versions first to then overwrite advanced colors
        local simpleButtons = {
            ["simple-link"] = theme.colors["text_link"],
            ["simple-button"] = theme.colors["button_background"],
            -- ["simple-field"] = Theme.colors["field_background"],
            ["simple-tab"] = theme.colors["tab_background"],
            ["simple-window"] = theme.colors["window_background"]
        }

        for id, color in pairs(simpleButtons) do
            dialog:modify{id = id, color = color}
        end

        -- Finally, copy colors
        for id, color in pairs(theme.colors) do
            -- Copy color just in case
            SetThemeColor(id, CopyColor(color))
        end

        dialog:modify{title = GetDialogTitle()} --
        dialog:modify{id = "save-configuration", enabled = isModified}
    end

    local function ThemeColor(options)
        dialog:color{
            id = options.id,
            label = options.label,
            color = currentTheme.colors[options.id],
            visible = options.visible,
            onchange = function()
                local color = dialog.data[options.id]
                currentTheme.colors[options.id] = color

                if options.onchange then options.onchange(color) end

                MarkThemeAsModified(true)
            end
        }
    end

    local function ChangeCursorColors()
        local color = dialog.data["editor_cursor"]
        local outlinecolor = dialog.data["editor_cursor_outline"]

        local shadowColor = Color {
            red = (color.red + outlinecolor.red) / 2,
            green = (color.green + outlinecolor.green) / 2,
            blue = (color.blue + outlinecolor.blue) / 2,
            alpha = color.alpha
        }

        currentTheme.colors["editor_cursor"] = color
        currentTheme.colors["editor_cursor_shadow"] = shadowColor
        currentTheme.colors["editor_cursor_outline"] = outlinecolor

        MarkThemeAsModified(true)
    end

    -- Setup the dialog
    dialog = Dialog {
        title = GetDialogTitle(),
        onclose = options.onclose,
        autofit = Align.TOP
    }

    dialog --
    :radio{
        id = "mode-simple",
        label = "Mode",
        text = "Simple",
        selected = true,
        onclick = function()
            ChangeMode()
            MarkThemeAsModified(true)
        end
    } --
    :radio{
        id = "mode-advanced",
        text = "Advanced",
        selected = false,
        onclick = function()
            ChangeMode()
            MarkThemeAsModified(true)
        end
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
        color = currentTheme.colors["text_link"],
        onchange = function()
            local color = dialog.data["simple-link"]

            SetThemeColor("text_link", color)
            SetThemeColor("text_separator", color)

            MarkThemeAsModified(true)
        end
    }

    dialog:separator{text = "Input Fields"}

    ThemeColor {label = "Highlight", id = "field_highlight", visible = true}

    -- FUTURE: Allow for separate changing of the "field_background"
    -- dialog:color{
    --     id = "simple-field",
    --     label = "Background",
    --     color = Theme.colors["field_background"],
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

    --         Theme.colors["field_background"] = color
    --         Theme.colors["field_shadow"] = shadowColor
    --         Theme.colors["field_corner_shadow"] = cornerShadowColor
    --     end
    -- }

    dialog:separator{text = "Editor"}

    ThemeColor {
        label = "Background",
        id = "editor_background",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -36, -20, -53)
            currentTheme.colors["editor_background_shadow"] = shadowColor
        end
    }

    ThemeColor {label = "Icons", id = "editor_icons", visible = false}

    ThemeColor {
        label = "Tooltip",
        id = "editor_tooltip",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -100, -90, -32)
            local cornerShadowColor = ShiftColor(color, -125, -152, -94)

            currentTheme.colors["editor_tooltip_shadow"] = shadowColor
            currentTheme.colors["editor_tooltip_corner_shadow"] =
                cornerShadowColor
        end
    }

    dialog --
    :color{
        id = "editor_cursor",
        label = "Cursor",
        color = currentTheme.colors["editor_cursor"],
        onchange = function() ChangeCursorColors() end
    } --
    :color{
        id = "editor_cursor_outline",
        color = currentTheme.colors["editor_cursor_outline"],
        onchange = function() ChangeCursorColors() end
    }

    dialog:separator{text = "Button"}

    ThemeColor {id = "button_highlight", visible = false}
    ThemeColor {id = "button_background", visible = false}
    ThemeColor {id = "button_shadow", visible = false}

    dialog:color{
        id = "simple-button",
        color = currentTheme.colors["button_background"],
        onchange = function()
            local color = dialog.data["simple-button"]
            local highlightColor = ShiftColor(color, 57, 57, 57)
            local shadowColor = ShiftColor(color, -74, -74, -74)

            SetThemeColor("button_highlight", highlightColor)
            SetThemeColor("button_background", color)
            SetThemeColor("button_shadow", shadowColor)

            MarkThemeAsModified(true)
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
        color = currentTheme.colors["tab_background"],
        onchange = function()
            local color = dialog.data["simple-tab"]
            local cornerHighlightColor = ShiftColor(color, 131, 110, 98)
            local highlightColor = ShiftColor(color, 49, 57, 65)
            local shadowColor = ShiftColor(color, -24, -61, -61)

            SetThemeColor("tab_corner_highlight", cornerHighlightColor)
            SetThemeColor("tab_highlight", highlightColor)
            SetThemeColor("tab_background", color)
            SetThemeColor("tab_shadow", shadowColor)

            MarkThemeAsModified(true)
        end
    }

    dialog:separator{text = "Window"}

    ThemeColor {
        id = "window_highlight",
        visible = false,
        onchange = function(color)
            currentTheme.colors["window_highlight"] = color

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(color, -57, -57, -57)
            local filedCornerShadowColor = ShiftColor(color, -74, -74, -74)

            currentTheme.colors["field_background"] = color
            currentTheme.colors["field_shadow"] = fieldShadowColor
            currentTheme.colors["field_corner_shadow"] = filedCornerShadowColor
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
        color = currentTheme.colors["window_background"],
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

            currentTheme.colors["field_background"] = highlightColor
            currentTheme.colors["field_shadow"] = fieldShadowColor
            currentTheme.colors["field_corner_shadow"] = filedCornerShadowColor

            MarkThemeAsModified(true)
        end
    } --

    ThemeColor {label = "Hover", id = "window_hover", visible = true}

    dialog --
    :separator() --
    :button{
        id = "save-configuration",
        label = "Configuration",
        text = "Save",
        enabled = false,
        onclick = function()
            local onsave = function(theme)
                dialog:modify{title = GetDialogTitle()}
                dialog:modify{id = "save-configuration", enabled = false}

                MarkThemeAsModified(false)
            end

            ThemeManager:Save(currentTheme, onsave)
        end
    } --
    :button{
        text = "Load",
        onclick = function()
            local onload = function(theme)
                theme = theme or Theme()

                LoadTheme(theme)
                MarkThemeAsModified(false)
                ApplyToCurrentTheme()
            end

            -- Hide the Theme Preferences dialog
            local bounds = dialog.bounds
            dialog:close()

            ThemeManager:Load(onload)

            -- Reopen the dialog
            bounds.height = dialog.sizeHint.height
            dialog:show{wait = false, bounds = bounds}
        end
    } --

    dialog --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            ApplyToCurrentTheme()
            dialog:close()
        end
    } --
    :button{text = "Apply", onclick = function() ApplyToCurrentTheme() end} -- 
    :button{text = "Cancel", onclick = function() dialog:close() end} --

    -- Load the current theme into the dialog
    LoadTheme(currentTheme)

    return dialog
end

function init(plugin)
    -- Do nothing when UI is not available
    if not app.isUIAvailable then return end

    -- Initialize plugin preferences data for backwards compatibility
    plugin.preferences.themePreferences =
        plugin.preferences.themePreferences or {}
    local storage = plugin.preferences.themePreferences

    ThemeManager:Init{storage = storage}

    local isDialogOpen = false

    plugin:newCommand{
        id = "ThemePreferences",
        title = "Theme Preferences...",
        group = "view_screen",
        onenabled = function() return not isDialogOpen end,
        onclick = function()
            local dialog = ThemePreferencesDialog {
                onclose = function() isDialogOpen = false end
            }

            -- Refreshing the UI on open to fix the issue where the dialog would keep parts of the old theme
            app.command.Refresh()

            -- Show Theme Preferences dialog
            local uiScale = app.preferences.general["ui_scale"]

            dialog:show{
                wait = false,
                bounds = Rectangle(app.window.width / 2 - DIALOG_WIDTH / 2,
                                   app.window.height / 2 -
                                       dialog.sizeHint.height / 2,
                                   DIALOG_WIDTH * uiScale,
                                   dialog.sizeHint.height)
            }
            isDialogOpen = true
        end
    }
end

function exit(plugin)
    -- 
end

-- TODO: Rename "Simple" mode to "Basic"?
-- TODO: Test showing configuration export code in a non-editable field instead of a dialog
