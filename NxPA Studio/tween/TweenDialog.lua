Tweener = dofile("./Tweener.lua");

return function(dialogTitle)
    local dialog = Dialog(dialogTitle);

    dialog:number{
        id = "frames",
        label = "Frames:",
        text = "2",
        decimals = false
    }:button{
        text = "Tween",
        onclick = function()
            Tweener:tween{
                sprite = app.activeSprite,
                loop = dialog.data["loop"],
                frames = dialog.data["frames"]
            }
        end
    }:check{id = "loop", label = "Loop:", selected = false}

    return dialog;
end
