function GetWindowSize()
    if app.apiVersion >= 25 then return app.window end

    local dialog = Dialog()
    dialog:show{wait = false}
    dialog:close()

    return Size(dialog.bounds.x * 2 + dialog.bounds.width,
                dialog.bounds.y * 2 + dialog.bounds.height)
end

return function(size, position)
    local window = GetWindowSize()

    local uiScale = app.preferences.general["ui_scale"]
    size = Size(size.width * uiScale, size.height * uiScale)

    local x = (window.width - size.width) / 2
    local y = (window.height - size.height) / 2

    if position then
        x = position.x
        y = position.y
    end

    return Rectangle(x, y, size.width, size.height)
end
