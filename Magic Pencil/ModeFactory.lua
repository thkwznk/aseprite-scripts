local ModeFactory = {modes = {}}

function ModeFactory:Init(modesDirectoryPath)
    -- Load all modes from a given directory
    local files = app.fs.listFiles(modesDirectoryPath)

    for _, filePath in ipairs(files) do
        if self:_IsModeFile(filePath) then
            local modePath = app.fs.joinPath(modesDirectoryPath, filePath)
            local modeId = app.fs.fileTitle(filePath)
            local mode = dofile(modePath)

            self.modes[modeId] = mode
        end
    end
end

function ModeFactory:_IsModeFile(filePath)
    local modeSuffix = "Mode.lua"

    return string.sub(filePath, #filePath - (#modeSuffix - 1)) == modeSuffix
end

function ModeFactory:Create(modeId) return self.modes[modeId] end

return ModeFactory
