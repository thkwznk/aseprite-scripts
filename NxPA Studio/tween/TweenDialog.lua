Tweener = dofile("./Tweener.lua");

function SelectFrames(from, to)
    local frames = {}
    for i = from, to do table.insert(frames, i) end
    app.range.frames = frames
end

return function(dialogTitle)
    local dialog = Dialog(dialogTitle)

    if app.range.isEmpty then SelectFrames(1, #app.activeSprite.frames) end

    local function onchange()
        local firstFrame = dialog.data["firstFrame"]
        local lastFrame = dialog.data["lastFrame"]

        dialog:modify{id = "tweenButton", enabled = firstFrame < lastFrame}

        -- Highlight selected frames
        SelectFrames(firstFrame, lastFrame)
    end

    dialog --
    :separator{text = "Frames"} --
    :slider{
        id = "firstFrame",
        label = "From",
        min = 1,
        max = #app.activeSprite.frames,
        value = app.range.frames[1].frameNumber,
        onchange = onchange
    } --
    :slider{
        id = "lastFrame",
        label = "To",
        min = 1,
        max = #app.activeSprite.frames,
        value = app.range.frames[#app.range.frames].frameNumber,
        onchange = onchange
    } --
    :separator() --
    :number{id = "framesToAdd", label = "# of frames to add", text = "1"} --
    :button{
        id = "tweenButton",
        text = "Tween",
        onclick = function()
            Tweener:tween{
                sprite = app.activeSprite,
                firstFrame = dialog.data["firstFrame"],
                lastFrame = dialog.data["lastFrame"],
                framesToAdd = dialog.data["framesToAdd"]
            }
            dialog:close()
        end
    } --
    :button{text = "Cancel"}

    return dialog;
end
