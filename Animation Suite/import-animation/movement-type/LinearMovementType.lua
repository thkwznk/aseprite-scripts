local LinearMovementType = {
    sourceWidth = nil,
    sourceHeight = nil,

    xSpeed = 1,
    ySpeed = 0
}

function LinearMovementType:SetMovementDialogSection(options)
    local sourceWidth = options.sourceSize.width
    local sourceHeight = options.sourceSize.height

    if sourceWidth ~= self.sourceWidth or sourceHeight ~= self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xSpeed = math.min(math.max(self.xSpeed, -sourceWidth), sourceWidth)
        self.ySpeed = math.min(math.max(self.ySpeed, -sourceHeight),
                               sourceHeight)
    end

    self.sourceWidth = self.sourceWidth or sourceWidth
    self.sourceHeight = self.sourceHeight or sourceHeight

    options.dialog:slider{
        id = "movement-x-speed",
        label = "X Speed",
        min = -self.sourceWidth,
        max = self.sourceWidth,
        value = self.xSpeed,
        onchange = function()
            self.xSpeed = options.dialog.data["movement-x-speed"]
            options.onchange()
        end
    } --
    :slider{
        id = "movement-y-speed",
        label = "Y Speed",
        min = -self.sourceHeight,
        max = self.sourceHeight,
        value = self.ySpeed,
        onchange = function()
            self.ySpeed = options.dialog.data["movement-y-speed"]
            options.onchange()
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
