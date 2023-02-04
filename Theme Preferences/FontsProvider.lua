local DefaultFont = {
    default = {name = "Aseprite", size = "9"},
    mini = {name = "Aseprite Mini", size = "7"}
}
local FontSizes = {"6", "7", "8", "9", "10", "11", "12"}

local FontsProvider = {storage = nil, availableFonts = {}}

function FontsProvider:Init(options)
    self.storage = options.storage
    self.storage.font = self.storage.font or DefaultFont

    self:_RefreshAvailableFonts()
end

function FontsProvider:GetCurrentFont() return self.storage.font end

function FontsProvider:SetDefaultFont(fontName)
    if fontName == nil or #fontName == 0 then return end

    local newFont = self.availableFonts[fontName]
    if newFont == nil then return end

    self.storage.font.default.name = newFont.name
    self.storage.font.default.type = newFont.type
    self.storage.font.default.file = newFont.file
end

function FontsProvider:SetMiniFont(fontName)

    if fontName == nil or #fontName == 0 then return end

    local newFont = self.availableFonts[fontName]
    if newFont == nil then return end

    self.storage.font.mini.name = newFont.name
    self.storage.font.mini.type = newFont.type
    self.storage.font.mini.file = newFont.file
end

function FontsProvider:SetDefaultFontSize(fontSize)
    self.storage.font.default.size = fontSize
end

function FontsProvider:SetMiniFontSize(fontSize)
    self.storage.font.mini.size = fontSize
end

function FontsProvider:GetFontDeclaration(font)
    if not font.type or not font.file then return "" end

    return string.format("<font name=\"%s\" type=\"%s\" file=\"%s\" />",
                         font.name, font.type, font.file)
end

-- FUTURE: Revisit this, currently can cause issues and completely break the window layout rendering Aseprite unusable
function FontsProvider:VerifyScaling()
    local currentFont = self:GetCurrentFont()

    local isDefaultFontVector = currentFont.default.type == nil or
                                    currentFont.default.type ~= "spritesheet"
    local isMiniFontVector = currentFont.mini.type == nil or
                                 currentFont.mini.type == "spritesheet"

    if not isDefaultFontVector and not isMiniFontVector then return end

    local screenScale = app.preferences.general["screen_scale"]
    local uiScale = app.preferences.general["ui_scale"]

    if screenScale < uiScale then return end

    local userChoice = app.alert {
        title = "Warning",
        text = {
            "One of the selected fonts may appear blurry, switching UI and Screen Scaling may help.",
            "",
            "Current: Screen " .. tostring(screenScale * 100) .. "%, " .. "UI " ..
                tostring(uiScale * 100) .. "%",
            "Suggested: Screen " .. tostring(uiScale * 100) .. "%, " .. "UI " ..
                tostring(screenScale * 100) .. "%", "",
            "Would you like to switch?"
        },
        buttons = {"Yes", "No"}
    }

    if userChoice == 1 then -- Yes = 1
        app.preferences.general["screen_scale"] = uiScale
        app.preferences.general["ui_scale"] = screenScale

        app.alert {
            title = "Aseprite Restart Necessary",
            text = "Please restart Aseprite for the changes to be applied."
        }
    end
end

function FontsProvider:_ReadAll(filePath)
    local file = assert(io.open(filePath, "rb"))
    local content = file:read("*all")
    file:close()
    return content
end

function FontsProvider:_FindAll(content, pattern)
    local results = {}
    local start = 0
    while start ~= -1 do
        local matchStart = string.find(content, pattern, start)

        if not matchStart then break end
        matchStart = matchStart + #pattern

        local matchEnd = string.find(content, "\"", matchStart) - 1

        local name = string.sub(content, matchStart, matchEnd)
        table.insert(results, name)

        start = matchEnd
    end

    return results
end

function FontsProvider:GetFontsFromDirectory(path, fonts)
    local files = app.fs.listFiles(path)
    fonts = fonts or {}

    for _, file in ipairs(files) do
        local filePath = app.fs.joinPath(path, file)

        if app.fs.isDirectory(filePath) then
            self:GetFontsFromDirectory(filePath, fonts)
        elseif file == "fonts.xml" then
            local fileContent = ReadAll(filePath)
            local names = self:_FindAll(fileContent, "name=\"")

            for _, name in ipairs(names) do
                fonts[name] = {name = name}
            end
        elseif app.fs.fileExtension(filePath) == "ttf" then
            local name = app.fs.fileTitle(filePath)

            fonts[name] = {
                name = name,
                type = "truetype",
                file = app.fs.fileName(filePath)
            }
        end
    end

    return fonts
end

function FontsProvider:GetAvailableFontNames()
    if not self.availableFonts then self:_RefreshAvailableFonts() end

    local fontNames = {}

    for name, _ in pairs(self.availableFonts) do
        table.insert(fontNames, name)
    end

    table.sort(fontNames)

    return fontNames
end

function FontsProvider:_RefreshAvailableFonts()
    self.availableFonts = {}

    local systemFonts = self:_GetSystemFonts()
    for name, font in pairs(systemFonts) do self.availableFonts[name] = font end

    local declaredFonts = self:_GetDeclaredFonts()
    for name, font in pairs(declaredFonts) do
        self.availableFonts[name] = font
    end
end

function FontsProvider:_GetDeclaredFonts()
    local extensionsDirectory = app.fs.joinPath(app.fs.userConfigPath,
                                                "extensions")

    return self:GetFontsFromDirectory(extensionsDirectory)
end

function FontsProvider:_GetSystemFonts()
    local fontsDirectories = {
        "C:/Windows/Fonts", -- Windows
        "/Library/Fonts/", -- Mac
        "~/.fonts", "/usr/local/share/fonts", "/usr/share/fonts" -- Linux
    }

    local systemFonts = {}

    for _, fontsDirectory in ipairs(fontsDirectories) do
        if app.fs.isDirectory(fontsDirectory) then
            local fonts = self:GetFontsFromDirectory(fontsDirectory)

            for fontName, font in pairs(fonts) do
                systemFonts[fontName] = font
            end
        end
    end

    return systemFonts
end

function FontsProvider:OpenDialog(onconfirm)
    local dialog = Dialog("Font Configuration")

    local fontNames = self:GetAvailableFontNames()
    local currentFont = self:GetCurrentFont()

    local updateFonts = function()
        self:SetDefaultFontSize(dialog.data["default-font-size"])
        self:SetMiniFontSize(dialog.data["mini-font-size"])

        self:SetDefaultFont(dialog.data["default-font"])
        self:SetMiniFont(dialog.data["mini-font"])

        onconfirm()

        -- self:VerifyScaling()
    end

    dialog --
    :separator{text = "Default"} --
    :combobox{
        id = "default-font",
        label = "Name",
        option = currentFont.default.name,
        options = fontNames,
        onchange = function()
            local newFont = self.availableFonts[dialog.data["default-font"]]
            dialog:modify{
                id = "default-font-size",
                enabled = newFont.file ~= nil
            }
        end
    } --
    :combobox{
        id = "default-font-size",
        options = FontSizes,
        option = currentFont.default.size or DefaultFont.default.size,
        enabled = currentFont.default.file ~= nil,
        onchange = function()
            self:SetDefaultFontSize(dialog.data["default-font-size"])
        end
    } --
    :separator{text = "Mini"} --
    :combobox{
        id = "mini-font",
        label = "Name",
        option = currentFont.mini.name,
        options = fontNames,
        onchange = function()
            local newFont = self.availableFonts[dialog.data["mini-font"]]
            dialog:modify{id = "mini-font-size", enabled = newFont.file ~= nil}
        end
    } --
    :combobox{
        id = "mini-font-size",
        options = FontSizes,
        option = currentFont.mini.size or DefaultFont.mini.size,
        enabled = currentFont.mini.file ~= nil,
        onchange = function()
            self:SetMiniFontSize(dialog.data["mini-font-size"])
        end
    } --
    :separator() --
    :button{
        text = "Reset to Default",
        onclick = function()
            dialog --
            :modify{id = "default-font-size", option = DefaultFont.default.size} --
            :modify{id = "mini-font-size", option = DefaultFont.mini.size} --
            :modify{id = "default-font", option = DefaultFont.default.name} --
            :modify{id = "mini-font", option = DefaultFont.mini.name} --

            updateFonts()
        end
    } --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            updateFonts()
            dialog:close()
        end
    } --
    :button{text = "Apply", onclick = updateFonts} --
    :button{text = "Cancel"}

    dialog:show()
end

return FontsProvider
