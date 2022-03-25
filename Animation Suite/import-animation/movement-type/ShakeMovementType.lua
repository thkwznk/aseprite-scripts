local ShakeMovementType = {frames = 1, xRange = 1, yRange = 1}

function ShakeMovementType:SetMovementDialogSection(sourceSize, dialog, onchange)
    if sourceSize.width ~= self.sourceWidth or sourceSize.height ~=
        self.sourceHeight then
        self.sourceWidth = nil
        self.sourceHeight = nil

        self.xRange = math.min(self.xRange, sourceSize.width)
        self.yRange = math.min(self.yRange, sourceSize.height)
    end

    self.sourceWidth = self.sourceWidth or sourceSize.width
    self.sourceHeight = self.sourceHeight or sourceSize.height

    self.frames = self.frames or 1
    self.xRange = self.xRange or 1
    self.yRange = self.yRange or 1

    dialog:number{
        id = "frames",
        label = "Frames",
        text = tostring(self.frames),
        onchange = function()
            self.frames = dialog.data["frames"] or 1
            onchange()
        end
    } --
    :slider{
        id = "shake-movement-x-range",
        label = "X Range",
        min = 0,
        max = self.sourceWidth,
        value = self.xRange,
        onchange = function()
            self.xRange = dialog.data["shake-movement-x-range"]
            onchange()
        end
    } --
    :slider{
        id = "shake-movement-y-range",
        label = "Y Range",
        min = 0,
        max = self.sourceHeight,
        value = self.yRange,
        onchange = function()
            self.yRange = dialog.data["shake-movement-y-range"]
            onchange()
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
