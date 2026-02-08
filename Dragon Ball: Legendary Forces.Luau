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

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage.Assets.CombatAssets.CombatRemotes.ActivateCombat

-- ================= SETTINGS =================
local TELEPORT_DELAY = 0.05
local BACK_OFFSET = 3
local AutoFarmEnabled = false
local SelectedBossName = nil
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

-- ================= UI =================

-- Boss selector
Tabs.Main:AddDropdown("BossSelectorDropdown", {
	Title = "Select Boss",
	Values = getBossList(),
	Multi = false,
	Default = nil,
	Callback = function(value)
		SelectedBossName = value
	end
})

-- Autofarm toggle
Tabs.Main:AddToggle("AutoFarmToggle", {
	Title = "Auto Farm Boss",
	Default = false,
	Callback = function(state)
		AutoFarmEnabled = state
	end
})

-- ================= LOGIC =================

-- Get selected boss
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

-- Autofarm loop
task.spawn(function()
	while true do
		if AutoFarmEnabled then
			local character = player.Character
			local playerHrp = character and character:FindFirstChild("HumanoidRootPart")

			local boss, bossHrp, bossHumanoid = getBoss()

			-- Only farm if boss is alive
			if playerHrp and bossHrp and bossHumanoid and bossHumanoid.Health > 0 then
				-- Teleport slightly behind boss
				playerHrp.CFrame = bossHrp.CFrame * CFrame.new(0, 0, BACK_OFFSET)

				-- Attack
				combatRemote:FireServer()
			end
		end

		task.wait(TELEPORT_DELAY)
	end
end)
