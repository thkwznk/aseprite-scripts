include("../common/Transaction")
include("ScaleAlgorithm")

function CreateScaleDialog(dialogTitle)
    local dialog = Dialog(dialogTitle);

    dialog:separator{text = "Nearest Neighbour"}:number{
        id = "scale",
        label = "Scale",
        text = "2",
        decimals = false
    }:button{
        text = "Scale",
        onclick = Transaction(function()
            ScaleAlgorithm:NearestNeighbour(app.activeSprite,
                                            dialog.data["scale"])
        end)
    }:separator{text = "Advanced"}:button{
        text = "Eagle",
        onclick = Transaction(function()
            ScaleAlgorithm:Eagle(app.activeSprite)
        end)
    }:button{
        text = "Scale2x",
        onclick = Transaction(function()
            ScaleAlgorithm:Scale2x(app.activeSprite)
        end)
    }:newrow():button{
        text = "Hawk D",
        onclick = Transaction(function()
            ScaleAlgorithm:Hawk(app.activeSprite, false)
        end)
    }:button{
        text = "Hawk N",
        onclick = Transaction(function()
            ScaleAlgorithm:Hawk(app.activeSprite, true)
        end)
    }:separator():button{
        text = "Undo",
        onclick = function() app.command.Undo() end
    }

    return dialog;
end
