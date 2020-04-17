-- Copyright (C) 2018 Kacper Woźniak
--
-- This file is released under the terms of the CC BY 4.0 license.
-- See https://creativecommons.org/licenses/by/4.0/ for more information.
--
-- Version: 1.0.1, May 24, 2019

-- Check is UI available
if not app.isUIAvailable then
    return
end

----------------------------------------------------------------------------------------------------
-- External functions ------------------------------------------------------------------------------
    -- http://lua-users.org/wiki/SaveTableToFile
    -- http://lua-users.org/wiki/SplitJoin
----------------------------------------------------------------------------------------------------

--// exportstring( string )
--// returns a "Lua" portable version of the string
function exportstring( s )
    return string.format("%q", s)
end

--// The Save Function
function table.save(  tbl,filename )
    local charS,charE = "   ","\n"
    local file,err = io.open( filename, "wb" )
    if err then return err end

    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    file:write( "return {"..charE )

    for idx,t in ipairs( tables ) do
        file:write( "-- Table: {"..idx.."}"..charE )
        file:write( "{"..charE )
        local thandled = {}

        for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
                if not lookup[v] then
                table.insert( tables, v )
                lookup[v] = #tables
                end
                file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
                file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
                file:write(  charS..tostring( v )..","..charE )
            end
        end

        for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then
            
                local str = ""
                local stype = type( i )
                -- handle index
                if stype == "table" then
                if not lookup[i] then
                    table.insert( tables,i )
                    lookup[i] = #tables
                end
                str = charS.."[{"..lookup[i].."}]="
                elseif stype == "string" then
                str = charS.."["..exportstring( i ).."]="
                elseif stype == "number" then
                str = charS.."["..tostring( i ).."]="
                end
            
                if str ~= "" then
                stype = type( v )
                -- handle value
                if stype == "table" then
                    if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                    end
                    file:write( str.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                    file:write( str..exportstring( v )..","..charE )
                elseif stype == "number" then
                    file:write( str..tostring( v )..","..charE )
                end
                end
            end
        end
        file:write( "},"..charE )
    end
    file:write( "}" )
    file:close()
end

--// The Load Function
function table.load( sfile )
    local ftables,err = loadfile( sfile )
    if err then return _,err end
    local tables = ftables()
    for idx = 1,#tables do
        local tolinki = {}
        for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
                tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
                table.insert( tolinki,{ i,tables[i[1]] } )
            end
        end
        -- link indices
        for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
        end
    end
    return tables[1]
end

-- Compatibility: Lua-5.1
-- // Split String Function
function split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

-- // Split Path Function
function split_path(str)
    return split(str,'[\\/]+')
end

----------------------------------------------------------------------------------------------------
-- Helpers -----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function table:last(t) return t[#t] end
function table:removeLast(t) table.remove(t, #t) end
function table:any(t) return #t > 0 end

function string:first(s) return string.sub(s, 1, 1) end

local OutputPathProvider = {
    outputFileName=".output"
}

function OutputPathProvider:setOutputFileName(outputFileName)
    self.outputFileName = outputFileName
end

function OutputPathProvider:_getFileNameWithoutExtension(path)
    local fileNameWithExtension = table:last(split_path(path))
    local fileNameSplit = split(fileNameWithExtension, "[.]+")
    table:removeLast(fileNameSplit)
    local fileNameWithoutExtension = table.concat(fileNameSplit, ".")

    return fileNameWithoutExtension
end

function OutputPathProvider:_getDirectoryName(path)
    local splitPath = split_path(path)
    table:removeLast(splitPath)

    return table.concat(splitPath, "\\")
end

function OutputPathProvider:global()
    return ".\\" .. self.outputFileName 
end

function OutputPathProvider:forDirectory(filePath)
    return self:_getDirectoryName(filePath) .. "\\" .. self.outputFileName
end

function OutputPathProvider:forFile(filePath)
    return self:_getDirectoryName(filePath) .. "\\." .. self:_getFileNameWithoutExtension(filePath) .. self.outputFileName
end

----------------------------------------------------------------------------------------------------

local Gui = {
    _title="Title",
    _dialog=nil,
    _tasks={},
    _tasksPath=".\\.tasks",
    _checkedPrefix="!",
    _hideChecked=false
}

function Gui:setTitle(title) self._title = title end
function Gui:setTasksPath(path) self._tasksPath = path end

function Gui:loadTasks()
    local loadedTasks = table.load(self._tasksPath)

    if loadedTasks then
        self._tasks = loadedTasks
    else
        self._tasks = {}
    end
end

function Gui:saveTasks()
    table.save(self._tasks, self._tasksPath)
end

function Gui:addTask(text)
    if not text or text == "" then
        return
    end

    table.insert(self._tasks, text)
end

function Gui:deleteTasks()
    local keptTasks = {}

    for index, value in ipairs(self._tasks) do
        if not self._dialog.data[tostring(index)] then
            table.insert(keptTasks, value)
        end
    end

    self._tasks = keptTasks
    self:saveTasks()
    self:showEditView()
end

function Gui:checkTask(index)
    local task = self._tasks[index]

    self._tasks[index] = self._checkedPrefix .. task
end

function Gui:isChecked(index)
    local task = self._tasks[index]
    local firstChar = string:first(task)

    return firstChar == self._checkedPrefix
end

function Gui:getNumberOfTasksToShow()
    local result = 0

    for index, value in ipairs(self._tasks) do
        if self:isChecked(index) then
            if not self._hideChecked then
                result = result + 1
            end
        else
            result = result + 1
        end
    end

    return result
end

function Gui:refresh(config)
    -- Close current dialog
    if self._dialog then self._dialog:close() end

    if not config or not config["reload"] then
        self:loadTasks()
    end

    self._dialog = Dialog(self._title)
        :entry{
            id="entryText",
        }
        :button{
            text="                    +                    ",
            onclick=function()
                local text = self._dialog.data["entryText"]
                self:addTask(text)
                self:saveTasks()
                self:refresh{ reload=false }
            end
        }

    if table:any(self._tasks) then
        self._dialog
            :check{
                id="hideChecked",
                text="Hide Checked Tasks", 
                selected=self._hideChecked,
                onclick=function()
                    self._hideChecked = not self._hideChecked
                    self:refresh{ reload=false }
                end
            }
    end

    if self:getNumberOfTasksToShow() > 0 then
        self._dialog
            :separator{ text="Tasks" }
    end

    local checkedOffset = 1 + string.len(self._checkedPrefix)
    
    for index, value in ipairs(self._tasks) do
        if self:isChecked(index) then
            if not self._hideChecked then
                self._dialog
                    :separator{
                        text=value:sub(checkedOffset)
                    }
            end
        else
            self._dialog
                :check{
                    text=value,
                    selected=false,
                    onclick=function()
                        self:checkTask(index)
                        self:saveTasks()
                        self:refresh{ reload=false }
                    end
                }
                :newrow()
        end
    end

    if table:any(self._tasks) then
        if self:getNumberOfTasksToShow() > 0 then self._dialog:separator() end

        self._dialog
            :button{
                text="Delete",
                onclick=function() self:showEditView() end
            }
    end

    self._dialog:show{ wait=false }
end

function Gui:showEditView(config)
    if not table:any(self._tasks) then
        self:refresh()
        return
    end

    -- Close current dialog
    if self._dialog then self._dialog:close() end

    if config and config["reload"] then
        self:loadTasks()
    end

    local selectAll = config and config["selectAll"]
    local selectNone = config and config["selectNone"]

    self._dialog = Dialog(self._title .. ": Delete")

    local checkedOffset = 1 + string.len(self._checkedPrefix)

    if selectAll then
        self._dialog
        :check{
            text="Select None",
            selected=true,
            onclick=function()
                self:showEditView{
                    selectNone=true,
                    reload=false
                }
            end
        }
    else
        self._dialog
            :check{
                text="Select All",
                selected=false,
                onclick=function()
                    self:showEditView{
                        selectAll=true,
                        reload=false
                    }
                end
            }
    end
    
    self._dialog:separator{ text="Tasks" }

    for index, value in ipairs(self._tasks) do
        local isChecked = self:isChecked(index)
        self._dialog
            :check{
                id=tostring(index),
                text=isChecked and value:sub(checkedOffset) or value,
                selected=selectAll or isChecked and not selectNone
            }
            :newrow()
    end

    self._dialog
        :separator()
        :button{
            text="Delete Selected",
            onclick=function()
                self:deleteTasks()
            end
        }
        :button{
            text="Back",
            onclick=function()
                self:refresh{ reload=false }
            end
        }
        :show{ wait=false }
end

----------------------------------------------------------------------------------------------------
-- Start script ------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

do
    local config = {
        title="Note",
        outputFileName=".tasks"
    }

    OutputPathProvider:setOutputFileName(config.outputFileName)

    Gui:setTitle(config.title)
    Gui:setTasksPath(OutputPathProvider:global())

    Gui:refresh()
end
