SpriteAnalyzerDialog = dofile("./SpriteAnalyzerDialog.lua")
PreviewSpriteDrawer = dofile("./PreviewSpriteDrawer.lua")
PresetProvider = dofile("./PresetProvider.lua")

local ImageProvider = {sprite = nil}

function ImageProvider:New(options)
    options = options or {}
    setmetatable(options, self)
    self.__index = self
    return options
end

function ImageProvider:Init(options)
    self.sprite = options and options.sprite
    self.bounds = options and options.bounds
end

function ImageProvider:GetImage()
    -- TODO: ColorMode from sprite
    local image = Image(self.bounds.width, self.bounds.height, ColorMode.RGB)
    image:drawSprite(self.sprite, app.activeFrame, -self.bounds.x,
                     -self.bounds.y)

    return image
end

local SpriteAnalyzer = {}

function SpriteAnalyzer:CreateNewSpriteFromSelection(sprite)
    local bounds = sprite.selection.bounds
    sprite.selection:deselect()

    local newSprite = Sprite(bounds.width, bounds.height, sprite.colorMode)
    newSprite:setPalette(sprite.palettes[1])
    newSprite.filename = "Sprite Analysis"

    local originalSpritePreferences = app.preferences.document(sprite)
    local newSpritePreferences = app.preferences.document(newSprite)

    newSpritePreferences.show.grid = false
    newSpritePreferences.show.pixel_grid = false
    newSpritePreferences.bg.color1 = originalSpritePreferences.bg.color1
    newSpritePreferences.bg.color2 = originalSpritePreferences.bg.color2

    return newSprite, bounds
end

function SpriteAnalyzer:IsSpriteOpen(sprite)
    if sprite == nil then return false end

    for _, openSprite in ipairs(app.sprites) do
        if openSprite == sprite then return true end
    end

    return false
end

function SpriteAnalyzer:Do(plugin)
    local activeSprite = app.activeSprite
    local previewSprite, bounds =
        self:CreateNewSpriteFromSelection(activeSprite)

    if activeSprite == nil or bounds == nil or previewSprite == nil then
        return
    end

    local spriteAnalyzerDialog = SpriteAnalyzerDialog:New()

    local imageProvider = ImageProvider:New()
    imageProvider:Init{sprite = activeSprite, bounds = bounds}

    -- Start analysis
    local onSpriteChange = nil

    local onChange = function()
        -- Remove listener if preview sprite was closed
        if not self:IsSpriteOpen(previewSprite) then
            activeSprite.events:off(onSpriteChange)
            return
        end

        local originalActiveSprite = app.activeSprite

        -- WARNING: All changes done to the "previewSprite" require to first switch an active sprite to it, otherwise Aseprite will crash when trying to undo an action
        app.activeSprite = previewSprite

        app.transaction(function()
            PreviewSpriteDrawer:Update(imageProvider, previewSprite, bounds,
                                       spriteAnalyzerDialog:GetConfiguration())
        end)
        app.refresh()

        -- Restore focus to the original sprite
        app.activeSprite = originalActiveSprite
    end

    -- Initial drawing of the preview image
    onChange()

    onSpriteChange = activeSprite.events:on('change', onChange)

    local presetProvider = PresetProvider:New{plugin = plugin}

    spriteAnalyzerDialog:Create{
        title = "Sprite Analysis",
        presetProvider = presetProvider,
        imageProvider = imageProvider,
        spriteBounds = bounds,
        dialogBounds = plugin.preferences.dialogBounds,
        onclose = function(lastDialogBounds)
            if self:IsSpriteOpen(previewSprite) then
                previewSprite:close()
            end

            if self:IsSpriteOpen(activeSprite) then
                activeSprite.events:off(onSpriteChange)
            end

            plugin.preferences.dialogBounds = lastDialogBounds or
                                                  plugin.preferences
                                                      .dialogBounds
        end,
        onchange = onChange
    }
    spriteAnalyzerDialog:Show()
end

return SpriteAnalyzer
