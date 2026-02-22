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
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage.Assets.CombatAssets.CombatRemotes.ActivateCombat

-- ================= SETTINGS =================
local TELEPORT_DELAY = 0.05
local BACK_OFFSET = 3

local AutoFarmEnabled = false
local SelectedBossName = nil

local AutoKiEnabled = false
local AutoDBEnabled = false
local AutoWhisEnabled = false
local AutoUIEnabled = false -- New toggle
-- ============================================

-- Get boss list
local function getBossList()
    local list = {}
    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return list end

    for _, boss in ipairs(bossesFolder:GetChildren()) do
        if boss:IsA("Model") then
            table.insert(list, boss.Name)
        end
    end

    return list
end

-- ================= UI =================

Tabs.Main:AddDropdown("BossSelectorDropdown", {
    Title = "Select Boss",
    Values = getBossList(),
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedBossName = value
    end
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm Boss",
    Default = false,
    Callback = function(state)
        AutoFarmEnabled = state
    end
})

Tabs.Main:AddToggle("AutoFarmWhisToggle", {
    Title = "AutoFarm Beerus",
    Default = false,
    Callback = function(state)
        AutoWhisEnabled = state
        AutoFarmEnabled = state
        if state then
            SelectedBossName = "Beerus"
        end
    end
})

Tabs.Main:AddToggle("AutoFarmGameModeToggle", {
    Title = "Auto Farm Gamemode",
    Default = false,
    Callback = function(state)
        print("hi")
    end
})

Tabs.Misc:AddToggle("AutoKiToggle", {
    Title = "AutoCharge KI",
    Default = false,
    Callback = function(state)
        AutoKiEnabled = state
    end
})

Tabs.Misc:AddToggle("AutoDBToggle", {
    Title = "Auto Dragon Balls",
    Default = false,
    Callback = function(state)
        AutoDBEnabled = state
    end
})

Tabs.Misc:AddToggle("AutoUIToggle", {
    Title = "Auto UI",
    Default = false,
    Callback = function(state)
        AutoUIEnabled = state
    end
})

-- ================= LOGIC =================

local function getBoss()
    if not SelectedBossName then return end

    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return end

    local boss = bossesFolder:FindFirstChild(SelectedBossName)
    if not boss then return end

    local hrp = boss:FindFirstChild("HumanoidRootPart")
    local humanoid = boss:FindFirstChildOfClass("Humanoid")

    return boss, hrp, humanoid
end

-- Boss autofarm loop
task.spawn(function()
    while true do
        if AutoFarmEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")

            local boss, bossHrp, bossHumanoid = getBoss()

            if playerHrp and bossHrp and bossHumanoid and bossHumanoid.Health > 0 then
                playerHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                combatRemote:FireServer()
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end)

-- Auto Whis quest loop (every 5 seconds)
task.spawn(function()
    while true do
        if AutoWhisEnabled then
            ReplicatedStorage.Remotes.giveQuests:FireServer("Whis")
        end
        task.wait(5)
    end
end)

-- Auto Dragon Balls loop
task.spawn(function()
    local TOUCH_DELAY = 0.2

    local dragonBallFolders = {
        workspace:WaitForChild("DragonBalls"):WaitForChild("PorungaBalls"),
        workspace:WaitForChild("DragonBalls"):WaitForChild("ShenronBalls")
    }

    local function fireTouch(touchInterest)
        if touchInterest then
            firetouchinterest(player.Character.HumanoidRootPart, touchInterest.Parent, 0)
            task.wait()
            firetouchinterest(player.Character.HumanoidRootPart, touchInterest.Parent, 1)
        end
    end

    while true do
        if AutoDBEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            for _, folder in ipairs(dragonBallFolders) do
                for i = 1, 7 do
                    if not AutoDBEnabled then break end

                    local ball = folder:FindFirstChild(tostring(i))
                    if ball then
                        local corpo = ball:FindFirstChild("corpo")
                        local touchInterest = corpo and corpo:FindFirstChild("TouchInterest")
                        if touchInterest then
                            fireTouch(touchInterest)
                            task.wait(TOUCH_DELAY)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Auto KI loop
task.spawn(function()
    while true do
        if AutoKiEnabled then
            ReplicatedStorage.IncreaseEnergyEvent:FireServer(
                workspace.stalou0406.IAKiCharge.IsCharging,
                false
            )
        else
            ReplicatedStorage.IncreaseEnergyEvent:FireServer(
                workspace.stalou0406.IAKiCharge.IsCharging,
                true
            )
        end
        task.wait(0.3)
    end
end)

-- Auto UI loop
task.spawn(function()
    local TP_DELAY = 0.1
    while true do
        if AutoUIEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local npc = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("MerusCH")
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                -- Teleport to NPC
                player.Character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                -- Attack NPC
                combatRemote:FireServer()
            end
        end
        task.wait(TP_DELAY)
    end
end)
