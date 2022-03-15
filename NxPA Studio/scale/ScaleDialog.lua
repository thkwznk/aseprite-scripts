Transaction = dofile("../shared/Transaction.lua");
ScaleAlgorithm = dofile("./ScaleAlgorithm.lua");

return function(dialogTitle)
    -- Declare a variable for dialog to reference in "onSiteChange" event handler
    local dialog = nil

    local function onSiteChange()
        dialog --
        :modify{id = "eagle", enabled = app.activeSprite ~= nil} --
        :modify{id = "scale2x", enabled = app.activeSprite ~= nil} --
        :modify{id = "scale3x", enabled = app.activeSprite ~= nil}
    end
    app.events:on('sitechange', onSiteChange)

    dialog = Dialog {
        title = dialogTitle,
        onclose = function() app.events:off(onSiteChange) end
    }

    dialog --
    :separator{text = "Algorithm"} --
    :button{
        id = "eagle",
        text = "Eagle",
        onclick = Transaction(function()
            ScaleAlgorithm:Eagle(app.activeSprite)
        end)
    } --
    :newrow() --
    :button{
        id = "scale2x",
        text = "Scale2x",
        onclick = Transaction(function()
            ScaleAlgorithm:Scale2x(app.activeSprite)
        end)
    } --
    :button{
        id = "scale3x",
        text = "Scale3x",
        onclick = Transaction(function()
            ScaleAlgorithm:Scale3x(app.activeSprite)
        end)
    } --
    :separator() --
    :button{text = "Cancel"}

    return dialog
end
