AnimationImporter = dofile("./AnimationImporter.lua")
Axis = dofile("./Axis.lua")
GuideLayer = dofile("./GuideLayer.lua")
ImageProviderFactory = dofile("./image-providers/ImageProviderFactory.lua")
Logger = dofile("../shared/Logger.lua")
MovementType = dofile("./movement-type/MovementType.lua")
MovementTypeFactory = dofile("./movement-type/MovementTypeFactory.lua")
PositionCalculatorFactory = dofile(
                                "./position-calculators/PositionCalculatorFactory.lua")
SourceType = dofile("./source-type/SourceType.lua")
SourceTypeFactory = dofile("./source-type/SourceTypeFactory.lua")
SpriteHelper = dofile("../shared/SpriteHelper.lua")

local EndPositionType = {Line = "Reached line", OffScreen = "Sprite off-screen"}

local ImportAnimationDialog = {
    targetSprite = nil, -- Sprite to import to
    sourceSprite = nil, -- Sprite to import from

    targetLayer = nil,
    targetFrameNumber = nil,

    guideLayer = nil,
    imageProvider = nil,
    positionCalculator = nil,

    sourceType = nil,
    movementType = nil,

    dialog = nil, -- Dialog object reference
    title = nil, -- Dialog title
    bounds = nil, -- Dialog bounds
    data = {} -- Dialog data
}

function ImportAnimationDialog:_GetSprites()
    Logger:Trace("Getting sprites...")
    local timer = Logger:StartTimer("Getting sprites")

    local spriteNames = {}
    local sprites = {}

    for i, sprite in ipairs(app.sprites) do
        if sprite == self.targetSprite then goto continue end

        local spriteName = sprite.filename:match("^.+\\(.+)$") or
                               ("Sprite #" .. tostring(i))
        Logger:Trace("Sprite " .. tostring(i) .. ": Name = " .. spriteName)

        sprites[spriteName] = sprite
        table.insert(spriteNames, spriteName)

        ::continue::
    end

    Logger:EndTimer(timer)

    return spriteNames, sprites
end

function ImportAnimationDialog:Create(config)
    self.title = (config and config["title"]) or self.title
    self.targetSprite = (config and config["targetSprite"]) or self.targetSprite
    self.targetLayer = (config and config["targetLayer"]) or self.targetLayer
    self.targetFrameNumber = (config and config["targetFrameNumber"]) or
                                 self.targetFrameNumber

    if self.guideLayer == nil then
        self.guideLayer = GuideLayer:Create()
        self.guideLayer:Init(self.targetSprite)
    end

    self.dialog = Dialog {
        title = self.title,
        onclose = function() self:_ClearHistory() end
    }

    local spriteNames, sprites = self:_GetSprites()

    -- Initialize source sprite
    self.data.sourceSprite = self.data.sourceSprite or spriteNames[1]
    self.sourceSprite = self.sourceSprite or sprites[self.data.sourceSprite]

    -- Initialize values
    self:_InitializeData()

    -- Initial setup for the Source Type
    self:_UpdateSourceType()

    -- Initial setup for the Movement Type
    self:_UpdateMovementType()

    self.dialog --
    :slider{
        id = "frame",
        label = "Frame",
        min = 1,
        max = #self.targetSprite.frames + 1,
        value = self.targetFrameNumber,
        onchange = function()
            local frames = self.targetSprite.frames
            self.targetFrameNumber = self.dialog.data["frame"]
            app.activeFrame = frames[math.min(#self.targetSprite.frames,
                                              self.targetFrameNumber)]
        end
    } -- Source Section
    :separator{text = "Source"} --
    :combobox{
        id = "source-sprite",
        label = "Sprite",
        options = spriteNames,
        option = self.data.sourceSprite,
        onchange = function()
            self.data.sourceSprite = self.dialog.data["source-sprite"]
            self.sourceSprite = sprites[self.data.sourceSprite]
            self:Refresh()
        end
    } --
    :combobox{
        id = "source-type",
        label = "From",
        options = SourceType,
        option = self.data.sourceType,
        onchange = function()
            self.data.sourceType = self.dialog.data["source-type"]
            self:_UpdateSourceType()
            self:Refresh()
        end
    } --
    :newrow()

    local onSourceTypeChange = function()
        self:_UpdateImageProvider()
        self:_UpdateGuideLayer()
        self:_UpdateEndPosition()
    end
    local onSourceTypeRelease = function() self:Refresh() end
    self.sourceType:SetSourceDialogSection(self.sourceSprite, self.dialog,
                                           onSourceTypeChange,
                                           onSourceTypeRelease)

    local sourceSize = self.sourceType:GetSourceSize()

    -- Start Position Section
    self.dialog:separator{text = "Start position"} --
    :slider{
        id = "start-position-x",
        label = "X",
        min = -sourceSize.width,
        max = self.targetSprite.width + sourceSize.width,
        value = self.data.startPositionX,
        onchange = function()
            self.data.startPositionX = self.dialog.data["start-position-x"]
            self:_UpdatePositionCalculator()
            self:_UpdateGuideLayer()
        end
    } --
    :slider{
        id = "start-position-y",
        label = "Y",
        min = -sourceSize.height,
        max = self.targetSprite.height + sourceSize.height,
        value = self.data.startPositionY,
        onchange = function()
            self.data.startPositionY = self.dialog.data["start-position-y"]
            self:_UpdatePositionCalculator()
            self:_UpdateGuideLayer()
        end
    } --
    -- Movement Section
    self.dialog:separator{text = "Movement"} --
    :combobox{
        id = "movement-type",
        label = "Type",
        options = MovementType,
        option = self.data.movementType,
        onchange = function()
            self.data.movementType = self.dialog.data["movement-type"]
            self:Refresh()
        end
    }

    self.movementType:SetMovementDialogSection(sourceSize, self.dialog,
                                               function()
        self:_UpdatePositionCalculator()
        self:_UpdateGuideLayer()
        self:_UpdateEndPosition()
    end)

    -- End Position Section
    self.dialog:separator{id = "end-position-separator", text = "End"} --
    :combobox{
        id = "end-position-type",
        label = "Type",
        options = EndPositionType,
        option = self.data.endPositionType,
        onchange = function()
            self.data.endPositionType = self.dialog.data["end-position-type"]

            self:_UpdateEndPosition()
            self:_UpdatePositionCalculator()
            self:_UpdateGuideLayer()
        end
    } --
    :combobox{
        id = "end-position-axis",
        label = "Axis",
        options = Axis,
        option = self.data.endPositionAxis,
        onchange = function()
            self.data.endPositionAxis = self.dialog.data["end-position-axis"]

            local max = self:_GetMaxEndPositionValue()

            if self.data.endPositionValue > max then
                self.data.endPositionValue = max
            end

            self:Refresh()
        end
    } --
    :slider{
        id = "end-position-value",
        label = "End on",
        min = 0,
        max = self:_GetMaxEndPositionValue(),
        value = self.data.endPositionValue,
        onchange = function()
            self.data.endPositionValue = self.dialog.data["end-position-value"]
            self:_UpdatePositionCalculator()
            self:_UpdateGuideLayer()
        end
    } --
    :button{
        text = "Import",
        focus = true,
        onclick = function() self:_HandleImportButtonClick() end
    }

    -- Update visibility
    self:_UpdateEndPosition()

    -- Initial setup for the Image Provider
    self:_UpdateImageProvider()

    -- Initial setup for the Position Calculator
    self:_UpdatePositionCalculator()

    -- Initial draw of the Guide Layer
    self:_UpdateGuideLayer()

    -- Reset bounds
    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        self.dialog.bounds = newBounds
    end
end

function ImportAnimationDialog:_GetMaxEndPositionValue()
    return self.data.endPositionAxis == Axis.X and self.targetSprite.width or
               self.targetSprite.height
end

function ImportAnimationDialog:_UpdateEndPosition()
    self.dialog:modify{
        id = "end-position-separator",
        visible = self.data.movementType ~= MovementType.Static
    }:modify{
        id = "end-position-type",
        visible = self.data.movementType ~= MovementType.Static
    }:modify{
        id = "end-position-value",
        visible = self.data.endPositionType == EndPositionType.Line and
            self.data.movementType ~= MovementType.Static
    }:modify{
        id = "end-position-axis",
        visible = self.data.endPositionType == EndPositionType.Line and
            self.data.movementType ~= MovementType.Static
    }

    local sourceSize = self.sourceType:GetSourceSize()

    self.data.endPositionBounds = {
        x = -sourceSize.width,
        y = -sourceSize.height,
        width = self.targetSprite.width + sourceSize.width,
        height = self.targetSprite.height + sourceSize.height
    }
end

function ImportAnimationDialog:_InitializeData()
    -- Source Section
    self.data.sourceType = self.data.sourceType or SourceType.Layer

    -- Movement Section
    self.data.movementType = self.data.movementType or MovementType.Linear

    -- Start Position Section
    local previousCel = self.targetLayer and self.targetFrameNumber > 1 and
                            self.targetLayer:cel(self.targetFrameNumber - 1)
    local previousCelX = previousCel and
                             (previousCel.position.x +
                                 (previousCel.bounds.width / 2))
    local previousCelY = previousCel and
                             (previousCel.position.y +
                                 (previousCel.bounds.height / 2))

    self.data.startPositionX = self.data.startPositionX or previousCelX or
                                   self.targetSprite.width / 2
    self.data.startPositionY = self.data.startPositionY or previousCelY or
                                   self.targetSprite.height / 2

    -- End Position Section
    self.data.endPositionType = self.data.endPositionType or
                                    EndPositionType.OffScreen
    self.data.endPositionAxis = self.data.endPositionAxis or Axis.X
    self.data.endPositionValue = self.data.endPositionValue or
                                     self.targetSprite.width
end

function ImportAnimationDialog:_UpdateSourceType()
    self.sourceType = SourceTypeFactory:CreateSourceType(self.data.sourceType)
end

function ImportAnimationDialog:_UpdateMovementType()
    self.movementType = MovementTypeFactory:CreateMovementType(self.data
                                                                   .movementType)
end

function ImportAnimationDialog:_UpdateImageProvider()
    local sourceParams = self.sourceType:GetSourceParams()

    self.imageProvider = ImageProviderFactory:CreateImageProvider(
                             self.sourceSprite, self.targetSprite,
                             self.data.sourceType, sourceParams)
end

function ImportAnimationDialog:_UpdatePositionCalculator()
    Logger:Trace("Updating Position Calculator...")
    Logger:Trace("Start Position X = " .. self.data.startPositionX)
    Logger:Trace("Start Position Y = " .. self.data.startPositionY)
    Logger:Trace("End Position Axis = " .. self.data.endPositionAxis)
    Logger:Trace("End Position Value = " .. self.data.endPositionValue)
    Logger:Trace("Movement Type = " .. self.data.movementType)

    local startPosition = {
        X = self.data.startPositionX,
        Y = self.data.startPositionY
    }

    local endOn = {
        Axis = self.data.endPositionType == EndPositionType.Line and
            self.data.endPositionAxis or nil,
        Value = self.data.endPositionType == EndPositionType.Line and
            self.data.endPositionValue or nil,
        Bounds = self.data.endPositionBounds
    }

    local movementParams = self.movementType:GetMovementParams()

    self.positionCalculator =
        PositionCalculatorFactory:CreatePositionCalculator(self.data
                                                               .movementType,
                                                           startPosition, endOn,
                                                           movementParams)
end

function ImportAnimationDialog:_UpdateGuideLayer()
    self.guideLayer:Update(self.imageProvider, self.positionCalculator)
end

function ImportAnimationDialog:_HandleImportButtonClick()
    Logger:Trace("Import Button Clicked")
    self:_ClearGuideLayer()

    AnimationImporter:Init(self.targetSprite, self.targetLayer,
                           self.targetFrameNumber)
    local lastFrameNumber = AnimationImporter:Import(self.imageProvider,
                                                     self.positionCalculator)

    -- Update target frame
    self.targetFrameNumber = app.activeFrame.frameNumber

    local lastCel = self.targetLayer:cel(lastFrameNumber)
    if lastCel ~= nil and self.data.endPositionType ~= EndPositionType.OffScreen then
        self.targetFrameNumber = lastFrameNumber + 1
        app.activeFrame = self.targetSprite.frames[lastFrameNumber]

        self.data.startPositionX = lastCel.position.x +
                                       (lastCel.bounds.width / 2)
        self.data.startPositionY = lastCel.position.y +
                                       (lastCel.bounds.height / 2)
    end

    self:Refresh()
end

function ImportAnimationDialog:_ClearGuideLayer()
    app.undo() -- Undo the last Guide Layer update
    app.undo() -- Undo creating Guide Layer
    app.transaction(function() end) -- Create an empty transaction to clear the last one from memory
    app.undo() -- Undo the dummy transaction so it will be overwritten with the next action and removed from history

    self.guideLayer = nil
end

function ImportAnimationDialog:_ClearHistory()
    if not self.refreshing then
        self:_ClearGuideLayer()

        self.targetSprite = nil
        self.targetLayer = nil
        self.targetFrameNumber = nil

        self.sourceSprite = nil

        self.sourceType:Clear()
        self.sourceType = nil

        self.movementType:Clear()
        self.movementType = nil

        self.dialog = nil
        self.data = {}
    end

    self.refreshing = false
end

function ImportAnimationDialog:Refresh()
    self.bounds = self.dialog.bounds

    self.refreshing = true

    self.dialog:close()
    self:Create()
    self:Show()
end

function ImportAnimationDialog:Show() self.dialog:show{wait = true} end

return ImportAnimationDialog
