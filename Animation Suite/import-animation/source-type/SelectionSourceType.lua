local SelectionSourceType = {
    sourceSprite = nil,
    frameWidth = nil,
    frameHeight = nil
}

function SelectionSourceType:SetSourceDialogSection(sprite, dialog, onchange,
                                                    onrelease)
    if self.sourceSprite ~= sprite then self:Clear() end

    self.sourceSprite = self.sourceSprite or sprite
    self.frameWidth = self.frameWidth or sprite.selection.bounds.height
    self.frameHeight = self.frameHeight or sprite.selection.bounds.height

    dialog:slider{
        id = "source-frame-width",
        label = "Frame Width",
        min = 1,
        max = sprite.selection.bounds.width,
        value = self.frameWidth,
        onchange = function()
            self.frameWidth = dialog.data["source-frame-width"]
            onchange()
        end,
        onrelease = onrelease
    } --
    :slider{
        id = "source-frame-height",
        label = "Frame Height",
        min = 1,
        max = sprite.selection.bounds.height,
        value = self.frameHeight,
        onchange = function()
            self.frameHeight = dialog.data["source-frame-height"]
            onchange()
        end,
        onrelease = onrelease
    }
end

function SelectionSourceType:GetSourceParams()
    return {Frame = {width = self.frameWidth, height = self.frameHeight}}
end

function SelectionSourceType:GetSourceSize()
    return {width = self.frameWidth, height = self.frameHeight}
end

function SelectionSourceType:Clear()
    self.sourceSprite = nil
    self.frameWidth = nil
    self.frameHeight = nil
end

return SelectionSourceType
