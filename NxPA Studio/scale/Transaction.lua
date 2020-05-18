return function(action)
    return function()
        if app.activeSprite == nil then return end

        app.transaction(action)
        app.refresh()
    end
end
