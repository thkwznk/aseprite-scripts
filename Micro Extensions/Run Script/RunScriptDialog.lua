local commands = dofile("./Commands.lua")

local SCRIPTS_DIRECTORY = app.fs.joinPath(app.fs.userConfigPath, "scripts")

local function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end
local function RemoveSpaces(s) return (s:gsub(" ", "")) end

local RunScriptPageSize = 6

local function CreateFileStructure(directory, prefix, structure)
    structure = structure or {}
    prefix = prefix or ""

    for _, filename in ipairs(app.fs.listFiles(directory)) do
        local fullFilename = app.fs.joinPath(directory, filename)

        if app.fs.isDirectory(fullFilename) then
            table.insert(structure, {
                filename = filename,
                filepath = fullFilename,
                children = CreateFileStructure(fullFilename,
                                               prefix .. filename .. " > ", {})
            })
        elseif app.fs.isFile(fullFilename) and app.fs.fileExtension(filename) ==
            "lua" then
            local title = app.fs.fileTitle(filename)
            table.insert(structure, {
                filename = filename,
                name = title,
                path = "File > Scripts > " .. prefix .. title,
                filepath = fullFilename
            })
        end
    end

    return structure
end

local function SearchScriptsRecursively(fileStructure, searchText, pattern,
                                        prefix, exactMatches, prefixMatches,
                                        fuzzyMatches)
    for _, fileEntry in ipairs(fileStructure) do
        if fileEntry.children then
            SearchScriptsRecursively(fileEntry.children, searchText, pattern,
                                     prefix .. fileEntry.filename .. " > ",
                                     exactMatches, prefixMatches, fuzzyMatches)
        else
            local name = fileEntry.filename:lower()

            if name == searchText then
                table.insert(exactMatches, fileEntry)
            elseif StartsWith(name, searchText) then
                table.insert(prefixMatches, fileEntry)
            elseif name:match(pattern) then
                table.insert(fuzzyMatches, fileEntry)
            end
        end
    end
end

local function CopyToResults(matches, results, showDisabled)
    for _, match in ipairs(matches) do
        match.enabled = true
        if match.onenable ~= nil then match.enabled = match.onenable() end

        if showDisabled or match.enabled then
            table.insert(results, match)
        end
    end
end

local function SearchScripts(searchText, fileStructure)
    local exactMatches, prefixMatches, fuzzyMatches, results = {}, {}, {}, {}

    -- Use lowercase for case-insensitive search
    searchText = searchText:lower()

    local pattern = ""
    for i = 1, #searchText do
        pattern = pattern .. searchText:sub(i, i) .. ".*"
    end

    SearchScriptsRecursively(fileStructure, searchText, pattern, "",
                             exactMatches, prefixMatches, fuzzyMatches)

    table.sort(exactMatches, function(a, b) return a.filename < b.filename end)
    table.sort(prefixMatches, function(a, b) return a.filename < b.filename end)
    table.sort(fuzzyMatches, function(a, b) return a.filename < b.filename end)

    CopyToResults(exactMatches, results)
    CopyToResults(prefixMatches, results)
    CopyToResults(fuzzyMatches, results)

    return results
end

local function SearchCommands(searchText, showDisabled)
    local exactMatches, prefixMatches, fuzzyMatches, results = {}, {}, {}, {}

    -- Use lowercase for case-insensitive search
    searchText = searchText:lower()

    local pattern = ""
    for i = 1, #searchText do
        pattern = pattern .. searchText:sub(i, i) .. ".*"
    end

    for _, command in ipairs(commands) do
        local name = command.name:lower()
        local path = command.path:lower()

        if name == searchText then
            table.insert(exactMatches, command)
        elseif path == searchText then
            table.insert(exactMatches, command)
        elseif StartsWith(name, searchText) then
            table.insert(prefixMatches, command)
        elseif StartsWith(path, searchText) then
            table.insert(prefixMatches, command)
        elseif name:match(pattern) then
            table.insert(fuzzyMatches, command)
        elseif path:match(pattern) then
            table.insert(fuzzyMatches, command)
        end
    end

    CopyToResults(exactMatches, results, showDisabled)
    CopyToResults(prefixMatches, results, showDisabled)
    CopyToResults(fuzzyMatches, results, showDisabled)

    return results
end

local function RunScriptDialog(options)
    local search = ""
    local dialog
    dialog = Dialog {
        title = options.title,
        onclose = function()
            if options.onclose then options.onclose(dialog.data) end
        end
    }
    local results = {}
    local currentPage = 1

    local fileStructure = CreateFileStructure(SCRIPTS_DIRECTORY)

    local function RefreshWidgets()
        local numberOfPages = math.max(math.ceil(#results / RunScriptPageSize),
                                       1)
        currentPage = math.min(currentPage or 1, numberOfPages)

        local skip = (currentPage - 1) * RunScriptPageSize
        local resultsOnPage = math.min(RunScriptPageSize, #results - skip)

        dialog:modify{
            id = "resultsSeparator",
            visible = #dialog.data.search > 0
        }
        dialog:modify{
            id = "noResults",
            visible = #dialog.data.search > 0 and resultsOnPage == 0
        }

        for i = 1, resultsOnPage do
            local result = results[skip + i]

            local name = result.name
            if dialog.data.showPaths then name = result.path end

            dialog:modify{
                id = "result-" .. tostring(i),
                visible = true,
                text = name,
                enabled = result.enabled
            }
        end

        if resultsOnPage < RunScriptPageSize then
            for i = resultsOnPage + 1, RunScriptPageSize do
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

    local function SearchAll()
        search = RemoveSpaces(dialog.data.search)
        results = {}
        if #search > 0 then
            if dialog.data.searchCommands then
                for _, command in ipairs(
                                      SearchCommands(search,
                                                     dialog.data.showDisabled)) do
                    table.insert(results, command)
                end
            end

            if dialog.data.searchScripts then
                for _, script in ipairs(SearchScripts(search, fileStructure)) do
                    table.insert(results, script)
                end
            end
        end

        RefreshWidgets()
    end

    dialog --
    :label{text = "Search a command or script by name:"} --
    :entry{id = "search", text = search, onchange = function() SearchAll() end} --
    :separator{id = "resultsSeparator", text = "Results:"} --
    :label{id = "noResults", text = "No results"} --
    :button{
        id = "prev-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            currentPage = currentPage - 1
            RefreshWidgets()
            dialog:modify{
                id = "result-" .. tostring(RunScriptPageSize),
                focus = true
            }
        end
    } --
    :newrow()

    for i = 1, RunScriptPageSize do
        dialog --
        :button{
            id = "result-" .. tostring(i),
            visible = false,
            onclick = function()
                local skip = (currentPage - 1) * RunScriptPageSize
                local result = results[i + skip]

                -- Close the dialog first to avoid having it left open if the scripts opens it's own dialog with option `wait=true`
                dialog:close()

                if result.command then
                    app.command[result.command](result.parameters)
                else
                    -- Execute the selected script
                    dofile(result.filepath)
                end

                if options.onrun then
                    options.onrun(result, dialog.data)
                end
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
    :separator{text = "Sources:"} --
    :check{
        id = "searchCommands",
        text = "Commands",
        selected = options.searchCommands,
        onclick = function() SearchAll() end
    } --
    :check{
        id = "searchScripts",
        text = "Scripts",
        selected = options.searchScripts,
        onclick = function() SearchAll() end
    } --
    :separator{text = "Options:"} -- 
    :check{
        id = "showPaths",
        text = "Show paths",
        selected = options.showPaths,
        onclick = function() SearchAll() end
    } --
    :check{
        id = "showDisabled",
        text = "Show disabled",
        selected = options.showDisabled,
        onclick = function() SearchAll() end
    } --
    :button{text = "Cancel"}

    -- Open and close to initialize the dialog bounds
    dialog:show{wait = false}
    dialog:modify{id = "resultsSeparator", visible = false}
    dialog:modify{id = "noResults", visible = false}
    dialog:close()

    local defaultWidth = 280

    -- Set an initial width of the dialog
    local newBounds = dialog.bounds
    newBounds.x = newBounds.x - math.abs(newBounds.width - defaultWidth) / 2
    newBounds.width = defaultWidth
    dialog.bounds = newBounds

    return dialog
end

return RunScriptDialog
