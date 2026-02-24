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
    Zeni = Window:AddTab({ Title = "Zeni", Icon = "dollar-sign" }),
    Gamemode = Window:AddTab({ Title = "Waves/Gamemode", Icon = "waves" }),
    Troll = Window:AddTab({ Title = "Troll/PVP", Icon = "swords" }),
    DragonBall = Window:AddTab({ Title = "DragonBall", Icon = "" }),
    MUI = Window:AddTab({ Title = "Ultra Instinct", Icon = "" }),
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
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage.Assets.CombatAssets.CombatRemotes.ActivateCombat

-- ================= SETTINGS =================
local TELEPORT_DELAY = 0.05
local BACK_OFFSET = 3
local SCAN_DELAY = 2 -- Delay between scanning for new targets

local AutoFarmEnabled = false
local SelectedBossName = nil

local AutoWhisEnabled = false
local AutoUIEnabled = false
local AutoFarmGamemodeEnabled = false
local AutoLowLevelEnabled = false
-- ============================================

-- Get nearby bosses (within 500 studs)
local function getNearbyBosses()
    local list = {}
    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return list end
    
    local character = player.Character
    local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
    if not playerHrp then return list end

    for _, boss in ipairs(bossesFolder:GetChildren()) do
        if boss:IsA("Model") then
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (playerHrp.Position - hrp.Position).Magnitude
                -- Only show bosses within 500 studs
                if distance <= 500 then
                    table.insert(list, boss.Name)
                end
            end
        end
    end

    return list
end

-- Update dropdown values periodically
local function updateBossDropdown()
    while true do
        if Fluent and Fluent:GetDropdown("BossSelectorDropdown") then
            local nearbyBosses = getNearbyBosses()
            Fluent:GetDropdown("BossSelectorDropdown"):SetValues(nearbyBosses)
        end
        task.wait(5) -- Update every 5 seconds
    end
end

-- Get all valid targets in workspace (models with HumanoidRootPart)
local function getWorkspaceTargets()
    local targets = {}
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        -- Check if it's a model with HumanoidRootPart and has health
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            
            if hrp and humanoid and humanoid.Health > 0 then
                -- Make sure it's not the player
                if obj ~= player.Character then
                    table.insert(targets, {
                        model = obj,
                        hrp = hrp,
                        humanoid = humanoid
                    })
                end
            end
        end
    end
    
    return targets
end

-- Dragon Ball collection function
local function collectDragonBalls()
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

    -- Collect balls once
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, folder in ipairs(dragonBallFolders) do
            for i = 1, 7 do
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
        Fluent:Notify({
            Title = "Dragon Balls",
            Content = "Finished collecting Dragon Balls!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Error",
            Content = "Character not found!",
            Duration = 3
        })
    end
end

-- ================= UI =================
local Section1 = Tabs.Main:AddSection("Boss Farming")

Tabs.Main:AddDropdown("BossSelectorDropdown", {
    Title = "Select Boss",
    Values = getNearbyBosses(), -- Show nearby bosses initially
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedBossName = value
    end
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm Boss",
    Default = false,
    Callback = function(state)
        AutoFarmEnabled = state
        if state then
            AutoFarmGamemodeEnabled = false
            AutoWhisEnabled = false
            AutoLowLevelEnabled = false
        end
    end
})

local Section2 = Tabs.Zeni:AddSection("High Level")

Tabs.Zeni:AddToggle("AutoFarmWhisToggle", {
    Title = "AutoFarm Money",
    Default = false,
    Callback = function(state)
        AutoWhisEnabled = state
        if state then
            AutoFarmEnabled = state
            AutoFarmGamemodeEnabled = false
            AutoLowLevelEnabled = false
            SelectedBossName = "Beerus"
        end
    end
})

local Section2_5 = Tabs.Main:AddSection("Low Level")

Tabs.Main:AddToggle("AutoFarmBlackGoku", {
    Title = "AutoFarm Money",
    Default = false,
    Callback = function(state)
        AutoLowLevelEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoFarmGamemodeEnabled = false
            SelectedBossName = "GokuBlack"
        end
    end
})

local Section3 = Tabs.Gamemode:AddSection("Gamemode")

Tabs.Gamemode:AddToggle("AutoFarmGameModeToggle", {
    Title = "Auto Farm Gamemode",
    Default = false,
    Callback = function(state)
        AutoFarmGamemodeEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoLowLevelEnabled = false
        end
    end
})

local Section4 = Tabs.DragonBall:AddSection("Dragon Balls")

Tabs.DragonBall:AddButton({
    Title = "Collect Dragon Balls",
    Callback = collectDragonBalls
})

local Section5 = Tabs.MUI:AddSection("UI")

Tabs.MUI:AddToggle("AutoUIToggle", {
    Title = "Auto MUI Chamber",
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
        if AutoFarmEnabled or AutoLowLevelEnabled then
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

-- Auto Farm Gamemode loop
task.spawn(function()
    local currentTarget = nil
    local lastScanTime = 0
    
    while true do
        if AutoFarmGamemodeEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if playerHrp then
                -- Scan for new targets every SCAN_DELAY seconds
                if tick() - lastScanTime > SCAN_DELAY then
                    local targets = getWorkspaceTargets()
                    
                    -- Find the closest target
                    local closestDistance = math.huge
                    local closestTarget = nil
                    
                    for _, target in ipairs(targets) do
                        if target.hrp and target.humanoid and target.humanoid.Health > 0 then
                            local distance = (playerHrp.Position - target.hrp.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestTarget = target
                            end
                        end
                    end
                    
                    currentTarget = closestTarget
                    lastScanTime = tick()
                end
                
                -- Attack current target if valid
                if currentTarget and currentTarget.hrp and currentTarget.humanoid and currentTarget.humanoid.Health > 0 then
                    playerHrp.CFrame = currentTarget.hrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                    combatRemote:FireServer()
                else
                    -- Target is dead or invalid, force a rescan
                    lastScanTime = 0
                end
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

-- Start updating the boss dropdown
task.spawn(updateBossDropdown)
