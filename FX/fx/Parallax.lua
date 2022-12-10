local LinearMovement = "Linear"

local Parallax = {
    initialPositions = {},
    movementFunctions = {
        [LinearMovement] = function() return 1 end,
        ["Ease Out Cubic"] = function(x) return 1 - ((1 - x) ^ 3) end,
        ["Ease In Out Back"] = function(x)
            local c1 = 1.70158
            local c2 = c1 * 1.525

            return x < 0.5 and (((2 * x) ^ 2) * ((c2 + 1) * 2 * x - c2)) / 2 or
                       (((2 * x - 2) ^ 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) /
                       2
        end,
        ["Ease Out Elastic"] = function(x)
            local c4 = (2 * math.pi) / 3

            return x == 0 and 0 or x == 1 and 1 or (2 ^ (-10 * x)) *
                       math.sin((x * 10 - 0.75) * c4) + 1;
        end
    }
}

function Parallax:GetDefaultMovementFunction() return LinearMovement end

function Parallax:GetMovementFunctions()
    local result = {}
    for key, _ in pairs(self.movementFunctions) do table.insert(result, key) end

    return result
end

function Parallax:GetFullLayerName(layer)
    local result = layer.name
    local parent = layer.parent

    while parent ~= layer.sprite do
        result = parent.name .. " > " .. result
        parent = parent.parent
    end

    return result
end

function Parallax:_IterateOverLayers(layers, action)
    -- Iterate in reverse to go from top to bottom
    for i = #layers, 1, -1 do
        local layer = layers[i]

        if layer.isGroup then
            Parallax:_IterateOverLayers(layer.layers, action)
        else
            action(layer)
        end
    end
end

function Parallax:InitPreview(sourceSprite, sourceFrameNumber, parameters)
    local width = sourceSprite.width
    local height = sourceSprite.height

    self.sourceSprite = sourceSprite
    self.previewSprite = Sprite(width, height)
    self.previewSprite:setPalette(self.sourceSprite.palettes[1])

    self.sourceFrameNumber = sourceFrameNumber

    local firstLayer = self.previewSprite.layers[1]

    self:_CreatePreviewLayers(sourceSprite.layers, self.previewSprite)

    self.previewSprite:deleteLayer(firstLayer)

    self:UpdatePreviewImages(parameters)
end

function Parallax:_CreatePreviewLayers(layers, parent)
    for _, layer in ipairs(layers) do
        if layer.isGroup then
            local previewGroup = self.previewSprite:newGroup()
            previewGroup.name = layer.name
            previewGroup.stackIndex = layer.stackIndex
            previewGroup.isVisible = layer.isVisible
            previewGroup.parent = parent

            self:_CreatePreviewLayers(layer.layers, previewGroup)
        else
            local previewLayer = self.previewSprite:newLayer()
            previewLayer.name = layer.name
            previewLayer.stackIndex = layer.stackIndex
            previewLayer.isVisible = layer.isVisible
            previewLayer.parent = parent
        end
    end
end

function Parallax:UpdatePreviewImages(parameters)
    local width = self.sourceSprite.width
    local height = self.sourceSprite.height

    -- Map source with 
    local layerMap = {}

    self:_IterateOverLayers(self.sourceSprite.layers, function(layer)
        local id = self:_GetLayerId(layer)
        layerMap[id] = {source = layer}
    end)

    self:_IterateOverLayers(self.previewSprite.layers, function(layer)
        local id = self:_GetLayerId(layer)
        layerMap[id].preview = layer
    end)

    for id, map in pairs(layerMap) do
        local cel = map.source.cels[self.sourceFrameNumber]

        if cel and map.source.isVisible and map.preview.isVisible then -- Save the initial position of the layers
            local newImage

            newImage = Image(cel.bounds.width + width,
                             cel.bounds.height + height)

            newImage:drawImage(cel.image, Point(0, 0))
            newImage:drawImage(cel.image, Point(width, 0))

            newImage:drawImage(cel.image, Point(0, height))
            newImage:drawImage(cel.image, Point(width, height))

            self.initialPositions[id] = Point(cel.position.x - width,
                                              cel.position.y - height)

            self.previewSprite:newCel(map.preview, 1, newImage,
                                      self.initialPositions[id])
        end
    end

    app.refresh()
end

function Parallax:_GetLayerId(layer)
    local id = tostring(layer.stackIndex)

    local parent = layer.parent

    while parent ~= layer.sprite do
        id = tostring(parent.stackIndex) .. "-" .. id
        parent = parent.parent
    end

    return id
end

function Parallax:Preview(parameters)
    self:_IterateOverLayers(self.previewSprite.layers, function(layer)
        local cel = layer:cel(1)

        if cel then
            local id = self:_GetLayerId(layer)
            local distance = parameters["distance-" .. id]
            -- local wrap = parameters["wrap-" .. id]

            local initialPosition = self.initialPositions[id]
            local shiftX = parameters.speedX * (parameters.shift / distance)
            local shiftY = parameters.speedY * (parameters.shift / distance)

            -- if wrap then
            shiftX = shiftX % layer.sprite.width
            shiftY = shiftY % layer.sprite.height
            -- end

            -- Fix for NaN
            if shiftX ~= shiftX then shiftX = 0 end
            if shiftY ~= shiftY then shiftY = 0 end

            cel.position = Point(initialPosition.x + shiftX,
                                 initialPosition.y + shiftY)
        end
    end)
end

function Parallax:ClosePreview() self.previewSprite:close() end

function Parallax:Generate(sourceSprite, parameters)
    local destinationSprite = Sprite(sourceSprite.spec)

    -- Save the reference to the first, default layer to delete it later
    local firstLayer = destinationSprite.layers[1]

    -- Fill the destination sprite with the required number of frames, assuming there's already one
    for _ = 2, parameters.frames do destinationSprite:newEmptyFrame() end

    Parallax:_GenerateLayers(sourceSprite, destinationSprite,
                             sourceSprite.layers, parameters, destinationSprite)

    -- Delete the first, defualt layer in the destination sprite
    destinationSprite:deleteLayer(firstLayer)
end

function Parallax:_GenerateLayers(sourceSprite, destinationSprite, layers,
                                  parameters, parent)
    -- Iterate over layers in reverse to keep the same order
    for i = #layers, 1, -1 do
        local layer = layers[i]

        if not layer.isVisible then goto skipLayer end

        if layer.isGroup then
            local newGroup = destinationSprite:newGroup()
            newGroup.name = layer.name
            newGroup.parent = parent
            newGroup.stackIndex = 1

            self:_GenerateLayers(sourceSprite, destinationSprite, layer.layers,
                                 parameters, newGroup)
        else
            local linkedSourceCelsMap = self:_MapLinkedSourceCels(layer)

            local factor = 1.0 / tonumber(layer.data)

            -- Create an abastract model of the layer
            local celsModel = self:_BuildCelsModel(sourceSprite,
                                                   destinationSprite, factor,
                                                   parameters,
                                                   linkedSourceCelsMap)

            -- Build the actual timeline in the destination sprite based on the model
            self:_RebuildLayer(sourceSprite, destinationSprite, layer,
                               celsModel, parent, parameters)
        end

        ::skipLayer::
    end
end

function Parallax:_MapLinkedSourceCels(layer)
    local map = {}

    for i = 1, #layer.cels do
        local cel = layer.cels[i]
        map[cel.frameNumber] = cel.frameNumber

        for j = 1, i - 1 do
            local otherCel = layer.cels[j]

            if cel ~= otherCel and cel.image == otherCel.image then

                map[cel.frameNumber] = otherCel.frameNumber
                break
            end
        end
    end

    return map
end

function Parallax:_BuildCelsModel(sourceSprite, destinationSprite, factor,
                                  parameters, linkedSourceCelsMap)
    local celsModel = {}

    for frameNumber = 1, parameters.frames do
        local shiftX = frameNumber
        local shiftY = frameNumber

        -- FUTURE: Adjust this for X and Y
        -- if parameters.movementFunction ~= LinearMovement then
        --     local easingFunction =
        --         self.movementFunctions[parameters.movementFunction]
        --     local easing = easingFunction(frameNumber / parameters.frames)

        --     shiftX = destinationSprite.width * easing
        -- end

        shiftX = math.floor(shiftX * parameters.speedX * factor) %
                     destinationSprite.width
        shiftY = math.floor(shiftY * parameters.speedY * factor) %
                     destinationSprite.height

        -- Fix for nan
        if shiftX ~= shiftX then shiftX = 0 end
        if shiftY ~= shiftY then shiftY = 0 end

        local sourceFrameNumber = (frameNumber % #sourceSprite.frames) + 1

        -- Map to a linked cel
        sourceFrameNumber = linkedSourceCelsMap[sourceFrameNumber]

        if not celsModel[sourceFrameNumber] then
            celsModel[sourceFrameNumber] = {}
        end

        if not celsModel[sourceFrameNumber][shiftX] then
            celsModel[sourceFrameNumber][shiftX] = {}
        end

        if not celsModel[sourceFrameNumber][shiftX][shiftY] then
            celsModel[sourceFrameNumber][shiftX][shiftY] = {}
        end

        table.insert(celsModel[sourceFrameNumber][shiftX][shiftY], frameNumber)
    end

    return celsModel
end

function Parallax:_RebuildLayer(sourceSprite, destinationSprite, sourceLayer,
                                celsModel, parent, parameters)
    local newLayer = destinationSprite:newLayer()
    newLayer.name = sourceLayer.name
    newLayer.parent = parent
    newLayer.stackIndex = 1

    local celCache = {}
    local sourceWidth, sourceHeight = sourceSprite.width, sourceSprite.height

    for sourceFrameNumber, shiftX in pairs(celsModel) do
        for x, shiftY in pairs(shiftX) do
            for y, destinationFrames in pairs(shiftY) do
                Parallax:_RebuildCel(sourceFrameNumber, destinationFrames, x, y,
                                     sourceWidth, sourceHeight,
                                     destinationSprite, sourceLayer, newLayer,
                                     celCache, parameters)
            end
        end
    end
end

function Parallax:_RebuildCel(sourceFrameNumber, destinationFrameNumbers,
                              shiftX, shiftY, sourceWidth, sourceHeight,
                              destinationSprite, sourceLayer, destinationLayer,
                              celCache, parameters)
    local image

    local sourceCel = sourceLayer:cel(sourceFrameNumber)
    local position = sourceCel.position

    local alreadyCopiedCelNumber = celCache[sourceFrameNumber]

    if alreadyCopiedCelNumber then
        local resizedCel = destinationLayer:cel(alreadyCopiedCelNumber)
        image = resizedCel.image
    else
        -- TODO: What if it's empty?

        local sourceImage = sourceCel.image

        if parameters.speedX ~= 0 and parameters.speedY ~= 0 then
            image = Image(sourceImage.width + sourceWidth,
                          sourceImage.height + sourceHeight)

            image:drawImage(sourceImage, Point(0, 0))
            image:drawImage(sourceImage, Point(sourceWidth, 0))

            image:drawImage(sourceImage, Point(0, sourceHeight))
            image:drawImage(sourceImage, Point(sourceWidth, sourceHeight))
        elseif parameters.speedX ~= 0 and parameters.speedY == 0 then
            image = Image(sourceImage.width + sourceWidth, sourceImage.height)

            image:drawImage(sourceImage, Point(0, 0))
            image:drawImage(sourceImage, Point(sourceWidth, 0))
        elseif parameters.speedX == 0 and parameters.speedY ~= 0 then
            image = Image(sourceWidth, sourceImage.height + sourceHeight)

            image:drawImage(sourceImage, Point(0, 0))
            image:drawImage(sourceImage, Point(0, sourceHeight))
        end

        celCache[sourceFrameNumber] = destinationFrameNumbers[1]
    end

    -- Create the image to insert into the cel
    local newPosition

    if parameters.speedX ~= 0 and parameters.speedY ~= 0 then
        newPosition = Point(-sourceWidth + position.x + shiftX,
                            -sourceHeight + position.y + shiftY)
    elseif parameters.speedX ~= 0 and parameters.speedY == 0 then
        newPosition = Point(-sourceWidth + position.x + shiftX,
                            position.y + shiftY)
    elseif parameters.speedX == 0 and parameters.speedY ~= 0 then
        newPosition = Point(position.x + shiftX,
                            -sourceHeight + position.y + shiftY)
    end

    destinationSprite:newCel(destinationLayer, destinationFrameNumbers[1],
                             image, newPosition)

    -- Link only if there's more than one cel in the cluster
    if #destinationFrameNumbers > 1 then
        -- Link all identical
        app.range.frames = destinationFrameNumbers
        app.range.layers = {destinationLayer}
        app.command:LinkCels()
    end
end

return Parallax

-- FUTURE: Decide whether or not a layer is wrapping based on the fact if it spans the entire canvas length/width or not
