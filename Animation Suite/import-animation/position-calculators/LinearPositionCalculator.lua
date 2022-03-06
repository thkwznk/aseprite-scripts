Logger = dofile("../../shared/Logger.lua")
PositionCalculator = dofile("./PositionCalculator.lua")

local LinearPositionCalculator = PositionCalculator:Create()

function LinearPositionCalculator:GetPositions()
    Logger:Trace("Getting Positions...")

    local x = self.startPosition.X
    local y = self.startPosition.Y

    local firstPositionReturned = false

    return function()
        Logger:Trace("X = " .. x .. ", Y = " .. y)

        if not firstPositionReturned then
            firstPositionReturned = true
            return x, y
        end

        -- Safeguards
        if not self:_HasValidParameters() then return nil end

        x = x + self.movementParams.Speed.X
        y = y + self.movementParams.Speed.Y

        if self:_ReachedEnd(x, y) then return nil end

        return x, y
    end
end

return LinearPositionCalculator
