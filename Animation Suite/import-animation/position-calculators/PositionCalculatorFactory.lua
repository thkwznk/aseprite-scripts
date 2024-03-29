LinearPositionCalculator = dofile("./LinearPositionCalculator.lua")
Logger = dofile("../../shared/Logger.lua")
MovementType = dofile("../movement-type/MovementType.lua")
PositionCalculator = dofile("./PositionCalculator.lua")
SinePositionCalculator = dofile("./SinePositionCalculator.lua")
StaticPositionCalculator = dofile("./StaticPositionCalculator.lua")
ShakePositionCalculator = dofile("./ShakePositionCalculator.lua")
ParabolaPositionCalculator = dofile("./ParabolaPositionCalculator.lua")

local PositionCalculatorFactory = {}

function PositionCalculatorFactory:CreatePositionCalculator(movementType,
                                                            startPosition,
                                                            endOn, params)
    Logger:Trace("\n=== CreatePositionCalculator ===\n")
    Logger:Trace("Movement type: " .. movementType)
    Logger:Trace("Start position: X = " .. startPosition.X .. ", Y = " ..
                     startPosition.Y)
    Logger:Trace("End on: Axis = " .. tostring(endOn.Axis) .. ", Value = " ..
                     tostring(endOn.Value))
    Logger:Trace("Speed: X = " .. tostring(params.Speed and params.Speed.X) ..
                     ", Y = " .. tostring(params.Speed and params.Speed.Y))

    local calculator = nil

    if movementType == MovementType.Static then
        calculator = StaticPositionCalculator:Create()
    end

    if movementType == MovementType.Sine then
        calculator = SinePositionCalculator:Create()
    end

    if movementType == MovementType.Linear then
        calculator = LinearPositionCalculator:Create()
    end

    if movementType == MovementType.Shake then
        calculator = ShakePositionCalculator:Create()
    end

    if movementType == MovementType.Parabola then
        calculator = ParabolaPositionCalculator:Create()
    end

    calculator:Init(startPosition, endOn, params)
    return calculator
end

return PositionCalculatorFactory
