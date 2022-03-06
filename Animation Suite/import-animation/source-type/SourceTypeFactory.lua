SourceType = dofile("./SourceType.lua")
LayerSourceType = dofile("./LayerSourceType.lua")
TagSourceType = dofile("./TagSourceType.lua")
SelectionSourceType = dofile("./SelectionSourceType.lua")

local SourceTypeFactory = {}

function SourceTypeFactory:CreateSourceType(type)
    if type == SourceType.Layer then return LayerSourceType end
    if type == SourceType.Tag then return TagSourceType end
    if type == SourceType.Selection then return SelectionSourceType end
end

return SourceTypeFactory
