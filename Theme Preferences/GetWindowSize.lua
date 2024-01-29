return function()
    if app.apiVersion >= 25 then return app.window end

    local dialog = Dialog()
    dialog:show{wait = false}
    dialog:close()

    return Size(dialog.bounds.x * 2 + dialog.bounds.width,
                dialog.bounds.y * 2 + dialog.bounds.height)
end
