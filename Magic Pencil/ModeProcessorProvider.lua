local RegularMode = dofile("./modes/RegularMode.lua")
local GraffitiMode = dofile("./modes/GraffitiMode.lua")
local OutlineMode = dofile("./modes/OutlineMode.lua")
local OutlineLiveMode = dofile("./modes/OutlineLiveMode.lua")
local CutMode = dofile("./modes/CutMode.lua")
local MergeMode = dofile("./modes/MergeMode.lua")
local SelectionMode = dofile("./modes/SelectionMode.lua")
local ColorizeMode = dofile("./modes/ColorizeMode.lua")
local DesaturateMode = dofile("./modes/DesaturateMode.lua")
local ShiftMode = dofile("./modes/ShiftMode.lua")

local MixModes = dofile("./modes/MixMode.lua")

local Mode = dofile("./Mode.lua")

local ModeProcessorProvider = {
    modes = {
        [Mode.Regular] = RegularMode,
        [Mode.Graffiti] = GraffitiMode,
        [Mode.Outline] = OutlineMode,
        [Mode.OutlineLive] = OutlineLiveMode,
        [Mode.Cut] = CutMode,
        [Mode.Merge] = MergeMode,
        [Mode.Selection] = SelectionMode,
        [Mode.Colorize] = ColorizeMode,
        [Mode.Desaturate] = DesaturateMode,
        [Mode.Shift] = ShiftMode
    }
}

-- Add variants
for _, mixVariant in ipairs(MixModes) do
    ModeProcessorProvider.modes[mixVariant.variantId] = mixVariant
end

function ModeProcessorProvider:Get(modeId) return self.modes[modeId] end

return ModeProcessorProvider
