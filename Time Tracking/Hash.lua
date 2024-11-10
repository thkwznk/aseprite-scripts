local sha1 = dofile("./sha1.lua")

-- TODO: Integrate hashing into the new SHA1 class/method

local hash, cached, hashCache = nil, nil, {}

return function(text)
    cached = hashCache[text]
    if cached then return cached end

    -- Add a "_" as the first character to always make it a valid table key
    hash = "_" .. sha1.hex(text)
    hashCache[text] = hash

    return hash
end
