Logger = dofile("../../shared/Logger.lua")
PositionCalculator = dofile("./PositionCalculator.lua")

local ParabolaPositionCalculator = PositionCalculator:Create()

function ParabolaPositionCalculator:GetPositions()
    Logger:Trace("Getting Positions...")

    local i = 0

    local firstPositionReturned = false

    local a = (self.startPosition.Y - self.movementParams.Peak.Y) /
                  ((self.startPosition.X - self.movementParams.Peak.X) ^ 2)

    return function()
        if not firstPositionReturned then
            firstPositionReturned = true
            return self.startPosition.X, self.startPosition.Y
        end

        -- Safeguards
        if not self:_HasValidParameters() then return nil end

        i = i + 1

        local x = self.startPosition.X + i * self.movementParams.Speed.X
        local y = a * ((x - self.movementParams.Peak.X) ^ 2) +
                      self.movementParams.Peak.Y

        Logger:Trace("X = " .. x .. ", Y = " .. y)

        if self:_ReachedEnd(x, y) then return nil end

        return x, y
    end
end

return ParabolaPositionCalculator
