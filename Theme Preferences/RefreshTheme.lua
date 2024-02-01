local Template = dofile("./Template.lua")

local THEME_ID = "custom"

local ExtensionsDirectory = app.fs.joinPath(app.fs.userConfigPath, "extensions")
local ThemePreferencesDirectory = app.fs.joinPath(ExtensionsDirectory,
                                                  "theme-preferences")
local SheetTemplatePath = app.fs.joinPath(ThemePreferencesDirectory,
                                          "sheet-template.png")
local SheetPath = app.fs.joinPath(ThemePreferencesDirectory, "sheet.png")
local ThemeXmlTemplatePath = app.fs.joinPath(ThemePreferencesDirectory,
                                             "theme-template.xml")
local ThemeXmlPath = app.fs.joinPath(ThemePreferencesDirectory, "theme.xml")

function ColorToHex(color)
    return string.format("#%02x%02x%02x", color.red, color.green, color.blue)
end

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

function UpdateThemeSheet(template, theme)
    -- Prepare color lookup
    local map = {}

    for id, templateColor in pairs(template.colors) do
        map[templateColor.rgbaPixel] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = SheetTemplatePath}

    -- Save references to function to improve performance
    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local value, themeColor

    local pc = app.pixelColor
    local rgba, r, g, b, rgbaA = pc.rgba, pc.rgbaR, pc.rgbaG, pc.rgbaB, pc.rgbaA

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            value = getPixel(image, x, y)
            themeColor = map[rgba(r(value), g(value), b(value))]

            if themeColor then
                drawPixel(image, x, y, Color {
                    red = themeColor.red,
                    green = themeColor.green,
                    blue = themeColor.blue,
                    -- Restore the original alpha value
                    alpha = rgbaA(value)
                })
            end
        end
    end

    image:saveAs(SheetPath)
end

function FormatFontDeclaration(font)
    if not font.type or not font.file then return "" end

    return string.format("<font name=\"%s\" type=\"%s\" file=\"%s\" />",
                         font.name, font.type, font.file)
end

function UpdateThemeXml(template, theme, font)
    -- Prepare theme.xml
    local xmlContent = ReadAll(ThemeXmlTemplatePath)

    for id, _ in pairs(template.colors) do
        xmlContent = xmlContent:gsub("<" .. id .. ">",
                                     ColorToHex(theme.colors[id]))
    end

    -- Setting fonts for these just in case it's a system font
    xmlContent = xmlContent:gsub("<system_font_default>",
                                 FormatFontDeclaration(font.default))
    xmlContent = xmlContent:gsub("<default_font>", font.default.name)
    xmlContent = xmlContent:gsub("<default_font_size>", font.default.size)

    xmlContent = xmlContent:gsub("<system_font_mini>",
                                 FormatFontDeclaration(font.mini))
    xmlContent = xmlContent:gsub("<mini_font>", font.mini.name)
    xmlContent = xmlContent:gsub("<mini_font_size>", font.mini.size)

    -- TODO: If using system fonts - ask user if they want to switch default scaling percentages

    WriteAll(ThemeXmlPath, xmlContent)
end

return function(theme, font)
    local template = Template()

    UpdateThemeSheet(template, theme)
    UpdateThemeXml(template, theme, font)

    -- Switch Aseprite to the custom theme
    app.preferences.theme.selected = THEME_ID

    -- Force refresh of the Aseprite UI to reload the theme
    app.command.Refresh()
end
