local ReplaceExistingBehavior = "Replace"
local PushExistingBehavior = "Push"

function Repeat(n, linked, behavior)
    app.transaction(function()
        local content = linked and "cellinked" or "cel"

        local sprite = app.activeSprite
        local originalRange = CopyRange(app.range)
        local originalTag = nil

        if behavior == PushExistingBehavior then
            -- If repeating CELS - cels need to be moved one by one, from the end, new empty frames need to be added at the end if necessary
            local lastFrame = GetLastFrame(originalRange.frames)

            local shiftFrames = n * #originalRange.frames

            for _, layer in ipairs(originalRange.layers) do
                -- If the sprite has less frames than last frame number + n - add missing frames (empty)
                local lastFrameOnLayer = GetLastFrameOnLayer(layer)
                local framesToAdd = lastFrameOnLayer.frameNumber + shiftFrames -
                                        #sprite.frames

                if framesToAdd > 0 then
                    app.activeFrame = GetLastFrame(sprite.frames)
                    for _ = 1, framesToAdd do
                        app.command.NewFrame {content = "empty"}
                    end
                end

                -- For each layer in the original range, for each frame (descending), move the cel n frames
                for frameNumber = #sprite.frames, lastFrame.frameNumber + 1, -1 do
                    local cel = layer:cel(frameNumber)

                    if cel then
                        sprite:newCel(layer, frameNumber + shiftFrames,
                                      cel.image, cel.position)
                    end
                end
            end

            app.range:clear()
            app.range.frames = originalRange.frames
            app.range.layers = originalRange.layers
        end

        for i = 0, n - 1 do
            app.command.NewFrame {content = content}

            -- If the selected frames had a tag, repeat it as well 
            if originalTag then
                local newTag = sprite:newTag(app.range.frames[1].frameNumber,
                                             app.range.frames[#app.range.frames]
                                                 .frameNumber)
                newTag.name = originalTag.name .. " " .. tostring(i + 2)
                newTag.color = originalTag.color
                newTag.aniDir = originalTag.aniDir
            end
        end

        if originalTag then
            -- Fix the original tag, it gets extended if you push frames
            originalTag.fromFrame = originalRange.frames[1]
            originalTag.toFrame = originalRange.frames[#originalRange.frames]
        end
    end)
end

function GetLastFrame(frames)
    local lastFrame = frames[1]

    for _, frame in ipairs(frames) do
        if frame.frameNumber > lastFrame.frameNumber then
            lastFrame = frame
        end
    end

    return lastFrame
end

function GetLastFrameOnLayer(layer)
    local lastFrame = nil

    for _, cel in ipairs(layer.cels) do
        if lastFrame == nil then
            lastFrame = cel.frame
        else
            if cel.frame.frameNumber > lastFrame.frameNumber then
                lastFrame = cel.frame
            end
        end
    end

    return lastFrame
end

function CopyRange(range)
    local copy = {layers = {}, frames = {}, cels = {}}

    for _, layer in ipairs(range.layers) do table.insert(copy.layers, layer) end
    for _, frame in ipairs(range.frames) do table.insert(copy.frames, frame) end

    return copy
end

function RepeatDialog(title)
    local dialog = Dialog(title)

    dialog --
    :separator{text = "Repeat"} --
    :number{
        id = "n",
        label = "Times:",
        decimals = 0,
        text = "1",
        onchange = function()
            dialog:modify{id = "ok-button", enabled = dialog.data.n > 0}
        end
    } --
    :separator{text = "Options"} --
    :combobox{
        id = "behavior",
        label = "Existing cels/frames:",
        options = {ReplaceExistingBehavior, PushExistingBehavior},
        option = PushExistingBehavior
    } --
    :check{id = "linked", label = "Repeat Linked:"} --
    :separator() --
    :button{
        id = "ok-button",
        text = "&OK",
        onclick = function()
            Repeat(dialog.data.n, dialog.data.linked, dialog.data.behavior)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

function init(plugin)
    plugin:newCommand{
        id = "RepeatCelsPopup",
        title = "Repeat Cel(s)",
        group = "cel_popup_new",
        onclick = function()
            local dialog = RepeatDialog("Repeat Cel(s)")
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "RepeatCels",
        title = "Repeat Cel(s)",
        group = "cel_new",
        onclick = function()
            local dialog = RepeatDialog("Repeat Cel(s)")
            dialog:show()
        end
    }
end

function exit(plugin) end
