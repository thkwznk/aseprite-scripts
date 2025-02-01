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

local LoopDialog = {
    title = nil,
    dialog = nil,
    bounds = nil,
    layers = {},
    layersToLoop = {},
    maxNumberOfFrames = 1024
}

function LoopDialog:GetAvailableLayers()
    local layers = {}

    for _, layer in ipairs(app.activeSprite.layers) do
        -- TODO: Handle background layers
        if layer.isBackground then goto skip end

        table.insert(layers, layer.name)

        ::skip::
    end

    return layers
end

function LoopDialog:_LayerSelected(layer)
    for _, layerToLoop in ipairs(self.layersToLoop) do
        if layerToLoop == layer then return true end
    end

    return false
end

function LoopDialog:Create(title)
    self.title = title or self.title
    self.layersToLoop = {}
    self.layers = self:GetAvailableLayers()
end

function LoopDialog:Show()
    self.dialog = Dialog(self.title)

    self.dialog --
    :separator{text = "Select layers to loop:"} --

    -- Get all layers
    for _, layer in ipairs(self.layers) do
        local isSelected = self:_LayerSelected(layer)

        self.dialog:button{
            label = layer,
            text = isSelected and "-" or "+",
            onclick = function()
                if isSelected then
                    for i = 1, #self.layersToLoop do
                        if self.layersToLoop[i] == layer then
                            table.remove(self.layersToLoop, i)
                            break
                        end
                    end
                else
                    table.insert(self.layersToLoop, layer)
                end

                self:Refresh()
            end
        }
    end

    self.dialog:separator{
        text = "Selected " .. tostring(#self.layersToLoop) .. " Layers to loop"
    }:number{
        id = "maxNumberOfFrames",
        label = "Max # of Frames",
        text = tostring(self.maxNumberOfFrames),
        decimals = 0,
        onchange = function()
            self.maxNumberOfFrames = self.dialog.data["maxNumberOfFrames"]
        end
    }:button{
        text = "Loop Animations",
        enabled = #self.layersToLoop > 1,
        onclick = function()
            app.transaction(function()
                Loop(app.activeSprite, self.layersToLoop, self.maxNumberOfFrames)
            end)
            self.dialog:close()
        end
    } --
    :button{text = "Cancel"}

    -- Reset bounds
    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        self.dialog.bounds = newBounds
    end

    self.dialog:show()
end

function LoopDialog:Refresh()
    self.bounds = self.dialog.bounds
    self.dialog:close()
    self:Show()
end

return LoopDialog
