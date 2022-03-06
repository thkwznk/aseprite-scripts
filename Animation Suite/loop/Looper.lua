local Looper = {}

function Looper:Loop(sprite, layersToLoop, maxNumberOfFrames)
    local layers = self:_GetLayersToLoop(sprite, layersToLoop)
    local layerAnimationCels = self:_GetLayerAnimationCels(layers)

    while true do
        local notLoopedLayers = self:_GetNotLoopedLayers(sprite, layers)
        if #notLoopedLayers == 0 then break end

        for _, layer in ipairs(notLoopedLayers) do
            repeat
                local isDone = self:_RepeatAnimation(sprite, layer,
                                                     layerAnimationCels[layer],
                                                     maxNumberOfFrames)
            until isDone
        end

        if #sprite.frames > maxNumberOfFrames then break end
    end
end

function Looper:_GetLayersToLoop(sprite, layersToLoop)
    local layers = {}

    for _, layer in ipairs(sprite.layers) do
        -- Skip empty layers to avoid issues with calculations
        if #layer.cels == 0 then goto continue end

        for _, layerToLoop in pairs(layersToLoop) do
            if layer.name == layerToLoop then
                table.insert(layers, layer)
            end
        end

        ::continue::
    end

    return layers
end

function Looper:_GetLayerAnimationCels(layers)
    local layerAnimationCels = {}

    for _, layer in ipairs(layers) do
        local cels = {}
        for _, cel in ipairs(layer.cels) do table.insert(cels, cel) end

        layerAnimationCels[layer] = cels
    end

    return layerAnimationCels
end

function Looper:_GetNotLoopedLayers(sprite, layers)
    local result = {}

    for _, layer in ipairs(layers) do
        local lastFrameCel = layer:cel(#sprite.frames)
        if lastFrameCel == nil then table.insert(result, layer) end
    end

    return result
end

function Looper:_GetLastCelFrameNumber(layer)
    local frameNumber = -1
    for _, cel in ipairs(layer.cels) do frameNumber = cel.frameNumber end
    return frameNumber
end

function Looper:_RepeatAnimation(sprite, layer, animationCels, maxNumberOfFrames)
    local fromFrame = self:_GetLastCelFrameNumber(layer)
    local frameNumber = fromFrame

    for imageIndex = 1, #animationCels do
        frameNumber = fromFrame + imageIndex

        if frameNumber > maxNumberOfFrames then return true end
        if frameNumber > #sprite.frames then sprite:newEmptyFrame() end

        sprite:newCel(layer, frameNumber, animationCels[imageIndex].image,
                      animationCels[imageIndex].position)
    end

    return frameNumber == #sprite.frames
end

return Looper
