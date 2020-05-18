ScaleDialog = dofile("./scale/ScaleDialog.lua");
TweenDialog = dofile("./tween/TweenDialog.lua");

function init(plugin)
    plugin:newCommand{
        id = "advanced-scaling",
        title = "Advanced Scaling",
        group = "sprite_size",
        onclick = function()
            local dialog = ScaleDialog("Advanced Scaling");
            dialog:show{wait = false};
        end
    }

    plugin:newCommand{
        id = "add-inbetween-frame",
        title = "Add Inbetween Frames",
        group = "cel_delete",
        onclick = function()
            local dialog = TweenDialog("Add Inbetween Frames");
            dialog:show{wait = false};
        end
    }
end

function exit(plugin) end

