local Tool = {
    supportedTools = {
        "pencil", "spray", "eraser", "paint_bucket", "line", "curve",
        "rectangle", "filled_rectangle", "ellipse", "filled_ellipse", "contour",
        "polygon"
    }
}

function Tool:IsSupported(toolId, modeProcessor)
    -- For modes that require the mask color the eraser makes it impossible to detect which button was pressed
    if modeProcessor.useMaskColor and toolId == "eraser" then return false end

    for _, supportedToolId in ipairs(self.supportedTools) do
        if supportedToolId == toolId then return true end
    end

    return false
end

return Tool
