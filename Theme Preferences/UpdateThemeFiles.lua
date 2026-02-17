local CopyColor = dofile("./CopyColor.lua")
local Theme = dofile("./Theme.lua")

local ThemeTemplate = Theme()

local ExtensionsDirectory = app.fs.joinPath(app.fs.userConfigPath, "extensions")
local BaseDirectory = app.fs.joinPath(ExtensionsDirectory, "theme-preferences")

local Path = {
    SheetTemplate = app.fs.joinPath(BaseDirectory, "sheet-template.png"),
    Sheet = app.fs.joinPath(BaseDirectory, "sheet.png"),
    ThemeXmlTemplate = app.fs.joinPath(BaseDirectory, "theme-template.xml"),
    ThemeXml = app.fs.joinPath(BaseDirectory, "theme.xml")
}

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

local function UpdateThemeXml(theme)
    -- Prepare theme.xml
    local xmlContent = ReadAll(Path.ThemeXmlTemplate)

    for id, color in pairs(theme.colors) do
        xmlContent = xmlContent:gsub("<" .. id .. ">", ColorToHex(color))
    end

    WriteAll(Path.ThemeXml, xmlContent)
end

return function(theme)
    -- Prepare color lookup
    local Map = {}

    for id, templateColor in pairs(ThemeTemplate.colors) do
        -- Map the template color to the theme color
        Map[ColorToHex(templateColor)] = theme.colors[id]
    end

    -- Prepare sheet.png
    local image = Image {fromFile = Path.SheetTemplate}
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

    image:saveAs(Path.Sheet)

    -- Update the XML theme file
    UpdateThemeXml(theme)

    app.command.Refresh()
end
