SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local TagSourceType = {sourceSprite = nil, tagNames = nil, selectedTag = nil}

function TagSourceType:SetSourceDialogSection(sprite, dialog, onchange)
    if self.sourceSprite ~= sprite then self:Clear() end

    self.sourceSprite = self.sourceSprite or sprite
    self.tagNames = self.tagNames or SpriteHelper:GetTagNames(self.sourceSprite)
    self.selectedTag = self.selectedTag or
                           (#self.tagNames > 0 and self.tagNames[1] or nil)

    dialog:combobox{
        id = "source-tag",
        label = "Tag",
        options = self.tagNames,
        option = self.selectedTag,
        onchange = function()
            self.selectedTag = dialog.data["source-tag"]
            onchange()
        end
    }
end

function TagSourceType:GetSourceParams() return {Tag = self.selectedTag} end

function TagSourceType:GetSourceSize()
    return {width = self.sourceSprite.width, height = self.sourceSprite.height}
end

function TagSourceType:Clear()
    self.sourceSprite = nil
    self.tagNames = nil
    self.selectedTag = nil
end

return TagSourceType
