Axis = dofile("../Axis.lua")
Logger = dofile("../../shared/Logger.lua")

local PositionCalculator = {}

function PositionCalculator:Create(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PositionCalculator:Init(startPosition, endOn, params)
    self.startPosition = startPosition
    self.endOn = endOn
    self.movementParams = params

    Logger:Trace("Initializing Position Calculator...")
    Logger:Trace("Start Position, X = " .. self.startPosition.X .. ", Y = " ..
                     self.startPosition.Y)
    Logger:Trace(
        "End On, Axis = " .. tostring(self.endOn.Axis) .. ", Value = " ..
            tostring(self.endOn.Value))
    Logger:Trace("Movement Params, Speed, X = " ..
                     tostring(
                         self.movementParams.Speed and
                             self.movementParams.Speed.X) .. ", Y = " ..
                     tostring(
                         self.movementParams.Speed and
                             self.movementParams.Speed.Y))
end

function PositionCalculator:GetPositions() end

function PositionCalculator:GetEndOnValue()
    if self.endOn.Axis ~= nil and self.endOn.Value ~= nil then
        return self.endOn.Value
    end
end

function PositionCalculator:_ReachedEnd(x, y)
    if self.endOn.Axis ~= nil and self.endOn.Value ~= nil then
        if self.endOn.Axis == Axis.X then
            if (self.startPosition.X < self.endOn.Value and x > self.endOn.Value) or
                (self.startPosition.X > self.endOn.Value and x <
                    self.endOn.Value) then return true end
        end

        if self.endOn.Axis == Axis.Y then
            if (self.startPosition.Y < self.endOn.Value and y > self.endOn.Value) or
                (self.startPosition.Y > self.endOn.Value and y <
                    self.endOn.Value) then return true end
        end
    end

    if x < self.endOn.Bounds.x or x > self.endOn.Bounds.width or y <
        self.endOn.Bounds.y or y > self.endOn.Bounds.height then return true end

    return false
end

function PositionCalculator:_HasValidParameters()
    return self.movementParams.Speed.X ~= 0 or self.movementParams.Speed.Y ~= 0
end

return PositionCalculator
