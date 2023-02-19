local Empty = "EMPTY"
local TagFramesPrefix = "Tag: "

local FramesOption = {All = "All frames", Specific = "Specific frames"}
local ExistingCelOption = {Ignore = "Ignore", Replace = "Replace"}

local Position = {
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

local CalculateAnchorPosition = function(cel, anchorPosition)
    local top = cel.position.y
    local bottom = cel.position.y + cel.bounds.height

    local left = cel.position.x
    local right = cel.position.x + cel.bounds.width

    local middle = cel.position.y + cel.bounds.height / 2
    local center = cel.position.x + cel.bounds.width / 2

    if anchorPosition == Position.TopLeft then
        return Point(left, top)
    elseif anchorPosition == Position.TopCenter then
        return Point(center, top)
    elseif anchorPosition == Position.TopRight then
        return Point(right, top)
    elseif anchorPosition == Position.MiddleLeft then
        return Point(left, middle)
    elseif anchorPosition == Position.MiddleCenter then
        return Point(center, middle)
    elseif anchorPosition == Position.MiddleRight then
        return Point(right, middle)
    elseif anchorPosition == Position.BottomLeft then
        return Point(left, bottom)
    elseif anchorPosition == Position.BottomCenter then
        return Point(center, bottom)
    elseif anchorPosition == Position.BottomRight then
        return Point(right, bottom)
    end
end

local CalculateRelativePosition = function(cel, placeholderCel, anchorPosition)
    local placeholderPosition = CalculateAnchorPosition(placeholderCel,
                                                        anchorPosition)

    return Point(cel.position.x - placeholderPosition.x,
                 cel.position.y - placeholderPosition.y)
end

local GetRelativePositions = function(sourceCels, trackedLayer, anchorPosition)
    local positions = {}

    for _, cel in ipairs(sourceCels) do
        local placeholderCel = trackedLayer:cel(cel.frameNumber)
        local position = Empty

        if cel ~= Empty and placeholderCel then
            position = CalculateRelativePosition(cel, placeholderCel,
                                                 anchorPosition)
        end

        table.insert(positions, position)
    end

    return positions
end

local MoveTrackingCel = function(trackedCel, relativePosition, anchorPosition)
    local anchor = CalculateAnchorPosition(trackedCel, anchorPosition)

    return Point(anchor.x + relativePosition.x, anchor.y + relativePosition.y)
end

local TrackCels = function(sprite, trackedLayer, framesRange, anchorPosition,
                           existingCelsOption)
    local selectedLayers = app.range.layers

    for _, layer in ipairs(selectedLayers) do
        local firstSourceFrame = app.range.frames[1].frameNumber

        local sourceCels = {}

        for _, frame in ipairs(app.range.frames) do
            table.insert(sourceCels, layer:cel(frame) or Empty)
        end

        local sourceImages = {}

        for _, cel in ipairs(sourceCels) do
            if cel == Empty then
                table.insert(sourceImages, Empty)
            else
                table.insert(sourceImages, Image(cel.image))
            end
        end

        local relativePositions = GetRelativePositions(sourceCels, trackedLayer,
                                                       anchorPosition)

        local offset = (firstSourceFrame - 1) % #sourceImages

        for i = framesRange.fromFrame, framesRange.toFrame do
            local hasExistingCel = layer:cel(i) ~= nil

            if hasExistingCel and existingCelsOption == ExistingCelOption.Ignore then
                goto skip_tracked_cel
            end

            local trackedCel = trackedLayer:cel(i)

            if trackedCel then
                local originalIndex = (i - offset) % #sourceImages

                if originalIndex == 0 then
                    originalIndex = #sourceImages
                end

                local relativePosition = relativePositions[originalIndex]

                if relativePosition ~= Empty then
                    local newPosition = MoveTrackingCel(trackedCel,
                                                        relativePosition,
                                                        anchorPosition)

                    sprite:newCel(layer, trackedCel.frameNumber,
                                  sourceImages[originalIndex], newPosition)
                elseif existingCelsOption == ExistingCelOption.Replace and
                    layer:cel(i) then
                    sprite:deleteCel(layer, i)
                end
            end

            ::skip_tracked_cel::
        end
    end
end

local GetFramesOptions = function(sprite)
    local framesOptions = {FramesOption.All}

    for _, tag in ipairs(sprite.tags) do
        table.insert(framesOptions, TagFramesPrefix .. tag.name)
    end

    table.insert(framesOptions, FramesOption.Specific)

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

    if position == Position.TopLeft then
        cel.position = Point(left, top)
    elseif position == Position.TopCenter then
        cel.position = Point(center, top)
    elseif position == Position.TopRight then
        cel.position = Point(right, top)
    elseif position == Position.MiddleLeft then
        cel.position = Point(left, middle)
    elseif position == Position.MiddleCenter then
        cel.position = Point(center, middle)
    elseif position == Position.MiddleRight then
        cel.position = Point(right, middle)
    elseif position == Position.BottomLeft then
        cel.position = Point(left, bottom)
    elseif position == Position.BottomCenter then
        cel.position = Point(center, bottom)
    elseif position == Position.BottomRight then
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

local GetAvailableLayers = function(sprite)
    local layerNames = {}
    local layers = {}

    -- Filter out selected layers
    local selectedLayers = app.range.layers

    for _, layer in ipairs(sprite.layers) do
        local isSelected = false

        for _, selectedLayer in ipairs(selectedLayers) do
            if selectedLayer == layer then
                isSelected = true
                break
            end
        end

        if not isSelected then
            table.insert(layerNames, layer.name)
            layers[layer.name] = layer
        end
    end

    return layerNames, layers
end

local SetupPositionRow = function(dialog, onclick, positionIds)
    for _, id in ipairs(positionIds) do
        dialog:button{id = id, onclick = function() onclick(id) end}
    end

    dialog:newrow()
end

local SetupPositionGrid = function(dialog, onclick)
    SetupPositionRow(dialog, onclick,
                     {Position.TopLeft, Position.TopCenter, Position.TopRight})
    SetupPositionRow(dialog, onclick, {
        Position.MiddleLeft, Position.MiddleCenter, Position.MiddleRight
    })
    SetupPositionRow(dialog, onclick, {
        Position.BottomLeft, Position.BottomCenter, Position.BottomRight
    })
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

            local layerNames, layers = GetAvailableLayers(sprite)
            local anchorPosition = Position.TopLeft
            local framesOptions = GetFramesOptions(sprite)

            local getSelectedFramesRange = function()
                local framesOption = dialog.data["framesOption"]
                local framesRange = {fromFrame = 1, toFrame = #sprite.frames}

                if framesOption == FramesOption.All then
                    -- Nothing specific
                elseif framesOption == FramesOption.Specific then
                    framesRange = {
                        fromFrame = dialog.data["from-specific-frame"],
                        toFrame = dialog.data["to-specific-frame"]
                    }
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

            local updateSpecificFrames = function()
                local visible = dialog.data["framesOption"] ==
                                    FramesOption.Specific
                dialog --
                :modify{id = "from-specific-frame", visible = visible} --
                :modify{id = "to-specific-frame", visible = visible}

                local okButtonEnabled = true

                if visible then
                    local from, to = dialog.data["from-specific-frame"],
                                     dialog.data["to-specific-frame"]

                    okButtonEnabled = from >= 1 and from <= to and to <=
                                          #sprite.frames
                end

                dialog:modify{id = "ok-button", enabled = okButtonEnabled}
            end

            local updateAnchorPosition =
                function(newPosition)
                    anchorPosition = newPosition

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

                    dialog:modify{id = "anchor-separator", visible = visible}

                    for _, positionId in pairs(Position) do
                        dialog:modify{
                            id = positionId,
                            visible = visible,
                            text = newPosition == positionId and "X" or ""
                        }
                    end
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
                onchange = function()
                    updateAnchorPosition(anchorPosition)
                end
            } --
            :combobox{
                id = "framesOption",
                label = "Frames:",
                options = framesOptions,
                onchange = function()
                    updateSpecificFrames()
                    updateAnchorPosition(anchorPosition)
                end
            } --
            :number{
                id = "from-specific-frame",
                visible = false,
                decimals = 0,
                text = tostring(1),
                onchange = updateSpecificFrames
            } --
            :number{
                id = "to-specific-frame",
                visible = false,
                decimals = 0,
                text = tostring(#sprite.frames),
                onchange = updateSpecificFrames
            } --
            :separator{id = "anchor-separator", text = "Anchor:"} --

            SetupPositionGrid(dialog, updateAnchorPosition)

            dialog:separator{text = "Options"} --
            :combobox{
                id = "existing-cels-option",
                label = "Existing cels:",
                options = existingCelsOptions
            } --
            :separator() --
            :button{
                id = "ok-button",
                text = "OK",
                onclick = function()
                    local trackedLayer = layers[dialog.data.trackedLayer]
                    local framesRange = getSelectedFramesRange()
                    local existingCelsOption =
                        dialog.data["existing-cels-option"]

                    app.transaction(function()
                        TrackCels(sprite, trackedLayer, framesRange,
                                  anchorPosition, existingCelsOption)
                    end)

                    dialog:close()
                end
            } --
            :button{text = "Cancel"}

            -- Initialize anchors
            updateAnchorPosition(anchorPosition)

            dialog:show()
        end
    }

    plugin:newCommand{
        id = "SnapToCels",
        title = "Snap to Cel(s)",
        group = "cel_popup_new",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = Dialog("Snap to Cel(s)")

            local layerNames, layers = GetAvailableLayers(sprite)
            local snapPosition = Position.MiddleCenter

            local updateSnapPosition = function(newPosition)
                snapPosition = newPosition

                for _, positionId in pairs(Position) do
                    dialog:modify{
                        id = positionId,
                        text = newPosition == positionId and "X" or ""
                    }
                end
            end

            dialog --
            :separator{text = "Target:"} --
            :combobox{
                id = "target-layer",
                label = "Layer:",
                options = layerNames
            } --
            :separator{text = "Position:"} --

            SetupPositionGrid(dialog, updateSnapPosition)

            dialog:separator() --
            :button{
                text = "&OK",
                onclick = function()
                    local targetLayer = layers[dialog.data["target-layer"]]

                    app.transaction(function()
                        SnapToLayer(targetLayer, snapPosition)
                    end)

                    dialog:close()
                    app.refresh()
                end
            } --
            :button{text = "Cancel"}

            -- Initialize the position
            updateSnapPosition(snapPosition)

            dialog:show()
        end
    }
end

function exit(plugin) end
