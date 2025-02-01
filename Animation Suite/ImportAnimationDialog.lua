local SourceType = {Selection = "Selection", Layer = "Layer", Tag = "Tag"}

local function GetSpriteName(filename)
    return filename:match("^.+\\(.+)$") or filename
end

local function GetSprites()
    local spriteNames = {}
    local sprites = {}

    for _, sprite in ipairs(app.sprites) do
        local spriteName = GetSpriteName(sprite.filename)

        sprites[spriteName] = sprite
        table.insert(spriteNames, spriteName)
    end

    return spriteNames, sprites
end

return function(options)
    local sprite = app.activeSprite
    local dialog = Dialog {title = options.title}

    local spriteNames, sprites = GetSprites()

    dialog --
    :separator{text = "Source"} --
    :combobox{
        id = "source-sprite",
        label = "Sprite",
        options = spriteNames,
        option = GetSpriteName(app.activeSprite.filename),
        onchange = function()
            app.activeSprite = sprites[dialog.data["source-sprite"]]
        end
    } --
    :button{
        text = "&Open",
        onclick = function()
            app.command.OpenFile()

            -- Reload the list of sprites
            spriteNames, sprites = GetSprites()
            local activeSpriteName = GetSpriteName(app.activeSprite.filename)

            dialog:modify{
                id = "source-sprite",
                option = activeSpriteName,
                options = spriteNames
            }
        end
    }:combobox{
        id = "source-type",
        label = "From",
        options = SourceType,
        -- option = self.data.sourceType,
        onchange = function()
            -- self.data.sourceType = self.dialog.data["source-type"]
            -- self:_UpdateSourceType()
            -- self:Refresh()
        end
    } --

    -- TODO: Layers
    -- TODO: Tags
    -- TODO: Hide the Selection source if a sprite doesn't have a selection
    -- TODO: Hide the Tag source if a sprite doesn't have tags

    return dialog
end
