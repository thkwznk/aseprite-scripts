local Tool = {
    supportedTools = {
        "pencil", "spray", "eraser", "paint_bucket", "line", "curve",
        "rectangle", "filled_rectangle", "ellipse", "filled_ellipse", "contour",
        "polygon"
    }
}

function Tool:IsSupported(toolId)
    for _, supportedToolId in ipairs(self.supportedTools) do
        if supportedToolId == toolId then return true end
    end

    return false
end

return Tool
