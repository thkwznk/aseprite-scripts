local Hash = dofile("./Hash.lua")
local Tab = dofile("./Tab.lua")

local Preferences = {dataStorage = nil}

function Preferences:Init(pluginPreferences) self.dataStorage =
    pluginPreferences end

function Preferences:GetSelectedTab(sprite)
    if sprite == nil then return Tab.Session end

    local id = Hash(sprite.filename)
    local data = self.dataStorage[id]
    if data == nil then return Tab.Session end
    if data.tab == nil then data.tab = Tab.Session end

    return data.tab
end

function Preferences:UpdateSelectedTab(sprite, tab)
    if sprite == nil then return end

    local id = Hash(sprite.filename)
    local data = self.dataStorage[id]
    if data == nil then return end

    data.tab = tab
end

return Preferences
