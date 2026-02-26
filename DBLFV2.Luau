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
    Zeni = Window:AddTab({ Title = "Zeni", Icon = "dollar-sign" }),
    Gamemode = Window:AddTab({ Title = "Gamemode", Icon = "waves" }),
    Troll = Window:AddTab({ Title = "Troll/PVP", Icon = "swords" }),
    Top = Window:AddTab({ Title = "TOP", Icon = "circle" }),
    DragonBall = Window:AddTab({ Title = "DragonBall", Icon = "circle-star" }),
    MUI = Window:AddTab({ Title = "Ultra Instinct", Icon = "users" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
