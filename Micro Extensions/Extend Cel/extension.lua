function init(plugin)
    local function RestoreRange(prevFrames, prevLayers)
        local frames, layers = {}, {}

        for _, frame in ipairs(prevFrames) do
            table.insert(frames, frame.frameNumber)
        end

        for _, layer in ipairs(prevLayers) do table.insert(layers, layer) end

        app.range.frames = frames
        app.range.layers = layers
    end

    plugin:newCommand{
        id = "ExtendCel",
        title = "Extend Cel(s)",
        group = "cel_popup_links",
        onenabled = function()
            local cels = app.range.cels

            -- If there are no active cel
            if #cels == 0 then return false end

            -- If there is at least one cel to process
            for _, cel in ipairs(cels) do
                -- If the active cel is in NOT the last frame
                if #cel.sprite.frames ~= cel.frameNumber then
                    return true
                end

                local nextCel = cel.layer:cel(cel.frameNumber + 1)

                -- If the next cel is NOT occupied
                if not nextCel then return true end
            end

            return false
        end,
        onclick = function()
            local extendedCels = 0

            app.transaction("Extend Cels", function()
                local cels = app.range.cels
                local prevFrames = app.range.frames
                local prevLayers = app.range.layers

                app.range:clear()

                for _, cel in ipairs(cels) do
                    local frameNumbers = {cel.frameNumber}

                    -- The difference between using "Link Cels" and this function is that cels are being linked as far as possible, not limited by the selection
                    for frameNumber = cel.frameNumber + 1, #cel.sprite.frames do
                        if cel.layer:cel(frameNumber) then
                            break
                        end

                        table.insert(frameNumbers, frameNumber)
                    end

                    -- Only link cels if there's more than one frame of length
                    if #frameNumbers > 1 then
                        app.range.frames = frameNumbers
                        app.range.layers = {cel.layer}
                        app.command.LinkCels()

                        extendedCels = extendedCels + 1
                    end
                end

                RestoreRange(prevFrames, prevLayers)
            end)

            if extendedCels == 1 then
                app.tip("Extended Cel")
            elseif extendedCels > 1 then
                app.tip("Extended " .. tostring(extendedCels) .. " Cels")
            end
        end
    }
end

function exit(plugin) end
