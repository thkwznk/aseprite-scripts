local EmptyCel = "EMPTY_CEL"
local EmptyImage = "EMPTY_IMAGE"
local EmptyPosition = "EMPTY_POSITION"

local AllFrames = "All frames"
local SpecificFrames = "Specific frames"
local TagFramesPrefix = "Tag: "

local TrackCels = function(sprite, trackedLayer, framesRange)
    local selectedLayers = app.range.layers

    for _, layer in ipairs(selectedLayers) do
        local sourceCels = {}

        for _, frameNumber in ipairs(app.range.frames) do
            table.insert(sourceCels, layer:cel(frameNumber) or EmptyCel)
        end

        local sourceCel = sourceCels[1]

        -- These need to be saved, the source cels becomes nil
        local sourceLayer = sourceCel.layer
        local sourceImages = {}

        for _, cel in ipairs(sourceCels) do
            if cel == EmptyCel then
                table.insert(sourceImages, EmptyImage)
            else
                table.insert(sourceImages, Image(cel.image))
            end
        end

        local relativePositions = {}

        for _, cel in ipairs(sourceCels) do
            local placeholderCel = trackedLayer:cel(cel.frameNumber)

            local position = (cel ~= EmptyCel and placeholderCel) and
                                 Point(
                                     cel.position.x - placeholderCel.position.x,
                                     cel.position.y - placeholderCel.position.y) or
                                 EmptyPosition

            table.insert(relativePositions, position)
        end

        -- for i, cel in ipairs(trackedLayer.cels) do

        for i = framesRange.fromFrame, framesRange.toFrame do
            local cel = trackedLayer:cel(i)

            if cel then
                local originalIndex = i % #sourceImages

                if originalIndex == 0 then
                    originalIndex = #sourceImages
                end

                local relativePosition = relativePositions[originalIndex]

                if relativePosition ~= EmptyPosition then
                    local newPosition = Point(cel.position.x +
                                                  relativePosition.x,
                                              cel.position.y +
                                                  relativePosition.y)

                    sprite:newCel(sourceLayer, cel.frameNumber,
                                  sourceImages[originalIndex], newPosition)
                end
            end
        end
    end
end

local GetFramesOptions = function(sprite)
    local framesOptions = {AllFrames}

    for _, tag in ipairs(sprite.tags) do
        table.insert(framesOptions, TagFramesPrefix .. tag.name)
    end

    table.insert(framesOptions, SpecificFrames)

    return framesOptions
end

function init(plugin)
    plugin:newCommand{
        id = "TrackCels",
        title = "Track Cel(s)",
        group = "cel_popup_new",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = Dialog("Track Cel(s)")

            local layerNames = {}
            local layers = {}

            for _, layer in ipairs(sprite.layers) do
                table.insert(layerNames, layer.name)
                layers[layer.name] = layer
            end

            local framesOptions = GetFramesOptions(sprite)

            dialog --
            :separator{text = "Tracked"} --
            :combobox{
                id = "trackedLayer",
                label = "Layer",
                options = layerNames
            } --
            :combobox{
                id = "framesOption",
                label = "Frames:",
                options = framesOptions
            } --
            :separator{text = "Anchor"} --
            :button{text = "X"} --
            :button{text = ""} --
            :button{text = ""} --
            :newrow() --
            :button{text = ""} --
            :button{text = ""} --
            :button{text = ""} --
            :newrow() --
            :button{text = ""} --
            :button{text = ""} --
            :button{text = ""} --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    local trackedLayer = layers[dialog.data.trackedLayer]
                    local framesOption = dialog.data["framesOption"]

                    local framesRange = {
                        fromFrame = 1,
                        toFrame = #sprite.frames
                    }

                    if framesOption == AllFrames then
                        -- Nothing specific
                    elseif framesOption == SpecificFrames then
                        -- TODO: Implement
                    else -- Tag
                        local tagName = string.sub(framesOption,
                                                   #TagFramesPrefix + 1)

                        for _, tag in ipairs(sprite.tags) do
                            if tag.name == tagName then
                                framesRange = {
                                    fromFrame = tag.fromFrame.frameNumber,
                                    toFrame = tag.toFrame.frameNumber
                                }
                                break
                            end
                        end
                    end

                    app.transaction(function()
                        TrackCels(sprite, trackedLayer, framesRange)
                    end)

                    dialog:close()
                end
            } --
            :button{text = "Cancel"}

            dialog:show()
        end
    }
end

function exit(plugin) end

-- TODO: Implement tracking specific frames 
-- TODO: Test different anchors
