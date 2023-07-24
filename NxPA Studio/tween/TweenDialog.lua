Tweener = dofile("./Tweener.lua");

function SelectFrames(from, to)
    local frames = {}
    for i = from, to do table.insert(frames, i) end
    app.range.frames = frames
end

return function(dialogTitle)
    local sprite = app.activeSprite
    local dialog = Dialog(dialogTitle)

    if app.range.isEmpty then SelectFrames(1, #sprite.frames) end

    local function onchange()
        local firstFrame = dialog.data["firstFrame"]
        local lastFrame = dialog.data["lastFrame"]

        dialog:modify{
            id = "tweenButton",
            enabled = firstFrame > 0 and lastFrame > 0 and lastFrame <=
                #sprite.frames and firstFrame < lastFrame
        }

        -- Highlight selected frames
        SelectFrames(firstFrame, lastFrame)
    end

    dialog --
    :separator{text = "Frames"} --
    :number{
        id = "firstFrame",
        label = "From:",
        text = tostring(app.range.frames[1].frameNumber),
        onchange = onchange
    } --
    :number{
        id = "lastFrame",
        label = "To:",
        text = tostring(app.range.frames[#app.range.frames].frameNumber),
        onchange = onchange
    } --
    :separator() --
    :number{id = "framesToAdd", label = "# of frames to add", text = "1"} --
    :separator() --
    :button{
        id = "tweenButton",
        text = "OK",
        onclick = function()
            Tweener:Tween{
                sprite = sprite,
                firstFrame = dialog.data["firstFrame"],
                lastFrame = dialog.data["lastFrame"],
                framesToAdd = dialog.data["framesToAdd"]
            }
            dialog:close()
        end
    } --
    :button{text = "Cancel"}

    return dialog
end
