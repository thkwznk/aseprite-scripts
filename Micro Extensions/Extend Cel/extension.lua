function init(plugin)
    plugin:newCommand{
        id = "ExtendCel",
        title = "Extend Cel",
        group = "cel_popup_links",
        onenabled = function()
            -- If there's no active cel
            if app.activeCel == nil then return false end

            local cel = app.activeCel

            -- If the active cel is in the last frame
            if #cel.sprite.frames == cel.frameNumber then
                return false
            end

            local nextCel = cel.layer:cel(cel.frameNumber + 1)

            -- If the next cel is occupied
            if nextCel then return false end

            return true
        end,
        onclick = function()
            local cel = app.activeCel
            local frameNumbers = {cel.frameNumber}

            for frameNumber = cel.frameNumber + 1, #cel.sprite.frames do
                if cel.layer:cel(frameNumber) then break end

                table.insert(frameNumbers, frameNumber)
            end

            app.range.frames = frameNumbers
            app.command.LinkCels()
        end
    }
end

function exit(plugin) end
