local PageSize = 6
local SearchResultType = {
    Layer = "layer",
    Tag = "tag",
    Frame = "frame",
    Sprite = "sprite"
}

function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end

function GetPattern(text)
    local pattern = "";
    for i = 1, #text do pattern = pattern .. text:sub(i, i) .. ".*" end
    return pattern;
end

function SearchLayers(sprite, layers, pattern, searchText, exactMatches,
                      startsWith, results, prefix)
    prefix = prefix or ""

    for _, layer in ipairs(layers) do
        if layer.isGroup then
            SearchLayers(sprite, layer.layers, pattern, searchText,
                         exactMatches, startsWith, results,
                         prefix .. layer.name .. " > ")
        else
            local fullName = prefix .. layer.name

            local searchResult = {
                name = fullName,
                layer = layer,
                type = SearchResultType.Layer,
                sprite = sprite
            };

            local name = fullName:lower();

            if name == searchText:lower() then
                table.insert(exactMatches, searchResult)
            elseif StartsWith(name, searchText:lower()) then
                table.insert(startsWith, searchResult)
            elseif name:match(pattern) then
                table.insert(results, searchResult)
            end
        end
    end
end

function SearchTags(sprite, searchText, pattern, exactMatches, prefixMatches,
                    fuzzyMatches)
    for _, tag in ipairs(sprite.tags) do
        local searchResult = {
            name = tag.name,
            tag = tag,
            type = SearchResultType.Tag,
            sprite = sprite
        };

        local name = tag.name:lower()

        if name == searchText:lower() then
            table.insert(exactMatches, searchResult)
        elseif StartsWith(name, searchText:lower()) then
            table.insert(prefixMatches, searchResult)
        elseif name:match(pattern) then
            table.insert(fuzzyMatches, searchResult)
        end
    end
end

function Search(sprite, searchText, searchAll)
    if #searchText == 0 then return {} end

    local pattern = GetPattern(searchText):lower()

    local result = {}

    -- Split the results into three priority groups
    local exactMatches = {}
    local prefixMatches = {}
    local fuzzyMatches = {}

    for _, frame in ipairs(sprite.frames) do
        local frameNumber = tostring(frame.frameNumber)

        local searchResult = {
            name = frameNumber,
            frame = frame,
            type = SearchResultType.Frame
        }

        -- Frames are already in order, no need to sort them
        if frameNumber:match(pattern) then
            table.insert(result, searchResult)
        end
    end

    -- Search layers recursively
    SearchLayers(sprite, sprite.layers, pattern, searchText, exactMatches,
                 prefixMatches, fuzzyMatches)

    if searchAll then
        for _, openSprite in ipairs(app.sprites) do
            if openSprite.filename ~= app.activeSprite.filename then
                SearchLayers(openSprite, openSprite.layers, pattern, searchText,
                             exactMatches, prefixMatches, fuzzyMatches)
            end
        end
    end

    SearchTags(sprite, searchText, pattern, exactMatches, prefixMatches,
               fuzzyMatches)

    if searchAll then
        for _, openSprite in ipairs(app.sprites) do
            if openSprite.filename ~= app.activeSprite.filename then
                SearchTags(openSprite, searchText, pattern, exactMatches,
                           prefixMatches, fuzzyMatches)
            end
        end
    end

    if #app.sprites > 1 then
        for _, openSprite in ipairs(app.sprites) do
            local filename = app.fs.fileName(openSprite.filename)

            local searchResult = {
                name = filename,
                sprite = openSprite,
                type = SearchResultType.Sprite
            };

            local name = filename:lower()

            if name == searchText:lower() then
                table.insert(exactMatches, searchResult)
            elseif StartsWith(name, searchText:lower()) then
                table.insert(prefixMatches, searchResult)
            elseif name:match(pattern) then
                table.insert(fuzzyMatches, searchResult)
            end
        end
    end

    table.sort(exactMatches, function(a, b) return a.name < b.name end)
    table.sort(prefixMatches, function(a, b) return a.name < b.name end)
    table.sort(fuzzyMatches, function(a, b) return a.name < b.name end)

    for _, match in ipairs(exactMatches) do table.insert(result, match) end
    for _, match in ipairs(prefixMatches) do table.insert(result, match) end
    for _, match in ipairs(fuzzyMatches) do table.insert(result, match) end

    return result
end

function SearchDialog(options)
    local search = ""
    local results = {}
    local currentPage = 1

    local dialog
    dialog = Dialog {
        title = options.title,
        onclose = function()
            if options.onclose then options.onclose(dialog.data) end
        end
    }

    function RefreshWidgets()
        local numberOfPages = math.max(math.ceil(#results / PageSize), 1)
        currentPage = math.min(currentPage or 1, numberOfPages)

        local skip = (currentPage - 1) * PageSize
        local resultsOnPage = math.min(PageSize, #results - skip)

        dialog:modify{id = "no-results", visible = resultsOnPage == 0}

        for i = 1, resultsOnPage do
            local result = results[skip + i]

            local prefix = ""

            if dialog.data.searchAll and result.sprite and
                result.sprite.filename ~= app.activeSprite.filename and
                result.type ~= SourceType.Sprite then
                prefix = app.fs.fileTitle(result.sprite.filename) .. " > "
            end

            dialog:modify{
                id = "result-" .. tostring(i),
                visible = true,
                text = prefix .. result.name .. " (" .. result.type .. ")"
            }
        end

        if resultsOnPage < PageSize then
            for i = resultsOnPage + 1, PageSize do
                dialog:modify{id = "result-" .. tostring(i), visible = false}
            end
        end

        dialog --
        :modify{
            id = "prev-page",
            visible = currentPage > 1,
            enabled = numberOfPages > 1 and currentPage > 1
        } --
        :modify{
            id = "next-page",
            visible = currentPage < numberOfPages,
            enabled = numberOfPages > 1 and currentPage < numberOfPages
        }
    end

    dialog --
    :label{text = "Frame number, layer name, tag name or sprite name:"} --
    :entry{
        id = "search",
        text = search,
        onchange = function()
            search = dialog.data.search
            results = Search(app.activeSprite, search, dialog.data.searchAll)

            RefreshWidgets()
        end
    } --
    :separator{text = "Results:"} --
    :label{id = "no-results", text = "No results"} --
    :button{
        id = "prev-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            currentPage = currentPage - 1
            RefreshWidgets()
            dialog:modify{id = "result-" .. tostring(PageSize), focus = true}
        end
    } --
    :newrow()

    for i = 1, PageSize do
        dialog --
        :button{
            id = "result-" .. tostring(i),
            visible = false,
            onclick = function()
                local skip = (currentPage - 1) * PageSize
                local result = results[i + skip]

                -- Switch to the sprite first as the search result could be from another file
                if result.sprite then
                    app.activeSprite = result.sprite
                end

                if result.type == SearchResultType.Layer then
                    app.activeLayer = result.layer
                elseif result.type == SearchResultType.Tag then
                    -- Jump to the last frame first to ensure most tagged frames are visible on the timeline
                    app.activeFrame = result.tag.toFrame
                    app.activeFrame = result.tag.fromFrame
                elseif result.type == SearchResultType.Frame then
                    app.activeFrame = result.frame
                elseif result.type == SearchResultType.Sprite then
                    -- Already changed if variable exists
                end

                dialog:close()
            end
        } --
        :newrow()
    end

    dialog --
    :button{
        id = "next-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            currentPage = currentPage + 1
            RefreshWidgets()
            dialog:modify{id = "result-1", focus = true}
        end
    } --
    :separator() --
    :check{
        id = "searchAll",
        text = "Search within all open sprites",
        selected = options.searchAll,
        onclick = function()
            results = Search(app.activeSprite, search, dialog.data.searchAll)
            RefreshWidgets()
        end
    } --
    :button{text = "Cancel"}

    return dialog
end

return SearchDialog
