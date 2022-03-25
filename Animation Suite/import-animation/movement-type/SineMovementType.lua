local SineMovementType = {
    sourceWidth = nil,
    sourceHeight = nil,

    xSpeed = 1,
    ySpeed = 0,
    xRange = 4,
    yRange = 24
}

function SineMovementType:SetMovementDialogSection(options)
    local sourceWidth = options.sourceSize.width
    local sourceHeight = options.sourceSize.height

    if sourceWidth ~= self.sourceWidth or sourceHeight ~= self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xSpeed = math.min(math.max(self.xSpeed, -sourceWidth), sourceWidth)
        self.ySpeed = math.min(math.max(self.ySpeed, -sourceHeight),
                               sourceHeight)
        self.xRange = math.min(math.max(self.xRange, -sourceWidth * 4),
                               sourceWidth * 4)
        self.yRange = math.min(math.max(self.yRange, -sourceHeight * 4),
                               sourceHeight * 4)
    end

    self.sourceWidth = self.sourceWidth or sourceWidth
    self.sourceHeight = self.sourceHeight or sourceHeight
    self.xRange = self.xRange or sourceWidth
    self.yRange = self.yRange or sourceHeight

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
    } --
    :slider{
        id = "movement-x-range",
        label = "X Range",
        min = -self.sourceWidth * 4,
        max = self.sourceWidth * 4,
        value = self.xRange,
        onchange = function()
            self.xRange = options.dialog.data["movement-x-range"]
            options.onchange()
        end
    } --
    :slider{
        id = "movement-y-range",
        label = "Y Range",
        min = -self.sourceHeight * 4,
        max = self.sourceHeight * 4,
        value = self.yRange,
        onchange = function()
            self.yRange = options.dialog.data["movement-y-range"]
            options.onchange()
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
