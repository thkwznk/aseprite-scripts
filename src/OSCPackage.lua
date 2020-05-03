include("touch-screen-helper/TouchScreenHelperDialog")

function init(plugin)
    plugin:newCommand{
        id = "on-screen-controls",
        title = "On-Screen Controls",
        group = "view_controls",
        onclick = function()
            local dialog = CreateTouchScreenHelperDialog("On-Screen Controls");
            dialog:show{wait = false};
        end
    }
end

function exit(plugin) end

