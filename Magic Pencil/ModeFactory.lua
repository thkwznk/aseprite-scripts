local RegularMode = dofile("./modes/RegularMode.lua")
local GraffitiMode = dofile("./modes/GraffitiMode.lua")
local OutlineMode = dofile("./modes/OutlineMode.lua")
local OutlineLiveMode = dofile("./modes/OutlineLiveMode.lua")
local CutMode = dofile("./modes/CutMode.lua")
local SelectionMode = dofile("./modes/SelectionMode.lua")
local YeetMode = dofile("./modes/YeetMode.lua")
local ColorizeMode = dofile("./modes/ColorizeMode.lua")
local DesaturateMode = dofile("./modes/DesaturateMode.lua")

local MixModes = dofile("./modes/MixMode.lua")
local ShifModes = dofile("./modes/ShiftMode.lua")

local ModeFactory = {modes = {}}

function ModeFactory:Init(modesDirectoryPath)
    -- Load all modes from a given directory
    -- local files = app.fs.listFiles(modesDirectoryPath)

    -- for _, filePath in ipairs(files) do
    --     if self:_IsModeFile(filePath) then
    --         local modePath = app.fs.joinPath(modesDirectoryPath, filePath)
    --         local modeId = app.fs.fileTitle(filePath)
    --         local mode = dofile(modePath)

    --         if #mode == 0 then
    --             self.modes[modeId] = mode
    --         else
    --             for _, modeVariant in ipairs(mode) do
    --                 self.modes[modeVariant.variantId] = modeVariant
    --             end
    --         end
    --     end
    -- end

    -- TODO: In some, rare, cases the above implementation doesn't work

    self.modes["RegularMode"] = RegularMode
    self.modes["GraffitiMode"] = GraffitiMode
    self.modes["OutlineMode"] = OutlineMode
    self.modes["OutlineLiveMode"] = OutlineLiveMode
    self.modes["CutMode"] = CutMode
    self.modes["SelectionMode"] = SelectionMode
    self.modes["YeetMode"] = YeetMode
    self.modes["ColorizeMode"] = ColorizeMode
    self.modes["DesaturateMode"] = DesaturateMode

    for _, mixVariant in ipairs(MixModes) do
        self.modes[mixVariant.variantId] = mixVariant
    end

    for _, mixVariant in ipairs(ShifModes) do
        self.modes[mixVariant.variantId] = mixVariant
    end
end

function ModeFactory:_IsModeFile(filePath)
    local modeSuffix = "Mode.lua"

    return string.sub(filePath, #filePath - (#modeSuffix - 1)) == modeSuffix
end

function ModeFactory:Create(modeId) return self.modes[modeId] end

return ModeFactory
