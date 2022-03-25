local StaticMovementType = {frames = 1}

function StaticMovementType:SetMovementDialogSection(options)
    options.dialog:number{
        id = "frames",
        label = "Frames",
        text = tostring(self.frames),
        onchange = function()
            self.frames = options.dialog.data["frames"] or 1
            options.onchange()
        end
    }
end

function StaticMovementType:GetMovementParams() return {Frames = self.frames} end

function StaticMovementType:Clear() self.frames = 1 end

return StaticMovementType
