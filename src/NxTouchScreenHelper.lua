-- Check is UI available
if not app.isUIAvailable then return end

include("touch-screen-helper/TouchScreenHelperDialog")

do
    local dialog = CreateTouchScreenHelperDialog()

    dialog:show{wait = false}
end
