local FileProvider = {}

function FileProvider:ReadAll(filePath)
    local file = assert(io.open(filePath, "rb"))
    local content = file:read("*all")
    file:close()

    return content
end

function FileProvider:Write(filePath, content)
    local file = io.open(filePath, "w")

    if file then
        file:write(content)
        file:close()
    end
end

return FileProvider
