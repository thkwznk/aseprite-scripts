ScaleDialog = dofile("./scale/ScaleDialog.lua");
TweenDialog = dofile("./tween/TweenDialog.lua");
ColorAnalyzerDialog = dofile("./color-analyzer/ColorAnalyzerDialog.lua");

function init(plugin)
    -- Check is UI available
    if not app.isUIAvailable then return end

    plugin:newCommand{
        id = "AdvancedScaling",
        title = "Advanced Scaling...",
        group = "sprite_size",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = ScaleDialog("Advanced Scaling")
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "AddInbetweenFrames",
        title = "Inbetween Frames",
        group = "frame_popup_reverse",
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.frames > 1
        end,
        onclick = function()
            local dialog = TweenDialog("Add Inbetween Frames")
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "ColorAnalyzer",
        title = "Analyze Colors",
        group = "sprite_color",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = ColorAnalyzerDialog("Analyze Colors")

            dialog:show{wait = false}
            dialog:close()

            -- Don't display the dialog in the center of the screen, It covers the image
            local bounds = dialog.bounds
            bounds.x = bounds.x / 2
            bounds.width = 250

            dialog:show{bounds = bounds}
        end
    }
end

function exit(plugin) end

