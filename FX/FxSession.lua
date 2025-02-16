local FxSession = {}

function FxSession:Get(sprite, key, defaultValue)
    if defaultValue ~= nil then
        if self[sprite.filename] then
            if self[sprite.filename][key] ~= nil then
                return self[sprite.filename][key]
            end
        else
            self[sprite.filename] = {}
        end

        self[sprite.filename][key] = defaultValue
        return defaultValue
    end

    if not self[sprite.filename] then return nil end

    return self[sprite.filename][key]
end

function FxSession:Set(sprite, key, value)
    if not self[sprite.filename] then self[sprite.filename] = {} end

    self[sprite.filename][key] = value
end

return FxSession
