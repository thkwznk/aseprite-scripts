include("scale/ScaleDialog")
include("tween/TweenDialog")
include("touch-screen-helper/TouchScreenHelperDialog")

function init(plugin)
    -- TODO: Use plugin.preferences to save data:
    -- -- Last window position
    -- -- Data for Note script & remove dependency on file system access

    plugin:newCommand{
        id = "advanced-scaling",
        title = "Advanced Scaling",
        group = "sprite_size",
        onclick = function()
            local dialog = CreateScaleDialog("Advanced Scaling");

            dialog:show{wait = false};
        end
    }

    plugin:newCommand{
        id = "add-inbetween-frame",
        title = "Add Inbetween Frames",
        group = "cel_delete",
        onclick = function()
            local dialog = CreateTweenDialog("Add Inbetween Frames");

            dialog:show{wait = false};
        end
    }

    plugin:newCommand{
        id = "touch-screen-helper",
        title = "Touch Screen Helper",
        group = "view_controls",
        onclick = function()
            local dialog = CreateTouchScreenHelperDialog("TSHelper");

            dialog:show{wait = false};
        end
    }
end

function exit(plugin) end

