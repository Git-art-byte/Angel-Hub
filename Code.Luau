local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Dragon Blox" .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 330),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

Fluent:Notify({
        Title = "Loaded!",
        Content = "Angel Hub has succesfully been loaded!",
        SubContent = nil, -- Optional
        Duration = 5 -- Set to nil to make the notification not disappear
})

-- Fluent provides Lucide Icons, they are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Quests = Window:AddTab({ Title = "Quests", Icon = "message-circle-warning" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local Section = Tabs.Main:AddSection("Train")

local TrainEnabled = false
local SelectedSkillId = "1"

local SkillDropdown = Tabs.Main:AddDropdown("SkillDropdown", {
    Title = "Training Type",
    Values = {"Punch", "Durability", "Ki"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        if value == "Punch" then
            SelectedSkillId = "1"
        elseif value == "Durability" then
            SelectedSkillId = "6"
        elseif value == "Ki" then
            SelectedSkillId = "2"
        end
    end
})

local TrainToggle = Tabs.Main:AddToggle("TrainToggle", {
    Title = "Train",
    Default = false,
    Callback = function(state)
        TrainEnabled = state

        if state then
            task.spawn(function()
                while TrainEnabled do
                    local args = {
                        {
                            Camera = CFrame.new(-58.72254943847656, 85.52032470703125, -374.1243896484375, 0.5716235637664795, 0.8078518509864807, -0.14360305666923523, 0, 0.17501555383205414, 0.9845656752586365, 0.8205159902572632, -0.562800943851471, 0.10004301369190216),
                            SkillId = SelectedSkillId,
                            Began = true,
                            CFrame = CFrame.new(-58.139434814453125, 72.95044708251953, -374.5310363769531, 0.5714630484580994, 0.8079167604446411, -0.14387644827365875, 0.0002584535686764866, 0.1751476675271988, 0.9845421314239502, 0.820627748966217, -0.562666654586792, 0.099881611764431),
                            ["Typ\208\181"] = 1,
                            Aim = vector.create(-50.945613861083984, 23.723339080810547, -379.5251159667969)
                        }
                    }

                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Remotes")
                        :WaitForChild("SkillRemote")
                        :FireServer(unpack(args))

                    task.wait()
                end
            end)
        else
            local args = {
                {
                    Camera = CFrame.new(-58.72254943847656, 85.52032470703125, -374.1243896484375, 0.5716235637664795, 0.8078518509864807, -0.14360305666923523, 0, 0.17501555383205414, 0.9845656752586365, 0.8205159902572632, -0.562800943851471, 0.10004301369190216),
                    SkillId = SelectedSkillId,
                    Began = false,
                    CFrame = CFrame.new(-58.139434814453125, 72.95044708251953, -374.5310363769531, 0.5714630484580994, 0.8079167604446411, -0.14387644827365875, 0.0002584535686764866, 0.1751476675271988, 0.9845421314239502, 0.820627748966217, -0.562666654586792, 0.099881611764431),
                    ["Typ\208\181"] = 1,
                    Aim = vector.create(-50.945613861083984, 23.723339080810547, -379.5251159667969)
                }
            }

            game:GetService("ReplicatedStorage")
                :WaitForChild("Remotes")
                :WaitForChild("SkillRemote")
                :FireServer(unpack(args))
        end
    end
})


local Section = Tabs.Quests:AddSection("Evee")

local SelectedQuestId = 2

local MobDropdown = Tabs.Quests:AddDropdown("MobDropdown", {
    Title = "Select Mob",
    Values = {
        "Atom X002 Army"
    },
    Default = 1,
    Multi = false,
    Callback = function(value)
        if value == "Atom X002 Army" then
            SelectedQuestId = 2
    end
})

-- Auto-farm nearest mob with continuous follow
local running = false

local FarmToggle = Tabs.Quests:AddToggle("AutoFarmToggle", 
{
    Title = "AutoFarm Mob",
    Default = false,
    Callback = function(state)
        running = state
        if state then
            print("AutoFarm Toggle On")

            task.spawn(function()
                local Players = game:GetService("Players")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local player = Players.LocalPlayer
                local playerHRP = player.Character:WaitForChild("HumanoidRootPart")
                local mobsFolder = workspace["World Mobs"].Mobs
                local SkillRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillRemote")

                -- punch args
                local punchArgs = {
                    {
                        Camera = CFrame.new(-58.72254943847656, 85.52032470703125, -374.1243896484375, 0.5716235637664795, 0.8078518509864807, -0.14360305666923523, 0, 0.17501555383205414, 0.9845656752586365, 0.8205159902572632, -0.562800943851471, 0.10004301369190216),
                        SkillId = "1",
                        Began = true,
                        CFrame = CFrame.new(-58.139434814453125, 72.95044708251953, -374.5310363769531, 0.5714630484580994, 0.8079167604446411, -0.14387644827365875, 0.0002584535686764866, 0.1751476675271988, 0.9845421314239502, 0.820627748966217, -0.562666654586792, 0.099881611764431),
                        ["Typ\208\181"] = 1,
                        Aim = Vector3.new(-50.945613861083984, 23.723339080810547, -379.5251159667969)
                    }
                }

                -- helper function for distance
                local function getDistance(mob)
                    if mob:FindFirstChild("HumanoidRootPart") then
                        return (playerHRP.Position - mob.HumanoidRootPart.Position).Magnitude
                    end
                    return math.huge
                end

                while running do
                    -- find all mobs of interest
                    local mobs = {}
                    for _, mob in pairs(mobsFolder:GetChildren()) do
                        if mob.Name == "Atom X002 Army" and mob:FindFirstChild("HumanoidRootPart") then
                            table.insert(mobs, mob)
                        end
                    end

                    if #mobs == 0 then
                        task.wait(0.5)
                        continue
                    end

                    -- nearest mob first
                    table.sort(mobs, function(a,b)
                        return getDistance(a) < getDistance(b)
                    end)

                    for _, mob in ipairs(mobs) do
                        if not running then break end
                        if not mob.Parent then continue end

                        -- continuously follow and punch until mob dies
                        while mob.Parent and running do
                            local hrpPos = mob.HumanoidRootPart.Position
                            local backPosition = hrpPos - (mob.HumanoidRootPart.CFrame.LookVector * 5)
                            playerHRP.CFrame = CFrame.new(backPosition, hrpPos)
                            task.wait(0.05) -- small wait to update teleport

                            -- punch
                            SkillRemote:FireServer(unpack(punchArgs))
                        end

                        -- stop punch once mob dead
                        punchArgs[1].Began = false
                        SkillRemote:FireServer(unpack(punchArgs))
                        punchArgs[1].Began = true
                        task.wait(0.1)
                    end
                end
            end)
        else
            print("AutoFarm Toggle Off")
            running = false
        end
    end
})
