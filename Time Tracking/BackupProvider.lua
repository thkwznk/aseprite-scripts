local ExtensionsDirectory = app.fs.joinPath(app.fs.userConfigPath, "extensions")
local TimeTrackingDirectory = app.fs.joinPath(ExtensionsDirectory,
                                              "time-tracking")
local TempFilePath = app.fs.joinPath(TimeTrackingDirectory, "tmp.json")

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

local BackupProvider = {}

function BackupProvider:Save(data)
    local encodedData = json.encode(data)
    WriteAll(TempFilePath, encodedData)
end

function BackupProvider:Load()
    local tempFileContent = ReadAll(TempFilePath)
    local decodedData = json.decode(tempFileContent)
    return decodedData
end

return BackupProvider

-- TODO: Verify Aseprite version for the json namespace
