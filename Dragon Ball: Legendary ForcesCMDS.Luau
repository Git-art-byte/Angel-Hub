-- ANGEL HUB | Dragon Ball: Legendary Forces - Chat Commands
-- Clean & Modular Version with Roblox Notifications + Fixes & New Commands
-- Prefix: !

local PREFIX = "!"

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local combatRemote = ReplicatedStorage:WaitForChild("Assets", 9e9)
                     :WaitForChild("CombatAssets", 9e9)
                     :WaitForChild("CombatRemotes", 9e9)
                     :WaitForChild("ActivateCombat", 9e9)

-- Settings
local TELEPORT_OFFSET = 3
local TELEPORT_DELAY  = 0.05
local SCAN_DELAY      = 2
local BACK_OFFSET     = 3

-- State Variables
local loopkillConnection  = nil
local currentLoopBoss     = nil
local farmGamemodeEnabled = false
local farmConnection      = nil
local farmLastScanTime    = 0
local farmCurrentTarget   = nil
local viewTarget          = nil
local targetSpeed         = 16
local targetJump          = 50
local movementLoop        = nil

-- ────────────────────────────────────────────────
--  Notification Helper
-- ────────────────────────────────────────────────
local function notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Angel Hub",
            Text  = text or "Message",
            Duration = duration,
            Icon = ""
        })
    end)
end

-- ────────────────────────────────────────────────
--  Helper Functions
-- ────────────────────────────────────────────────
local function getCharacterHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function findPlayer(namePart)
    namePart = namePart:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Name:lower():find(namePart, 1, true) or plr.DisplayName:lower():find(namePart, 1, true) then
                return plr
            end
        end
    end
    return nil
end

local function getBoss(bossName)
    local bossesFolder = Workspace:FindFirstChild("Bosses")
    if not bossesFolder then return nil end
    bossName = bossName:lower()
    for _, boss in ipairs(bossesFolder:GetChildren()) do
        if boss:IsA("Model") and boss.Name:lower() == bossName then
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            local hum = boss:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                return hrp
            end
        end
    end
    return nil
end

local function getWorkspaceTargets(myHrp)
    local targets = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(targets, {hrp = hrp, hum = hum})
            end
        end
    end
    return targets
end

-- ────────────────────────────────────────────────
--  Movement Loop Manager
-- ────────────────────────────────────────────────
local function startMovementLoop()
    if movementLoop then return end
    movementLoop = RunService.Heartbeat:Connect(function()
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = targetSpeed
            hum.JumpPower = targetJump
            hum.UseJumpPower = true
        end
    end)
end

-- ────────────────────────────────────────────────
--  Core Features
-- ────────────────────────────────────────────────
local function collectDragonBalls()
    local hrp = getCharacterHRP()
    if not hrp then 
        notify("Error", "No character / HRP!")
        return 
    end

    local success, folders = pcall(function()
        return {
            Workspace:WaitForChild("DragonBalls", 5):WaitForChild("PorungaBalls", 5),
            Workspace:WaitForChild("DragonBalls", 5):WaitForChild("ShenronBalls", 5)
        }
    end)

    if not success then
        notify("Error", "DragonBalls folder not found!")
        return
    end

    local TOUCH_DELAY = 0.15
    for _, folder in ipairs(folders) do
        for i = 1, 7 do
            local ball = folder:FindFirstChild(tostring(i))
            if ball then
                local corpo = ball:FindFirstChild("corpo")
                local touchInterest = corpo and corpo:FindFirstChild("TouchInterest")
                if touchInterest then
                    firetouchinterest(hrp, touchInterest.Parent, 0)
                    task.wait()
                    firetouchinterest(hrp, touchInterest.Parent, 1)
                    task.wait(TOUCH_DELAY)
                end
            end
        end
    end
    notify("Dragon Balls", "All collected!")
end

local function SkidFling(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then 
        notify("Error", "Invalid target!")
        return 
    end

    local char = LocalPlayer.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not char or not hum or not root then 
        notify("Error", "Your character issue!")
        return 
    end

    local tchar = targetPlayer.Character
    local thum = tchar:FindFirstChildOfClass("Humanoid")
    local troot = thum and thum.RootPart
    local thead = tchar:FindFirstChild("Head")
    local accessory = tchar:FindFirstChildOfClass("Accessory")
    local handle = accessory and accessory:FindFirstChild("Handle")

    if thum and thum.Sit then 
        notify("Error", "Target is sitting!")
        return 
    end

    if root.AssemblyLinearVelocity.Magnitude < 50 then
        getgenv().OldPos = root.CFrame
    end

    local oldCamCFrame = Camera.CFrame
    local camConn = RunService.RenderStepped:Connect(function()
        Camera.CFrame = oldCamCFrame
    end)

    if thead then
        Camera.CameraSubject = thead
    elseif handle then
        Camera.CameraSubject = handle
    elseif thum and troot then
        Camera.CameraSubject = thum
    end

    local function FPos(basepart, pos, ang)
        root.CFrame = CFrame.new(basepart.Position) * pos * ang
        char:SetPrimaryPartCFrame(CFrame.new(basepart.Position) * pos * ang)
        root.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        root.AssemblyLinearVelocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        root.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(basepart)
        local timeout = tick() + 2
        local angle = 0
        repeat
            if not root or not thum then break end
            local velMag = basepart.AssemblyLinearVelocity.Magnitude
            if velMag < 50 then
                angle = angle + 100
                FPos(basepart, CFrame.new(0, 1.5, 0) + thum.MoveDirection * velMag / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(0, -1.5, 0) + thum.MoveDirection * velMag / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(2.25, 1.5, -2.25) + thum.MoveDirection * velMag / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(-2.25, -1.5, 2.25) + thum.MoveDirection * velMag / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(0, 1.5, 0) + thum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(0, -1.5, 0) + thum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
            else
                FPos(basepart, CFrame.new(0, 1.5, thum.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(basepart, CFrame.new(0, -1.5, -thum.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until basepart.AssemblyLinearVelocity.Magnitude > 500 or basepart.Parent ~= tchar or not targetPlayer.Parent or tick() > timeout
    end

    workspace.FallenPartsDestroyHeight = 0 / 0
    local bv = Instance.new("BodyVelocity")
    bv.Name = "EpixVel"
    bv.Parent = root
    bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
    bv.MaxForce = Vector3.new(1 / 0, 1 / 0, 1 / 0)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local flingPart = nil
    if troot and thead and (troot.Position - thead.Position).Magnitude > 5 then
        flingPart = thead
    elseif troot then
        flingPart = troot
    elseif thead then
        flingPart = thead
    elseif handle then
        flingPart = handle
    end

    if flingPart then
        SFBasePart(flingPart)
    end

    bv:Destroy()
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    camConn:Disconnect()
    Camera.CameraSubject = hum
    workspace.FallenPartsDestroyHeight = math.huge

    -- Enhanced cleanup to prevent self-fling
    local cleanupConn = RunService.Heartbeat:Connect(function()
        if root and getgenv().OldPos then
            root.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
            char:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new(0, 0, 0)
                    part.RotVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end)
    task.wait(1)  -- Extended cleanup time
    cleanupConn:Disconnect()

    notify("Fling", "Successfully flung " .. targetPlayer.Name)
end

local function killBossOnce(bossName)
    local bossHrp = getBoss(bossName)
    if not bossHrp then
        notify("Error", "Boss not found: " .. bossName)
        return
    end
    local myHrp = getCharacterHRP()
    if not myHrp then return end
    myHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, TELEPORT_OFFSET)
    combatRemote:FireServer()
end

local function startLoopKill(bossName)
    if loopkillConnection then loopkillConnection:Disconnect() end
    currentLoopBoss = bossName:lower()
    loopkillConnection = RunService.Heartbeat:Connect(function()
        killBossOnce(currentLoopBoss)
    end)
    notify("Loopkill", "Started on " .. bossName)
end

local function stopLoopKill()
    if loopkillConnection then
        loopkillConnection:Disconnect()
        loopkillConnection = nil
    end
    currentLoopBoss = nil
    notify("Loopkill", "Stopped!")
end

local function startFarmGamemode()
    if farmConnection then farmConnection:Disconnect() end
    farmGamemodeEnabled = true
    farmConnection = RunService.Heartbeat:Connect(function()
        local myHrp = getCharacterHRP()
        if not myHrp then return end
        if tick() - farmLastScanTime > SCAN_DELAY then
            local targets = getWorkspaceTargets(myHrp)
            local closestDist = math.huge
            local closest = nil
            for _, target in ipairs(targets) do
                local dist = (myHrp.Position - target.hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = target
                end
            end
            farmCurrentTarget = closest
            farmLastScanTime = tick()
        end
        if farmCurrentTarget and farmCurrentTarget.hum.Health > 0 then
            myHrp.CFrame = farmCurrentTarget.hrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)
            combatRemote:FireServer()
        else
            farmLastScanTime = 0
        end
    end)
    notify("Farm Gamemode", "Started (waves autofarm)!")
end

local function stopFarmGamemode()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    farmGamemodeEnabled = false
    farmCurrentTarget = nil
    notify("Farm Gamemode", "Stopped!")
end

-- ────────────────────────────────────────────────
--  Command Table
-- ────────────────────────────────────────────────
local commands = {
    help = {
        desc = "List all commands",
        func = function()
            notify("Angel Hub", "Commands:")
            for cmdName, info in pairs(commands) do
                task.spawn(function()
                    notify(PREFIX .. cmdName, info.desc)
                end)
                task.wait(0.2)
            end
        end
    },
    fling = {
        desc = "Fling player (partial match)",
        func = function(args)
            if not args[1] then
                notify("Usage", PREFIX .. "fling <name/part>")
                return
            end
            local targetPart = table.concat(args, " ")
            local target = findPlayer(targetPart)
            if target then
                SkidFling(target)
            else
                notify("Error", "Player not found!")
            end
        end
    },
    db = {
        desc = "Collect Dragon Balls",
        func = collectDragonBalls
    },
    kill = {
        desc = "Kill boss once",
        func = function(args)
            if not args[1] then return notify("Usage", PREFIX .. "kill <boss>") end
            local bossName = table.concat(args, " ")
            killBossOnce(bossName)
        end
    },
    loopkill = {
        desc = "Loopkill boss",
        func = function(args)
            if not args[1] then return notify("Usage", PREFIX .. "loopkill <boss>") end
            local bossName = table.concat(args, " ")
            startLoopKill(bossName)
        end
    },
    unloopkill = {
        desc = "Stop loopkill",
        func = stopLoopKill
    },
    speed = {
        desc = "Set speed (persistent)",
        func = function(args)
            local num = tonumber(args[1])
            if not num then return notify("Usage", PREFIX .. "speed <number>") end
            targetSpeed = num
            startMovementLoop()
            notify("Speed", "Set to " .. num .. " (anti-reset)")
        end
    },
    jump = {
        desc = "Set jump power (persistent)",
        func = function(args)
            local num = tonumber(args[1])
            if not num then return notify("Usage", PREFIX .. "jump <number>") end
            targetJump = num
            startMovementLoop()
            notify("Jump", "Set to " .. num .. " (anti-reset)")
        end
    },
    view = {
        desc = "View/spectate player",
        func = function(args)
            if not args[1] then return notify("Usage", PREFIX .. "view <name/part>") end
            local targetPart = table.concat(args, " ")
            local target = findPlayer(targetPart)
            if not target or not target.Character then 
                return notify("Error", "Player/character not found!") 
            end
            local targetHum = target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChild("Head")
            if targetHum then
                Camera.CameraSubject = targetHum
                viewTarget = target
                notify("View", "Now viewing " .. target.Name)
            end
        end
    },
    unview = {
        desc = "Stop viewing",
        func = function()
            local hum = getHumanoid()
            if hum then
                Camera.CameraSubject = hum
                viewTarget = nil
                notify("View", "Reset to self")
            end
        end
    },
    farmgamemode = {
        desc = "Toggle autofarm gamemode/waves",
        func = function()
            if farmGamemodeEnabled then
                stopFarmGamemode()
            else
                startFarmGamemode()
            end
        end
    }
}

-- ────────────────────────────────────────────────
--  Chat Handler
-- ────────────────────────────────────────────────
LocalPlayer.Chatted:Connect(function(message)
    local msgLower = message:lower()
    if not msgLower:match("^" .. PREFIX) then return end

    local trimmed = message:gsub("^%s*(.-)%s*$", "%1")
    local parts = {}
    for word in trimmed:gmatch("%S+") do
        table.insert(parts, word)
    end
    if #parts == 0 then return end

    local cmdRaw = parts[1]:lower()
    local cmdName = cmdRaw:sub(#PREFIX + 1)

    local cmd = commands[cmdName]
    if cmd and cmd.func then
        local args = {}
        for i = 2, #parts do table.insert(args, parts[i]) end
        cmd.func(args)
    else
        notify("Unknown", cmdRaw .. " not found!")
        notify("Help", "Use " .. PREFIX .. "help")
    end
end)

notify("Angel Hub", "Loaded! Prefix: " .. PREFIX)
notify("Tip", PREFIX .. "help for commands")
