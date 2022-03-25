local ShakeMovementType = {frames = 1, xRange = 1, yRange = 1}

function ShakeMovementType:SetMovementDialogSection(options)
    local sourceWidth = options.sourceSize.width
    local sourceHeight = options.sourceSize.height

    if sourceWidth ~= self.sourceWidth or sourceHeight ~= self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xRange = math.min(self.xRange, sourceWidth)
        self.yRange = math.min(self.yRange, sourceHeight)
    end

    self.sourceWidth = self.sourceWidth or sourceWidth
    self.sourceHeight = self.sourceHeight or sourceHeight

    self.frames = self.frames or 1
    self.xRange = self.xRange or 1
    self.yRange = self.yRange or 1

    options.dialog:number{
        id = "frames",
        label = "Frames",
        text = tostring(self.frames),
        onchange = function()
            self.frames = options.dialog.data["frames"] or 1
            options.onchange()
        end
    } --
    :slider{
        id = "shake-movement-x-range",
        label = "X Range",
        min = 0,
        max = self.sourceWidth,
        value = self.xRange,
        onchange = function()
            self.xRange = options.dialog.data["shake-movement-x-range"]
            options.onchange()
        end
    } --
    :slider{
        id = "shake-movement-y-range",
        label = "Y Range",
        min = 0,
        max = self.sourceHeight,
        value = self.yRange,
        onchange = function()
            self.yRange = options.dialog.data["shake-movement-y-range"]
            options.onchange()
        end
    } --
end

function ShakeMovementType:GetMovementParams()
    return {Frames = self.frames, Range = {X = self.xRange, Y = self.yRange}}
end

function ShakeMovementType:Clear()
    self.sourceWidth = nil
    self.sourceHeight = nil

    self.frames = 1
    self.xRange = 1
    self.yRange = 1
end

return ShakeMovementType
