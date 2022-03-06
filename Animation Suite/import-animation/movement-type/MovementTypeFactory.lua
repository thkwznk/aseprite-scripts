LinearMovementType = dofile("./LinearMovementType.lua")
MovementType = dofile("./MovementType.lua")
SineMovementType = dofile("./SineMovementType.lua")
StaticMovementType = dofile("./StaticMovementType.lua")

local MovementTypeFactory = {}

function MovementTypeFactory:CreateMovementType(type)
    if type == MovementType.Static then return StaticMovementType end
    if type == MovementType.Sine then return SineMovementType end
    if type == MovementType.Linear then return LinearMovementType end
end

return MovementTypeFactory
