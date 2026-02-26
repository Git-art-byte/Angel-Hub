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

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local combatRemote = game:GetService("ReplicatedStorage").Assets.CombatAssets.CombatRemotes.ActivateCombat

local AutoFarmEnabled = false
local WholeFolderEnabled = false
local SafeModeEnabled = false          -- New safe toggle
local FolderPath = ""
local SelectedMob = nil
local currentTarget = nil

local BACK_OFFSET = CFrame.new(0, 0, -5)
local TELEPORT_DELAY_NORMAL = 0.1
local TELEPORT_DELAY_SAFE = 0.4        -- Slower in safe mode to look more legit

local function getFolder(path)
    if path == "" then return nil end
    local parts = string.split(path, ".")
    local current = workspace
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then 
            Fluent:Notify({Title="Error", Content="Folder not found: " .. path, Duration=5})
            return nil 
        end
    end
    return current
end

-- Main autofarm loop
task.spawn(function()
    while true do
        if AutoFarmEnabled then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5) continue end

            local folder = getFolder(FolderPath)
            if not folder then task.wait(1) continue end

            -- Reset target if dead/gone
            if currentTarget and (not currentTarget.Parent or 
                (currentTarget:FindFirstChildOfClass("Humanoid") and currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0)) then
                currentTarget = nil
            end

            -- Pick new target
            if not currentTarget then
                local candidates = {}
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") then
                        local mhrp = mob:FindFirstChild("HumanoidRootPart")
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if mhrp and hum and hum.Health > 0 then
                            local dist = (mhrp.Position - hrp.Position).Magnitude
                            table.insert(candidates, {model = mob, hrp = mhrp, dist = dist})
                        end
                    end
                end

                if WholeFolderEnabled then
                    table.sort(candidates, function(a,b) return a.dist < b.dist end)
                    if #candidates > 0 then
                        currentTarget = candidates[1].model
                    end
                else
                    if SelectedMob then
                        for _, cand in ipairs(candidates) do
                            if cand.model.Name == SelectedMob then
                                currentTarget = cand.model
                                break
                            end
                        end
                    end
                end
            end

            -- Teleport and attack
            if currentTarget then
                local bossHRP = currentTarget:FindFirstChild("HumanoidRootPart")
                local bossHum = currentTarget:FindFirstChildOfClass("Humanoid")
                if bossHRP and bossHum and bossHum.Health > 0 then
                    hrp.CFrame = bossHRP.CFrame * BACK_OFFSET
                    combatRemote:FireServer()
                end
            end
        end
        
        -- Dynamic delay based on safe mode
        local currentDelay = SafeModeEnabled and TELEPORT_DELAY_SAFE or TELEPORT_DELAY_NORMAL
        task.wait(currentDelay)
    end
end)

-- UI
local Section1 = Tabs.Main:AddSection("AutoFarm")

local Input = Tabs.Main:AddInput("Input", {
    Title = "Input Folder",
    Description = "e.g. workspace.TOPBosses or workspace.Mobs.Bosses",
    Default = "",
    Placeholder = "workspace.Bosses",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        FolderPath = Value
    end
})

local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Select Mob",
    Description = "For single mode (refresh to update)",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(val)
        SelectedMob = val
        currentTarget = nil
    end
})

Tabs.Main:AddButton({
    Title = "Refresh Mob List (600 studs)",
    Description = "Scans nearby mobs in folder",
    Callback = function()
        local mobs = {}
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
            else
                Fluent:Notify({Title="Error", Content="Enter valid folder first!", Duration=4})
                return
            end
        end
        Dropdown:SetValues(mobs)
        if #mobs > 0 then 
            Dropdown:SetValue(mobs[1])
            SelectedMob = mobs[1]
        end
        Fluent:Notify({Title="Refreshed", Content=#mobs .. " mobs found", Duration=3})
    end
})

local Toggle1 = Tabs.Main:AddToggle("MyToggle1", {
    Title = "Start AutoFarm",
    Description = "Instant tp behind + spam attack",
    Default = false,
    Callback = function(state)
        AutoFarmEnabled = state
        if not state then currentTarget = nil end
    end
})

local Section2 = Tabs.Main:AddSection("Settings")

local ToggleWhole = Tabs.Main:AddToggle("MyToggle2", {
    Title = "Whole Folder Mode",
    Description = "Auto-kill closest → next (ignores dropdown)",
    Default = false,
    Callback = function(state)
        WholeFolderEnabled = state
        currentTarget = nil
    end
})

-- New Safe Mode Toggle
local ToggleSafe = Tabs.Settings:AddToggle("ToggleSafe", {
    Title = "Safe Mode",
    Description = "Slower teleport delay (less detectable)",
    Default = false,
    Callback = function(state)
        SafeModeEnabled = state
    end
})
