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
        "Atom X002 Army",
        "Atom X002"
    },
    Default = 1,
    Multi = false,
    Callback = function(value)
        if value == "Atom X002 Army" then
            SelectedQuestId = 2
        elseif value == "Atom X002" then
            SelectedQuestId = 7
        end
    end
})

local TakeQuestButton = Tabs.Quests:AddButton({
    Title = "Take Quest",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        -- save current position
        local originalCFrame = hrp.CFrame

        local npc = workspace:WaitForChild("Misc")
            :WaitForChild("NPC")
            :WaitForChild("Quests")
            :WaitForChild("QuestNPCDroid2_AtomX002")

        -- teleport to NPC head
        hrp.CFrame = npc.Head.CFrame * CFrame.new(0, 0, -3)

        -- wait a short moment to make sure the game registers the teleport
        task.wait(0.2)

        -- take quest
        local args = {
            "NPCQuest_Tribe Village",
            SelectedQuestId,
            npc
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_knit@1.4.7")
            :WaitForChild("knit")
            :WaitForChild("Services")
            :WaitForChild("DialogService")
            :WaitForChild("RF")
            :WaitForChild("Answer")
            :InvokeServer(unpack(args))

        -- wait 1 second then return to original position
        task.wait(0.75)
        hrp.CFrame = originalCFrame
    end
})


local running = false -- global flag to control the loop

local FarmToggle = Tabs.Quests:AddToggle("MyToggle5", 
{
    Title = "AutoFarm Nearest Mob",
    Default = false,
    Callback = function(state)
        if state then
            print("Toggle On")
            running = true

            -- Run the auto-farm in a separate thread so it doesn't block
            spawn(function()
                local Players = game:GetService("Players")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local player = Players.LocalPlayer
                local playerHRP = player.Character.HumanoidRootPart
                local mobsFolder = workspace["World Mobs"].Mobs
                local SkillRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillRemote")

                -- Your original punch args
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

                -- Helper function to get distance to Bandit
                local function getDistance(mob)
                    if mob:FindFirstChild("HumanoidRootPart") then
                        return (playerHRP.Position - mob.HumanoidRootPart.Position).Magnitude
                    end
                    return math.huge
                end

                -- Main loop
                while running do
                    -- Find all Bandits
                    local bandits = {}
                    for _, mob in pairs(mobsFolder:GetChildren()) do
                        if mob.Name == "Atom X002 Army" and mob:FindFirstChild("HumanoidRootPart") then
                            table.insert(bandits, mob)
                        end
                    end

                    if #bandits == 0 then
                        wait(0.5)
                        continue
                    end

                    -- Sort by nearest
                    table.sort(bandits, function(a, b)
                        return getDistance(a) < getDistance(b)
                    end)

                    -- Loop through each Bandit
                    for _, mob in ipairs(bandits) do
                        if not running then break end -- stop if toggle turned off
                        if not mob.Parent then continue end

                        -- Teleport behind Bandit facing them
                        local hrp = mob.HumanoidRootPart
                        local backPosition = hrp.Position - (hrp.CFrame.LookVector * 5)
                        playerHRP.CFrame = CFrame.new(backPosition, hrp.Position)
                        wait(0.1)

                        -- Start punching
                        SkillRemote:FireServer(unpack(punchArgs))

                        -- Keep punching until dead or toggle off
                        while mob.Parent and running do
                            SkillRemote:FireServer(unpack(punchArgs))
                            wait(0.1)
                        end

                        -- Stop punching
                        punchArgs[1].Began = false
                        SkillRemote:FireServer(unpack(punchArgs))
                        punchArgs[1].Began = true
                        wait(0.1)
                    end
                end
            end)
        else
            print("Toggle Off")
            running = false -- stops the auto-farm loop
        end
    end
})
