Logger = dofile("../../shared/Logger.lua")
PositionCalculator = dofile("./PositionCalculator.lua")

local SinePositionCalculator = PositionCalculator:Create()

function SinePositionCalculator:GetPositions()
    Logger:Trace("Getting Positions...")

    local i = 0

    local firstPositionReturned = false

    return function()
        if not firstPositionReturned then
            firstPositionReturned = true
            return self.startPosition.X, self.startPosition.Y
        end

        -- Safeguards
        if not self:_HasValidParameters() then return nil end

        i = i + 1

        local sineValue = math.sin(math.rad(i * self.movementParams.Range.X))

        local x = self.startPosition.X + i * self.movementParams.Speed.X
        local y = self.startPosition.Y + i * self.movementParams.Speed.Y +
                      sineValue * (self.movementParams.Range.Y / 2)

        if self:_ReachedEnd(x, y) then return nil end

        Logger:Trace("X = " .. x .. ", Y = " .. y)
        return x, y
    end
end

return SinePositionCalculator
