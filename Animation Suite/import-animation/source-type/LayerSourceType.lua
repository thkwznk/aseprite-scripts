SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local LayerSourceType = {
    sourceSprite = nil,
    layerNames = nil,
    selectedLayer = nil
}

function LayerSourceType:SetSourceDialogSection(sprite, dialog, onchange)
    if self.sourceSprite ~= sprite then self:Clear() end

    self.sourceSprite = self.sourceSprite or sprite
    self.layerNames = self.layerNames or SpriteHelper:GetLayerNames(sprite)
    self.selectedLayer = self.selectedLayer or
                             (#self.layerNames > 0 and self.layerNames[1] or nil)

    dialog:combobox{
        id = "source-layer",
        label = "Layer",
        options = self.layerNames,
        option = self.selectedLayer,
        onchange = function()
            self.selectedLayer = dialog.data["source-layer"]
            onchange()
        end
    }
end

function LayerSourceType:GetSourceParams() return {Layer = self.selectedLayer} end

function LayerSourceType:GetSourceSize()
    return {width = self.sourceSprite.width, height = self.sourceSprite.height}
end

function LayerSourceType:Clear()
    self.sourceSprite = nil
    self.layerNames = nil
    self.selectedLayer = nil
end

return LayerSourceType
