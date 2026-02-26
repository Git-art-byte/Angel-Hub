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

local AutoFarmEnabled = false
local WholeFolderEnabled = false
local FolderPath = ""
local SelectedMob = nil
local currentTarget = nil
local BACK_OFFSET = -5  -- To teleport behind the mob
local TELEPORT_DELAY = 0.1
local combatRemote = game:GetService("ReplicatedStorage").Assets.CombatAssets.CombatRemotes.ActivateCombat

local function getFolder(path)
    if path == "" then return nil end
    local parts = string.split(path, ".")
    local current = game
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

local Section1 = Tabs.Main:AddSection("AutoFarm")

local Input = Tabs.Main:AddInput("Input", {
    Title = "Input Folder",
    Description = "Input the path/link of the folder you want to farm the mobs(Warning: The mobs must be models with a HumanoidRootPart).",
    Default = "",
    Placeholder = "workspace.Bosses",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        FolderPath = Value
        local mobs = {}
        local player = game.Players.LocalPlayer
        local char = player.Character
        local phrp = char and char:FindFirstChild("HumanoidRootPart")
        if phrp then
            local folder = getFolder(FolderPath)
            if folder then
                for _, mob in ipairs(folder:GetChildren()) do
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp and (mhrp.Position - phrp.Position).Magnitude <= 600 then
                        table.insert(mobs, mob.Name)
                    end
                end
            end
        end
        if Dropdown then
            Dropdown:Destroy()
        end
        Dropdown = Tabs.Main:AddDropdown("Dropdown", {
            Title = "Select Mob",
            Description = "Select the mob you want to autofarm.",
            Values = mobs,
            Multi = false,
            Default = mobs[1] or nil,
            Callback = function(val)
                SelectedMob = val
            end
        })
    end
})

local Dropdown -- Declared here, will be set in input callback or initially

-- Initial population with empty
Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Select Mob",
    Description = "Select the mob you want to autofarm.",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(val)
        SelectedMob = val
    end
})

local Toggle1 = Tabs.Main:AddToggle("MyToggle1", 
{
    Title = "Start", 
    Description = "Commence the autofarm.",
    Default = false,
    Callback = function(state)
        AutoFarmEnabled = state
        if not state then
            currentTarget = nil
        end
    end 
})

local Section2 = Tabs.Main:AddSection("Settings")

local Toggle = Tabs.Main:AddToggle("MyToggle2", 
{
    Title = "Whole Folder", 
    Description = "Turning this toggle on gonna autofarm every mobs in the folder.",
    Default = false,
    Callback = function(state)
        WholeFolderEnabled = state
        currentTarget = nil  -- Reset target when changing mode
    end 
})

task.spawn(function()
    while true do
        if AutoFarmEnabled then
            local player = game.Players.LocalPlayer
            local char = player.Character
            local phrp = char and char:FindFirstChild("HumanoidRootPart")
            if phrp then
                local folder = getFolder(FolderPath)
                if folder then
                    if not currentTarget or not currentTarget.Parent or (currentTarget:FindFirstChildOfClass("Humanoid") and currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0) then
                        currentTarget = nil
                        if WholeFolderEnabled then
                            -- Find closest alive mob
                            local candidates = {}
                            for _, mob in ipairs(folder:GetChildren()) do
                                local hum = mob:FindFirstChildOfClass("Humanoid")
                                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                if hum and hum.Health > 0 and mhrp then
                                    local dist = (mhrp.Position - phrp.Position).Magnitude
                                    table.insert(candidates, {mob = mob, dist = dist})
                                end
                            end
                            table.sort(candidates, function(a, b) return a.dist < b.dist end)
                            if #candidates > 0 then
                                currentTarget = candidates[1].mob
                            end
                        else
                            if SelectedMob then
                                local mob = folder:FindFirstChild(SelectedMob)
                                if mob then
                                    local hum = mob:FindFirstChildOfClass("Humanoid")
                                    if hum and hum.Health > 0 then
                                        currentTarget = mob
                                    end
                                end
                            end
                        end
                    end
                    if currentTarget then
                        local bossHrp = currentTarget:FindFirstChild("HumanoidRootPart")
                        local bossHumanoid = currentTarget:FindFirstChildOfClass("Humanoid")
                        if bossHrp and bossHumanoid and bossHumanoid.Health > 0 then
                            phrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                            combatRemote:FireServer()
                        end
                    end
                end
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end)
