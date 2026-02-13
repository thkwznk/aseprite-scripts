local SCRIPTS_DIRECTORY = app.fs.joinPath(app.fs.userConfigPath, "scripts")

local function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end
local function RemoveSpaces(s) return (s:gsub(" ", "")) end

local RunScriptPageSize = 6

local listFiles, joinPath, fileTitle, isFile, fileExtension = app.fs.listFiles,
                                                              app.fs.joinPath,
                                                              app.fs.fileTitle,
                                                              app.fs.isFile,
                                                              app.fs
                                                                  .fileExtension
local insert = table.insert

local function CreateFileStructure(directory, prefix, structure)
    structure = structure or {}
    prefix = prefix or ""

    for _, filename in ipairs(listFiles(directory)) do
        local fullFilename = joinPath(directory, filename)

        if isFile(fullFilename) then
            if fileExtension(filename) == "lua" then
                local title = fileTitle(filename)
                insert(structure, {
                    filename = filename,
                    name = title,
                    path = prefix .. title,
                    filepath = fullFilename
                })
            end
        else
            insert(structure, {
                filename = filename,
                filepath = fullFilename,
                children = CreateFileStructure(fullFilename,
                                               prefix .. filename .. " > ", {})
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
                insert(exactMatches, fileEntry)
            elseif StartsWith(name, searchText) then
                insert(prefixMatches, fileEntry)
            elseif name:match(pattern) then
                insert(fuzzyMatches, fileEntry)
            end
        end
    end
end

local function CopyToResults(matches, results)
    -- TODO: This could be optimized
    for _, match in ipairs(matches) do insert(results, match) end
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

local function RunScriptDialog(options)
    local search = ""
    local dialog
    dialog = Dialog {
        title = options.title,
        onclose = function()
            if options.onclose then options.onclose(dialog.data) end
        end,
        -- resizeable = false,
        -- autofit = Align.TOP
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
        if #search > 0 then
            results = SearchScripts(search, fileStructure)
        else
            results = {}
        end

        RefreshWidgets()
    end

    dialog --
    :label{text = "Search a script by name:"} --
    :entry{id = "search", text = search, onchange = function() SearchAll() end} --
    :separator{id = "resultsSeparator", text = "Results:", visible = false} --
    :label{id = "noResults", text = "No results", visible = false} --
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

                -- Execute the selected script
                dofile(result.filepath)

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
    :separator{text = "Options:"} -- 
    :check{
        id = "showPaths",
        text = "Show paths",
        selected = options.showPaths,
        onclick = function() SearchAll() end
    } --

    return dialog
end

function init(plugin)
    local preferences = plugin.preferences

    local function CopyPreferences(data)
        -- "data" can be either plugin.preferences or dialog.data
        preferences.showPaths = data.showPaths or false
    end

    CopyPreferences(preferences)

    local lastRunOption

    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run...",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {
                title = "Run",
                showPaths = preferences.showPaths,
                onrun = function(option, data)
                    CopyPreferences(data)
                    lastRunOption = option
                end,
                onclose = function(data) CopyPreferences(data) end
            }
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "RepeatScriptAdvanced",
        title = "Run Last Script",
        onenabled = function() return lastRunOption ~= nil end,
        onclick = function()
            if lastRunOption.filepath and app.fs.isFile(lastRunOption.filepath) then
                dofile(lastRunOption.filepath)
            end
        end
    }
end

function exit(plugin) end

-- TODO: Add a profiler and options for repeating a script
-- TODD: Test other keyboard shortcuts (Ctrl+Alt+Space?)
