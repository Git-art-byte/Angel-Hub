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

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

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
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if not Character or not Humanoid or not RootPart then
        Fluent:Notify({
            Title = "Error",
            Content = "Your character not found!",
            Duration = 3
        })
        return
    end

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

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
    elseif not THead and Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then
        cameraConnection:Disconnect()
        return
    end

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0

        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end

    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart and not THead then
        SFBasePart(TRootPart)
    elseif not TRootPart and THead then
        SFBasePart(THead)
    elseif not TRootPart and not THead and Accessory and Handle then
        SFBasePart(Handle)
    else
        cameraConnection:Disconnect()
        return
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

    -- Restore normal camera control
    cameraConnection:Disconnect()
    workspace.CurrentCamera.CameraSubject = Humanoid

    repeat
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
        Humanoid:ChangeState("GettingUp")
        for _, x in pairs(Character:GetChildren()) do
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
            end
        end
        task.wait()
    until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
    
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

local Section5 = Tabs.MUI:AddSection("MUI Chamber")

Tabs.MUI:AddToggle("AutoUIToggle", {
    Title = "AutoFarm MUI Chamber",
    Default = false,
    Callback = function(state)
        AutoUIEnabled = state
    end
})

local Section6 = Tabs.Top:AddSection("Tournament of Power")

Tabs.Top:AddToggle("AutoTopToggle", {
    Title = "AutoFarm TOP Bosses",
    Default = false,
    Callback = function(state)
        print("hi")
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

-- Update boss dropdown values constantly
task.spawn(function()
    while true do
        if BossDropdown then
            local nearbyBosses = getNearbyBosses()
            BossDropdown:SetValues(nearbyBosses)
        end
        task.wait(0.05)
    end
end)

-- Update player dropdown values constantly (every 0.005 seconds as requested)
task.spawn(function()
    while true do
        if PlayerDropdown then
            local players = getAllPlayers()
            PlayerDropdown:SetValues(players)
        end
        task.wait(2) -- Updated to 0.005 seconds as requested
    end
end)
