local LinearMovementType = {
    sourceWidth = nil,
    sourceHeight = nil,

    xSpeed = 1,
    ySpeed = 0
}

function LinearMovementType:SetMovementDialogSection(sourceSize, dialog,
                                                     onchange)
    if sourceSize.width ~= self.sourceWidth or sourceSize.height ~=
        self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xSpeed = math.min(math.max(self.xSpeed, -sourceSize.width),
                               sourceSize.width)
        self.ySpeed = math.min(math.max(self.ySpeed, -sourceSize.height),
                               sourceSize.height)
    end

    self.sourceWidth = self.sourceWidth or sourceSize.width
    self.sourceHeight = self.sourceHeight or sourceSize.height

    dialog:slider{
        id = "movement-x-speed",
        label = "X Speed",
        min = -self.sourceWidth,
        max = self.sourceWidth,
        value = self.xSpeed,
        onchange = function()
            self.xSpeed = dialog.data["movement-x-speed"]
            onchange()
        end
    } --
    :slider{
        id = "movement-y-speed",
        label = "Y Speed",
        min = -self.sourceHeight,
        max = self.sourceHeight,
        value = self.ySpeed,
        onchange = function()
            self.ySpeed = dialog.data["movement-y-speed"]
            onchange()
        end
    }
end

function LinearMovementType:GetMovementParams()
    return {Speed = {X = self.xSpeed, Y = self.ySpeed}}
end

function LinearMovementType:Clear()
    self.xSpeed = 1
    self.ySpeed = 0
end

return LinearMovementType
