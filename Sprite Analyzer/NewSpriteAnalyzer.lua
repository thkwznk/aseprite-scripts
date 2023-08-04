NewSpriteAnalyzerDialog = dofile("./NewSpriteAnalyzerDialog.lua")
NewPreviewSpriteDrawer = dofile("./NewPreviewSpriteDrawer.lua")
PresetProvider = dofile("./PresetProvider.lua")

function GetImage(sprite, frame)
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
    local analyzedSprite = app.activeSprite
    if analyzedSprite == nil then return end

    local dialog

    local previewImage
    local previewImageProvider = {}
    function previewImageProvider:GetImage() return previewImage end

    -- Start analysis
    local onSpriteChange = nil

    local onChange = function()
        -- Remove listener if preview sprite was closed
        -- if not self:IsSpriteOpen(previewSprite) then
        --     activeSprite.events:off(onSpriteChange)
        --     return
        -- end

        local sourceImage = GetImage(analyzedSprite, app.activeFrame)
        previewImage = NewPreviewSpriteDrawer:Update(sourceImage,
                                                     dialog.data.analysisMode,
                                                     dialog.data.flip, {}, {})

        dialog:repaint()
    end

    -- Initial drawing of the preview image
    -- onChange()

    onSpriteChange = analyzedSprite.events:on('change', onChange)

    -- local presetProvider = PresetProvider:New{plugin = plugin}

    dialog = NewSpriteAnalyzerDialog {
        title = "Sprite Analysis",
        -- presetProvider = presetProvider,
        imageProvider = previewImageProvider, -- Might need to bring back the Image Provider
        -- spriteBounds = bounds,
        -- dialogBounds = plugin.preferences.dialogBounds,
        onclose = function(lastDialogBounds)
            -- TODO: Do I even need this?
            if self:IsSpriteOpen(analyzedSprite) then
                analyzedSprite.events:off(onSpriteChange)
            end

            plugin.preferences.dialogBounds = lastDialogBounds or
                                                  plugin.preferences
                                                      .dialogBounds
        end,
        onchange = onChange
    }
    dialog:show{wait = false}

    onChange()
end

return SpriteAnalyzer
