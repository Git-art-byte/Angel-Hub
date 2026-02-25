-- ANGEL HUB | Dragon Ball: Legendary Forces - Chat Commands
-- Prefix: !
-- Features: loopfling (specific target + radius separate), auto-stop on death + resume on respawn, !tp command

local PREFIX = "!"

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local combatRemote = ReplicatedStorage:WaitForChild("Assets")
                     :WaitForChild("CombatAssets")
                     :WaitForChild("CombatRemotes")
                     :WaitForChild("ActivateCombat")

-- Settings
local TELEPORT_OFFSET = 3   -- for kill / farm
local BACK_OFFSET     = 3   -- for farm
local SCAN_DELAY      = 2

-- Loopfling
local loopflingConnection        = nil
local loopflingTarget            = nil          -- Player or nil
local loopflingTargetConnections = {}
local loopflingRadius            = 120
local loopflingCooldown          = 0.5

-- Other states
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

-- Notification helper
local function notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Angel Hub",
            Text  = text or "",
            Duration = duration,
            Icon = ""
        })
    end)
end

-- Helpers
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function findPlayer(part)
    part = part:lower()
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer then
            if p.Name:lower():find(part,1,true) or p.DisplayName:lower():find(part,1,true) then
                return p
            end
        end
    end
    return nil
end

local function getBossHRP(name)
    local f = Workspace:FindFirstChild("Bosses")
    if not f then return nil end
    name = name:lower()
    for _, b in f:GetChildren() do
        if b:IsA("Model") and b.Name:lower() == name then
            local hrp = b:FindFirstChild("HumanoidRootPart")
            local h = b:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then return hrp end
        end
    end
    return nil
end

local function getWorkspaceTargets()
    local t = {}
    for _, o in Workspace:GetChildren() do
        if o:IsA("Model") and o ~= LocalPlayer.Character then
            local hrp = o:FindFirstChild("HumanoidRootPart")
            local h = o:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                table.insert(t, {hrp=hrp, hum=h})
            end
        end
    end
    return t
end

local function startMovementLoop()
    if movementLoop then return end
    movementLoop = RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h then
            h.WalkSpeed = targetSpeed
            h.JumpPower = targetJump
            h.UseJumpPower = true
        end
    end)
end

-- Fling function
local function SkidFling(target)
    if not target or not target.Character then return false end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not char or not hum or not root then return false end

    local tch = target.Character
    local thum = tch:FindFirstChildOfClass("Humanoid")
    local troot = thum and thum.RootPart
    local thead = tch:FindFirstChild("Head")
    if not thum or not troot then return false end

    if thum.Sit then return false end

    if root.AssemblyLinearVelocity.Magnitude < 50 then
        getgenv().OldPos = root.CFrame
    end

    local oldcam = Camera.CFrame
    local camc = RunService.RenderStepped:Connect(function() Camera.CFrame = oldcam end)

    Camera.CameraSubject = thead or thum

    local function FPos(p, off, ang)
        root.CFrame = CFrame.new(p.Position) * off * ang
        char:SetPrimaryPartCFrame(CFrame.new(p.Position) * off * ang)
        root.AssemblyLinearVelocity = Vector3.new(9e7, 9e7*10, 9e7)
        root.AssemblyAngularVelocity = Vector3.new(9e8,9e8,9e8)
    end

    local function SF(p)
        local endt = tick() + 1.8
        local a = 0
        repeat
            if not root or not thum then break end
            local vm = p.AssemblyLinearVelocity.Magnitude
            if vm < 50 then
                a = a + 120
                FPos(p, CFrame.new(0,math.random(-2,2),0), CFrame.Angles(math.rad(a),math.rad(a),0))
                task.wait(0.06)
            else
                FPos(p, CFrame.new(0,2,thum.WalkSpeed*1.2), CFrame.Angles(math.rad(80),0,0))
                task.wait(0.07)
            end
        until p.AssemblyLinearVelocity.Magnitude > 400 or not p.Parent or tick() > endt
    end

    local fp = (troot.Position - (thead and thead.Position or troot.Position)).Magnitude > 4 and thead or troot

    workspace.FallenPartsDestroyHeight = -math.huge

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9e8,9e8,9e8)
    bv.MaxForce = Vector3.new(1/0,1/0,1/0)
    bv.Parent = root

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    SF(fp)

    bv:Destroy()
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    camc:Disconnect()
    Camera.CameraSubject = hum

    task.spawn(function()
        for i=1,25 do
            if root and getgenv().OldPos then
                root.CFrame = getgenv().OldPos * CFrame.new(0,0.4,0)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait(0.04)
        end
    end)

    return true
end

-- Loop Fling (specific target mode)
local function forceStopLoopFling(reason)
    if loopflingConnection then loopflingConnection:Disconnect() loopflingConnection = nil end
    for _,c in loopflingTargetConnections do pcall(c.Disconnect,c) end
    loopflingTargetConnections = {}
    loopflingTarget = nil
    notify("Loop Fling", "Stopped: "..(reason or "manual"))
end

local function startLoopFling()
    if loopflingConnection then loopflingConnection:Disconnect() end
    for _,c in loopflingTargetConnections do pcall(c.Disconnect,c) end
    loopflingTargetConnections = {}

    local last = 0

    loopflingConnection = RunService.Heartbeat:Connect(function()
        if tick()-last < loopflingCooldown then return end
        local hrp = getHRP() if not hrp then return end

        if not loopflingTarget or not loopflingTarget.Character then return end

        local ch = loopflingTarget.Character
        local h = ch:FindFirstChildOfClass("Humanoid")
        local r = ch:FindFirstChild("HumanoidRootPart")

        if not h or not r or h.Health <= 0 then
            forceStopLoopFling("target died / invalid")
            return
        end

        if (hrp.Position - r.Position).Magnitude <= loopflingRadius then
            if SkidFling(loopflingTarget) then
                last = tick()
            end
        end
    end)

    -- Monitor target death / leave / respawn
    local function check()
        if not loopflingTarget then return end
        if not loopflingTarget.Parent then forceStopLoopFling("left server") return end
        local ch = loopflingTarget.Character
        if not ch then forceStopLoopFling("no character") return end
        local h = ch:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then forceStopLoopFling("died") end
    end

    check()

    table.insert(loopflingTargetConnections, loopflingTarget.CharacterAdded:Connect(check))
    table.insert(loopflingTargetConnections, loopflingTarget.CharacterRemoving:Connect(check))

    local ch = loopflingTarget.Character
    if ch then
        local h = ch:FindFirstChildOfClass("Humanoid")
        if h then
            table.insert(loopflingTargetConnections, h:GetPropertyChangedSignal("Health"):Connect(function()
                if h.Health <= 0 then forceStopLoopFling("died") end
            end))
        end
    end

    notify("Loop Fling", "Target locked → " .. loopflingTarget.Name .. " | radius " .. loopflingRadius)
end

local function stopLoopFling()
    forceStopLoopFling("stopped")
end

-- Dragon Balls
local function collectDB()
    local hrp = getHRP() if not hrp then notify("Error","No HRP") return end

    local folders = {
        Workspace:WaitForChild("DragonBalls"):WaitForChild("PorungaBalls"),
        Workspace:WaitForChild("DragonBalls"):WaitForChild("ShenronBalls")
    }

    for _,f in folders do
        for i=1,7 do
            local b = f:FindFirstChild(tostring(i))
            if b then
                local c = b:FindFirstChild("corpo")
                local t = c and c:FindFirstChild("TouchInterest")
                if t then
                    firetouchinterest(hrp, t.Parent, 0) task.wait()
                    firetouchinterest(hrp, t.Parent, 1) task.wait(0.15)
                end
            end
        end
    end
    notify("Dragon Balls","Collected!")
end

-- Boss
local function killBoss(name)
    local hrp = getBossHRP(name)
    if not hrp then notify("Error","Boss not found") return end
    local my = getHRP() if not my then return end
    my.CFrame = hrp.CFrame * CFrame.new(0,0,TELEPORT_OFFSET)
    combatRemote:FireServer()
end

local function startLoopKill(name)
    if loopkillConnection then loopkillConnection:Disconnect() end
    currentLoopBoss = name:lower()
    loopkillConnection = RunService.Heartbeat:Connect(function()
        killBoss(currentLoopBoss)
    end)
    notify("Loop Kill","Started → "..name)
end

local function stopLoopKill()
    if loopkillConnection then loopkillConnection:Disconnect() loopkillConnection = nil end
    currentLoopBoss = nil
    notify("Loop Kill","Stopped")
end

-- Farm Gamemode
local function startFarmGM()
    if farmConnection then farmConnection:Disconnect() end
    farmGamemodeEnabled = true
    farmConnection = RunService.Heartbeat:Connect(function()
        local my = getHRP() if not my then return end
        if tick() - farmLastScanTime > SCAN_DELAY then
            local ts = getWorkspaceTargets()
            local cd, ct = math.huge, nil
            for _,t in ts do
                local d = (my.Position - t.hrp.Position).Magnitude
                if d < cd then cd = d ct = t end
            end
            farmCurrentTarget = ct
            farmLastScanTime = tick()
        end
        if farmCurrentTarget and farmCurrentTarget.hum.Health > 0 then
            my.CFrame = farmCurrentTarget.hrp.CFrame * CFrame.new(0,0,BACK_OFFSET)
            combatRemote:FireServer()
        else
            farmLastScanTime = 0
        end
    end)
    notify("Farm Gamemode","ON")
end

local function stopFarmGM()
    if farmConnection then farmConnection:Disconnect() farmConnection = nil end
    farmGamemodeEnabled = false
    farmCurrentTarget = nil
    notify("Farm Gamemode","OFF")
end

-- New: Teleport to player
local function teleportToPlayer(namePart)
    local target = findPlayer(namePart)
    if not target or not target.Character then
        notify("TP Error", "Player not found or no character")
        return
    end

    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        notify("TP Error", "Target has no HumanoidRootPart")
        return
    end

    local myHRP = getHRP()
    if not myHRP then
        notify("TP Error", "You have no HumanoidRootPart")
        return
    end

    -- Teleport behind the player
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)  -- 5 studs behind
    notify("Teleport", "Teleported to " .. target.Name)
end

-- Commands table
local commands = {
    help = {
        desc = "Show commands",
        func = function()
            notify("Commands", 
                "!fling <name>\n" ..
                "!db\n" ..
                "!kill <boss>\n" ..
                "!loopkill <boss>\n" ..
                "!unloopkill\n" ..
                "!speed <num>\n" ..
                "!jump <num>\n" ..
                "!view <name>\n" ..
                "!unview\n" ..
                "!farmgamemode\n" ..
                "!loopfling <name> / <radius>\n" ..
                "!unloopfling\n" ..
                "!tp <name>"
            )
        end
    },

    fling = {
        desc = "Fling player",
        func = function(args)
            if not args[1] then return end
            local target = findPlayer(table.concat(args, " "))
            if target then
                SkidFling(target)
                notify("Fling", "→ " .. target.Name)
            else
                notify("Error", "Player not found")
            end
        end
    },

    db = { desc = "Collect dragon balls", func = collectDB },

    kill = {
        desc = "Kill boss once",
        func = function(args)
            if not args[1] then return end
            killBoss(table.concat(args, " "))
        end
    },

    loopkill = {
        desc = "Loop kill boss",
        func = function(args)
            if not args[1] then return end
            startLoopKill(table.concat(args, " "))
        end
    },

    unloopkill = { desc = "Stop loop kill", func = stopLoopKill },

    speed = {
        desc = "Set walkspeed",
        func = function(args)
            local n = tonumber(args[1])
            if n then
                targetSpeed = n
                startMovementLoop()
                notify("Speed", "Set to " .. n)
            end
        end
    },

    jump = {
        desc = "Set jump power",
        func = function(args)
            local n = tonumber(args[1])
            if n then
                targetJump = n
                startMovementLoop()
                notify("Jump", "Set to " .. n)
            end
        end
    },

    view = {
        desc = "View player",
        func = function(args)
            if not args[1] then return end
            local target = findPlayer(table.concat(args, " "))
            if target and target.Character then
                local sub = target.Character:FindFirstChild("Humanoid") or target.Character:FindFirstChild("Head")
                if sub then
                    Camera.CameraSubject = sub
                    viewTarget = target
                    notify("View", "→ " .. target.Name)
                end
            end
        end
    },

    unview = {
        desc = "Stop viewing",
        func = function()
            if getHum() then
                Camera.CameraSubject = getHum()
                viewTarget = nil
                notify("View", "Back to self")
            end
        end
    },

    farmgamemode = {
        desc = "Toggle waves farm",
        func = function()
            if farmGamemodeEnabled then
                stopFarmGM()
            else
                startFarmGM()
            end
        end
    },

    loopfling = {
        desc = "Loop fling specific player OR change radius",
        func = function(args)
            if not args[1] then
                notify("Usage", 
                    "!loopfling <playername>   → target only this guy\n" ..
                    "!loopfling <number>       → change radius only\n" ..
                    "Current radius: " .. loopflingRadius
                )
                return
            end

            local input = args[1]
            local rad = tonumber(input)

            if rad then
                if rad < 20 or rad > 1000 then
                    notify("Error", "Radius 20–1000 only")
                    return
                end
                loopflingRadius = rad
                notify("LoopFling Radius", "Set to " .. rad .. " studs")
                return
            end

            local target = findPlayer(input)
            if not target then
                notify("Error", "Player not found")
                return
            end

            loopflingTarget = target
            startLoopFling()
        end
    },

    unloopfling = {
        desc = "Stop loop fling",
        func = stopLoopFling
    },

    tp = {
        desc = "Teleport to player",
        func = function(args)
            if not args[1] then
                notify("Usage", "!tp <playername>")
                return
            end
            teleportToPlayer(table.concat(args, " "))
        end
    }
}

-- Chat listener
LocalPlayer.Chatted:Connect(function(msg)
    if not msg:lower():match("^"..PREFIX) then return end
    local parts = {}
    for w in msg:gmatch("%S+") do table.insert(parts, w) end
    if #parts < 1 then return end

    local cmdn = parts[1]:lower():sub(#PREFIX + 1)
    local cmd = commands[cmdn]
    if cmd and cmd.func then
        local args = {}
        for i = 2, #parts do table.insert(args, parts[i]) end
        cmd.func(args)
    else
        notify("Unknown", "Use !help")
    end
end)

notify("Angel Hub", "Loaded | !help for commands")
