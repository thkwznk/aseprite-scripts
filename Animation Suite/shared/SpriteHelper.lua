local SpriteHelper = {}

function SpriteHelper:GetLayerNames(sprite)
    local layerNames = {}

    for _, layer in ipairs(sprite.layers) do
        -- TODO: Handle groups in the future
        if not layer.isGroup then table.insert(layerNames, layer.name) end
    end

    return layerNames
end

function SpriteHelper:GetLayerByName(sprite, layerName)
    for _, layer in ipairs(sprite.layers) do
        -- TODO: Handle groups in the future
        if layer.name == layerName then return layer end
    end
end

function SpriteHelper:GetTagNames(sprite)
    local tagNames = {}

    for _, tag in ipairs(sprite.tags) do table.insert(tagNames, tag.name) end

    return tagNames
end

function SpriteHelper:GetTagByName(sprite, tagName)
    for _, tag in ipairs(sprite.tags) do
        if tag.name == tagName then return tag end
    end
end

return SpriteHelper
