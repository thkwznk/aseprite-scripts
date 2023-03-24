ControlsDialog = dofile("./ControlsDialog.lua");

function init(plugin)
    plugin:newCommand{
        id = "on-screen-controls",
        title = "On-Screen Controls",
        group = "view_controls",
        onclick = function()
            local dialog

            dialog = ControlsDialog {
                title = "On-Screen Controls",
                preferences = plugin.preferences,
                onclose = function()
                    plugin.preferences.x = dialog.bounds.x;
                    plugin.preferences.y = dialog.bounds.y;
                end
            }

            dialog:show{wait = false}
        end
    }
end

function exit(plugin) end

