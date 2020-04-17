local Run = {}

function Run:ForActiveSprite(action)
    local sprite = app.activeSprite

    if sprite == nil then return end

    action(sprite)
end

function Run:Transaction(action)
    app.transaction(action)
    app.refresh()
end
