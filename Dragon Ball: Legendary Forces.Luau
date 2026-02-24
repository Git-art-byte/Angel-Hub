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
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage.Assets.CombatAssets.CombatRemotes.ActivateCombat

-- ================= SETTINGS =================
local TELEPORT_DELAY = 0.05
local BACK_OFFSET = 3
local SCAN_DELAY = 2 -- Delay between scanning for new targets

local AutoFarmEnabled = false
local SelectedBossName = nil

local AutoKiEnabled = false
local AutoDBEnabled = false
local AutoWhisEnabled = false
local AutoUIEnabled = false
local AutoFarmGamemodeEnabled = false
local AutoSaibamanEnabled = false

-- Saibaman specific variables
local RADITZ_KILLS_NEEDED = 8
local NAPPA_KILLS_NEEDED = 10
local raditzKills = 0
local nappaKills = 0
local questActive = false
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

-- Get Saibaman targets (Raditz and Nappa)
local function getSaibamanTargets()
    local targets = {}
    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return targets end
    
    -- Find Raditz
    local raditz = bossesFolder:FindFirstChild("Raditz")
    if raditz then
        local hrp = raditz:FindFirstChild("HumanoidRootPart")
        local humanoid = raditz:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then
            table.insert(targets, {
                model = raditz,
                hrp = hrp,
                humanoid = humanoid,
                name = "Raditz"
            })
        end
    end
    
    -- Find Nappa
    local nappa = bossesFolder:FindFirstChild("Nappa")
    if nappa then
        local hrp = nappa:FindFirstChild("HumanoidRootPart")
        local humanoid = nappa:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then
            table.insert(targets, {
                model = nappa,
                hrp = hrp,
                humanoid = humanoid,
                name = "Nappa"
            })
        end
    end
    
    return targets
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
        if state then
            AutoFarmGamemodeEnabled = false
            AutoWhisEnabled = false
            AutoSaibamanEnabled = false
        end
    end
})

Tabs.Main:AddToggle("AutoFarmWhisToggle", {
    Title = "AutoFarm Beerus",
    Default = false,
    Callback = function(state)
        AutoWhisEnabled = state
        if state then
            AutoFarmEnabled = state
            AutoFarmGamemodeEnabled = false
            AutoSaibamanEnabled = false
            SelectedBossName = "Beerus"
        end
    end
})

Tabs.Main:AddToggle("AutoFarmGameModeToggle", {
    Title = "Auto Farm Gamemode",
    Default = false,
    Callback = function(state)
        AutoFarmGamemodeEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoSaibamanEnabled = false
        end
    end
})

-- Saibaman Toggle with Progress (using a Paragraph that we'll update by recreating it)
local SaibamanProgress = Tabs.Main:AddParagraph({
    Title = "Saibaman Progress",
    Content = "Raditz: 0/8 | Nappa: 0/10 | Quest: Inactive"
})

-- Function to update progress
local function updateSaibamanProgress()
    local questStatus = questActive and "Active" or "Inactive"
    SaibamanProgress.Content = ("Raditz: %d/%d | Nappa: %d/%d | Quest: %s"):format(
        raditzKills, RADITZ_KILLS_NEEDED,
        nappaKills, NAPPA_KILLS_NEEDED,
        questStatus
    )
end

Tabs.Main:AddToggle("AutoSaibamanToggle", {
    Title = "Auto Saibaman",
    Default = false,
    Callback = function(state)
        AutoSaibamanEnabled = state
        if state then
            -- Disable other farm modes
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoFarmGamemodeEnabled = false
            -- Reset counters
            raditzKills = 0
            nappaKills = 0
            questActive = false
            updateSaibamanProgress()
            
            -- Start quest immediately
            ReplicatedStorage.Remotes.giveQuests:FireServer("SaibamanQuest")
            questActive = true
            updateSaibamanProgress()
        end
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

-- Auto Saibaman loop
task.spawn(function()
    local currentTarget = nil
    local lastQuestTime = 0
    local QUEST_COOLDOWN = 3 -- Cooldown between quest requests
    local lastHealth = {}
    
    while true do
        if AutoSaibamanEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if playerHrp then
                -- Get current targets
                local targets = getSaibamanTargets()
                
                -- Check if we need to restart quest (all kills done)
                if (raditzKills >= RADITZ_KILLS_NEEDED and nappaKills >= NAPPA_KILLS_NEEDED) then
                    if tick() - lastQuestTime > QUEST_COOLDOWN then
                        -- Fire the quest remote to restart
                        ReplicatedStorage.Remotes.giveQuests:FireServer("SaibamanQuest")
                        lastQuestTime = tick()
                        
                        -- Reset kill counters
                        raditzKills = 0
                        nappaKills = 0
                        questActive = true
                        updateSaibamanProgress()
                        
                        -- Wait a bit after starting new quest
                        task.wait(2)
                    end
                end
                
                -- Monitor health to detect kills
                for _, target in ipairs(targets) do
                    local healthKey = target.name .. "_health"
                    
                    if not lastHealth[healthKey] then
                        lastHealth[healthKey] = target.humanoid.Health
                    end
                    
                    -- Check if health dropped to 0 (boss died)
                    if lastHealth[healthKey] > 0 and target.humanoid.Health <= 0 then
                        if target.name == "Raditz" and raditzKills < RADITZ_KILLS_NEEDED then
                            raditzKills = raditzKills + 1
                            print("Killed Raditz: " .. raditzKills .. "/" .. RADITZ_KILLS_NEEDED)
                            updateSaibamanProgress()
                        elseif target.name == "Nappa" and nappaKills < NAPPA_KILLS_NEEDED then
                            nappaKills = nappaKills + 1
                            print("Killed Nappa: " .. nappaKills .. "/" .. NAPPA_KILLS_NEEDED)
                            updateSaibamanProgress()
                        end
                        
                        -- Wait for boss to respawn
                        task.wait(2)
                    end
                    
                    lastHealth[healthKey] = target.humanoid.Health
                end
                
                -- Determine which boss to attack
                if raditzKills < RADITZ_KILLS_NEEDED then
                    -- Find Raditz
                    currentTarget = nil
                    for _, target in ipairs(targets) do
                        if target.name == "Raditz" then
                            currentTarget = target
                            break
                        end
                    end
                elseif nappaKills < NAPPA_KILLS_NEEDED then
                    -- Find Nappa
                    currentTarget = nil
                    for _, target in ipairs(targets) do
                        if target.name == "Nappa" then
                            currentTarget = target
                            break
                        end
                    end
                end
                
                -- Attack current target
                if currentTarget and currentTarget.hrp and currentTarget.humanoid and currentTarget.humanoid.Health > 0 then
                    -- Teleport behind the boss
                    playerHrp.CFrame = currentTarget.hrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                    
                    -- Fire combat remote
                    combatRemote:FireServer()
                end
            end
        end
        task.wait(TELEPORT_DELAY)
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
