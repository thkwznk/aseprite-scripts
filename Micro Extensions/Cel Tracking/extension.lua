local EmptyCel = "EMPTY_CEL"
local EmptyImage = "EMPTY_IMAGE"
local EmptyPosition = "EMPTY_POSITION"

local AllFrames = "All frames"
local SpecificFrames = "Specific frames"
local TagFramesPrefix = "Tag: "

local ExistingCelOption = {Ignore = "Ignore", Replace = "Replace"}
local SnapPosition = {
    TopLeft = "top-left-position",
    TopCenter = "top-center-position",
    TopRight = "top-right-position",
    MiddleLeft = "middle-left-position",
    MiddleCenter = "middle-center-position",
    MiddleRight = "middle-right-position",
    BottomLeft = "bottom-left-position",
    BottomCenter = "bottom-center-position",
    BottomRight = "bottom-right-position"
}

local TrackCels =
    function(sprite, trackedLayer, framesRange, existingCelsOption)
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
                                         cel.position.x -
                                             placeholderCel.position.x,
                                         cel.position.y -
                                             placeholderCel.position.y) or
                                     EmptyPosition

                table.insert(relativePositions, position)
            end

            for i = framesRange.fromFrame, framesRange.toFrame do
                local hasExistingCel = layer:cel(i) ~= nil

                if hasExistingCel and existingCelsOption ==
                    ExistingCelOption.Ignore then
                    goto skip_tracked_cel
                end

                local cel = trackedLayer:cel(i)

                if cel then
                    local originalIndex = i % #sourceImages

                    if originalIndex == 0 then
                        originalIndex = #sourceImages
                    end

                    local relativePosition = relativePositions[originalIndex]

                    if relativePosition ~= EmptyPosition then
                        local newPosition =
                            Point(cel.position.x + relativePosition.x,
                                  cel.position.y + relativePosition.y)

                        sprite:newCel(sourceLayer, cel.frameNumber,
                                      sourceImages[originalIndex], newPosition)
                    end
                end

                ::skip_tracked_cel::
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

local SnapToCel = function(cel, targetCel, position)
    local left = targetCel.position.x
    local right = targetCel.position.x + targetCel.bounds.width -
                      cel.bounds.width

    local top = targetCel.position.y
    local bottom = targetCel.position.y + targetCel.bounds.height -
                       cel.bounds.height

    local center = targetCel.position.x + targetCel.bounds.width / 2 -
                       cel.bounds.width / 2
    local middle = targetCel.position.y + targetCel.bounds.height / 2 -
                       cel.bounds.height / 2

    if position == SnapPosition.TopLeft then
        cel.position = Point(left, top)
    elseif position == SnapPosition.TopCenter then
        cel.position = Point(center, top)
    elseif position == SnapPosition.TopRight then
        cel.position = Point(right, top)
    elseif position == SnapPosition.MiddleLeft then
        cel.position = Point(left, middle)
    elseif position == SnapPosition.MiddleCenter then
        cel.position = Point(center, middle)
    elseif position == SnapPosition.MiddleRight then
        cel.position = Point(right, middle)
    elseif position == SnapPosition.BottomLeft then
        cel.position = Point(left, bottom)
    elseif position == SnapPosition.BottomCenter then
        cel.position = Point(center, bottom)
    elseif position == SnapPosition.BottomRight then
        cel.position = Point(right, bottom)
    end
end

local SnapToLayer = function(targetLayer, position)
    local cels = app.range.cels

    for _, cel in ipairs(cels) do
        local targetCel = targetLayer:cel(cel.frameNumber)
        if targetCel then SnapToCel(cel, targetCel, position) end
    end
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

            local existingCelsOptions = {
                ExistingCelOption.Replace, ExistingCelOption.Ignore
            }

            dialog --
            :separator{text = "Tracked:"} --
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
            :separator{id = "anchor-separator", text = "Anchor:"} --
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
            :separator{text = "Options"} --
            :combobox{
                id = "existing-cels-option",
                label = "Existing cels:",
                options = existingCelsOptions
            } --
            :separator() --
            :button{
                text = "OK",
                onclick = function()
                    local trackedLayer = layers[dialog.data.trackedLayer]
                    local framesRange = getSelectedFramesRange()
                    local existingCelsOption =
                        dialog.data["existing-cels-option"]

                    app.transaction(function()
                        TrackCels(sprite, trackedLayer, framesRange,
                                  existingCelsOption)
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

    plugin:newCommand{
        id = "TrackCels",
        title = "Snap to Layer",
        group = "cel_popup_new",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = Dialog("Snap to Layer")

            local layerNames = {}
            local layers = {}

            for _, layer in ipairs(sprite.layers) do
                table.insert(layerNames, layer.name)
                layers[layer.name] = layer
            end

            local position = SnapPosition.MiddleCenter

            local updatePosition = function(newPosition)
                position = newPosition

                for _, snapPosition in pairs(SnapPosition) do
                    dialog:modify{
                        id = snapPosition,
                        text = newPosition == snapPosition and "X" or ""
                    }
                end
            end

            dialog --
            :combobox{
                id = "target-layer",
                label = "Layer:",
                options = layerNames
            } --
            :separator{text = "Position:"} --
            :button{
                id = "top-left-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.TopLeft)
                end
            } --
            :button{
                id = "top-center-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.TopCenter)
                end
            } --
            :button{
                id = "top-right-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.TopRight)
                end
            } --
            :newrow() --
            :button{
                id = "middle-left-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.MiddleLeft)
                end
            } --
            :button{
                id = "middle-center-position",
                text = "X",
                onclick = function()
                    updatePosition(SnapPosition.MiddleCenter)
                end
            } --
            :button{
                id = "middle-right-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.MiddleRight)
                end
            } --
            :newrow() --
            :button{
                id = "bottom-left-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.BottomLeft)
                end
            } --
            :button{
                id = "bottom-center-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.BottomCenter)
                end
            } --
            :button{
                id = "bottom-right-position",
                text = "",
                onclick = function()
                    updatePosition(SnapPosition.BottomRight)
                end
            } --
            :separator() --
            :button{
                text = "&OK",
                onclick = function()
                    local targetLayer = layers[dialog.data["target-layer"]]

                    app.transaction(function()
                        SnapToLayer(targetLayer, position)
                    end)

                    dialog:close()
                    app.refresh()
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
-- TODO: For both commands, filter out the selected layers from target layers
