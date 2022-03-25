local SineMovementType = {
    sourceWidth = nil,
    sourceHeight = nil,

    xSpeed = 1,
    ySpeed = 0,
    xRange = 4,
    yRange = 24
}

function SineMovementType:SetMovementDialogSection(sourceSize, dialog, onchange)
    if sourceSize.width ~= self.sourceWidth or sourceSize.height ~=
        self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xSpeed = math.min(math.max(self.xSpeed, -sourceSize.width),
                               sourceSize.width)
        self.ySpeed = math.min(math.max(self.ySpeed, -sourceSize.height),
                               sourceSize.height)
        self.xRange = math.min(math.max(self.xRange, -sourceSize.width * 4),
                               sourceSize.width * 4)
        self.yRange = math.min(math.max(self.yRange, -sourceSize.height * 4),
                               sourceSize.height * 4)
    end

    self.sourceWidth = self.sourceWidth or sourceSize.width
    self.sourceHeight = self.sourceHeight or sourceSize.height
    self.xRange = self.xRange or sourceSize.width
    self.yRange = self.yRange or sourceSize.height

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
    } --
    :slider{
        id = "movement-x-range",
        label = "X Range",
        min = -self.sourceWidth * 4,
        max = self.sourceWidth * 4,
        value = self.xRange,
        onchange = function()
            self.xRange = dialog.data["movement-x-range"]
            onchange()
        end
    } --
    :slider{
        id = "movement-y-range",
        label = "Y Range",
        min = -self.sourceHeight * 4,
        max = self.sourceHeight * 4,
        value = self.yRange,
        onchange = function()
            self.yRange = dialog.data["movement-y-range"]
            onchange()
        end
    }
end

function SineMovementType:GetMovementParams()
    return {
        Speed = {X = self.xSpeed, Y = self.ySpeed},
        Range = {X = self.xRange, Y = self.yRange}
    }
end

function SineMovementType:Clear()
    self.sourceWidth = nil
    self.sourceHeight = nil

    self.xSpeed = 1
    self.ySpeed = 0
    self.xRange = 0
    self.yRange = 0
end

return SineMovementType
