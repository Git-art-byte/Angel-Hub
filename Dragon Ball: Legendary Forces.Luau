local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Dragon Ball: Legendary Forces" .. Fluent.Version,
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
    Main = Window:AddTab({ Title = "Training", Icon = "biceps-flexed" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

----------------------------------------------------------------
-- TRAIN
----------------------------------------------------------------
local SectionA = Tabs.Main:AddSection("Train")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SelectedSkill = "Mind Control"
local Training = false
local KiLoopRunning = false

-- DROPDOWN
Tabs.Main:AddDropdown("SkillDropdown", {
    Title = "Training Type",
    Values = {"Mind Control", "Ki Control"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        SelectedSkill = value
    end
})

-- TOGGLE
Tabs.Main:AddToggle("TrainToggle", {
    Title = "Train",
    Default = false,
    Callback = function(state)
        Training = state

        -- 🧠 MEDITATE (true / false only)
        if SelectedSkill == "Mind Control" then
            ReplicatedStorage.meditate:FireServer(state)
        end

        -- 🔥 KI CONTROL (loop)
        if SelectedSkill == "Ki Control" and state then
            if KiLoopRunning then return end
            KiLoopRunning = true

            task.spawn(function()
                while Training and SelectedSkill == "Ki Control" do
                    workspace.stalou0406["Genki Dama"].RemoteEvent:FireServer(
                        "GenkiDama"
                    )
                    task.wait(1)
                end
                KiLoopRunning = false
            end)
        end
    end
})
