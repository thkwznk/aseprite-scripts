NewSpriteAnalyzerDialog = dofile("./NewSpriteAnalyzerDialog.lua")
NewPreviewSpriteDrawer = dofile("./NewPreviewSpriteDrawer.lua")
PresetProvider = dofile("./PresetProvider.lua")

local GetSpriteImage = function(sprite, frame)
    local image = Image(sprite.width, sprite.height, sprite.colorMode)
    image:drawSprite(sprite, frame, 0, 0)
    return image
end

local SpriteAnalyzer = {}

-- TODO: Instead of this calculate what part of the sprite needs to be taken based on the preview itself if performance will require it

-- function SpriteAnalyzer:CreateNewSpriteFromSelection(sprite)
--     local bounds = sprite.selection.bounds
--     sprite.selection:deselect()

--     local newSprite = Sprite(bounds.width, bounds.height, sprite.colorMode)
--     newSprite:setPalette(sprite.palettes[1])
--     newSprite.filename = "Sprite Analysis"

--     local originalSpritePreferences = app.preferences.document(sprite)
--     local newSpritePreferences = app.preferences.document(newSprite)

--     newSpritePreferences.show.grid = false
--     newSpritePreferences.show.pixel_grid = false
--     newSpritePreferences.bg.color1 = originalSpritePreferences.bg.color1
--     newSpritePreferences.bg.color2 = originalSpritePreferences.bg.color2

--     return newSprite, bounds
-- end

function SpriteAnalyzer:IsSpriteOpen(sprite)
    if sprite == nil then return false end

    for _, openSprite in ipairs(app.sprites) do
        if openSprite == sprite then return true end
    end

    return false
end

function SpriteAnalyzer:Do(plugin)
    local activeSprite = app.activeSprite
    local bounds = Rectangle(0, 0, activeSprite.width, activeSprite.height)

    if activeSprite == nil then return end

    local NewSpriteAnalyzerDialog = NewSpriteAnalyzerDialog:New()

    -- Start analysis
    local onSpriteChange = nil

    local onChange = function()
        -- Remove listener if preview sprite was closed
        -- if not self:IsSpriteOpen(previewSprite) then
        --     activeSprite.events:off(onSpriteChange)
        --     return
        -- end

        local mode = NewSpriteAnalyzerDialog:GetAnalysisMode()

        if not mode then return end

        local sourceImage = GetSpriteImage(activeSprite, app.activeFrame)

        local image = NewPreviewSpriteDrawer:Update(sourceImage, bounds, mode,
                                                    NewSpriteAnalyzerDialog:GetConfiguration())

        -- TODO: Fix correctly repainting on mode change
        NewSpriteAnalyzerDialog:Repaint(image)
    end

    -- Initial drawing of the preview image
    onChange()

    onSpriteChange = activeSprite.events:on('change', onChange)

    local presetProvider = PresetProvider:New{plugin = plugin}

    NewSpriteAnalyzerDialog:Create{
        title = "Sprite Analysis",
        presetProvider = presetProvider,
        imageProvider = imageProvider, -- Might need to bring back the Image Provider
        spriteBounds = bounds,
        dialogBounds = plugin.preferences.dialogBounds,
        onclose = function(lastDialogBounds)
            -- TODO: Do I even need this?
            if self:IsSpriteOpen(activeSprite) then
                activeSprite.events:off(onSpriteChange)
            end

            plugin.preferences.dialogBounds = lastDialogBounds or
                                                  plugin.preferences
                                                      .dialogBounds
        end,
        onchange = onChange
    }
    NewSpriteAnalyzerDialog:Show()
end

return SpriteAnalyzer
