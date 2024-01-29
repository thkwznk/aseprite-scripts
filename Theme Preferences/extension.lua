local Template = dofile("./Template.lua")
local ThemeManager = dofile("./ThemeManager.lua")
local FontsProvider = dofile("./FontsProvider.lua")
local ThemePreferencesDialog = dofile("./ThemePreferencesDialog.lua")

local THEME_ID = "custom"
local DialogSize = Size(240, 412)

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

function UpdateThemeSheet(theme)
    -- Prepare color lookup
    local map = {}
    local template = Template()

    for id, templateColor in pairs(template.colors) do
        map[templateColor.rgbaPixel] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = SheetTemplatePath}

    -- Save references to function to improve performance
    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local rgbaA = app.pixelColor.rgbaA
    local pixelValue, themeColor

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            pixelValue = getPixel(image, x, y)
            themeColor = map[pixelValue]

            if themeColor then
                drawPixel(image, x, y, Color {
                    red = themeColor.red,
                    green = themeColor.green,
                    blue = themeColor.blue,
                    -- Restore the original alpha value
                    alpha = rgbaA(pixelValue)
                })
            end
        end
    end

    image:saveAs(SheetPath)
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

function RefreshTheme()
    UpdateThemeSheet(Theme)
    UpdateThemeXml(Theme)

    -- Switch Aseprite to the custom theme
    app.preferences.theme.selected = THEME_ID

    -- Force refresh of the Aseprite UI to reload the theme
    app.command.Refresh()

    ThemeManager:SetCurrentTheme(Theme)
end

function LoadTheme(theme, stopRefresh)
    Theme = theme
    IsModified = false

    if not stopRefresh then RefreshTheme() end
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

function GetWindowSize()
    if app.apiVersion >= 25 then return app.window end

    local dialog = Dialog()
    dialog:show{wait = false}
    dialog:close()

    return Size(dialog.bounds.x * 2 + dialog.bounds.width,
                dialog.bounds.y * 2 + dialog.bounds.height)
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
                local onconfirm = function() RefreshTheme() end

                -- Hide the Theme Preferences dialog
                dialog:close()

                FontsProvider:OpenDialog(onconfirm)

                -- Reopen the dialog
                dialog = CreateDialog()
            end

            local onok = function(colors, parameters)
                CopyToTheme(colors, parameters)
                RefreshTheme()
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

                local window = GetWindowSize()
                local bounds = Rectangle((window.width - DialogSize.width) / 2,
                                         (window.height - DialogSize.height) / 2,
                                         DialogSize.width, DialogSize.height)

                newDialog:show{
                    wait = false,
                    bounds = bounds,
                    autoscrollbars = true
                }
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

-- TODO: Move all of the Refresh/Update theme logic to a separate file
