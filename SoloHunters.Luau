local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Angel Hub | Solo Hunters " .. Fluent.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

Fluent:Notify({
        Title = "Loaded!",
        Content = "Angel Hub succesfuly Loaded",
        Duration = 5 -- Set to nil to make the notification not disappear
})

-- Fluent provides Lucide Icons, they are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local SectionA = Tabs.Main:AddSection("AutoFarm")

--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--// VARIABLES
local SelectedMobs = {} -- dictionary: [mobName] = true
local running = false
local AutoFarmPosition = "Back"

--// REMOTES
local CombatRemote = ReplicatedStorage
    .RemoteServices
    .CombatService
    .RF
    .UseWeapon

--// MOB FOLDER
local MobFolder = workspace:WaitForChild("Mobs")

------------------------------------------------
-- UI
------------------------------------------------

-- Multi Mob Dropdown
local MultiNearestMobDropdown = Tabs.Main:AddDropdown("MultiNearestMobDropdown", {
    Title = "Select Mob",
    Values = {},
    Multi = true,
    Default = {},
    Callback = function(values)
        SelectedMobs = values or {}
    end
})

-- AutoFarm Position
Tabs.Main:AddDropdown("AutoFarmPositionDropdown", {
    Title = "AutoFarm Position",
    Values = {"Under", "Front", "Back", "Upper"},
    Multi = false,
    Default = "Back",
    Callback = function(value)
        AutoFarmPosition = value
    end
})

-- AutoFarm Toggle
Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm",
    Default = false,
    Callback = function(state)
        running = state

        if state and not hasSelectedMobs() then
            Fluent:Notify({
                Title = "AutoFarm",
                Content = "Select at least one mob.",
                Duration = 3
            })
            running = false
            return
        end

        if state then
            startAutoFarm()
        end
    end
})

------------------------------------------------
-- HELPERS
------------------------------------------------

-- Check if at least one mob selected
function hasSelectedMobs()
    for _, v in pairs(SelectedMobs) do
        if v == true then
            return true
        end
    end
    return false
end

-- Update dropdown values
local function updateMobDropdown()
    local names, added = {}, {}

    for _, mob in ipairs(MobFolder:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            if not added[mob.Name] then
                added[mob.Name] = true
                table.insert(names, mob.Name)
            end
        end
    end

    table.sort(names)
    MultiNearestMobDropdown:SetValues(names)
end

task.spawn(function()
    while task.wait(1) do
        updateMobDropdown()
    end
end)

-- Get nearest selected mob
local function getNearestSelectedMob(hrp)
    local nearest, dist = nil, math.huge

    for _, mob in ipairs(MobFolder:GetChildren()) do
        if SelectedMobs[mob.Name] then
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and mhrp then
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

-- Position logic
local function getFarmPosition(mhrp)
    if AutoFarmPosition == "Back" then
        return mhrp.Position - mhrp.CFrame.LookVector * 5
    elseif AutoFarmPosition == "Front" then
        return mhrp.Position + mhrp.CFrame.LookVector * 5
    elseif AutoFarmPosition == "Under" then
        return mhrp.Position - Vector3.new(0, 5, 0)
    elseif AutoFarmPosition == "Upper" then
        return mhrp.Position + Vector3.new(0, 5, 0)
    end
end

------------------------------------------------
-- AUTO FARM CORE
------------------------------------------------

function startAutoFarm()
    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        while running do
            local mob = getNearestSelectedMob(hrp)
            if not mob then
                task.wait(0.1)
                continue
            end

            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")

            while humanoid and humanoid.Health > 0 and running do
                local pos = getFarmPosition(mhrp)
                hrp.CFrame = CFrame.new(pos, mhrp.Position)

                -- Attack
                CombatRemote:InvokeServer(0, {}, 1)

                task.wait(0.05)
            end

            task.wait(0.1)
        end
    end)
end
