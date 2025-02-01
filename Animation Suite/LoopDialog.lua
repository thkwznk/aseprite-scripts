local function GetLayersToLoop(sprite, layersToLoop)
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

local function GetLayerAnimationCels(layers)
    local layerAnimationCels = {}

    for _, layer in ipairs(layers) do
        local cels = {}
        for _, cel in ipairs(layer.cels) do table.insert(cels, cel) end

        layerAnimationCels[layer] = cels
    end

    return layerAnimationCels
end

local function GetNotLoopedLayers(sprite, layers)
    local result = {}

    for _, layer in ipairs(layers) do
        local lastFrameCel = layer:cel(#sprite.frames)
        if lastFrameCel == nil then table.insert(result, layer) end
    end

    return result
end

local function GetLastCelFrameNumber(layer)
    local frameNumber = -1
    for _, cel in ipairs(layer.cels) do frameNumber = cel.frameNumber end
    return frameNumber
end

local function RepeatAnimation(sprite, layer, animationCels, maxNumberOfFrames)
    local fromFrame = GetLastCelFrameNumber(layer)
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

local function Loop(sprite, layersToLoop, maxNumberOfFrames)
    local layers = GetLayersToLoop(sprite, layersToLoop)
    local layerAnimationCels = GetLayerAnimationCels(layers)

    while true do
        local notLoopedLayers = GetNotLoopedLayers(sprite, layers)
        if #notLoopedLayers == 0 then break end

        for _, layer in ipairs(notLoopedLayers) do
            repeat
                local isDone = RepeatAnimation(sprite, layer,
                                               layerAnimationCels[layer],
                                               maxNumberOfFrames)
            until isDone
        end

        if #sprite.frames > maxNumberOfFrames then break end
    end
end

local function GetAvailableLayers()
    local layers = {}

    for _, layer in ipairs(app.activeSprite.layers) do
        -- TODO: Handle background layers
        if layer.isBackground then goto skip end

        table.insert(layers, layer.name)

        ::skip::
    end

    return layers
end

local function LoopDialog(options)
    local layers = GetAvailableLayers()
    local layersToLoop = {}

    local dialog = Dialog {title = options.title}

    local function GetSeparatorLabel()
        if #layersToLoop >= 2 then
            return "Selected " .. tostring(#layersToLoop) .. " layers to loop"
        elseif #layersToLoop == 1 then
            return "Select at least 2 layers to loop, selected 1 layer"
        else
            return "Select at least 2 layers to loop, selected 0 layers"
        end
    end

    for i, layer in ipairs(layers) do
        local id = "layer-" .. tostring(i)
        local isSelected = false

        dialog:button{
            id = id,
            label = layer,
            text = "+",
            onclick = function()
                isSelected = not isSelected

                if not isSelected then
                    for i = 1, #layersToLoop do
                        if layersToLoop[i] == layer then
                            table.remove(layersToLoop, i)
                            break
                        end
                    end
                else
                    table.insert(layersToLoop, layer)
                end

                dialog --
                :modify{id = id, text = isSelected and "-" or "+"} --
                :modify{id = "separator-label", text = GetSeparatorLabel()} --
                :modify{id = "loop-button", enabled = #layersToLoop > 1}
            end
        }
    end

    dialog --
    :separator{id = "separator-label", text = GetSeparatorLabel()} --
    :number{
        id = "maxNumberOfFrames",
        label = "Max # of Frames",
        text = tostring(1024), -- 1024 is an arbitrary default value
        decimals = 0
    } --
    :button{
        id = "loop-button",
        text = "&OK",
        enabled = false,
        onclick = function()
            local maxNumberOfFrames = dialog.data["maxNumberOfFrames"]

            app.transaction(function()
                Loop(app.activeSprite, layersToLoop, maxNumberOfFrames)
            end)

            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

return LoopDialog
