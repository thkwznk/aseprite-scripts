Logger = dofile("../../shared/Logger.lua")
PositionCalculator = dofile("./PositionCalculator.lua")

local ShakePositionCalculator = PositionCalculator:Create()

function ShakePositionCalculator:GetPositions()
    Logger:Trace("Getting Positions...")

    local frames = self.movementParams.Frames

    local x = self.startPosition.X
    local y = self.startPosition.Y

    return function()
        Logger:Trace("X = " .. x .. ", Y = " .. y)

        if frames <= 0 then return nil end
        frames = frames - 1

        local xDelta = math.random(0, self.movementParams.Range.X * 2) -
                           self.movementParams.Range.X
        local yDelta = math.random(0, self.movementParams.Range.Y * 2) -
                           self.movementParams.Range.Y

        x = self.startPosition.X + xDelta
        y = self.startPosition.Y + yDelta

        return x, y
    end
end

return ShakePositionCalculator
