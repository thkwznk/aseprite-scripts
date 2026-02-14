local Template = dofile("./Template.lua")
local ThemeManager = dofile("./ThemeManager.lua")

local THEME_ID = "custom"
local DIALOG_WIDTH = 240
local DIALOG_TITLE = "Theme Preferences"

local ExtensionsDirectory = app.fs.joinPath(app.fs.userConfigPath, "extensions")
local ThemePreferencesDirectory = app.fs.joinPath(ExtensionsDirectory,
                                                  "theme-preferences")
local SheetTemplatePath = app.fs.joinPath(ThemePreferencesDirectory,
                                          "sheet-template.png")
local SheetPath = app.fs.joinPath(ThemePreferencesDirectory, "sheet.png")
local ThemeXmlTemplatePath = app.fs.joinPath(ThemePreferencesDirectory,
                                             "theme-template.xml")
local ThemeXmlPath = app.fs.joinPath(ThemePreferencesDirectory, "theme.xml")

local function ReadAll(filePath)
    local file = assert(io.open(filePath, "rb"))
    local content = file:read("*all")
    file:close()
    return content
end

local function WriteAll(filePath, content)
    local file = io.open(filePath, "w")
    if file then
        file:write(content)
        file:close()
    end
end

local function ColorToHex(color)
    return string.format("#%02x%02x%02x", color.red, color.green, color.blue)
end

local function RgbaPixelToColor(rgbaPixel)
    return Color {
        red = app.pixelColor.rgbaR(rgbaPixel),
        green = app.pixelColor.rgbaG(rgbaPixel),
        blue = app.pixelColor.rgbaB(rgbaPixel),
        alpha = app.pixelColor.rgbaA(rgbaPixel)
    }
end

local function CopyColor(originalColor)
    return Color {
        red = originalColor.red,
        green = originalColor.green,
        blue = originalColor.blue,
        alpha = originalColor.alpha
    }
end

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

-- Color Definitions
local Theme = {name = "", colors = {}, parameters = {}}

-- Copy template to theme
Theme.name = Template.name

for id, color in pairs(Template.colors) do Theme.colors[id] = CopyColor(color) end

for id, parameter in pairs(Template.parameters) do
    Theme.parameters[id] = parameter
end

local function UpdateThemeXml(theme)
    -- Prepare theme.xml
    local xmlContent = ReadAll(ThemeXmlTemplatePath)

    for id, color in pairs(theme.colors) do
        xmlContent = xmlContent:gsub("<" .. id .. ">", ColorToHex(color))
    end

    WriteAll(ThemeXmlPath, xmlContent)
end

local function RefreshTheme(template, theme)
    -- Prepare color lookup
    local Map = {}

    for id, templateColor in pairs(template.colors) do
        -- Map the template color to the theme color
        Map[ColorToHex(templateColor)] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = SheetTemplatePath}
    local pixelValue, newColor, pixelData, pixelColor, pixelValueKey,
          resultColor

    -- Save references to function to improve performance
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            pixelValue = getPixel(image, x, y)

            if pixelValue > 0 then
                pixelValueKey = tostring(pixelValue)
                pixelData = cache[pixelValueKey]

                if not pixelData then
                    pixelColor = RgbaPixelToColor(pixelValue)

                    cache[pixelValueKey] = {
                        id = ColorToHex(pixelColor),
                        color = pixelColor
                    }

                    pixelData = cache[pixelValueKey]
                end

                resultColor = Map[pixelData.id]

                if resultColor ~= nil then
                    newColor = CopyColor(resultColor)
                    newColor.alpha = pixelData.color.alpha -- Restore the original alpha value

                    drawPixel(image, x, y, newColor)
                end
            end
        end
    end

    image:saveAs(SheetPath)

    -- Update the XML theme file
    UpdateThemeXml(theme)

    app.command.Refresh()
end

local function ApplyTheme()
    RefreshTheme(Template, Theme)
    ThemeManager:SetCurrentTheme(Theme)

    -- Switch Aseprite to the custom theme
    if app.preferences.theme.selected ~= THEME_ID then
        app.preferences.theme.selected = THEME_ID
    end
end

local AdvancedWidgetIds = {
    "button_highlight", "button_background", "button_shadow",
    "tab_corner_highlight", "tab_highlight", "tab_background", "tab_shadow",
    "window_highlight", "window_background", "window_shadow", "text_link",
    "text_separator", "editor_icons"
}

local function ThemePreferencesDialog(options)
    local dialog
    local isModified = options.isModified
    local hasAppliedModifications = false

    local function GetDialogTitle()
        if isModified then
            return DIALOG_TITLE .. ": " .. Theme.name .. " (modified)"
        end

        return DIALOG_TITLE .. ": " .. Theme.name
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
            :modify{id = "simple-link", color = Theme.colors["text_link"]} --
            :modify{
                id = "simple-button",
                color = Theme.colors["button_background"]
            } --
            :modify{id = "simple-tab", color = Theme.colors["tab_background"]} --
            :modify{
                id = "simple-window",
                color = Theme.colors["window_background"]
            } --
            :modify{id = "editor_icons", color = Theme.colors["text_regular"]}
        end

        dialog --
        :modify{id = "simple-link", visible = isSimple} --
        :modify{id = "simple-button", visible = isSimple} --
        :modify{id = "simple-tab", visible = isSimple} --
        :modify{id = "simple-window", visible = isSimple}

        for _, id in ipairs(AdvancedWidgetIds) do
            dialog:modify{id = id, visible = dialog.data["mode-advanced"]}
        end

        Theme.parameters.isAdvanced = dialog.data["mode-advanced"]
    end

    local function SetThemeColor(id, color)
        Theme.colors[id] = color
        if dialog.data[id] then dialog:modify{id = id, color = color} end
    end

    local function LoadTheme(theme)
        -- Copy theme to the current theme
        Theme.name = theme.name
        Theme.parameters = theme.parameters

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
            color = Theme.colors[options.id],
            visible = options.visible,
            onchange = function()
                local color = dialog.data[options.id]
                Theme.colors[options.id] = color

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

        Theme.colors["editor_cursor"] = color
        Theme.colors["editor_cursor_shadow"] = shadowColor
        Theme.colors["editor_cursor_outline"] = outlinecolor

        MarkThemeAsModified(true)
    end

    local function LoadCurrentTheme()
        local currentTheme = ThemeManager:GetCurrentTheme()
        if currentTheme then LoadTheme(currentTheme) end
    end

    -- Setup the dialog
    dialog = Dialog {
        title = GetDialogTitle(),
        onclose = function()
            if options.onclose then
                options.onclose({isModified = hasAppliedModifications})
            end

            LoadCurrentTheme()
        end
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
        color = Theme.colors["text_link"],
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
            Theme.colors["editor_background_shadow"] = shadowColor
        end
    }

    ThemeColor {label = "Icons", id = "editor_icons", visible = false}

    ThemeColor {
        label = "Tooltip",
        id = "editor_tooltip",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -100, -90, -32)
            local cornerShadowColor = ShiftColor(color, -125, -152, -94)

            Theme.colors["editor_tooltip_shadow"] = shadowColor
            Theme.colors["editor_tooltip_corner_shadow"] = cornerShadowColor
        end
    }

    dialog --
    :color{
        id = "editor_cursor",
        label = "Cursor",
        color = Theme.colors["editor_cursor"],
        onchange = function() ChangeCursorColors() end
    } --
    :color{
        id = "editor_cursor_outline",
        color = Theme.colors["editor_cursor_outline"],
        onchange = function() ChangeCursorColors() end
    }

    dialog:separator{text = "Button"}

    ThemeColor {id = "button_highlight", visible = false}
    ThemeColor {id = "button_background", visible = false}
    ThemeColor {id = "button_shadow", visible = false}

    dialog:color{
        id = "simple-button",
        color = Theme.colors["button_background"],
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
        color = Theme.colors["tab_background"],
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
            Theme.colors["window_highlight"] = color

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(color, -57, -57, -57)
            local filedCornerShadowColor = ShiftColor(color, -74, -74, -74)

            Theme.colors["field_background"] = color
            Theme.colors["field_shadow"] = fieldShadowColor
            Theme.colors["field_corner_shadow"] = filedCornerShadowColor
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
        color = Theme.colors["window_background"],
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

            Theme.colors["field_background"] = highlightColor
            Theme.colors["field_shadow"] = fieldShadowColor
            Theme.colors["field_corner_shadow"] = filedCornerShadowColor

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

            ThemeManager:Save(Theme, onsave)
        end
    } --
    :button{
        text = "Load",
        onclick = function()
            local onload = function(theme)
                LoadTheme(theme)
                ApplyTheme()
                MarkThemeAsModified(false)
                hasAppliedModifications = isModified
            end

            local onreset = function()
                LoadTheme(Template)
                ApplyTheme()
                MarkThemeAsModified(false)
                hasAppliedModifications = isModified
            end

            -- Hide the Theme Preferences dialog
            dialog:close()

            ThemeManager:Load(onload, onreset)

            -- Reopen the dialog
            dialog:show{wait = false}
        end
    } --

    dialog --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            ApplyTheme()
            hasAppliedModifications = isModified
            dialog:close()
        end
    } --
    :button{
        text = "Apply",
        onclick = function()
            ApplyTheme()
            hasAppliedModifications = isModified
        end
    } -- 
    :button{text = "Cancel", onclick = function() dialog:close() end} --

    -- Init
    LoadCurrentTheme()

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
        title = DIALOG_TITLE .. "...",
        group = "view_screen",
        onenabled = function() return not isDialogOpen end,
        onclick = function()
            local dialog = ThemePreferencesDialog {
                isModified = storage.isThemeModified,
                onclose = function(options)
                    isDialogOpen = false
                    storage.isThemeModified = options.isModified
                end
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
                                   dialog.sizeHint.height * uiScale)
            }
            isDialogOpen = true
        end
    }
end

function exit(plugin)
    -- 
end
