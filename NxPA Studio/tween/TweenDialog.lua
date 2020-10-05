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
    local dialog = Dialog(dialogTitle);

    local frameNumbers = getFirstAndLastFrameNumber(app.activeSprite)

    dialog:number{
        id = "firstFrame",
        label = "From frame",
        text = tostring(frameNumbers.first)
    }:number{
        id = "lastFrame",
        label = "To frame",
        text = tostring(frameNumbers.last)
    }:number{id = "framesToAdd", label = "Number of frames to add:", text = "1"}
        :button{
            text = "Tween",
            onclick = function()
                Tweener:tween{
                    sprite = app.activeSprite,
                    firstFrame = dialog.data["firstFrame"],
                    lastFrame = dialog.data["lastFrame"],
                    framesToAdd = dialog.data["framesToAdd"]
                }
            end
        }

    return dialog;
end
