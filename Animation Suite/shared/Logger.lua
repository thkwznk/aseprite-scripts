LogLevel = dofile("./LogLevel.lua")

local Logger = {level = LogLevel.Warning}

function Logger:Trace(message)
    if self.level <= LogLevel.Trace then print(message) end
end

function Logger:Info(message)
    if self.level <= LogLevel.Info then print(message) end
end

function Logger:Warning(message)
    if self.level <= LogLevel.Warning then print(message) end
end

function Logger:StartTimer(name) return {name = name, startTime = os.clock()} end

function Logger:EndTimer(timer)
    local duration = os.clock() - timer.startTime

    self:Trace(timer.name .. "finished after " .. tostring(duration))
end

return Logger
