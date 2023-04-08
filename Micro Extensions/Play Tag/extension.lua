function PlayAllFrames()
    local playAll = app.preferences.editor.play_all
    app.preferences.editor.play_all = true

    app.command.PlayAnimation()

    app.preferences.editor.play_all = playAll
end

function PlayCustomTagByIndex(plugin, sprite, tagIndex)
    local customTagIndex = plugin.preferences[sprite.filename] and
                               plugin.preferences[sprite.filename]["tag-" ..
                                   tostring(tagIndex)]

    if customTagIndex then tagIndex = customTagIndex end

    PlayTagByIndex(sprite, tagIndex)
end

function PlayTagByIndex(sprite, tagIndex)
    -- Return if the tag index is not valid
    if tagIndex > #sprite.tags or tagIndex < 1 then return end

    local tag = sprite.tags[tagIndex]
    app.activeFrame = tag.fromFrame

    local playAll = app.preferences.editor.play_all
    app.preferences.editor.play_all = false

    app.command.PlayAnimation()

    app.preferences.editor.play_all = playAll
end

function FindClosestTagIndexToFrame(sprite, frameNumber)
    for i, tag in ipairs(sprite.tags) do
        if tag.fromFrame.frameNumber <= frameNumber and tag.toFrame.frameNumber >=
            frameNumber then return i end
    end
end

function init(plugin)
    plugin:newCommand{
        id = "SetTagShortcut",
        title = "Tag Play Shortcuts...",
        group = "tag_popup_properties",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite

            if not plugin.preferences[sprite.filename] then
                plugin.preferences[sprite.filename] = {}
            end

            local dialog = Dialog("Tag Play Shortcuts")
            local tags = {"<Default>"}

            for _, tag in ipairs(sprite.tags) do
                -- TODO: Differentiate tags with the same name
                table.insert(tags, tag.name)
            end

            for i = 1, 9 do
                local savedI = plugin.preferences[sprite.filename]["tag-" ..
                                   tostring(i)]

                local option = tags[1]

                if savedI then option = tags[savedI + 1] end

                dialog:combobox{
                    id = "tag-" .. tostring(i),
                    label = "Ctrl+" .. tostring(i),
                    options = tags,
                    option = option
                }
            end

            dialog --
            :separator() --
            :button{
                text = "Reset",
                onclick = function()
                    for i = 1, 9 do
                        local id = "tag-" .. tostring(i)

                        dialog:modify{id = id, option = tags[1]}
                    end
                end
            } --
            :separator() --
            :button{
                text = "&OK",
                onclick = function()
                    for shortcutIndex = 1, 9 do
                        local tagId = "tag-" .. tostring(shortcutIndex)
                        local tagName = dialog.data[tagId]

                        if tagName == tags[1] then -- Default
                            plugin.preferences[sprite.filename][tagId] = nil
                        else -- Custom
                            local ix = shortcutIndex

                            for j = 2, #tags do
                                if tags[j] == tagName then
                                    ix = j - 1
                                    break
                                end
                            end
                            print(shortcutIndex, ix, dialog.data[tagId])

                            plugin.preferences[sprite.filename][tagId] = ix
                        end
                    end

                    dialog:close()
                end
            } --
            :button{text = "&Cancel"} --

            dialog:show()
        end
    }

    plugin:newCommand{
        id = "PlayFirstTag",
        title = "Play Tag #1",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 1)
        end
    }

    plugin:newCommand{
        id = "PlaySecondTag",
        title = "Play Tag #2",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 2)
        end
    }

    plugin:newCommand{
        id = "PlayThirdTag",
        title = "Play Tag #3",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 3)
        end
    }

    plugin:newCommand{
        id = "PlayFourthTag",
        title = "Play Tag #4",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 4)
        end
    }

    plugin:newCommand{
        id = "PlayFifthTag",
        title = "Play Tag #5",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 5)
        end
    }

    plugin:newCommand{
        id = "PlaySixthTag",
        title = "Play Tag #6",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 6)
        end
    }

    plugin:newCommand{
        id = "PlaySeventhTag",
        title = "Play Tag #7",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 7)
        end
    }

    plugin:newCommand{
        id = "PlayEightTag",
        title = "Play Tag #8",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 8)
        end
    }

    plugin:newCommand{
        id = "PlayNinthTag",
        title = "Play Tag #9",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            PlayCustomTagByIndex(plugin, app.activeSprite, 9)
        end
    }

    plugin:newCommand{
        id = "PlayAllFrames",
        title = "Play All Frames",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayAllFrames() end
    }

    plugin:newCommand{
        id = "PlayNextTag",
        title = "Jump To Next Tag",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local currentFrameNumber = app.activeFrame.frameNumber
            local closestTagIndex = FindClosestTagIndexToFrame(sprite,
                                                               currentFrameNumber)

            if closestTagIndex < #sprite.tags then
                PlayTagByIndex(sprite, closestTagIndex + 1)
            end
        end
    }

    plugin:newCommand{
        id = "PlayPreviousTag",
        title = "Jump To Previous Tag",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local currentFrameNumber = app.activeFrame.frameNumber
            local closestTagIndex = FindClosestTagIndexToFrame(sprite,
                                                               currentFrameNumber)

            if closestTagIndex > 1 then
                PlayTagByIndex(sprite, closestTagIndex - 1)
            end
        end
    }
end

function exit(plugin) end

-- TODO: Fix data persistance / Use the new Extension-defined properties (for older versions, use the same method as the Time Tracking does)
-- TODO: Add settings for the play once/loop
-- TODO: Fix an issue when trying ot play next/previous tag when active frame is outside of a tag
-- TODO: Try to implement playing a sequence of tags (use the new Timer class)
-- TODO: Move the Tag Play Properties out of the Tag context menu - it doens't work there
