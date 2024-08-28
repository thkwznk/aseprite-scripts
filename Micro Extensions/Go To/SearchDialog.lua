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

function SearchLayers(sprite, layers, pattern, searchText, results, prefix)
    prefix = prefix or ""

    for _, layer in ipairs(layers) do
        if layer.isGroup then
            SearchLayers(sprite, layer.layers, pattern, searchText, results,
                         prefix .. layer.name .. " > ")
        else
            local fullName = prefix .. layer.name

            local searchResult = {
                name = fullName,
                layer = layer,
                weight = 0,
                type = SearchResultType.Layer
            };

            local name = fullName:lower();

            if StartsWith(name, searchText:lower()) then
                searchResult.weight = 1;
            elseif name:match(pattern) then
                searchResult.weight = searchText:len() / name:len()
            end

            if searchResult.weight > 0 then
                table.insert(results, searchResult)
            end
        end
    end
end

function Search(sprite, searchText, sources)
    if #searchText == 0 then return {} end

    local pattern = GetPattern(searchText):lower()
    local results = {}

    if sources.layers then
        SearchLayers(sprite, sprite.layers, pattern, searchText, results)
    end

    if sources.tags then
        for _, tag in ipairs(sprite.tags) do
            local searchResult = {
                name = tag.name,
                tag = tag,
                weight = 0,
                type = SearchResultType.Tag
            };

            local name = tag.name:lower()

            if StartsWith(name, searchText:lower()) then
                searchResult.weight = 1;
            elseif name:match(pattern) then
                searchResult.weight = searchText:len() / name:len()
            end

            if searchResult.weight > 0 then
                table.insert(results, searchResult)
            end
        end
    end

    if sources.frames then
        for _, frame in ipairs(sprite.frames) do
            local frameNumber = tostring(frame.frameNumber)

            local searchResult = {
                name = frameNumber,
                frame = frame,
                weight = 0,
                type = SearchResultType.Frame
            }

            if StartsWith(frameNumber, searchText:lower()) then
                searchResult.weight = 1;
            elseif frameNumber:match(pattern) then
                searchResult.weight = searchText:len() / frameNumber:len()
            end

            if searchResult.weight > 0 then
                table.insert(results, searchResult)
            end
        end
    end

    if sources.sprites then
        for _, openSprite in ipairs(app.sprites) do
            local filename = app.fs.fileName(openSprite.filename)

            local searchResult = {
                name = filename,
                sprite = openSprite,
                weight = 0,
                type = SearchResultType.Sprite
            };

            local name = filename:lower()

            if StartsWith(name, searchText:lower()) then
                searchResult.weight = 1;
            elseif name:match(pattern) then
                searchResult.weight = searchText:len() / name:len()
            end

            if searchResult.weight > 0 then
                table.insert(results, searchResult)
            end
        end
    end

    table.sort(results, function(a, b) return a.weight > b.weight end)

    return results
end

function SearchDialog(options)
    local search = ""
    local sources = options.sources or
                        {
            layers = true,
            tags = true,
            frames = false,
            sprites = false
        }
    local results = {}
    local currentPage = 1

    local dialog = Dialog(options.title)

    function RefreshWidgets()
        local numberOfPages = math.max(math.ceil(#results / PageSize), 1)
        currentPage = math.min(currentPage or 1, numberOfPages)

        local skip = (currentPage - 1) * PageSize
        local resultsOnPage = math.min(PageSize, #results - skip)

        dialog:modify{id = "no-results", visible = resultsOnPage == 0}

        for i = 1, resultsOnPage do
            local result = results[skip + i]

            dialog:modify{
                id = "result-" .. tostring(i),
                visible = true,
                text = result.name .. " (" .. result.type .. ")"
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
    :label{text = "Frame number, layer name or tag name:   "} --
    :entry{
        id = "search",
        text = search,
        onchange = function()
            search = dialog.data.search
            results = Search(app.activeSprite, search, sources)

            RefreshWidgets()
        end
    } --
    -- :check{
    --     id = "search-layers",
    --     text = "Layers",
    --     selected = sources.layers,
    --     onclick = function()
    --         sources.layers = dialog.data["search-layers"]
    --         results = Search(app.activeSprite, search, sources)
    --         RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-tags",
    --     text = "Tags",
    --     selected = sources.tags,
    --     onclick = function()
    --         sources.tags = dialog.data["search-tags"]
    --         results = Search(app.activeSprite, search, sources)
    --         RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-frames",
    --     text = "Frames",
    --     selected = sources.frames,
    --     onclick = function()
    --         sources.frames = dialog.data["search-frames"]
    --         results = Search(app.activeSprite, search, sources)
    --         RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-sprites",
    --     text = "Sprites",
    --     selected = sources.sprites,
    --     onclick = function()
    --         sources.sprites = dialog.data["search-sprites"]
    --         results = Search(app.activeSprite, search, sources)
    --         RefreshWidgets()
    --     end
    -- } --
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

                if result.type == SearchResultType.Layer then
                    app.activeLayer = result.layer
                elseif result.type == SearchResultType.Tag then
                    -- Jump to the last frame first to ensure most tagged frames are visible on the timeline
                    app.activeFrame = result.tag.toFrame
                    app.activeFrame = result.tag.fromFrame
                elseif result.type == SearchResultType.Frame then
                    app.activeFrame = result.frame
                elseif result.type == SearchResultType.Sprite then
                    app.activeSprite = result.sprite
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
    :button{text = "Cancel"}

    return dialog
end

return SearchDialog
