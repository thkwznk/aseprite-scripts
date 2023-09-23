local AdjustColorsDialog = dofile('./AdjustColorsDialog.lua')
local InvertColorsDialog = dofile('./InvertColorsDialog.lua')
local DesaturateColorsDialog = dofile('./DesaturateColorsDialog.lua')

function init(plugin)
    -- TODO: Add comment
    if app.apiVersion < 22 then return end

    plugin:newMenuSeparator{group = "edit_new"}

    plugin:newMenuGroup{
        id = "more_color_adjustments",
        title = "Colors",
        group = "edit_new"
    }

    -- "Adjust...", "Invert..." (Color/Value, with different options), "To Alpha", "Desaturate..." (with different options) - previews for all of them

    plugin:newCommand{
        id = "AdjustColorsOklab",
        title = "Adjust...",
        group = "more_color_adjustments",
        onenabled = function() return app.activeCel ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = AdjustColorsDialog(sprite)
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "InvertColorsOklab",
        title = "Invert...",
        group = "more_color_adjustments",
        onenabled = function() return app.activeCel ~= nil end,
        onclick = function()
            local dialog = InvertColorsDialog()
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "DestaurateColorsOklab",
        title = "Desaturate...",
        group = "more_color_adjustments",
        onenabled = function() return app.activeCel ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local dialog = DesaturateColorsDialog(sprite)
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "ColorToAlpha",
        title = "To Alpha",
        group = "more_color_adjustments",
        onenabled = function() return app.activeCel ~= nil end,
        onclick = function()
            -- TODO: Move the implementation here
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end

-- TODO: Add a common implementation for the preview canvas
