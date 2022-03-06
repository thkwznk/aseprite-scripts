Looper = dofile("./Looper.lua");

local LoopDialog = {
    title = nil,
    dialog = nil,
    bounds = nil,
    layers = {},
    layersToLoop = {}
}

function LoopDialog:GetAvailableLayers()
    local layers = {}

    for _, layer in ipairs(app.activeSprite.layers) do
        -- TODO: Handle background layersF
        if layer.isBackground then goto skip end

        table.insert(layers, layer.name)

        ::skip::
    end

    return layers
end

function LoopDialog:_LayerSelected(layer)
    for _, layerToLoop in ipairs(self.layersToLoop) do
        if layerToLoop == layer then return true end
    end

    return false
end

function LoopDialog:Create(title)
    self.title = title or self.title
    self.layersToLoop = {}
    self.layers = self:GetAvailableLayers()
end

function LoopDialog:Show()
    self.dialog = Dialog(self.title)

    self.dialog --
    :separator{text = "Select layers to loop:"} --

    -- Get all layers
    for _, layer in ipairs(self.layers) do
        local isSelected = self:_LayerSelected(layer)

        self.dialog:button{
            label = layer,
            text = isSelected and "-" or "+",
            onclick = function()
                if isSelected then
                    for i = 1, #self.layersToLoop do
                        if self.layersToLoop[i] == layer then
                            table.remove(self.layersToLoop, i)
                            break
                        end
                    end
                else
                    table.insert(self.layersToLoop, layer)
                end

                self:Refresh()
            end
        }
    end

    self.dialog:separator{
        text = "Selected " .. tostring(#self.layersToLoop) .. " Layers to loop"
    }:number{
        id = "maxNumberOfFrames",
        label = "Max # of Frames",
        text = tostring(1024),
        decimals = 0
    }:button{
        text = "Loop Animations",
        enabled = #self.layersToLoop > 1,
        onclick = function()
            app.transaction(function()
                Looper:Loop(app.activeSprite, self.layersToLoop,
                            self.dialog.data["maxNumberOfFrames"])
            end)
            self.dialog:close()
        end
    }

    -- Reset bounds
    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        self.dialog.bounds = newBounds
    end

    self.dialog:show()
end

function LoopDialog:Refresh()
    self.bounds = self.dialog.bounds
    self.dialog:close()
    self:Show()
end

return LoopDialog
