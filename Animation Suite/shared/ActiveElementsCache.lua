local ActiveElementsCache = {cache = {}}

function ActiveElementsCache:_GetActiveElementsFromSprite(sprite)
    local cached = self.cache[sprite.filename]

    if cached == nil then
        local currentSprite = app.activeSprite

        app.activeSprite = sprite
        self.cache[sprite.filename] = {
            activeLayer = app.activeLayer,
            activeFrame = app.activeFrame,
            activeCel = app.activeCel
        }
        app.activeSprite = currentSprite

        cached = self.cache[sprite.filename]
    end

    return cached
end

function ActiveElementsCache:GetActiveCel(sprite)
    local cached = self:_GetActiveElementsFromSprite(sprite)
    return cached.activeCel
end

function ActiveElementsCache:Clear() self.cache = {} end

return ActiveElementsCache
