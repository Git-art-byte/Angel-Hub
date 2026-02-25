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
local SCAN_DELAY = 2

local AutoFarmEnabled = false
local AutoWhisEnabled = false
local AutoUIEnabled = false
local AutoFarmGamemodeEnabled = false
local AutoLowLevelEnabled = false
local AutoTopEnabled = false          -- ← NEW

local SelectedBossName = nil
local SelectedPlayer = nil

-- Dropdown references
local BossDropdown = nil
local PlayerDropdown = nil

-- ============================================

local function getAllPlayers()
    local playerList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(playerList, plr.Name)
        end
    end
    return playerList
end

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
                if distance <= 500 then
                    table.insert(list, boss.Name)
                end
            end
        end
    end

    return list
end

local function getWorkspaceTargets()
    local targets = {}
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            
            if hrp and humanoid and humanoid.Health > 0 then
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
        Fluent:Notify({Title = "Error", Content = "Player not found or invalid!", Duration = 3})
        return 
    end

    local Character = player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not Character or not Humanoid or not RootPart then
        Fluent:Notify({Title = "Error", Content = "Your character not found!", Duration = 3})
        return
    end

    if THumanoid and THumanoid.Sit then
        Fluent:Notify({Title = "Error", Content = "Target is sitting!", Duration = 3})
        return
    end

    local freezeCameraCFrame = Camera.CFrame
    local cameraConnection = RunService.RenderStepped:Connect(function()
        Camera.CFrame = freezeCameraCFrame
    end)

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
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
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
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
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        cameraConnection:Disconnect()
        return
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
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

-- ================= UI =================

-- Main Tab - Boss Farming
Tabs.Main:AddSection("Boss Farming")

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
            AutoTopEnabled = false
        end
    end
})

-- Zeni Tab
Tabs.Zeni:AddSection("High Level")

Tabs.Zeni:AddToggle("AutoFarmWhisToggle", {
    Title = "AutoFarm Money (Whis)",
    Default = false,
    Callback = function(state)
        AutoWhisEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoFarmGamemodeEnabled = false
            AutoLowLevelEnabled = false
            AutoTopEnabled = false
            SelectedBossName = "Beerus"
        end
    end
})

Tabs.Zeni:AddSection("Low Level")

Tabs.Zeni:AddToggle("AutoFarmBlackGoku", {
    Title = "AutoFarm Money (Goku Black)",
    Default = false,
    Callback = function(state)
        AutoLowLevelEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoFarmGamemodeEnabled = false
            AutoTopEnabled = false
            SelectedBossName = "GokuBlack"
        end
    end
})

-- Gamemode Tab
Tabs.Gamemode:AddSection("Waves")

Tabs.Gamemode:AddToggle("AutoFarmGameModeToggle", {
    Title = "AutoFarm Waves",
    Default = false,
    Callback = function(state)
        AutoFarmGamemodeEnabled = state
        if state then
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoLowLevelEnabled = false
            AutoTopEnabled = false
        end
    end
})

-- Troll Tab
Tabs.Troll:AddSection("Troll")

PlayerDropdown = Tabs.Troll:AddDropdown("PlayerDropdown", {
    Title = "Select Player to Fling",
    Values = getAllPlayers(),
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedPlayer = value
    end
})

Tabs.Troll:AddButton({
    Title = "Fling",
    Callback = function()
        if SelectedPlayer then
            SkidFling(SelectedPlayer)
        else
            Fluent:Notify({Title = "Error", Content = "Please select a player first!", Duration = 3})
        end
    end
})

-- Dragon Ball Tab
Tabs.DragonBall:AddSection("Dragon Balls")

Tabs.DragonBall:AddButton({
    Title = "Get Dragon Balls",
    Callback = collectDragonBalls
})

Tabs.DragonBall:AddToogle("LoopDBToogle", {
    Title = "Loop Get DB",
    Default = false,
    Callback = function()
        print("hi")
   end
})
-- MUI Tab
Tabs.MUI:AddSection("MUI Chamber")

Tabs.MUI:AddToggle("AutoUIToggle", {
    Title = "AutoFarm MUI Chamber",
    Default = false,
    Callback = function(state)
        AutoUIEnabled = state
        if state then
            AutoTopEnabled = false
        end
    end
})

-- TOP Tab (Tournament of Power)
Tabs.Top:AddSection("Tournament of Power")

Tabs.Top:AddToggle("AutoTopToggle", {
    Title = "AutoFarm TOP Bosses",
    Default = false,
    Callback = function(state)
        AutoTopEnabled = state
        
        if state then
            -- Disable conflicting farms
            AutoFarmEnabled = false
            AutoWhisEnabled = false
            AutoLowLevelEnabled = false
            AutoFarmGamemodeEnabled = false
            AutoUIEnabled = false
            
            Fluent:Notify({
                Title = "TOP Autofarm",
                Content = "Started farming all TOP bosses",
                Duration = 4
            })
        else
            Fluent:Notify({
                Title = "TOP Autofarm",
                Content = "Stopped",
                Duration = 3
            })
        end
    end
})

-- ==================== MAIN LOOPS ====================

-- Boss autofarm
task.spawn(function()
    while true do
        if AutoFarmEnabled or AutoLowLevelEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
            local boss, bossHrp, bossHumanoid = nil, nil, nil
            
            local bossesFolder = workspace:FindFirstChild("Bosses")
            if bossesFolder and SelectedBossName then
                local bossModel = bossesFolder:FindFirstChild(SelectedBossName)
                if bossModel then
                    bossHrp = bossModel:FindFirstChild("HumanoidRootPart")
                    bossHumanoid = bossModel:FindFirstChildOfClass("Humanoid")
                end
            end

            if playerHrp and bossHrp and bossHumanoid and bossHumanoid.Health > 0 then
                playerHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                combatRemote:FireServer()
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end)

-- Gamemode / Waves autofarm
task.spawn(function()
    local currentTarget = nil
    local lastScanTime = 0
    
    while true do
        if AutoFarmGamemodeEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if playerHrp then
                if tick() - lastScanTime > SCAN_DELAY then
                    local targets = getWorkspaceTargets()
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
                    lastScanTime = tick()
                end
                
                if currentTarget and currentTarget.hrp and currentTarget.humanoid and currentTarget.humanoid.Health > 0 then
                    playerHrp.CFrame = currentTarget.hrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
                    combatRemote:FireServer()
                else
                    lastScanTime = 0
                end
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end)

-- Whis quest spam
task.spawn(function()
    while true do
        if AutoWhisEnabled then
            ReplicatedStorage.Remotes.giveQuests:FireServer("Whis")
        end
        task.wait(5)
    end
end)

-- MUI Chamber farm
task.spawn(function()
    local TP_DELAY = 0.1
    while true do
        if AutoUIEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local npc = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("MerusCH")
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                combatRemote:FireServer()
            end
        end
        task.wait(TP_DELAY)
    end
end)

-- TOP Bosses autofarm (NEW)
task.spawn(function()
    local TOP_DELAY = 0.07
    local BACK_OFFSET_TOP = 4
    
    while true do
        if AutoTopEnabled then
            local character = player.Character
            local playerHrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if not playerHrp then
                task.wait(0.5)
                continue
            end
            
            local topFolder = workspace:FindFirstChild("TOPBosses")
            if not topFolder then
                task.wait(1)
                continue
            end
            
            local targetHrp = nil
            local targetHumanoid = nil
            local bestDist = math.huge
            
            -- Find closest living boss
            for _, boss in ipairs(topFolder:GetChildren()) do
                if boss:IsA("Model") then
                    local hrp = boss:FindFirstChild("HumanoidRootPart")
                    local hum = boss:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (playerHrp.Position - hrp.Position).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            targetHrp = hrp
                            targetHumanoid = hum
                        end
                    end
                end
            end
            
            if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                playerHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET_TOP)
                combatRemote:FireServer()
            end
        end
        
        task.wait(TOP_DELAY)
    end
end)

-- Update boss dropdown
task.spawn(function()
    while true do
        if BossDropdown then
            BossDropdown:SetValues(getNearbyBosses())
        end
        task.wait(0.5)
    end
end)

-- Update player dropdown
task.spawn(function()
    while true do
        if PlayerDropdown then
            PlayerDropdown:SetValues(getAllPlayers())
        end
        task.wait(2)
    end
end)

print("Angel Hub | Dragon Ball: Legendary Forces - Loaded with TOP autofarm")
