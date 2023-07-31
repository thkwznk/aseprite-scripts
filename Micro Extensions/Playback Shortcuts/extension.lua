local pluginKey = "thkwznk/play-tag"
local DefaultPlaybackOption = "<Default>"
local SequencePlaybackOption = "<Sequence>"
local SequenceIndex = -1

local CustomTagIndicesFallback = {}

function GetUniqueId()
    local randomNumber = math.random(1, 16 ^ 8)
    return string.format("%08x", randomNumber)
end

function GetTagUniqueId(tag)
    if not tag then return nil end

    local uniqueId = tag.properties(pluginKey).uniqueId

    if uniqueId == nil then
        uniqueId = GetUniqueId()
        tag.properties(pluginKey).uniqueId = uniqueId
    end

    return uniqueId
end

function GetTagOptions(sprite)
    local names = {}
    local tagDictionary = {}

    for _, tag in ipairs(sprite.tags) do
        local name = string.format("%s [%d...%d]", tag.name,
                                   tag.fromFrame.frameNumber,
                                   tag.toFrame.frameNumber)
        table.insert(names, name)
        tagDictionary[name] = tag
    end

    return names, tagDictionary
end

function GetTagByUniqueId(sprite, uniqueId)
    for _, tag in ipairs(sprite.tags) do
        if tag.properties(pluginKey).uniqueId == uniqueId then return tag end
    end
end

function PlayAllFrames()
    local playAll = app.preferences.editor.play_all
    app.preferences.editor.play_all = true

    app.activeFrame = 1
    app.command.PlayAnimation()

    app.preferences.editor.play_all = playAll
end

function GetCustomTagIndex(sprite, tagIndex)
    -- Custom tags are only available from v1.3-rc1
    if app.apiVersion < 21 then
        return (CustomTagIndicesFallback[sprite.filename] and
                   CustomTagIndicesFallback[sprite.filename][tagIndex]) or
                   tagIndex
    end

    local tagKey = "tag-" .. tostring(tagIndex)
    local tagUniqueId = sprite.properties(pluginKey)[tagKey]

    if tagUniqueId == SequencePlaybackOption then return SequenceIndex end

    if tagUniqueId then
        for i, tag in ipairs(sprite.tags) do
            if tag.properties(pluginKey).uniqueId == tagUniqueId then
                return i
            end
        end
    end

    return tagIndex
end

function SetCustomTagIndex(sprite, tagIndex, customTag)
    -- Custom tags are only available from v1.3-rc1
    if app.apiVersion < 21 then
        for i, tag in ipairs(sprite.tags) do
            if tag == customTag then
                if not CustomTagIndicesFallback[sprite.filename] then
                    CustomTagIndicesFallback[sprite.filename] = {
                        1, 2, 3, 4, 5, 6, 7, 8, 9
                    }
                end

                CustomTagIndicesFallback[sprite.filename][tagIndex] = i
                break
            end
        end

        return
    end

    sprite.properties(pluginKey)["tag-" .. tagIndex] = GetTagUniqueId(customTag)
end

function PlayCustomTagByIndex(sprite, tagIndex)
    local customTagIndex = GetCustomTagIndex(sprite, tagIndex)

    if customTagIndex == SequenceIndex then
        local sequenceIds = sprite.properties(pluginKey).sequence
        local tagSequence = {}

        for _, tagId in ipairs(sequenceIds) do
            table.insert(tagSequence, GetTagByUniqueId(sprite, tagId))
        end

        PlaySequence(tagSequence)
        return
    end

    PlayTagByIndex(sprite, customTagIndex)
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

function FindTagIndex(sprite, frameNumber)
    for i, tag in ipairs(sprite.tags) do
        if tag.fromFrame.frameNumber <= frameNumber and tag.toFrame.frameNumber >=
            frameNumber then return i end
    end
end

function FindNextTagIndex(sprite, frameNumber)
    local tagIndex = FindTagIndex(sprite, frameNumber)

    -- If the frame is within a tag, return decremented index or last tag index
    if tagIndex then return tagIndex < #sprite.tags and tagIndex + 1 or 1 end

    local closestTagStart = #sprite.frames
    local closestTagStartIndex = 0

    for i, tag in ipairs(sprite.tags) do
        if tag.fromFrame.frameNumber > frameNumber and tag.fromFrame.frameNumber -
            frameNumber < closestTagStart then
            closestTagStart = tag.fromFrame.frameNumber - frameNumber
            closestTagStartIndex = i
        end
    end

    if closestTagStartIndex == 0 then return 1 end

    return closestTagStartIndex
end

function FindPreviousTagIndex(sprite, frameNumber)
    local tagIndex = FindTagIndex(sprite, frameNumber)

    -- If the frame is within a tag, return decremented index or last tag index
    if tagIndex then return tagIndex > 1 and tagIndex - 1 or #sprite.tags end

    local closestTagEnd = #sprite.frames
    local closestTagEndIndex = 0

    for i, tag in ipairs(sprite.tags) do
        if tag.toFrame.frameNumber < frameNumber and frameNumber -
            tag.toFrame.frameNumber < closestTagEnd then
            closestTagEnd = frameNumber - tag.toFrame.frameNumber
            closestTagEndIndex = i
        end
    end

    if closestTagEndIndex == 0 then return #sprite.tags end

    return closestTagEndIndex
end

function RecursiveTimer(sequence, sequenceIndex, cancellationToken)
    if app.activeFrame == nil then cancellationToken.onCancel() end
    app.activeFrame = sequence[sequenceIndex].frameNumber

    local timer

    local ontick = function()
        local isPlaying = sequenceIndex < #sequence
        local isCorrectFrame =
            app.activeFrame and app.activeFrame.frameNumber ==
                sequence[sequenceIndex].frameNumber

        if isPlaying and isCorrectFrame and not cancellationToken.isCancelled then
            RecursiveTimer(sequence, sequenceIndex + 1, cancellationToken)
        else
            cancellationToken.onCancel()
        end

        timer:stop()
    end

    timer = Timer {interval = sequence[sequenceIndex].duration, ontick = ontick}
    timer:start()
end

function PlaySequence(tagSequence)
    local sprite = app.activeSprite
    local layer = app.activeLayer

    local cancellationToken = {isCancelled = false}

    local onChangeListener
    onChangeListener = sprite.events:on('change', function()
        cancellationToken.isCancelled = true
        cancellationToken.frame = app.activeFrame
    end)

    local onSiteChange
    onSiteChange = app.events:on('sitechange', function()
        if sprite ~= app.activeSprite or layer ~= app.activeLayer then
            cancellationToken.isCancelled = true
        end
    end)

    cancellationToken.onCancel = function()
        if sprite then sprite.events:off(onChangeListener) end
        app.events:off(onSiteChange)

        if cancellationToken.frame then
            app.activeFrame = cancellationToken.frame
        end
    end

    local frameSequence = {}

    for _, tag in ipairs(tagSequence) do
        for frameNumber = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
            table.insert(frameSequence, tag.sprite.frames[frameNumber])
        end
    end

    if #frameSequence > 0 then
        RecursiveTimer(frameSequence, 1, cancellationToken)
    end
end

function PlaybackShortcutsDialog(options)
    local dialog = Dialog(options.title)

    dialog --
    :separator{text = "Shortcuts:"}

    local playbackOptions, tagDictionary = GetPlaybackOptions(options.sprite)

    for i = 1, 9 do
        local option = playbackOptions[1]
        local customTagIndex = GetCustomTagIndex(options.sprite, i)

        if customTagIndex == SequenceIndex then
            option = SequencePlaybackOption
        elseif customTagIndex ~= i then
            option = playbackOptions[customTagIndex + 1]
        end

        dialog:combobox{
            id = "tag-" .. tostring(i),
            label = "Ctrl+" .. tostring(i),
            options = playbackOptions,
            option = option
        }
    end

    dialog --
    :button{
        text = "Reset",
        onclick = function()
            for i = 1, 9 do
                dialog:modify{
                    id = "tag-" .. tostring(i),
                    option = DefaultPlaybackOption
                }
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

                if tagName == SequencePlaybackOption then
                    options.sprite.properties(pluginKey)[tagId] =
                        SequencePlaybackOption
                else
                    local tag = tagDictionary[tagName]
                    SetCustomTagIndex(options.sprite, shortcutIndex, tag)
                end
            end

            dialog:close()
        end
    } --
    :button{text = "&Cancel"} --

    return dialog
end

function PlaybackSequenceDialog(options)
    local tagNames, tagDictionary = GetTagOptions(options.sprite)
    local spriteProperties = options.sprite.properties(pluginKey)

    table.insert(tagNames, 1, "")

    local dialog = Dialog(options.title)
    local sequenceIds = spriteProperties.sequence or {}
    local sequenceNames = {}

    for _, sequenceId in ipairs(sequenceIds) do
        for tagName, tag in pairs(tagDictionary) do
            if tag.properties(pluginKey).uniqueId == sequenceId then
                table.insert(sequenceNames, tagName)
                break
            end
        end
    end

    dialog --
    :separator{text = "Sequence:"}

    for i = 1, 9 do
        dialog --
        :combobox{
            id = "sequence-tag-" .. tostring(i),
            label = "Tag #" .. tostring(i),
            options = tagNames,
            option = sequenceNames[i],
            visible = i == 1 or sequenceNames[i - 1] ~= nil,
            onchange = function()
                for j = 9, 2, -1 do
                    local isPreviousEmpty =
                        #dialog.data["sequence-tag-" .. tostring(j - 1)] == 0

                    dialog:modify{
                        id = "sequence-tag-" .. tostring(j),
                        visible = not isPreviousEmpty
                    }

                    if not isPreviousEmpty then break end
                end
            end
        } --
        :newrow()
    end

    dialog --
    :separator() --
    :button{
        text = "OK",
        onclick = function()
            local sequenceIds = {}

            for i = 1, 9 do
                local tagName = dialog.data["sequence-tag-" .. tostring(i)]

                if #tagName > 1 then
                    local tag = tagDictionary[tagName]
                    table.insert(sequenceIds, GetTagUniqueId(tag))
                end
            end

            spriteProperties.sequence = sequenceIds

            dialog:close()
        end
    } --
    :button{
        text = "&Play",
        onclick = function()
            local tagSequence = {}

            for i = 1, 9 do
                local tagName = dialog.data["sequence-tag-" .. tostring(i)]

                if #tagName > 1 then
                    local tag = tagDictionary[tagName]
                    table.insert(tagSequence, tag)
                end
            end

            PlaySequence(tagSequence)
        end
    } --
    :button{text = "Cancel"}

    return dialog
end

function GetPlaybackOptions(sprite)
    local playbackOptions = {DefaultPlaybackOption}
    local tagNames, tagDictionary = GetTagOptions(sprite)

    for _, tagName in ipairs(tagNames) do
        table.insert(playbackOptions, tagName)
    end

    -- Only add option to play the sequence from v1.3-rc1
    if app.apiVersion >= 21 then
        table.insert(playbackOptions, SequencePlaybackOption)
    end

    return playbackOptions, tagDictionary
end

function init(plugin)
    -- Custom tags are only available from v1.3-rc1
    if app.apiVersion >= 21 then
        plugin:newMenuGroup{
            id = "tag_playback",
            title = "Tag Playback",
            group = "cel_animation"
        }

        plugin:newCommand{
            id = "PlaybackShortcuts",
            title = "Shortcuts...",
            group = "tag_playback",
            onenabled = function()
                return app.activeSprite ~= nil and #app.activeSprite.tags > 1
            end,
            onclick = function()
                local dialog = PlaybackShortcutsDialog {
                    title = "Tag Playback Shortcuts",
                    sprite = app.activeSprite
                }
                dialog:show()
            end
        }

        plugin:newMenuSeparator{group = "tag_playback"}

        plugin:newCommand{
            id = "PlaybackSequences",
            title = "Sequence...",
            group = "tag_playback",
            onenabled = function()
                return app.activeSprite ~= nil and #app.activeSprite.tags > 1
            end,
            onclick = function()
                local sprite = app.activeSprite
                local dialog = PlaybackSequenceDialog {
                    title = "Tag Playback Sequence",
                    sprite = sprite
                }
                dialog:show()
            end
        }
    else
        plugin:newCommand{
            id = "PlaybackShortcuts",
            title = "Tag Playback Shortcuts...",
            group = "cel_animation",
            onenabled = function()
                return app.activeSprite ~= nil and #app.activeSprite.tags > 1
            end,
            onclick = function()
                local dialog = PlaybackShortcutsDialog {
                    title = "Tag Playback Shortcuts",
                    sprite = app.activeSprite
                }
                dialog:show()
            end
        }
    end

    plugin:newCommand{
        id = "PlayFirstTag",
        title = "Play Tag #1",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 1) end
    }

    plugin:newCommand{
        id = "PlaySecondTag",
        title = "Play Tag #2",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 2) end
    }

    plugin:newCommand{
        id = "PlayThirdTag",
        title = "Play Tag #3",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 3) end
    }

    plugin:newCommand{
        id = "PlayFourthTag",
        title = "Play Tag #4",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 4) end
    }

    plugin:newCommand{
        id = "PlayFifthTag",
        title = "Play Tag #5",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 5) end
    }

    plugin:newCommand{
        id = "PlaySixthTag",
        title = "Play Tag #6",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 6) end
    }

    plugin:newCommand{
        id = "PlaySeventhTag",
        title = "Play Tag #7",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 7) end
    }

    plugin:newCommand{
        id = "PlayEightTag",
        title = "Play Tag #8",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 8) end
    }

    plugin:newCommand{
        id = "PlayNinthTag",
        title = "Play Tag #9",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function() PlayCustomTagByIndex(app.activeSprite, 9) end
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

            local nextTagIndex = FindNextTagIndex(sprite, currentFrameNumber)
            PlayTagByIndex(sprite, nextTagIndex)
        end
    }

    plugin:newCommand{
        id = "PlayPreviousTag",
        title = "Jump To Previous Tag",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local sprite = app.activeSprite
            local currentFrameNumber = app.activeFrame.frameNumber

            local previouTagIndex = FindPreviousTagIndex(sprite,
                                                         currentFrameNumber)
            PlayTagByIndex(sprite, previouTagIndex)
        end
    }
end

function exit(plugin) end
