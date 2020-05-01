table.map = function(t, f)
    local result = {};
    for k, v in pairs(t) do result[k] = f(v) end
    return result;
end