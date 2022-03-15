Tweener = dofile("./Tweener.lua");

function getFirstAndLastFrameNumber(sprite)
    if app.range.isEmpty then return {first = 1, last = #sprite.frames} end

    local first = #sprite.frames;
    local last = 1;

    for _, frame in ipairs(app.range.frames) do
        local frameNumber = frame.frameNumber;
        if frameNumber < first then first = frameNumber; end
        if frameNumber > last then last = frameNumber; end
    end

    return {first = first, last = last}
end

return function(dialogTitle)
    local dialog = Dialog(dialogTitle)
    local frameNumbers = getFirstAndLastFrameNumber(app.activeSprite)

    local function validateButton()
        dialog:modify{
            id = "tweenButton",
            enabled = dialog.data["firstFrame"] < dialog.data["lastFrame"]
        }
    end

    dialog --
    :separator{text = "Frames"} --
    :slider{
        id = "firstFrame",
        label = "From",
        min = 1,
        max = #app.activeSprite.frames,
        value = frameNumbers.first,
        onchange = validateButton
    } --
    :slider{
        id = "lastFrame",
        label = "To",
        min = 1,
        max = #app.activeSprite.frames,
        value = frameNumbers.last,
        onchange = validateButton
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
