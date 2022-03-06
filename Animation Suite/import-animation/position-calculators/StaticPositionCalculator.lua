Logger = dofile("../../shared/Logger.lua")
PositionCalculator = dofile("./PositionCalculator.lua")

local LinearPositionCalculator = PositionCalculator:Create()

function LinearPositionCalculator:GetPositions()
    Logger:Trace("Getting Positions...")

    local frames = self.movementParams.Frames

    local x = self.startPosition.X
    local y = self.startPosition.Y

    return function()
        Logger:Trace("X = " .. x .. ", Y = " .. y)

        if frames <= 0 then return nil end

        frames = frames - 1

        return x, y
    end
end

return LinearPositionCalculator
