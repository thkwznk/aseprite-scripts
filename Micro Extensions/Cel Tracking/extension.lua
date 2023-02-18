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

            local getSelectedFramesRange = function()
                local framesOption = dialog.data["framesOption"]

                local framesRange = {fromFrame = 1, toFrame = #sprite.frames}

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

                return framesRange
            end

            local updateAnchors = function()
                local trackedLayer = layers[dialog.data.trackedLayer]
                local framesRange = getSelectedFramesRange()

                local visible = false
                local startBounds = nil

                -- If cels change size, show anchor options
                for frameNumber = framesRange.fromFrame, framesRange.toFrame do
                    local cel = trackedLayer:cel(frameNumber)

                    if cel then
                        if startBounds == nil then
                            startBounds = cel.bounds
                        end

                        if startBounds.width ~= cel.bounds.width or
                            startBounds.height ~= cel.bounds.height then
                            visible = true
                            break
                        end
                    end
                end

                dialog --
                :modify{id = "anchor-separator", visible = visible} --
                :modify{id = "top-left-anchor", visible = visible} --
                :modify{id = "top-center-anchor", visible = visible} --
                :modify{id = "top-right-anchor", visible = visible} --
                -- :newrow() --
                :modify{id = "middle-left-anchor", visible = visible} --
                :modify{id = "middle-center-anchor", visible = visible} --
                :modify{id = "middle-right-anchor", visible = visible} --
                -- :newrow() --
                :modify{id = "bottom-left-anchor", visible = visible} --
                :modify{id = "bottom-center-anchor", visible = visible} --
                :modify{id = "bottom-right-anchor", visible = visible} --
            end

            dialog --
            :separator{text = "Tracked"} --
            :combobox{
                id = "trackedLayer",
                label = "Layer",
                options = layerNames,
                onchange = function() updateAnchors() end
            } --
            :combobox{
                id = "framesOption",
                label = "Frames:",
                options = framesOptions,
                onchange = function() updateAnchors() end
            } --
            :separator{id = "anchor-separator", text = "Anchor"} --
            :button{id = "top-left-anchor", text = "X"} --
            :button{id = "top-center-anchor", text = ""} --
            :button{id = "top-right-anchor", text = ""} --
            :newrow() --
            :button{id = "middle-left-anchor", text = ""} --
            :button{id = "middle-center-anchor", text = ""} --
            :button{id = "middle-right-anchor", text = ""} --
            :newrow() --
            :button{id = "bottom-left-anchor", text = ""} --
            :button{id = "bottom-center-anchor", text = ""} --
            :button{id = "bottom-right-anchor", text = ""} --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    local trackedLayer = layers[dialog.data.trackedLayer]
                    local framesRange = getSelectedFramesRange()

                    app.transaction(function()
                        TrackCels(sprite, trackedLayer, framesRange)
                    end)

                    dialog:close()
                end
            } --
            :button{text = "Cancel"}

            -- Initialize anchors
            updateAnchors()

            dialog:show()
        end
    }
end

function exit(plugin) end

-- TODO: Implement tracking specific frames 
-- TODO: Test different anchors
