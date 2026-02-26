local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Dragon Ball: Legendary Forces " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:Notify({
    Title = "Loaded!",
    Content = "Angel Hub has succesfully been loaded!",
    Duration = 5
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local Section1 = Tabs.Main:AddSection("AutoFarm")

local Input = Tabs.Main:AddInput("Input", {
    Title = "Input Folder",
    Description = "Input the path/link of the folder you want to farm the mobs.",
    Default = "Default",
    Placeholder = "workspace.Bosses",
    Numeric = false, -- Only allows numbers
    Finished = false, -- Only calls callback when you press enter
    Callback = function(Value)
        print("Input changed:", Value)
    end
})

local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Select Mob",
    Description = "Select the mob you want to autofarm.",
    Values = {},
    Multi = false,
    Default = 1,
})

local Toggle1 = Tabs.Main:AddToggle("MyToggle1", 
{
    Title = "Start", 
    Description = "Commence the autofarm.",
    Default = false
    Callback = function(state)
	if state then
	    print("Toggle On")
	else
	    print("Toggle Off")
        end
    end 
})

local Section2 = Tabs.Main:AddSection("Settings")

local Toggle = Tabs.Main:AddToggle("MyToggle2", 
{
    Title = "Whole Folder", 
    Description = "Turning this toogle on gonna autofarm every mobs in the folder.",
    Default = false
    Callback = function(state)
	if state then
	    print("Toggle On")
	else
	    print("Toggle Off")
        end
    end 
})
