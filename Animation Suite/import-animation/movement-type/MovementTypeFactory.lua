LinearMovementType = dofile("./LinearMovementType.lua")
MovementType = dofile("./MovementType.lua")
SineMovementType = dofile("./SineMovementType.lua")
StaticMovementType = dofile("./StaticMovementType.lua")
ShakeMovementType = dofile("./ShakeMovementType.lua")
ParabolaMovementyType = dofile("./ParabolaMovementyType.lua")

local MovementTypeFactory = {}

function MovementTypeFactory:CreateMovementType(type)
    if type == MovementType.Static then return StaticMovementType end
    if type == MovementType.Sine then return SineMovementType end
    if type == MovementType.Linear then return LinearMovementType end
    if type == MovementType.Shake then return ShakeMovementType end
    if type == MovementType.Parabola then return ParabolaMovementyType end
end

return MovementTypeFactory
