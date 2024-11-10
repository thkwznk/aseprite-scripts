return {
    Now = function() return os.clock() end,
    Date = function()
        local time = os.time()
        return os.date("*t", time)
    end
}
