local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Driving Empire " .. Fluent.Version,
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

local Section1 = Tabs.Main:AddSection("Auto Arrest")

-- Store the target username here
local targetUsername = ""

local Input = Tabs.Main:AddInput("ArrestInput", {
    Title = "Enter Username",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        targetUsername = Value  -- update whenever text changes
        print("Target set to:", Value)
    end
})

Tabs.Main:AddButton({
    Title = "Arrest",
    Callback = function()
        if targetUsername == "" then
            Fluent:Notify({
                Title = "Error",
                Content = "Please enter a username first!",
                Duration = 4
            })
            return
        end

        -- Find the target player
        local targetPlayer = game.Players:FindFirstChild(targetUsername)
        if not targetPlayer then
            Fluent:Notify({
                Title = "Error",
                Content = "Player '" .. targetUsername .. "' not found in server.",
                Duration = 5
            })
            return
        end

        local targetChar = targetPlayer.Character
        if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
            Fluent:Notify({
                Title = "Error",
                Content = "Target has no character or HRP.",
                Duration = 4
            })
            return
        end

        local myChar = game.Players.LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
            Fluent:Notify({
                Title = "Error",
                Content = "You have no character.",
                Duration = 4
            })
            return
        end

        Fluent:Notify({
            Title = "Arresting",
            Content = "Teleporting to " .. targetUsername .. " for 8 seconds...",
            Duration = 6
        })

        local hrp = myChar.HumanoidRootPart
        local targetHRP = targetChar.HumanoidRootPart

        local startTime = tick()
        local connection

        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if tick() - startTime >= 8 then
                connection:Disconnect()
                Fluent:Notify({
                    Title = "Finished",
                    Content = "Arrest loop ended.",
                    Duration = 4
                })
                return
            end

            -- Teleport directly on top of target (small Y offset to avoid sinking)
            hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 0)
        end)
    end
})

-- Optional: small notification when window fully ready
Fluent:Notify({
    Title = "Ready",
    Content = "Enter username → click Arrest to start TP loop",
    Duration = 6
})
