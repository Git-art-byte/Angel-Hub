------------------------------------------------
-- FLUENT UI SETUP
------------------------------------------------
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title = "Angel Hub | Solo Hunters " .. Fluent.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:Notify({
    Title = "Loaded!",
    Content = "Angel Hub successfully loaded",
    Duration = 5
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

------------------------------------------------
-- SERVICES
------------------------------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer

------------------------------------------------
-- VARIABLES
------------------------------------------------
local SelectedMobs = {}
local running = false
local attacking = false
local AutoFarmPosition = "Back"
local WEAPON_NAME = "Kasaka's Venom Fang"

------------------------------------------------
-- MOB FOLDER
------------------------------------------------
local MobFolder = workspace:WaitForChild("Mobs")

------------------------------------------------
-- UI
------------------------------------------------
Tabs.Main:AddSection("AutoFarm")

local MobDropdown = Tabs.Main:AddDropdown("MobDropdown", {
    Title = "Select Mob",
    Values = {},
    Multi = true,
    Default = {},
    Callback = function(v)
        SelectedMobs = v or {}
    end
})

Tabs.Main:AddDropdown("PositionDropdown", {
    Title = "Position",
    Values = {"Back", "Front", "Under", "Upper"},
    Default = "Back",
    Callback = function(v)
        AutoFarmPosition = v
    end
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Default = false,
    Callback = function(v)
        running = v
        if not v then
            stopAttack()
        else
            startAutoFarm()
        end
    end
})

------------------------------------------------
-- HELPERS
------------------------------------------------
local function updateMobList()
    local names, seen = {}, {}
    for _, mob in ipairs(MobFolder:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            if not seen[mob.Name] then
                seen[mob.Name] = true
                table.insert(names, mob.Name)
            end
        end
    end
    table.sort(names)
    MobDropdown:SetValues(names)
end

task.spawn(function()
    while task.wait(1) do
        updateMobList()
    end
end)

local function getNearestMob(hrp)
    local nearest, dist = nil, math.huge
    for _, mob in ipairs(MobFolder:GetChildren()) do
        if SelectedMobs[mob.Name] then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and mhrp then
                local d = (hrp.Position - mhrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = mob
                end
            end
        end
    end
    return nearest
end

local function getPosition(mhrp)
    if AutoFarmPosition == "Back" then
        return mhrp.Position - mhrp.CFrame.LookVector * 4
    elseif AutoFarmPosition == "Front" then
        return mhrp.Position + mhrp.CFrame.LookVector * 4
    elseif AutoFarmPosition == "Under" then
        return mhrp.Position - Vector3.new(0, 4, 0)
    elseif AutoFarmPosition == "Upper" then
        return mhrp.Position + Vector3.new(0, 4, 0)
    end
end

------------------------------------------------
-- WEAPON HANDLING (NO UNEQUIP LOOP)
------------------------------------------------
local function getWeapon()
    local char = player.Character
    if not char then return nil end

    local tool = char:FindFirstChild(WEAPON_NAME)
    if tool then return tool end

    local bpTool = player.Backpack:FindFirstChild(WEAPON_NAME)
    if bpTool then
        bpTool.Parent = char
        return bpTool
    end

    return nil
end

function startAttack()
    if attacking then return end
    attacking = true

    task.spawn(function()
        while attacking do
            local tool = getWeapon()
            if tool then
                tool:Activate()
            end
            task.wait(0.12)
        end
    end)
end

function stopAttack()
    attacking = false
end

------------------------------------------------
-- AUTO FARM CORE
------------------------------------------------
function startAutoFarm()
    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        while running do
            local mob = getNearestMob(hrp)
            if not mob then
                stopAttack()
                task.wait(0.1)
                continue
            end

            local hum = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")

            while hum and hum.Health > 0 and running do
                hrp.CFrame = CFrame.new(getPosition(mhrp), mhrp.Position)
                startAttack()
                task.wait(0.1)
            end

            stopAttack()
        end

        stopAttack()
    end)
end
