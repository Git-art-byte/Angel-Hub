-- ANGEL HUB | Dragon Ball: Legendary Forces  →  Chat Commands Version
-- by Ange (converted to chat commands)

local PREFIX = "."   -- ← Change this to your preferred prefix (e.g. "!", ":", ";", "/")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CombatAssets"):WaitForChild("CombatRemotes"):WaitForChild("ActivateCombat")

-- Settings
local TELEPORT_DELAY = 0.05
local BACK_OFFSET = 3

-- State
local loopkillConnection = nil
local currentLoopBossName = nil

-- ================= FLING SYSTEM (kept almost unchanged) =================
local function SkidFling(TargetPlayer)
    if typeof(TargetPlayer) == "string" then
        TargetPlayer = Players:FindFirstChild(TargetPlayer) or Players:FindFirstChildWhichIsA("Player", function(p)
            return p.DisplayName == TargetPlayer
        end)
    end
    
    if not TargetPlayer or not TargetPlayer.Character then 
        warn("[Angel] Player not found or no character")
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

    if not Character or not Humanoid or not RootPart then return end
    if THumanoid and THumanoid.Sit then warn("[Angel] Target is sitting!") return end

    getgenv().OldPos = getgenv().OldPos or RootPart.CFrame

    local freezeCameraCFrame = workspace.CurrentCamera.CFrame
    local cameraConn = RunService.RenderStepped:Connect(function()
        workspace.CurrentCamera.CFrame = freezeCameraCFrame
    end)

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid then
        workspace.CurrentCamera.CameraSubject = THumanoid
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
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    -- (you can keep more positions if you want stronger fling)
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0,0,0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or not BasePart.Parent or tick() > Time + TimeToWait

    end

    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead and (TRootPart.Position - THead.Position).Magnitude > 5 then
        SFBasePart(THead)
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    cameraConn:Disconnect()
    workspace.CurrentCamera.CameraSubject = Humanoid

    -- Return to old position
    repeat
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
        Humanoid:ChangeState("GettingUp")
        task.wait()
    until (RootPart.Position - getgenv().OldPos.Position).Magnitude < 25

    print("[Angel] Flung → " .. TargetPlayer.Name)
end

-- ================= Dragon Balls =================
local function collectDragonBalls()
    local TOUCH_DELAY = 0.2
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then warn("[Angel] No character!") return end

    local folders = {
        Workspace:WaitForChild("DragonBalls"):WaitForChild("PorungaBalls"),
        Workspace:WaitForChild("DragonBalls"):WaitForChild("ShenronBalls")
    }

    for _, folder in ipairs(folders) do
        for i = 1, 7 do
            local ball = folder:FindFirstChild(tostring(i))
            if ball then
                local corpo = ball:FindFirstChild("corpo")
                local touch = corpo and corpo:FindFirstChild("TouchInterest")
                if touch then
                    firetouchinterest(hrp, touch.Parent, 0)
                    task.wait()
                    firetouchinterest(hrp, touch.Parent, 1)
                    task.wait(TOUCH_DELAY)
                end
            end
        end
    end

    print("[Angel] Dragon Balls collected!")
end

-- ================= Boss Kill / LoopKill =================
local function getBoss(bossName)
    local bosses = Workspace:FindFirstChild("Bosses")
    if not bosses then return nil end
    return bosses:FindFirstChild(bossName)
end

local function killBoss(bossName, shouldLoop)
    local boss = getBoss(bossName)
    if not boss then 
        warn("[Angel] Boss not found: " .. tostring(bossName))
        return 
    end

    local bossHrp = boss:FindFirstChild("HumanoidRootPart")
    local bossHum = boss:FindFirstChildOfClass("Humanoid")
    if not bossHrp or not bossHum or bossHum.Health <= 0 then return end

    local char = player.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    myHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
    combatRemote:FireServer()

    if shouldLoop then
        print("[Angel] Started loopkill → " .. bossName)
    end
end

local function startLoopKill(bossName)
    if loopkillConnection then
        loopkillConnection:Disconnect()
        loopkillConnection = nil
    end

    currentLoopBossName = bossName

    loopkillConnection = RunService.Heartbeat:Connect(function()
        if not currentLoopBossName then return end
        killBoss(currentLoopBossName, false)  -- false = don't print spam
    end)
end

local function stopLoopKill()
    if loopkillConnection then
        loopkillConnection:Disconnect()
        loopkillConnection = nil
    end
    currentLoopBossName = nil
    print("[Angel] Loopkill stopped")
end

-- ================= Chat Listener =================
player.Chatted:Connect(function(msg)
    local lowered = msg:lower():gsub("%s+", " "):match("^%s*(.-)%s*$")  -- trim
    if not lowered:find("^" .. PREFIX) then return end

    local args = {}
    for word in lowered:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]:sub(#PREFIX + 1):lower()

    if cmd == "fling" and args[2] then
        local targetName = table.concat(args, " ", 2)
        SkidFling(targetName)

    elseif cmd == "db" then
        collectDragonBalls()

    elseif cmd == "kill" and args[2] then
        local bossName = table.concat(args, " ", 2)
        killBoss(bossName, false)

    elseif cmd == "loopkill" and args[2] then
        local bossName = table.concat(args, " ", 2)
        startLoopKill(bossName)

    elseif cmd == "unloopkill" or cmd == "unloopkoll" then
        stopLoopKill()

    end
end)

print("[Angel Chat Commands] Loaded | Prefix = " .. PREFIX)
print("Available:  " .. PREFIX .. "fling <name>,  " .. PREFIX .. "db,  " .. PREFIX .. "kill <boss>,  " .. PREFIX .. "loopkill <boss>,  " .. PREFIX .. "unloopkill")
