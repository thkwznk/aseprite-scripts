local SCRIPTS_DIRECTORY = app.fs.joinPath(app.fs.userConfigPath, "scripts")

function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end

local LastScriptPath
local RunScriptPageSize = 6

function GetPattern(text)
    local pattern = "";
    for i = 1, #text do pattern = pattern .. text:sub(i, i) .. ".*" end
    return pattern;
end

function Search(searchText)
    local pattern = GetPattern(searchText):lower()
    local results = {}

    for _, filename in ipairs(app.fs.listFiles(SCRIPTS_DIRECTORY)) do
        local fullFilename = app.fs.joinPath(SCRIPTS_DIRECTORY, filename)

        if app.fs.isFile(fullFilename) then
            -- TODO: Search recursively in folders as well

            local searchResult = {name = filename, weight = 0}
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

function RunScriptDialog(options)
    local search = ""
    local dialog = Dialog(options.title)
    local results = {}
    local currentPage = 1

    local refreshWidgets = function()
        local numberOfPages = math.max(math.ceil(#results / RunScriptPageSize),
                                       1)
        currentPage = math.min(currentPage or 1, numberOfPages)

        local skip = (currentPage - 1) * RunScriptPageSize
        local resultsOnPage = math.min(RunScriptPageSize, #results - skip)

        dialog:modify{id = "no-results", visible = resultsOnPage == 0}

        for i = 1, resultsOnPage do
            local result = results[skip + i]

            dialog:modify{
                id = "result-" .. tostring(i),
                visible = true,
                text = result.name
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

    dialog --
    :label{text = "Script name:"} --
    :entry{
        id = "search",
        text = search,
        onchange = function()
            search = dialog.data.search

            if #search == 0 then
                results = {}
            else
                results = Search(search)
            end

            refreshWidgets()
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
            refreshWidgets()
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

                local scriptPath = app.fs.joinPath(SCRIPTS_DIRECTORY,
                                                   result.name)

                -- Close the dialog first to avoid having it left open if the scripts opens it's own dialog with option `wait=true`
                dialog:close()

                -- Execute the selected script
                dofile(scriptPath)

                LastScriptPath = scriptPath
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
            refreshWidgets()
            dialog:modify{id = "result-1", focus = true}
        end
    } --
    :separator() --
    :button{text = "Cancel"}

    -- Open and close to initialize the dialog bounds
    dialog:show{wait = false}
    dialog:close()

    local defaultWidth = 200
    
    -- Set an initial width of the dialog
    local newBounds = dialog.bounds
    newBounds.x = newBounds.x - math.abs(newBounds.width - defaultWidth) / 2
    newBounds.width = defaultWidth
    dialog.bounds = newBounds

    return dialog
end

function init(plugin)
    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run Script",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {title = "Run Script"}
            dialog:show()

            -- TODO: Run script from another directory
            -- TODO: Register scripts as commands to be able to assign keyboard shortcuts to them (this will need to also verify if such a command already exists)
            -- TODO: ^ OR assign scripts to keyboard shortcuts from this dialog?
            -- TODO: Assign scripts to buttons in the UI
            -- TODO: Add an option to "Import Script" that copies a script from a given location to the APP_DATA directory of Aseprite
        end
    }

    plugin:newCommand{
        id = "RepeatScriptAdvanced",
        title = "Run Last Script",
        onclick = function()
            if app.fs.isFile(LastScriptPath) then
                dofile(LastScriptPath)
            end
        end
    }
end

function exit(plugin) end
