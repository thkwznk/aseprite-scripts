function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end

local PageSize = 6
local SearchResultType = {
    Layer = "layer",
    Tag = "tag",
    Frame = "frame",
    Sprite = "sprite"
}

local SearchDialog = {
    dialog = nil,
    search = "",
    results = {},
    currentPage = 1,
    pages = 1,
    sources = {layers = true, tags = true, frames = false, sprites = false}
}

function SearchDialog:Create(options)
    self.search = ""
    self.sources = options.sources
    self.dialog = Dialog(options.title)

    self.dialog --
    :label{text = "Frame number, layer name or tag name:   "} --
    :entry{
        id = "search",
        text = self.search,
        onchange = function()
            self.search = self.dialog.data.search

            if #self.search == 0 then
                self.results = {}
            else
                self.results = self:Search(app.activeSprite, self.search,
                                           self.sources)
            end

            self:RefreshWidgets()
        end
    } --
    -- :check{
    --     id = "search-layers",
    --     text = "Layers",
    --     selected = self.sources.layers,
    --     onclick = function()
    --         self.sources.layers = self.dialog.data["search-layers"]
    --         self.results = self:Search(app.activeSprite, self.search,
    --                                    self.sources)
    --         self:RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-tags",
    --     text = "Tags",
    --     selected = self.sources.tags,
    --     onclick = function()
    --         self.sources.tags = self.dialog.data["search-tags"]
    --         self.results = self:Search(app.activeSprite, self.search,
    --                                    self.sources)
    --         self:RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-frames",
    --     text = "Frames",
    --     selected = self.sources.frames,
    --     onclick = function()
    --         self.sources.frames = self.dialog.data["search-frames"]
    --         self.results = self:Search(app.activeSprite, self.search,
    --                                    self.sources)
    --         self:RefreshWidgets()
    --     end
    -- } --
    -- :check{
    --     id = "search-sprites",
    --     text = "Sprites",
    --     selected = self.sources.sprites,
    --     onclick = function()
    --         self.sources.sprites = self.dialog.data["search-sprites"]
    --         self.results = self:Search(app.activeSprite, self.search,
    --                                    self.sources)
    --         self:RefreshWidgets()
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
            self.currentPage = self.currentPage - 1
            self:RefreshWidgets()
            self.dialog:modify{
                id = "result-" .. tostring(PageSize),
                focus = true
            }
        end
    } --
    :newrow()

    for i = 1, PageSize do
        self.dialog --
        :button{
            id = "result-" .. tostring(i),
            visible = false,
            onclick = function()
                local skip = (self.currentPage - 1) * PageSize
                local result = self.results[i + skip]

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

                self:Close()
            end
        } --
        :newrow()
    end

    self.dialog --
    :button{
        id = "next-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            self.currentPage = self.currentPage + 1
            self:RefreshWidgets()
            self.dialog:modify{id = "result-1", focus = true}
        end
    } --
    :separator() --
    :button{text = "Cancel"}
end

function SearchDialog:Search(sprite, searchText, sources)
    local pattern = self:GetPattern(searchText):lower()
    local results = {}

    if sources.layers then
        self:SearchLayers(sprite, sprite.layers, pattern, searchText, results)
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

function SearchDialog:GetPattern(text)
    local pattern = "";
    for i = 1, #text do pattern = pattern .. text:sub(i, i) .. ".*" end
    return pattern;
end

function SearchDialog:SearchLayers(sprite, layers, pattern, searchText, results,
                                   prefix)
    prefix = prefix or ""

    for _, layer in ipairs(layers) do
        if layer.isGroup then
            self:SearchLayers(sprite, layer.layers, pattern, searchText,
                              results, prefix .. layer.name .. " > ")
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

function SearchDialog:RefreshWidgets()
    local numberOfPages = math.max(math.ceil(#self.results / PageSize), 1)
    self.currentPage = math.min(self.currentPage or 1, numberOfPages)

    local skip = (self.currentPage - 1) * PageSize
    local resultsOnPage = math.min(PageSize, #self.results - skip)

    self.dialog:modify{id = "no-results", visible = resultsOnPage == 0}

    for i = 1, resultsOnPage do
        local result = self.results[skip + i]

        self.dialog:modify{
            id = "result-" .. tostring(i),
            visible = true,
            text = result.name .. " (" .. result.type .. ")"
        }
    end

    if resultsOnPage < PageSize then
        for i = resultsOnPage + 1, PageSize do
            self.dialog:modify{id = "result-" .. tostring(i), visible = false}
        end
    end

    self.dialog --
    :modify{
        id = "prev-page",
        visible = self.currentPage > 1,
        enabled = numberOfPages > 1 and self.currentPage > 1
    } --
    :modify{
        id = "next-page",
        visible = self.currentPage < numberOfPages,
        enabled = numberOfPages > 1 and self.currentPage < numberOfPages
    }
end

function SearchDialog:Show() if self.dialog then self.dialog:show() end end
function SearchDialog:Close() if self.dialog then self.dialog:close() end end

function init(plugin)
    plugin:newCommand{
        id = "GoTo",
        title = "Go to...",
        group = "sprite_properties",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            SearchDialog:Create{
                title = "Go to",
                sources = {layers = true, tags = true, frames = true}
            }
            SearchDialog:Show()
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
