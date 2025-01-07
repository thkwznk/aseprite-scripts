local RegularMode = dofile("./modes/RegularMode.lua")
local GraffitiMode = dofile("./modes/GraffitiMode.lua")
local OutlineMode = dofile("./modes/OutlineMode.lua")
local OutlineLiveMode = dofile("./modes/OutlineLiveMode.lua")
local CutMode = dofile("./modes/CutMode.lua")
local SelectionMode = dofile("./modes/SelectionMode.lua")
local YeetMode = dofile("./modes/YeetMode.lua")
local ColorizeMode = dofile("./modes/ColorizeMode.lua")
local DesaturateMode = dofile("./modes/DesaturateMode.lua")
local ShiftMode = dofile("./modes/ShiftMode.lua")

local MixModes = dofile("./modes/MixMode.lua")

local ModeProcessorProvider = {
    modes = {
        ["RegularMode"] = RegularMode,
        ["GraffitiMode"] = GraffitiMode,
        ["OutlineMode"] = OutlineMode,
        ["OutlineLiveMode"] = OutlineLiveMode,
        ["CutMode"] = CutMode,
        ["SelectionMode"] = SelectionMode,
        ["YeetMode"] = YeetMode,
        ["ColorizeMode"] = ColorizeMode,
        ["DesaturateMode"] = DesaturateMode,
        ["ShiftMode"] = ShiftMode
    }
}

-- Add variants
for _, mixVariant in ipairs(MixModes) do
    ModeProcessorProvider.modes[mixVariant.variantId] = mixVariant
end

function ModeProcessorProvider:Get(modeId) return self.modes[modeId] end

return ModeProcessorProvider
