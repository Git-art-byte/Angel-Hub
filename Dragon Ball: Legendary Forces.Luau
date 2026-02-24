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
    Gamemode = Window:AddTab({ Title = "Gamemode", Icon = "waves" }),
    Troll = Window:AddTab({ Title = "Troll/PVP", Icon = "swords" }),
    TOP = Window:AddTab({ Title = "TOP", Icon = "hand-fist" }),
    DragonBall = Window:AddTab({ Title = "DragonBall", Icon = "circle-star" }),
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
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage.Assets.CombatAssets.CombatRemotes.ActivateCombat

-- ================= SETTINGS =================
local TELEPORT_DELAY = 0.1 -- Increased to reduce lag
local BACK_OFFSET = 3
local SCAN_DELAY = 3 -- Increased to reduce lag

local AutoFarmEnabled = false
local SelectedBossName = nil

local AutoWhisEnabled = false
local AutoUIEnabled = false
local AutoFarmGamemodeEnabled = false
local AutoLowLevelEnabled = false

-- Variable to store dropdown references
local BossDropdown = nil
local PlayerDropdown = nil
local SelectedPlayer = nil
-- ============================================

-- Get all players in the server (updates constantly)
local function getAllPlayers()
    local playerList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(playerList, plr.Name)
        end
    end
    return playerList
end

-- Get nearby bosses (within 500 studs) - OPTIMIZED
local function getNearbyBosses()
    local list = {}
    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return list end
    
    -- Don't run if character doesn't exist
    local character = player.Character
    if not character then return list end
    
    local playerHrp = character:FindFirstChild("HumanoidRootPart")
    if not playerHrp then return list end

    for _, boss in ipairs(bossesFolder:GetChildren()) do
        if boss:IsA("Model") then
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Quick distance check
                local distance = (playerHrp.Position - hrp.Position).Magnitude
                if distance <= 500 then
                    table.insert(list, boss.Name)
                end
            end
        end
    end

    return list
end

-- Get all valid targets in workspace (models with HumanoidRootPart) - OPTIMIZED
local function getWorkspaceTargets()
    local targets = {}
    local character = player.Character
    if not character then return targets end
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        -- Only check every 5th object to reduce lag (spread out scanning)
        if obj:IsA("Model") and obj ~= character then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
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

    -- Safely get folders
    local dragonBallsFolder = workspace:FindFirstChild("DragonBalls")
    if not dragonBallsFolder then 
        Fluent:Notify({
            Title = "Error",
            Content = "Dragon Balls folder not found!",
            Duration = 3
        })
        return
    end
    
    local dragonBallFolders = {
        dragonBallsFolder:FindFirstChild("PorungaBalls"),
        dragonBallsFolder:FindFirstChild("ShenronBalls")
    }

    local function fireTouch(touchInterest)
        if touchInterest and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            firetouchinterest(player.Character.HumanoidRootPart, touchInterest.Parent, 0)
            task.wait()
            firetouchinterest(player.Character.HumanoidRootPart, touchInterest.Parent, 1)
        end
    end

    -- Collect balls once
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, folder in ipairs(dragonBallFolders) do
            if folder then
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

-- ================= FLING SYSTEM =================
local SkidFling = function(TargetPlayer)
    if typeof(TargetPlayer) == "string" then
        TargetPlayer = Players:FindFirstChild(TargetPlayer)
    end
    
    if not TargetPlayer or not TargetPlayer.Character then 
        Fluent:Notify({
            Title = "Error",
            Content = "Player not found or invalid!",
            Duration = 3
        })
        return 
    end

    local Character = player.Character
    if not Character then 
        Fluent:Notify({
            Title = "Error",
            Content = "Your character not found!",
            Duration = 3
        })
        return
    end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    
    if not Humanoid or not RootPart then
        Fluent:Notify({
            Title = "Error",
            Content = "Your character not found!",
            Duration = 3
        })
        return
    end

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    
    if THumanoid and THumanoid.Sit then
        Fluent:Notify({
            Title = "Error",
            Content = "Target is sitting!",
            Duration = 3
        })
        return
    end

    -- Freeze camera from current position
    local freezeCameraCFrame = Camera.CFrame
    local cameraConnection
    cameraConnection = RunService.RenderStepped:Connect(function()
        Camera.CFrame = freezeCameraCFrame
    end)

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    -- Simple fling (shortened version to reduce lag)
    for i = 1, 10 do
        if TRootPart then
            RootPart.CFrame = TRootPart.CFrame * CFrame.new(0, 1, 0)
            task.wait()
            RootPart.CFrame = TRootPart.CFrame * CFrame.new(0, -1, 0)
            task.wait()
        end
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

    -- Restore normal camera control
    cameraConnection:Disconnect()
    workspace.CurrentCamera.CameraSubject = Humanoid

    -- Return to original position
    if getgenv().OldPos then
        RootPart.CFrame = getgenv().OldPos
    end
    
    Fluent:Notify({
        Title = "Fling Complete",
        Content = "Successfully flung " .. TargetPlayer.Name,
        Duration = 3
    })
end
-- ================================================

-- ================= UI =================
local Section1 = Tabs.Main:AddSection("Boss Farming")

-- Create dropdown and store reference
BossDropdown = Tabs.Main:AddDropdown("BossSelectorDropdown", {
    Title = "Select Boss",
    Values = getNearbyBosses(),
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
            AutoFarmEnabled = false
            AutoFarmGamemodeEnabled = false
            AutoLowLevelEnabled = false
            SelectedBossName = "Beerus"
        end
    end
})

local Section2_5 = Tabs.Zeni:AddSection("Low Level")

Tabs.Zeni:AddToggle("AutoFarmBlackGoku", {
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

local Section3 = Tabs.Gamemode:AddSection("Waves")

Tabs.Gamemode:AddToggle("AutoFarmGameModeToggle", {
    Title = "AutoFarm Waves",
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

local Section3_5 = Tabs.Troll:AddSection("Troll")

-- Player dropdown that updates constantly
PlayerDropdown = Tabs.Troll:AddDropdown("PlayerDropdown", {
    Title = "Select Player to Fling",
    Values = getAllPlayers(),
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedPlayer = value
    end
})

-- Fling button
Tabs.Troll:AddButton({
    Title = "Fling",
    Callback = function()
        if SelectedPlayer then
            SkidFling(SelectedPlayer)
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Please select a player first!",
                Duration = 3
            })
        end
    end
})

local Section4 = Tabs.DragonBall:AddSection("Dragon Balls")

Tabs.DragonBall:AddButton({
    Title = "Get Dragon Balls",
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
    if not SelectedBossName then return nil end

    local bossesFolder = workspace:FindFirstChild("Bosses")
    if not bossesFolder then return nil end

    local boss = bossesFolder:FindFirstChild(SelectedBossName)
    if not boss then return nil end

    local hrp = boss:FindFirstChild("HumanoidRootPart")
    local humanoid = boss:FindFirstChildOfClass("Humanoid")

    return boss, hrp, humanoid
end

-- OPTIMIZED: Single combined loop for all autofarm features
task.spawn(function()
    local lastBossScan = 0
    local lastGamemodeScan = 0
    local lastWhisTime = 0
    local lastUITime = 0
    local currentTarget = nil
    
    while true do
        local currentTime = tick()
        local character = player.Character
        local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
        
        -- Boss Farming (AutoFarmEnabled or AutoLowLevelEnabled)
        if (AutoFarmEnabled or AutoLowLevelEnabled) and playerHrp then
            local boss, bossHrp, bossHumanoid = getBoss()
            if bossHrp and bossHumanoid and bossHumanoid.Health > 0 then
                playerHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                combatRemote:FireServer()
            end
        end
        
        -- Gamemode Waves Farming
        if AutoFarmGamemodeEnabled and playerHrp then
            -- Scan for targets every SCAN_DELAY seconds
            if currentTime - lastGamemodeScan > SCAN_DELAY then
                local targets = getWorkspaceTargets()
                
                -- Find closest target
                local closestDistance = math.huge
                local closestTarget = nil
                
                for _, target in ipairs(targets) do
                    local distance = (playerHrp.Position - target.hrp.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestTarget = target
                    end
                end
                
                currentTarget = closestTarget
                lastGamemodeScan = currentTime
            end
            
            -- Attack current target
            if currentTarget and currentTarget.hrp and currentTarget.humanoid and currentTarget.humanoid.Health > 0 then
                playerHrp.CFrame = currentTarget.hrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                combatRemote:FireServer()
            end
        end
        
        -- Whis quest (every 5 seconds)
        if AutoWhisEnabled and currentTime - lastWhisTime > 5 then
            pcall(function()
                ReplicatedStorage.Remotes.giveQuests:FireServer("Whis")
            end)
            lastWhisTime = currentTime
        end
        
        -- Auto UI (every 0.5 seconds to reduce lag)
        if AutoUIEnabled and playerHrp and currentTime - lastUITime > 0.5 then
            local npc = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("MerusCH")
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                playerHrp.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                combatRemote:FireServer()
            end
            lastUITime = currentTime
        end
        
        task.wait(TELEPORT_DELAY)
    end
end)

-- Update boss dropdown values (every 1 second instead of 0.05)
task.spawn(function()
    while true do
        if BossDropdown then
            local nearbyBosses = getNearbyBosses()
            pcall(function()
                BossDropdown:SetValues(nearbyBosses)
            end)
        end
        task.wait(1) -- Reduced from 0.05 to 1 second
    end
end)

-- Update player dropdown values (every 1 second instead of 0.05)
task.spawn(function()
    while true do
        if PlayerDropdown then
            local players = getAllPlayers()
            pcall(function()
                PlayerDropdown:SetValues(players)
            end)
        end
        task.wait(1) -- Reduced from 0.05 to 1 second
    end
end)
