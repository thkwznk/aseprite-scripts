local StackIndexId = dofile("../StackIndexId.lua")

local function IterateOverLayers(layers, action)
    for i = 1, #layers do
        local layer = layers[i]

        if layer.isGroup then
            IterateOverLayers(layer.layers, action)
        elseif layer.isVisible and not layer.isReference then
            action(layer)
        end
    end
end

local function MapLinkedSourceCels(layer)
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

local function BuildCelsModel(sourceSprite, destinationSprite, factor,
                              parameters, linkedSourceCelsMap)
    local celsModel = {}

    for frameNumber = 1, parameters.frames do
        local shiftX = frameNumber
        local shiftY = frameNumber

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

        -- For an empty cel `sourceFrameNumber` is nil
        if sourceFrameNumber then
            if not celsModel[sourceFrameNumber] then
                celsModel[sourceFrameNumber] = {}
            end

            if not celsModel[sourceFrameNumber][shiftX] then
                celsModel[sourceFrameNumber][shiftX] = {}
            end

            if not celsModel[sourceFrameNumber][shiftX][shiftY] then
                celsModel[sourceFrameNumber][shiftX][shiftY] = {}
            end

            table.insert(celsModel[sourceFrameNumber][shiftX][shiftY],
                         frameNumber)
        end
    end

    return celsModel
end

local function RebuildCel(sourceFrameNumber, destinationFrameNumbers, shiftX,
                          shiftY, sourceWidth, sourceHeight, destinationSprite,
                          sourceLayer, destinationLayer, celCache, parameters)
    -- Validate parameters
    if parameters.speedX == 0 and parameters.speedY == 0 then return end

    local image

    local sourceCel = sourceLayer:cel(sourceFrameNumber)
    local position = sourceCel.position

    local alreadyCopiedCelNumber = celCache[sourceFrameNumber]

    if alreadyCopiedCelNumber then
        local resizedCel = destinationLayer:cel(alreadyCopiedCelNumber)
        image = resizedCel.image
    else
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

local function RebuildLayer(sourceSprite, destinationSprite, sourceLayer,
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
                RebuildCel(sourceFrameNumber, destinationFrames, x, y,
                           sourceWidth, sourceHeight, destinationSprite,
                           sourceLayer, newLayer, celCache, parameters)
            end
        end
    end
end

local function GenerateLayers(sourceSprite, destinationSprite, layers,
                              parameters, parent)
    -- Iterate over layers in reverse to keep the same order
    for i = #layers, 1, -1 do
        local layer = layers[i]

        if layer.isGroup then
            local newGroup = destinationSprite:newGroup()
            newGroup.name = layer.name
            newGroup.parent = parent
            newGroup.stackIndex = 1

            GenerateLayers(sourceSprite, destinationSprite, layer.layers,
                           parameters, newGroup)
        elseif layer.isVisible and not layer.isReference then
            local linkedSourceCelsMap = MapLinkedSourceCels(layer)

            local factor = 1.0 / tonumber(layer.data)

            -- Create an abastract model of the layer
            local celsModel = BuildCelsModel(sourceSprite, destinationSprite,
                                             factor, parameters,
                                             linkedSourceCelsMap)

            -- Build the actual timeline in the destination sprite based on the model
            RebuildLayer(sourceSprite, destinationSprite, layer, celsModel,
                         parent, parameters)
        end
    end
end

local Parallax = {initialPositions = {}}

function Parallax:Preview(sprite, parameters)
    local previewImage = Image(sprite.width, sprite.height, sprite.colorMode)

    IterateOverLayers(sprite.layers, function(layer)
        local cel = layer:cel(1)

        if cel then
            local id = StackIndexId(layer)
            local distance = parameters["distance-" .. id]
            -- local wrap = parameters["wrap-" .. id]

            local shiftX = parameters.speedX * (parameters.shift / distance)
            local shiftY = parameters.speedY * (parameters.shift / distance)

            local x = cel.position.x + shiftX
            local y = cel.position.y + shiftY

            -- if wrap then
            x = x % sprite.width
            y = y % sprite.height
            -- end

            -- Fix for NaN
            if x ~= x then x = 0 end
            if y ~= y then y = 0 end

            previewImage:drawImage(cel.image, Point(x, y))

            -- TODO: These checks could also check the cel bounds
            if x > 0 then
                previewImage:drawImage(cel.image, Point(x - sprite.width, y))
            elseif x < 0 then
                previewImage:drawImage(cel.image, Point(x + sprite.width, y))
            end

            if y > 0 then
                previewImage:drawImage(cel.image, Point(x, y - sprite.height))
            elseif y < 0 then
                previewImage:drawImage(cel.image, Point(x, y + sprite.height))

            end
        end
    end)

    return previewImage
end

function Parallax:Generate(sourceSprite, parameters)
    -- Save the values in the layer data
    IterateOverLayers(sourceSprite.layers, function(layer)
        local id = StackIndexId(layer)
        layer.data = parameters["distance-" .. id] or 0
    end)

    local destinationSprite = Sprite(sourceSprite.spec)
    destinationSprite:setPalette(sourceSprite.palettes[1])

    -- Save the reference to the first, default layer to delete it later
    local firstLayer = destinationSprite.layers[1]

    -- Fill the destination sprite with the required number of frames, assuming there's already one
    for _ = 2, parameters.frames do destinationSprite:newEmptyFrame() end

    GenerateLayers(sourceSprite, destinationSprite, sourceSprite.layers,
                   parameters, destinationSprite)

    -- Delete the first, defualt layer in the destination sprite
    destinationSprite:deleteLayer(firstLayer)
end

return Parallax

-- FUTURE: Decide whether or not a layer is wrapping based on the fact if it spans the entire canvas length/width or not
