local AdjustColorsDialog = dofile('./AdjustColorsDialog.lua')
local InvertColorsDialog = dofile('./InvertColorsDialog.lua')
local DesaturateColorsDialog = dofile('./DesaturateColorsDialog.lua')

function init(plugin)
    -- API v22 is required for the new menu options (new group and separator) 
    if app.apiVersion < 22 then return end

    plugin:newMenuSeparator{group = "edit_new"}

    plugin:newMenuGroup{
        id = "more_color_adjustments",
        title = "Colors",
        group = "edit_new"
    }

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
            local sprite = app.activeSprite
            local dialog = InvertColorsDialog(sprite)
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

    plugin:newMenuSeparator{group = "more_color_adjustments"}

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
