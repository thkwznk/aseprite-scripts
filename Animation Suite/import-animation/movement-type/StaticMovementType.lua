local StaticMovementType = {frames = 1}

function StaticMovementType:SetMovementDialogSection(sourceSize, dialog,
                                                     onchange)
    dialog:number{
        id = "frames",
        label = "Frames",
        text = tostring(self.frames),
        onchange = function()
            self.frames = dialog.data["frames"] or 1
            onchange()
        end
    }
end

function StaticMovementType:GetMovementParams()
    return {Speed = {X = 0, Y = 0}, Frames = self.frames}
end

function StaticMovementType:Clear() self.frames = 1 end

return StaticMovementType
