-- ANGEL HUB | Dragon Ball: Legendary Forces - Chat Commands
-- Clean & Modular Version with Roblox Notifications
-- Prefix: !

local PREFIX = "!"

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local combatRemote = ReplicatedStorage:WaitForChild("Assets", 5)
                     :WaitForChild("CombatAssets", 5)
                     :WaitForChild("CombatRemotes", 5)
                     :WaitForChild("ActivateCombat", 5)

-- Settings
local TELEPORT_OFFSET = 3
local TELEPORT_DELAY  = 0.05

-- State for loopkill
local loopkillConnection = nil
local currentLoopBoss    = nil

-- ────────────────────────────────────────────────
--  Notification Helper (uses Roblox's built-in system)
-- ────────────────────────────────────────────────

local function notify(title, text, duration)
    duration = duration or 4
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Angel Hub",
            Text  = text or "Message",
            Duration = duration,
            Icon = ""   -- You can put a decal/image id here if you want an icon
        })
    end)
end

-- ────────────────────────────────────────────────
--  Helper Functions
-- ────────────────────────────────────────────────

local function getCharacterHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function findPlayer(namePart)
    namePart = namePart:lower()
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local uname = plr.Name:lower()
            local dname = plr.DisplayName:lower()
            
            if uname:find(namePart, 1, true) or dname:find(namePart, 1, true) then
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
                return boss, hrp
            end
        end
    end
    return nil
end

-- ────────────────────────────────────────────────
--  Core Features
-- ────────────────────────────────────────────────

local function collectDragonBalls()
    local hrp = getCharacterHRP()
    if not hrp then 
        notify("Error", "No character / HRP found!")
        return 
    end

    local folders = {
        Workspace:WaitForChild("DragonBalls", 5):WaitForChild("PorungaBalls", 5),
        Workspace:WaitForChild("DragonBalls", 5):WaitForChild("ShenronBalls", 5)
    }

    local TOUCH_DELAY = 0.15

    for _, folder in ipairs(folders) do
        for i = 1, 7 do
            local ball = folder:FindFirstChild(tostring(i))
            if ball then
                local corpo = ball:FindFirstChild("corpo")
                if corpo then
                    local touch = corpo:FindFirstChildWhichIsA("TouchTransmitter")
                    if touch then
                        firetouchinterest(hrp, corpo, 0)
                        task.wait()
                        firetouchinterest(hrp, corpo, 1)
                        task.wait(TOUCH_DELAY)
                    end
                end
            end
        end
    end

    notify("Dragon Balls", "Collected all Dragon Balls!")
end

local function flingPlayer(targetNamePart)
    local target = findPlayer(targetNamePart)
    if not target then
        notify("Fling Failed", "Player not found: " .. targetNamePart)
        return
    end

    if not target.Character then
        notify("Fling Failed", target.Name .. " has no character")
        return
    end

    notify("Flinging", "Attempting to fling: " .. target.Name)

    -- ── Simplified strong fling logic ──
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart

    local tchar = target.Character
    local thum = tchar:FindFirstChildOfClass("Humanoid")
    local troot = thum and thum.RootPart
    local thead = tchar:FindFirstChild("Head")

    if not root or not thum then return end
    if thum.Sit then 
        notify("Fling Failed", "Target is sitting!")
        return 
    end

    getgenv().OldPos = getgenv().OldPos or root.CFrame

    local camConn
    camConn = RunService.RenderStepped:Connect(function()
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
    end)

    workspace.CurrentCamera.CameraSubject = thead or thum

    local function setPos(offset, angle)
        root.CFrame = troot.CFrame * offset * angle
        char:SetPrimaryPartCFrame(troot.CFrame * offset * angle)
        root.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
        root.RotVelocity = Vector3.new(9e8,9e8,9e8)
    end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9e8,9e8,9e8)
    bv.MaxForce = Vector3.new(1/0,1/0,1/0)
    bv.Parent = root

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    for i = 1, 14 do
        if not troot.Parent then break end
        setPos(CFrame.new(0, math.random(-3,3), math.random(-3,3)), CFrame.Angles(math.rad(math.random(-180,180)), math.rad(math.random(-180,180)), 0))
        task.wait(0.07)
    end

    bv:Destroy()
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    camConn:Disconnect()
    workspace.CurrentCamera.CameraSubject = hum

    -- Return attempt
    for i = 1, 12 do
        root.CFrame = getgenv().OldPos * CFrame.new(0,0.5,0)
        task.wait(0.04)
    end

    notify("Fling Complete", "Flinged → " .. target.Name)
end

local function killBossOnce(bossName)
    local boss, bossHrp = getBoss(bossName)
    if not boss then
        notify("Kill Failed", "Boss not found: " .. bossName)
        return
    end

    local myHrp = getCharacterHRP()
    if not myHrp then 
        notify("Error", "No character HRP")
        return 
    end

    myHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, TELEPORT_OFFSET)
    combatRemote:FireServer()

    notify("Attack Sent", "Attacking: " .. bossName)
end

local function startLoopKill(bossName)
    if loopkillConnection then
        loopkillConnection:Disconnect()
    end

    currentLoopBoss = bossName:lower()
    notify("Loopkill Started", "Now looping: " .. bossName)

    loopkillConnection = RunService.Heartbeat:Connect(function()
        if not currentLoopBoss then return end
        killBossOnce(currentLoopBoss)
    end)
end

local function stopLoopKill()
    if loopkillConnection then
        loopkillConnection:Disconnect()
        loopkillConnection = nil
    end
    currentLoopBoss = nil
    notify("Loopkill Stopped", "Loopkill has been disabled")
end

-- ────────────────────────────────────────────────
--  Command Table
-- ────────────────────────────────────────────────

local commands = {
    help = {
        desc = "Shows this help message",
        func = function()
            notify("Angel Hub Commands", "Available commands:")
            task.wait(0.1)
            for cmd, info in pairs(commands) do
                notify(PREFIX .. cmd, info.desc)
            end
        end
    },

    fling = {
        desc = "Fling a player (partial name match)",
        func = function(args)
            if not args[1] then
                notify("Usage", PREFIX .. "fling <name or part>")
                return
            end
            local targetPart = table.concat(args, " ")
            flingPlayer(targetPart)
        end
    },

    db = {
        desc = "Collect all Dragon Balls",
        func = collectDragonBalls
    },

    kill = {
        desc = "One-time attack a boss",
        func = function(args)
            if not args[1] then
                notify("Usage", PREFIX .. "kill <boss name>")
                return
            end
            local bossName = table.concat(args, " ")
            killBossOnce(bossName)
        end
    },

    loopkill = {
        desc = "Start auto-attacking a boss",
        func = function(args)
            if not args[1] then
                notify("Usage", PREFIX .. "loopkill <boss name>")
                return
            end
            local bossName = table.concat(args, " ")
            startLoopKill(bossName)
        end
    },

    unloopkill = {
        desc = "Stop current loopkill",
        func = stopLoopKill
    },
}

-- ────────────────────────────────────────────────
--  Chat Handler
-- ────────────────────────────────────────────────

LocalPlayer.Chatted:Connect(function(message)
    if not message:lower():match("^" .. PREFIX) then return end

    local trimmed = message:match("^%s*(.-)%s*$")
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
        for i = 2, #parts do
            table.insert(args, parts[i])
        end
        cmd.func(args)
    else
        notify("Unknown Command", cmdRaw .. " not found")
        notify("Tip", "Use " .. PREFIX .. "help to see commands")
    end
end)

-- Startup message
notify("Angel Hub", "Chat commands loaded | Prefix = " .. PREFIX)
notify("Commands", "Type " .. PREFIX .. "help to see all commands")
