local DefaultFont = {
    default = {name = "Aseprite"},
    mini = {name = "Aseprite Mini"}
}

local FontsProvider = {storage = nil, availableFonts = {}}

function FontsProvider:Init(options)
    self.storage = options.storage
    self.storage.font = self.storage.font or DefaultFont

    self:_RefreshAvailableFonts()
end

function FontsProvider:GetCurrentFont() return self.storage.font end

function FontsProvider:SetDefaultFont(fontName)
    self.storage.font.default = self.availableFonts[fontName]
end

function FontsProvider:SetMiniFont(fontName)
    self.storage.font.mini = self.availableFonts[fontName]
end

function FontsProvider:GetFontDeclaration(font)
    if not font.type or not font.file then return "" end

    return string.format("<font name=\"%s\" type=\"%s\" file=\"%s\" />",
                         font.name, font.type, font.file)
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

function FontsProvider:PrintFilesRecursively(path, fonts)
    local files = app.fs.listFiles(path)
    fonts = fonts or {}

    for _, file in ipairs(files) do
        local filePath = app.fs.joinPath(path, file)

        if app.fs.isDirectory(filePath) then
            self:PrintFilesRecursively(filePath, fonts)
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

    return self:PrintFilesRecursively(extensionsDirectory)
end

function FontsProvider:_GetSystemFonts()
    -- TODO: Pick directory based on the OS
    return self:PrintFilesRecursively("C:/Windows/Fonts")
end

return FontsProvider
