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

function ReadAll(filePath)
    local file = assert(io.open(filePath, "rb"))
    local content = file:read("*all")
    file:close()
    return content
end

function WriteAll(filePath, content)
    local file = io.open(filePath, "w")
    if file then
        file:write(content)
        file:close()
    end
end

function ColorToHex(color)
    return string.format("#%02x%02x%02x", color.red, color.green, color.blue)
end

-- Color Definitions
local Theme = {name = "", colors = {}, parameters = {}}

-- Copy template to theme
Theme.name = Template.name

for id, color in pairs(Template.colors) do
    Theme.colors[id] = Color(color.rgbaPixel)
end

for id, parameter in pairs(Template.parameters) do
    Theme.parameters[id] = parameter
end

-- Dialog
local ThemePreferencesDialog = {
    isModified = false,
    lastRefreshState = false,
    isDialogOpen = false,
    onClose = nil,
    dialog = nil
}

ThemePreferencesDialog.dialog = Dialog {
    title = DIALOG_TITLE,
    onclose = function() ThemePreferencesDialog:onClose() end
}

function ThemePreferencesDialog:SetInitialWidth()
    self.dialog:show{wait = false}
    self.dialog:close()

    local bounds = self.dialog.bounds
    bounds.x = bounds.x - (DIALOG_WIDTH - bounds.width) / 2
    bounds.width = DIALOG_WIDTH

    self.dialog.bounds = bounds
end

function ThemePreferencesDialog:RefreshTheme(template, theme)
    -- Prepare color lookup
    local Map = {}

    for id, templateColor in pairs(template.colors) do
        -- Map the template color to the theme color
        Map[ColorToHex(templateColor)] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = SheetTemplatePath}
    local newColor, pixelColor, pixelColorId

    for pixel in image:pixels() do
        pixelColor = Color(pixel())
        pixelColorId = ColorToHex(pixelColor)

        if pixelColor.alpha > 0 and Map[pixelColorId] ~= nil then
            newColor = Color(Map[pixelColorId].rgbaPixel)
            newColor.alpha = pixelColor.alpha
            image:drawPixel(pixel.x, pixel.y, newColor)
        end
    end

    image:saveAs(SheetPath)

    -- Prepare theme.xml
    local xmlContent = ReadAll(ThemeXmlTemplatePath)

    for id, color in pairs(theme.colors) do
        xmlContent = xmlContent:gsub("<" .. id .. ">", ColorToHex(color))
    end

    WriteAll(ThemeXmlPath, xmlContent)

    app.command.Refresh()
end

function ThemePreferencesDialog:Refresh()
    self.lastRefreshState = self.isModified

    self:RefreshTheme(Template, Theme)
    ThemeManager:SetCurrentTheme(Theme)

    -- Switch Aseprite to the custom theme
    if app.preferences.theme.selected ~= THEME_ID then
        app.preferences.theme.selected = THEME_ID
    end
end

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

function ThemePreferencesDialog:MarkThemeAsModified()
    self.isModified = true

    self.dialog --
    :modify{id = "save-configuration", enabled = true} --
    :modify{title = DIALOG_TITLE .. ": " .. Theme.name .. " (modified)"}
end

function ThemePreferencesDialog:SetThemeColor(id, color)
    Theme.colors[id] = color
    if self.dialog.data[id] then self.dialog:modify{id = id, color = color} end
end

function ThemePreferencesDialog:ChangeMode(options)
    -- Set default options
    options = options or {}
    options.force = options.force ~= nil and options.force or false

    local isSimple = self.dialog.data["mode-simple"]

    if isSimple then
        if not options.force then
            local confirmation = app.alert {
                title = "Warning",
                text = "Switching to Simple Mode will modify your theme, do you want to continue?",
                buttons = {"Yes", "No"}
            }

            if confirmation == 2 then
                self.dialog:modify{id = "mode-simple", selected = false}
                self.dialog:modify{id = "mode-advanced", selected = true}
                return
            end
        end

        -- Set new simple values when switching to Simple Mode
        self.dialog --
        :modify{id = "simple-link", color = Theme.colors["text_link"]} --
        :modify{id = "simple-button", color = Theme.colors["button_background"]} --
        :modify{id = "simple-tab", color = Theme.colors["tab_background"]} --
        :modify{id = "simple-window", color = Theme.colors["window_background"]} --
        :modify{id = "editor_icons", color = Theme.colors["text_regular"]}
    end

    self.dialog --
    :modify{id = "simple-link", visible = isSimple} --
    :modify{id = "simple-button", visible = isSimple} --
    :modify{id = "simple-tab", visible = isSimple} --
    :modify{id = "simple-window", visible = isSimple}

    local advancedWidgetIds = {
        "button_highlight", "button_background", "button_shadow",
        "tab_corner_highlight", "tab_highlight", "tab_background", "tab_shadow",
        "window_highlight", "window_background", "window_shadow", "text_link",
        "text_separator", "editor_icons"
    }

    for _, id in ipairs(advancedWidgetIds) do
        self.dialog:modify{id = id, visible = self.dialog.data["mode-advanced"]}
    end

    Theme.parameters.isAdvanced = self.dialog.data["mode-advanced"]
    self:MarkThemeAsModified()
end

function ThemePreferencesDialog:LoadTheme(theme)
    -- Copy theme to the current theme
    Theme.name = theme.name
    Theme.parameters = theme.parameters

    -- Chanage mode
    self.dialog --
    :modify{id = "mode-simple", selected = not theme.parameters.isAdvanced} --
    :modify{id = "mode-advanced", selected = theme.parameters.isAdvanced}

    self:ChangeMode{force = true}

    -- Copy colors
    for id, color in pairs(theme.colors) do
        -- Copy color just in case
        self:SetThemeColor(id, Color(color.rgbaPixel))
    end

    -- Load simple versions first to then overwrite advanced colors
    local simpleButtons = {
        ["simple-link"] = theme.colors["text_link"],
        ["simple-button"] = theme.colors["button_background"],
        -- ["simple-field"] = Theme.colors["field_background"],
        ["simple-tab"] = theme.colors["tab_background"],
        ["simple-window"] = theme.colors["window_background"]
    }

    for id, color in pairs(simpleButtons) do
        self.dialog:modify{id = id, color = color}
    end

    self.dialog:modify{title = DIALOG_TITLE .. ": " .. theme.name} --
    self.dialog:modify{id = "save-configuration", enabled = false}

    self.isModified = false
end

function ThemePreferencesDialog:ThemeColor(options)
    self.dialog:color{
        id = options.id,
        label = options.label,
        color = Theme.colors[options.id],
        visible = options.visible,
        onchange = function()
            local color = self.dialog.data[options.id]
            Theme.colors[options.id] = color

            if options.onchange then options.onchange(color) end

            self:MarkThemeAsModified()
        end
    }
end

function ThemePreferencesDialog:ChangeCursorColors()
    local color = self.dialog.data["editor_cursor"]
    local outlinecolor = self.dialog.data["editor_cursor_outline"]

    local shadowColor = Color {
        red = (color.red + outlinecolor.red) / 2,
        green = (color.green + outlinecolor.green) / 2,
        blue = (color.blue + outlinecolor.blue) / 2,
        alpha = color.alpha
    }

    Theme.colors["editor_cursor"] = color
    Theme.colors["editor_cursor_shadow"] = shadowColor
    Theme.colors["editor_cursor_outline"] = outlinecolor

    self:MarkThemeAsModified()
end

function ThemePreferencesDialog:LoadCurrentTheme()
    local currentTheme = ThemeManager:GetCurrentTheme()
    if currentTheme then self:LoadTheme(currentTheme) end
end

function ThemePreferencesDialog:Init()
    -- Colors = Tint, Highlight, Tooltip (label as Hover)

    -- Link/Separator = Tint Color
    -- Simple Tab Color = 50/50 Tint Color/Window Background Color
    -- Highlight = Highlight
    -- Tooltip = Tooltip
    -- Hover = 50/50 Tooltip/Window Background Color

    self.dialog --
    -- :radio{
    --     id = "mode-tint",
    --     label = "Mode",
    --     text = "Tint",
    --     selected = true,
    --     onclick = ChangeMode
    -- } --
    :radio{
        id = "mode-simple",
        label = "Mode",
        text = "Simple",
        selected = true,
        onclick = function() self:ChangeMode() end
    } --
    :radio{
        id = "mode-advanced",
        text = "Advanced",
        selected = false,
        onclick = function() self:ChangeMode() end
    }

    self.dialog:separator{text = "Text"}

    self:ThemeColor{
        label = "Active/Regular",
        id = "text_active",
        visible = true
    }
    self:ThemeColor{
        id = "text_regular",
        visible = true,
        onchange = function(color)
            if self.dialog.data["mode-simple"] then
                self:SetThemeColor("editor_icons", color)
            end
        end
    }
    self:ThemeColor{label = "Link/Separator", id = "text_link", visible = false}
    self:ThemeColor{id = "text_separator", visible = false}

    self.dialog:color{
        id = "simple-link",
        label = "Link/Separator",
        color = Theme.colors["text_link"],
        onchange = function()
            local color = self.dialog.data["simple-link"]

            self:SetThemeColor("text_link", color)
            self:SetThemeColor("text_separator", color)

            self:MarkThemeAsModified()
        end
    }

    self.dialog:separator{text = "Input Fields"}

    self:ThemeColor{label = "Highlight", id = "field_highlight", visible = true}

    -- FUTURE: Allow for separate chaning of the "field_background"
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

    self.dialog:separator{text = "Editor"}

    self:ThemeColor{
        label = "Background",
        id = "editor_background",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -36, -20, -53)
            Theme.colors["editor_background_shadow"] = shadowColor
        end
    }

    self:ThemeColor{label = "Icons", id = "editor_icons", visible = false}

    self:ThemeColor{
        label = "Tooltip",
        id = "editor_tooltip",
        onchange = function(color)
            local shadowColor = ShiftColor(color, -100, -90, -32)
            local cornerShadowColor = ShiftColor(color, -125, -152, -94)

            Theme.colors["editor_tooltip_shadow"] = shadowColor
            Theme.colors["editor_tooltip_corner_shadow"] = cornerShadowColor
        end
    }

    self.dialog --
    :color{
        id = "editor_cursor",
        label = "Cursor",
        color = Theme.colors["editor_cursor"],
        onchange = function() self:ChangeCursorColors() end
    } --
    :color{
        id = "editor_cursor_outline",
        color = Theme.colors["editor_cursor_outline"],
        onchange = function() self:ChangeCursorColors() end
    }

    self.dialog:separator{text = "Button"}

    self:ThemeColor{id = "button_highlight", visible = false}
    self:ThemeColor{id = "button_background", visible = false}
    self:ThemeColor{id = "button_shadow", visible = false}

    self.dialog:color{
        id = "simple-button",
        color = Theme.colors["button_background"],
        onchange = function()
            local color = self.dialog.data["simple-button"]
            local highlightColor = ShiftColor(color, 57, 57, 57)
            local shadowColor = ShiftColor(color, -74, -74, -74)

            self:SetThemeColor("button_highlight", highlightColor)
            self:SetThemeColor("button_background", color)
            self:SetThemeColor("button_shadow", shadowColor)

            self:MarkThemeAsModified()
        end
    }

    self:ThemeColor{label = "Selected", id = "button_selected", visible = true}

    self.dialog:separator{text = "Tab"}

    self:ThemeColor{id = "tab_corner_highlight", visible = false}
    self:ThemeColor{id = "tab_highlight", visible = false}
    self:ThemeColor{id = "tab_background", visible = false}
    self:ThemeColor{id = "tab_shadow", visible = false}

    self.dialog:color{
        id = "simple-tab",
        color = Theme.colors["tab_background"],
        onchange = function()
            local color = self.dialog.data["simple-tab"]
            local cornerHighlightColor = ShiftColor(color, 131, 110, 98)
            local highlightColor = ShiftColor(color, 49, 57, 65)
            local shadowColor = ShiftColor(color, -24, -61, -61)

            self:SetThemeColor("tab_corner_highlight", cornerHighlightColor)
            self:SetThemeColor("tab_highlight", highlightColor)
            self:SetThemeColor("tab_background", color)
            self:SetThemeColor("tab_shadow", shadowColor)

            self:MarkThemeAsModified()
        end
    }

    self.dialog:separator{text = "Window"}

    self:ThemeColor{
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

    self:ThemeColor{id = "window_background", visible = false}

    self:ThemeColor{
        id = "window_shadow",
        visible = false,
        onchange = function(color)
            local cornerShadowColor = ShiftColor(color, -49, -44, -20)
            self:SetThemeColor("window_corner_shadow", cornerShadowColor)
        end
    }

    self.dialog:color{
        id = "simple-window",
        color = Theme.colors["window_background"],
        onchange = function()
            local color = self.dialog.data["simple-window"]
            local highlightColor = ShiftColor(color, 45, 54, 66)
            local shadowColor = ShiftColor(color, -61, -73, -73)
            local cornerShadowColor = ShiftColor(color, -110, -117, -93)

            self:SetThemeColor("window_highlight", highlightColor)
            self:SetThemeColor("window_background", color)
            self:SetThemeColor("window_shadow", shadowColor)
            self:SetThemeColor("window_corner_shadow", cornerShadowColor)

            -- FUTURE: Remove this when setting a separate value for the "field_background" is possible

            local fieldShadowColor = ShiftColor(highlightColor, -57, -57, -57)
            local filedCornerShadowColor =
                ShiftColor(highlightColor, -74, -74, -74)

            Theme.colors["field_background"] = highlightColor
            Theme.colors["field_shadow"] = fieldShadowColor
            Theme.colors["field_corner_shadow"] = filedCornerShadowColor

            self:MarkThemeAsModified()
        end
    } --

    self:ThemeColor{label = "Hover", id = "window_hover", visible = true}

    self.dialog --
    :separator() --
    :button{
        id = "save-configuration",
        label = "Configuration",
        text = "Save",
        enabled = false,
        onclick = function()
            local onsave = function(theme)
                self.dialog:modify{title = DIALOG_TITLE .. ": " .. theme.name}
                self.dialog:modify{id = "save-configuration", enabled = false}

                self.isModified = false
                self.lastRefreshState = false
            end

            ThemeManager:Save(Theme, onsave)
        end
    } --
    :button{
        text = "Load",
        onclick = function()
            local onload = function(theme)
                self:LoadTheme(theme)
                self:Refresh()
            end

            local onreset = function()
                self:LoadTheme(Template)
                self:Refresh()
            end

            ThemeManager:Load(onload, onreset)
        end
    } --

    self.dialog --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            self:Refresh()
            self.dialog:close()
        end
    } --
    :button{text = "Apply", onclick = function() self:Refresh() end} -- 
    :button{text = "Cancel", onclick = function() self.dialog:close() end} --
end

ThemePreferencesDialog:Init()

function init(plugin)
    -- Initialize a table in preferences to persist data
    plugin.preferences.themePreferences =
        plugin.preferences.themePreferences or {
            savedThemes = {
                "<Peach:1:A:////6MbGnnx8eGBQ////98vfxpKerlVh/+u2////0sq9lYF0ZFVgAgIC/f39/0wA/0wA/1dX////xsbGtbW1ZVVhQUEs/wB9mwBdggAf/v//f39/AQAAAQEB>",
                "<Garden:1:B:////3u7T/5wAaseC7f//8cq9aseCUnNh/+u2////8cq9tIF0g1VgAAAA////ATskATsk/5wA////xsbGtbW1YGBgPEwr/5wAm0IAggQA/v///s1//5wAATsk>",
                "<Blue:1:A:////5ubmnJyceGBQ6O//lrr/ZYHNTUSQ/+u26fL+vLy8f3NzTkdfAAAA////S1r/S1r/AM3/6fL+sLnFn6i0TExMKDgXAM3/AHPfADWhAAAAcH9/4P//AAFV>",
                "<Professional:1:A:////4ODglpaW/4AA////0dnhoKCgiGNj4ODg7fb/wMDAg3d3UktjICAg////QEBAQEBA/4AA7fb/tL3Go6y1QEBAHCwL/4AAmyYAggAA////f39/AAAAICAg>",
                "<Eva:1:B:////zc3Ng4OD/74t/9H/rpzffWOeZSZh/74tkOqAwMDAOm5ZCUJFAAAA////kOqAOm5ZOm5ZkOqAV7FHRqA2XFxcOEgnkOqALJBgE1IiAAAASHVAkOqAAQEB>",
                "<Orange:1:B:////xsbG/4AAeGBQ/8eR/4AAaGhodysr/+u2////0sq9lYF0ZFVgAgIC/f39/1cA/1cA/1cA////xsbGtbW1UFBQLDwb/8eRm21xgi8z/4AA/79/////AQEB>",
                "<Magic:1:B:////zMzMMbnBAICAg+7iMbnBAICAAENDoKCg7fb/wMDAAICAAFRsAgIC/f39/wD//wD//wD/7fb/tL3Go6y1YGBgPEwr/wD/mwDfggCh/v///n///wD/AQEB>",
                "<Game Boy:1:B:4PjQiMBwNGhWNGhW4PjQiMBwNGhWCBgg4PjQ4PjQiMBwNGhWAzxCCBgg4PjQ4PjQNGhWNGhW4PjQp7+Xlq6GCBggAAQA4PjQfJ6wY2By4PjQdIh4CBggCBgg>",
                "<Warm:1:A:///jz8aqhXxgeGBQ//jezcO9nIp8hE0//+u2////0sq9lYF0ZFVgAgIC/f39QW4ZQW4Z/3sk////xsbGtbW1XFxcOEgn//99fZKdgmcf/v//n7aMQW4ZAQEB>",
                "<Dark:1:B:iYmJYWFhFxcXEiE7KXf/AEnHMzMzEiE7AEnHYGBgUFBQICAgAAAMwMDA////ALTmALTmKXf/YGBgJycnFhYWAAAAAAAAKXf/AB3fAACh////lLv/KXf/AAAA>"
            },
            currentTheme = "<Default:1:A:////xsbGfHx8eGBQ////rsvffZKeZVVh/+u2////0sq9lYF0ZFVgAgIC/f39LEyRLEyR/1dX////xsbGtbW1ZVVhQUEs//99m6Vdgmcf/v//e3x8AQAAAQEB>"
        }
    local storage = plugin.preferences.themePreferences

    -- Initialize a table in prefereces to save themes
    if storage.savedThemes == nil then storage.savedThemes = {} end

    ThemeManager:Init{storage = storage}

    -- Initialize data from plugin preferences
    ThemePreferencesDialog:LoadCurrentTheme()
    ThemePreferencesDialog.isModified = plugin.preferences.themePreferences
                                            .isThemeModified
    if ThemePreferencesDialog.isModified then
        ThemePreferencesDialog:MarkThemeAsModified()
    end

    -- Treat the "Modified" state as the last known refresh state 
    ThemePreferencesDialog.lastRefreshState = ThemePreferencesDialog.isModified

    -- Setup function to be called on close
    ThemePreferencesDialog.onClose = function()
        ThemePreferencesDialog:LoadCurrentTheme()

        ThemePreferencesDialog.isModified =
            ThemePreferencesDialog.lastRefreshState
        if ThemePreferencesDialog.isModified then
            ThemePreferencesDialog:MarkThemeAsModified()
        end

        ThemePreferencesDialog.isDialogOpen = false
    end

    -- Set the initial width of the dialog
    ThemePreferencesDialog:SetInitialWidth()

    plugin:newCommand{
        id = "ThemePreferences",
        title = DIALOG_TITLE .. "...",
        group = "view_screen",
        onenabled = function()
            return not ThemePreferencesDialog.isDialogOpen
        end,
        onclick = function()
            -- Refreshing the UI on open to fix the issue where the dialog would keep parts of the old theme
            app.command.Refresh()

            -- Show Theme Preferences dialog
            ThemePreferencesDialog.dialog:show{wait = false}

            -- Treat the "Modified" state as the last known refresh state 
            ThemePreferencesDialog.lastRefreshState =
                ThemePreferencesDialog.isModified

            -- Update the dialog if the theme is modified
            if ThemePreferencesDialog.isModified then
                ThemePreferencesDialog:MarkThemeAsModified()
            end

            ThemePreferencesDialog.isDialogOpen = true
        end
    }
end

function exit(plugin)
    plugin.preferences.themePreferences.isThemeModified =
        ThemePreferencesDialog.isModified
end
