SpriteAnalyzer = dofile("./SpriteAnalyzer.lua")

function init(plugin)
    plugin:newCommand{
        id = "sprite-analyzer",
        title = "Sprite Analyzer",
        group = "view_controls",
        onenabled = function()
            return app.activeSprite ~= nil and
                       not app.activeSprite.selection.isEmpty
        end,
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            SpriteAnalyzer:Do(plugin)
        end
    }
end

function exit(plugin) end

