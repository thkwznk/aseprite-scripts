dofile("./DeepCopy.lua")

local PresetProvider = {plugin = nil}

function PresetProvider:New(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PresetProvider:GetPresetNames()
    local presetNames = {}
    if self.plugin.preferences.presets == nil then return presetNames end

    for _, preset in ipairs(self.plugin.preferences.presets) do
        table.insert(presetNames, preset.name)
    end

    return presetNames
end

function PresetProvider:GetPresetByName(name)
    if self.plugin.preferences.presets == nil then return nil end

    for i, preset in ipairs(self.plugin.preferences.presets) do
        if preset.name == name then
            local presetCopy = deepcopy(preset)
            self:_ConvertRGBAPixelsToColors(presetCopy.outlineColors)

            for _, flatColors in ipairs(presetCopy.flatColors) do
                self:_ConvertRGBAPixelsToColors(flatColors)
            end

            return presetCopy
        end
    end
end

function PresetProvider:_ConvertColorsToRGBAPixels(colors)
    for i = 1, #colors do colors[i] = colors[i].rgbaPixel end
end

function PresetProvider:_ConvertRGBAPixelsToColors(rgbaPixels)
    for i = 1, #rgbaPixels do rgbaPixels[i] = Color(rgbaPixels[i]) end
end

function PresetProvider:SavePreset(preset)
    if self.plugin.preferences.presets == nil then
        self.plugin.preferences.presets = {}
    end

    local presetCopy = deepcopy(preset)

    -- Replace all colors with their "rgbaPixel" values, otherwise they won't serialize and won't load after restarting Aseprite
    self:_ConvertColorsToRGBAPixels(presetCopy.outlineColors)

    for _, flatColors in ipairs(presetCopy.flatColors) do
        self:_ConvertColorsToRGBAPixels(flatColors)
    end

    local presetOverridden = false

    for i, existingPreset in ipairs(self.plugin.preferences.presets) do
        if existingPreset.name == presetCopy.name then
            self.plugin.preferences.presets[i] = presetCopy
            presetOverridden = true
            break
        end
    end

    if not presetOverridden then
        table.insert(self.plugin.preferences.presets, presetCopy)
    end
end

function PresetProvider:DeleteProvider(name)
    if self.plugin.preferences.presets == nil then return end

    for i, preset in ipairs(self.plugin.preferences.presets) do
        if preset.name == name then
            table.remove(self.plugin.preferences.presets, i)
            break
        end
    end
end

return PresetProvider
