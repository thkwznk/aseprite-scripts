function StackIndexId(layer)
    local id = tostring(layer.stackIndex)

    local parent = layer.parent

    while parent ~= layer.sprite do
        id = tostring(parent.stackIndex) .. "-" .. id
        parent = parent.parent
    end

    return id
end

return StackIndexId
