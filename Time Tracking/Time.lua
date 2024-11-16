return {
    Now = function() return os.clock() end,
    Date = function()
        local time = os.time()
        return os.date("*t", time)
    end,
    Parse = function(time)
        local seconds = time % 60
        local hours = math.floor(time / 3600)
        local minutes = math.floor((time - (hours * 3600)) / 60)

        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
}
