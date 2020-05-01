include("extensions/String")

-- Check is UI available
if not app.isUIAvailable then return end

do
    local dialog = Dialog("Test")

    local tests = {
        "LayerMask", "LayerOpen", "LayerFromBackground", "LayerAdd",
        "LayerFromForeground", "LayerProperties", "FrameAdd", "Ladder", "Loader"
    }

    function GetPattern(text)
        local pattern = "";

        for i = 1, #text do
            local v = text:sub(i, i)
            pattern = pattern .. v .. ".*"
        end

        return pattern;
    end

    function Check(text)
        local pattern = GetPattern(text):lower()

        local results = {}

        for i, v in ipairs(tests) do
            local command = tests[i]:lower();

            if command:match(pattern) then
                local _weight = text:len() / command:len()

                if command:startsWith(text:lower()) then
                    _weight = 1;
                end

                table.insert(results, {
                    txt = tests[i],
                    weight = _weight
                })
            end
        end

        table.sort(results, function(a, b)
            return a.weight > b.weight
        end)

        -- Console Output
        local output = ""

        for i, v in ipairs(results) do
            output = output .. v.txt .. "   (" .. v.weight .. ")\n"
        end

        print(output)
    end

    dialog:entry{id = "text", label = "Text"}:button{
        text = "OK",
        onclick = function() Check(dialog.data["text"]); end
    }:show{wait = false}
end
