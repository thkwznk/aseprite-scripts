local Mode = dofile("./Mode.lua")
local RegularMode = dofile("./modes/RegularMode.lua")
local GraffitiMode = dofile("./modes/GraffitiMode.lua")
local OutlineLiveMode = dofile("./modes/OutlineLiveMode.lua")
local CutMode = dofile("./modes/CutMode.lua")
local MergeMode = dofile("./modes/MergeMode.lua")
local SelectionMode = dofile("./modes/SelectionMode.lua")
local MixMode = dofile("./modes/MixMode.lua")
local MixProportionalMode = dofile("./modes/MixProportionalMode.lua")
local OutlineMode = dofile("./modes/OutlineMode.lua")
local ColorizeMode = dofile("./modes/ColorizeMode.lua")
local DesaturateMode = dofile("./modes/DesaturateMode.lua")
local ShiftMode = dofile("./modes/ShiftMode.lua")

local ModeProcessorProvider = {
    modes = {
        [Mode.Regular] = RegularMode,

        [Mode.Graffiti] = GraffitiMode,
        [Mode.OutlineLive] = OutlineLiveMode,

        [Mode.Cut] = CutMode,
        [Mode.Merge] = MergeMode,
        [Mode.Selection] = SelectionMode,

        [Mode.Mix] = MixMode,
        [Mode.MixProportional] = MixProportionalMode,

        [Mode.Outline] = OutlineMode,
        [Mode.Colorize] = ColorizeMode,
        [Mode.Desaturate] = DesaturateMode,
        [Mode.Shift] = ShiftMode
    }
}

function ModeProcessorProvider:Get(modeId) return self.modes[modeId] end

return ModeProcessorProvider
