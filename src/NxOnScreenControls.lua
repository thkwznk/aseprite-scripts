-- Check is UI available
if not app.isUIAvailable then return end

include("on-screen-controls/Controlsdialog")

do
    ControlsDialog:Create("NxOSC");
    ControlsDialog:Show();
end
