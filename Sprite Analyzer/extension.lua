SpriteAnalyzer = dofile("./SpriteAnalyzer.lua")
NewSpriteAnalyzer = dofile("./NewSpriteAnalyzer.lua")

function init(plugin)
    -- Check is UI available
    if not app.isUIAvailable then return end

    plugin:newCommand{
        id = "sprite-analyzer",
        title = "Sprite Analyzer",
        group = "view_controls",
        onenabled = function()
            return app.activeSprite ~= nil and
                       not app.activeSprite.selection.isEmpty
        end,
        onclick = function() SpriteAnalyzer:Do(plugin) end
    }

    if app.apiVersion >= 21 then
        plugin:newCommand{
            id = "NewSpriteAnalyzer",
            title = "[NEW] Sprite Analyzer",
            group = "view_controls",
            onenabled = function() return app.activeSprite ~= nil end,
            onclick = function() NewSpriteAnalyzer:Do(plugin) end
        }
    end
end

function exit(plugin) end

