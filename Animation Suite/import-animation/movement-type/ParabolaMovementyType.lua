local ParabolaMovementyType = {
    sourceWidth = nil,
    sourceHeight = nil,

    xSpeed = 1,
    xPeak = nil,
    yPeak = nil
}

function ParabolaMovementyType:SetMovementDialogSection(options)
    local sourceWidth = options.sourceSize.width

    if sourceWidth ~= self.sourceWidth then
        self.sourceWidth = nil

        self.xSpeed = math.min(self.xSpeed, sourceWidth)
    end

    self.sourceWidth = self.sourceWidth or sourceWidth

    self.xSpeed = self.xSpeed or 1
    self.xPeak = self.xPeak or options.targetSize.width / 2
    self.yPeak = self.yPeak or options.targetSize.height / 2

    options.dialog:slider{
        id = "parabola-movement-x-speed",
        label = "Speed",
        min = 1,
        max = sourceWidth,
        value = self.xSpeed,
        onchange = function()
            self.xSpeed = options.dialog.data["parabola-movement-x-speed"]
            options.onchange()
        end
    } --
    :slider{
        id = "parabola-movement-x-peak",
        label = "X Peak",
        min = 0,
        max = options.targetSize.width,
        value = self.xPeak,
        onchange = function()
            self.xPeak = options.dialog.data["parabola-movement-x-peak"]
            options.onchange()
        end
    } --
    :slider{
        id = "parabola-movement-y-peak",
        label = "Y Peak",
        min = 0,
        max = options.targetSize.height,
        value = self.yPeak,
        onchange = function()
            self.yPeak = options.dialog.data["parabola-movement-y-peak"]
            options.onchange()
        end
    } --
end

function ParabolaMovementyType:GetMovementParams()
    return {
        Speed = {X = self.xSpeed, Y = 0},
        Peak = {X = self.xPeak, Y = self.yPeak}
    }
end

function ParabolaMovementyType:Clear()
    self.xPeak = nil
    self.yPeak = nil
end

return ParabolaMovementyType
