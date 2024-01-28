local Template = dofile("./Template.lua")
local ThemeManager = dofile("./ThemeManager.lua")
local FontsProvider = dofile("./FontsProvider.lua")
local ThemePreferencesDialog = dofile("./ThemePreferencesDialog.lua")

local THEME_ID = "custom"
local DIALOG_WIDTH = 240

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

-- Start from the template
local Theme = Template()
local IsDialogOpen = false

function RefreshTheme(theme)
    local template = Template()
    -- Prepare color lookup
    local map = {}

    for id, templateColor in pairs(template.colors) do
        -- Map the template color to the theme color
        local r = templateColor.red
        local g = templateColor.green
        local b = templateColor.blue

        if not map[r] then map[r] = {} end
        if not map[r][g] then map[r][g] = {} end
        map[r][g][b] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = SheetTemplatePath}

    -- Save references to function to improve performance
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local pixelValue = getPixel(image, x, y)

            if pixelValue > 0 then
                local r = app.pixelColor.rgbaR(pixelValue)

                if map[r] then
                    local g = app.pixelColor.rgbaG(pixelValue)

                    if map[r][g] then
                        local b = app.pixelColor.rgbaB(pixelValue)

                        if map[r][g][b] then
                            local themeColor = map[r][g][b]

                            drawPixel(image, x, y, Color {
                                red = themeColor.red,
                                green = themeColor.green,
                                blue = themeColor.blue,
                                -- Restore the original alpha value
                                alpha = app.pixelColor.rgbaA(pixelValue)
                            })
                        end
                    end
                end
            end
        end
    end

    image:saveAs(SheetPath)

    -- Update the XML theme file
    UpdateThemeXml(theme)

    app.command.Refresh()
end

function UpdateThemeXml(theme)
    -- Prepare theme.xml
    local xmlContent = ReadAll(ThemeXmlTemplatePath)

    for id, color in pairs(theme.colors) do
        xmlContent = xmlContent:gsub("<" .. id .. ">", ColorToHex(color))
    end

    local font = FontsProvider:GetCurrentFont()

    -- Setting fonts for these just in case it's a system font
    xmlContent = xmlContent:gsub("<system_font_default>",
                                 FontsProvider:GetFontDeclaration(font.default))
    xmlContent = xmlContent:gsub("<default_font>", font.default.name)
    xmlContent = xmlContent:gsub("<default_font_size>", font.default.size)

    xmlContent = xmlContent:gsub("<system_font_mini>",
                                 FontsProvider:GetFontDeclaration(font.mini))
    xmlContent = xmlContent:gsub("<mini_font>", font.mini.name)
    xmlContent = xmlContent:gsub("<mini_font_size>", font.mini.size)

    -- TODO: If using system fonts - ask user if they want to switch default scaling percentages

    WriteAll(ThemeXmlPath, xmlContent)
end

function Refresh()
    RefreshTheme(Theme)
    ThemeManager:SetCurrentTheme(Theme)

    -- Switch Aseprite to the custom theme
    if app.preferences.theme.selected ~= THEME_ID then
        app.preferences.theme.selected = THEME_ID
    end
end

function LoadTheme(theme, stopRefresh)
    Theme = theme
    IsModified = false

    if not stopRefresh then Refresh() end
end

function CopyToTheme(colors, parameters)
    -- Copy new colors
    for key, _ in pairs(Theme.colors) do
        if colors[key] then Theme.colors[key] = colors[key] end
    end

    -- Copy new parameters
    for key, _ in pairs(Theme.parameters) do
        if parameters[key] ~= nil then
            Theme.parameters[key] = parameters[key]
        end
    end

    IsModified = parameters.isModified
end

function init(plugin)
    -- Do nothing when UI is not available
    if not app.isUIAvailable then return end

    -- Initialize plugin preferences data for backwards compatibility
    plugin.preferences.themePreferences =
        plugin.preferences.themePreferences or {}
    local storage = plugin.preferences.themePreferences

    -- Initialize data from plugin preferences
    ThemeManager:Init{storage = storage}
    Theme = ThemeManager:GetCurrentTheme() or Theme

    FontsProvider:Init{storage = storage}
    IsModified = storage.isThemeModified

    plugin:newCommand{
        id = "ThemePreferencesNew",
        title = "Theme Preferences...",
        group = "view_screen",
        onenabled = function() return not IsDialogOpen end,
        onclick = function()
            local dialog = nil
            local CreateDialog = nil

            local onsave = function(colors, parameters, onSuccessDialog)
                local onsuccess = function(theme)
                    -- Pass the saved theme to the dialog to update the window title
                    onSuccessDialog(theme)
                    IsModified = false
                end

                CopyToTheme(colors, parameters)
                ThemeManager:Save(Theme, onsuccess)
            end

            local onload = function()
                local onload = function(theme) LoadTheme(theme) end
                local onreset = function() LoadTheme(Template()) end

                -- Hide the Theme Preferences dialog
                dialog:close()

                ThemeManager:Load(onload, onreset)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onfont = function()
                local onconfirm = function() Refresh() end

                -- Hide the Theme Preferences dialog
                dialog:close()

                FontsProvider:OpenDialog(onconfirm)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onok = function(colors, parameters)
                CopyToTheme(colors, parameters)
                Refresh()
            end

            CreateDialog = function()
                local newDialog = ThemePreferencesDialog {
                    name = Theme.name,
                    colors = Theme.colors,
                    parameters = Theme.parameters,
                    isModified = IsModified,
                    onclose = function() IsDialogOpen = false end,
                    onsave = onsave,
                    onload = onload,
                    onfont = onfont,
                    onok = onok
                }

                newDialog:show{wait = false}
                return newDialog
            end

            dialog = CreateDialog()
            IsDialogOpen = true
        end
    }
end

function exit(plugin)
    plugin.preferences.themePreferences.isThemeModified = IsModified
end
