local Template = dofile("./Template.lua")()

local CODE_VERSION = 2
local START_CHARACTER = "<"
local LAST_CHARACTER = ">"
local SPLIT_CHARACTER = ":"

local Base64ThemeEncoder = {
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',
    colorIds = {
        -- Button
        "button_highlight", --
        "button_background", --
        "button_shadow", --
        "button_selected", --
        -- Tab
        "tab_corner_highlight", --
        "tab_highlight", --
        "tab_background", --
        "tab_shadow", --
        -- Window
        "window_hover", --
        "window_highlight", --
        "window_background", --
        "window_shadow", --
        "window_corner_shadow", --
        -- Text
        "text_regular", --
        "text_active", --
        "text_link", --
        "text_separator", --
        -- Field
        "field_highlight", --
        "field_background", --
        "field_shadow", --
        "field_corner_shadow", --
        -- Editor
        "editor_background", --
        "editor_background_shadow", --
        "editor_tooltip", --
        "editor_tooltip_shadow", --
        "editor_tooltip_corner_shadow", --
        "editor_cursor", --
        "editor_cursor_shadow", --
        "editor_cursor_outline", --
        "editor_icons", --
        -- Outline
        "outline", --
        -- Window Title Bar
        "window_title_bar_corner_highlight", --
        "window_title_bar_highlight", --
        "window_title_bar_background", --
        "window_title_bar_shadow"
    }
}

function Base64ThemeEncoder:NumberToBinaryString(x, legth)
    local result = ""
    while x ~= 1 and x ~= 0 do
        result = tostring(x % 2) .. result
        x = math.modf(x / 2)
    end
    result = tostring(x) .. result

    while legth and #result < legth do result = "0" .. result end

    return result
end

function Base64ThemeEncoder:NumberToBase64(x)
    if x == 0 then return self.alphabet:sub(1, 1) end

    local remainder = x
    local result = ""

    while remainder > 0 do
        local part = remainder % 64
        remainder = (remainder - part) / 64

        result = self.alphabet:sub(part + 1, part + 1) .. result
    end

    return result
end

function Base64ThemeEncoder:Base64ToNumber(x)
    local result = 0

    for i = 1, #x do
        local character = x:sub(i, i)
        local xyz = string.find(self.alphabet, character) - 1

        result = result + (xyz * (64 ^ (#x - i)))
    end

    return math.floor(result)
end

function Base64ThemeEncoder:ColorToRgbBinary(color)
    return self:NumberToBinaryString(color.red, 8) ..
               self:NumberToBinaryString(color.green, 8) ..
               self:NumberToBinaryString(color.blue, 8)
end

function Base64ThemeEncoder:RgbBinaryToColor(n)
    return Color {
        red = tonumber(n:sub(1, 8), 2),
        green = tonumber(n:sub(9, 16), 2),
        blue = tonumber(n:sub(17, 24), 2),
        alpha = 255
    }
end

function Base64ThemeEncoder:EncodeColor(color)
    local rgbBinary = self:ColorToRgbBinary(color)
    local rgbNumber = tonumber(rgbBinary, 2)
    local rgbEncoded = self:NumberToBase64(rgbNumber)

    while #rgbEncoded < 4 do
        rgbEncoded = self.alphabet:sub(1, 1) .. rgbEncoded
    end

    return rgbEncoded
end

function Base64ThemeEncoder:DecodeColor(encodedColor)
    local rgbNumber = math.floor(self:Base64ToNumber(encodedColor))
    local rgbBinary = self:NumberToBinaryString(rgbNumber, 24)
    local decodedColor = self:RgbBinaryToColor(rgbBinary)

    return decodedColor
end

function Base64ThemeEncoder:EncodeSigned(name, parameters, colors)
    -- Validate name
    if #name == 0 or #name > 32 then return end

    local encodedParameters = self:EncodeParameters(parameters)
    local encodedColors = self:EncodeColors(colors)

    -- <THEME_NAME:CODE_VERSION:ENCODED_PARAMS:ENCODED_COLORS>
    return START_CHARACTER .. name .. SPLIT_CHARACTER .. CODE_VERSION ..
               SPLIT_CHARACTER .. encodedParameters .. SPLIT_CHARACTER ..
               encodedColors .. LAST_CHARACTER
end

function Base64ThemeEncoder:EncodeParameters(parameters)
    local advancedFlag = parameters.isAdvanced and "1" or "0"

    local parametersBinary = advancedFlag
    local parametersNumber = tonumber(parametersBinary, 2)
    local result = self:NumberToBase64(parametersNumber)

    return result
end

function Base64ThemeEncoder:EncodeColors(colors)
    local result = ""

    for _, id in ipairs(self.colorIds) do
        result = result ..
                     self:EncodeColor(
                         colors[id] or self:GetDefaultColor(id, colors))
    end

    return result
end

function Base64ThemeEncoder:SplitString(string, separator)
    local result = {}

    local partial = ""
    for i = 1, #string do
        local c = string:sub(i, i)
        if c ~= separator then
            partial = partial .. c
        else
            table.insert(result, partial)
            partial = ""
        end
    end

    if #partial > 0 then table.insert(result, partial) end

    return result
end

function Base64ThemeEncoder:DecodeSigned(code)
    if code == nil or #code == 0 then return end

    local startIndex = code:find(START_CHARACTER)
    if startIndex == nil then return end

    local lastIndex = code:find(LAST_CHARACTER)
    if lastIndex == nil then return end

    local trimmedSignedCode = code:sub(startIndex + 1, lastIndex - 1)
    local codeSplit = self:SplitString(trimmedSignedCode, SPLIT_CHARACTER)
    if #codeSplit ~= 4 then return nil end

    local name = codeSplit[1]
    local version = codeSplit[2]
    local encodedParams = codeSplit[3]
    local encodedColors = codeSplit[4]

    local parameters = self:DecodeParameters(version, encodedParams)
    local colors = self:DecodeColors(version, encodedColors)

    return {name = name, parameters = parameters, colors = colors}
end

function Base64ThemeEncoder:DecodeParameters(version, encodedParameters)
    -- FUTURE: Update parameters depending on the version
    _ = version

    -- FUTURE: This will depend on version
    local expectedBinaryLength = 1

    local parametersNumber = self:Base64ToNumber(encodedParameters)
    local parametersBinary = self:NumberToBinaryString(parametersNumber,
                                                       expectedBinaryLength)

    local advancedFlag = parametersBinary:sub(1, 1)

    local parameters = {isAdvanced = advancedFlag == "1"}

    return parameters
end

function Base64ThemeEncoder:DecodeColors(version, encodedColors)
    -- FUTURE: Update colors depending on the version
    _ = version

    local decodedColors = {}

    for i = 1, #encodedColors, 4 do
        local encodedColor = encodedColors:sub(i, i + 3)
        table.insert(decodedColors, self:DecodeColor(encodedColor))
    end

    local colors = {}
    for i, id in ipairs(self.colorIds) do
        colors[id] = decodedColors[i] or self:GetDefaultColor(id, colors)
    end

    return colors
end

function Base64ThemeEncoder:DecodeName(code)
    if code == nil or #code == 0 then return end

    local startIndex = code:find(START_CHARACTER)
    if startIndex == nil then return end

    local lastIndex = code:find(LAST_CHARACTER)
    if lastIndex == nil then return end

    local trimmedSignedCode = code:sub(startIndex + 1, lastIndex - 1)
    local codeSplit = self:SplitString(trimmedSignedCode, SPLIT_CHARACTER)
    if #codeSplit ~= 4 then return nil end

    local name = codeSplit[1]

    return name
end

function Base64ThemeEncoder:GetDefaultColor(id, colors)
    if id == "outline" then return Template.colors[id] end

    if id == "window_title_bar_corner_highlight" then
        return colors["tab_corner_highlight"]
    end

    if id == "window_title_bar_highlight" then return colors["tab_highlight"] end

    if id == "window_title_bar_background" then
        return colors["tab_background"]
    end

    if id == "window_title_bar_shadow" then return colors["tab_shadow"] end
end

return Base64ThemeEncoder
