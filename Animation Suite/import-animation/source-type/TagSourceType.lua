SpriteHelper = dofile("../../shared/SpriteHelper.lua")

local TagSourceType = {sourceSprite = nil, tagNames = nil, selectedTag = nil}

function TagSourceType:SetSourceDialogSection(sprite, dialog, onchange)
    if self.sourceSprite ~= sprite then self:Clear() end

    self.sourceSprite = self.sourceSprite or sprite
    self.tagNames = self.tagNames or SpriteHelper:GetTagNames(self.sourceSprite)
    self.selectedTag = self.selectedTag or
                           (#self.tagNames > 0 and self.tagNames[1] or nil)
    self.flipHorizontal = self.flipHorizontal or false
    self.flipVertical = self.flipVertical or false

    dialog:combobox{
        id = "source-tag",
        label = "Tag",
        options = self.tagNames,
        option = self.selectedTag,
        onchange = function()
            self.selectedTag = dialog.data["source-tag"]
            onchange()
        end
    } --
    :check{
        id = "source-flip-horizontal",
        label = "Flip",
        text = "Horizontal",
        selected = self.flipHorizontal,
        onclick = function()
            self.flipHorizontal = dialog.data["source-flip-horizontal"]
            onchange()
        end
    } --
    :check{
        id = "source-flip-vertical",
        text = "Vertical",
        selected = self.flipVertical,
        onclick = function()
            self.flipVertical = dialog.data["source-flip-vertical"]
            onchange()
        end
    }
end

function TagSourceType:GetSourceParams()
    return {
        Tag = self.selectedTag,
        FlipHorizontal = self.flipHorizontal,
        FlipVertical = self.flipVertical
    }
end

function TagSourceType:GetSourceSize()
    return {width = self.sourceSprite.width, height = self.sourceSprite.height}
end

function TagSourceType:Clear()
    self.sourceSprite = nil
    self.tagNames = nil
    self.selectedTag = nil
end

return TagSourceType
