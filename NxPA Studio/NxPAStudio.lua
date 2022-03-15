ScaleDialog = dofile("./scale/ScaleDialog.lua");
TweenDialog = dofile("./tween/TweenDialog.lua");
ColorAnalyzerDialog = dofile("./color-analyzer/ColorAnalyzerDialog.lua");

function init(plugin)
    plugin:newCommand{
        id = "advanced-scaling",
        title = "Advanced Scaling",
        group = "sprite_size",
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            local dialog = ScaleDialog("Advanced Scaling");
            dialog:show{wait = false};
        end
    }

    plugin:newCommand{
        id = "add-inbetween-frame",
        title = "Add Inbetween Frames",
        group = "cel_delete",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            local dialog = TweenDialog("Add Inbetween Frames")
            dialog:show{wait = true}
        end
    }

    plugin:newCommand{
        id = "color-analyzer",
        title = "Analyze Colors",
        group = "sprite_color",
        onclick = function()
            -- Check are UI and sprite available
            if not app.isUIAvailable then return end
            if app.activeSprite == nil then return end

            ColorAnalyzerDialog:Create("Analyze Colors");
            ColorAnalyzerDialog:Show(false);
        end
    }
end

function exit(plugin) end

