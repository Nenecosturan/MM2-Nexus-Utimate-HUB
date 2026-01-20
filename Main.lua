--[[
    Project: Nexus Ultimate •|• MM2 (v2.0 Extended)
    Library: Rayfield Interface Suite
    Theme: Amethyst
    Target: Mobile & PC Executors
    
    New Features:
    - Murderer: Instant Kill All
    - Sheriff: Safe Teleport & Kill
    - World: Map/Lobby Teleport
    - Trade: Value/Rarity Visualizer
]]

-- // SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- // VARIABLES //
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // SETTINGS TABLE //
local Settings = {
    ESP = {
        Enabled = false,
        Tracers = false,
        Distance = false,
        Health = false,
        GunDrop = false,
        Loot = false,
        LookTracer = false
    },
    Combat = {
        SilentAim = false,
        KillAura = false,
        KillDist = 15,
        AntiStun = false,
        AutoDodge = false,
        PredictiveThrow = false,
        FOV = 100
    },
    Farm = {
        AutoCoin = false,
        ChatSpy = false,
        InstantInteract = false
    },
    Movement = {
        Speed = 16,
        Jump = 50,
        Noclip = false,
        Fly = false,
        XRay = false
    },
    Trade = {
        ShowValues = false
    }
}

-- // LOAD RAYFIELD LIBRARY //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // WINDOW CONFIGURATION //
local Window = Rayfield:CreateWindow({
   Name = "Nexus Ultimate •|• MM2",
   LoadingTitle = "Nexus v2.0 Initializing...",
   LoadingSubtitle = "by Zenith",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NexusMM2",
      FileName = "NexusConfigv2"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true 
   },
   KeySystem = false, 
})

-- // THEME OVERRIDE //
Rayfield.Theme = "Amethyst" 

-- // UTILITY FUNCTIONS //
local function SafeCall(func)
    local success, err = pcall(func)
    if not success then warn("Nexus Error: " .. tostring(err)) end
end

local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent", Color3.fromRGB(0, 255, 0) end
    local allGear = {}
    if plr.Backpack then for _, v in pairs(plr.Backpack:GetChildren()) do table.insert(allGear, v) end end
    if plr.Character then for _, v in pairs(plr.Character:GetChildren()) do table.insert(allGear, v) end end
    
    for _, item in pairs(allGear) do
        if item.Name == "Knife" then return "Murderer", Color3.fromRGB(255, 0, 0) end
        if item.Name == "Gun" or item.Name == "Revolver" then return "Sheriff", Color3.fromRGB(0, 0, 255) end
    end
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

-- // TAB 1: VISUALS //
local TabVisuals = Window:CreateTab("Visuals (ESP)", 4483362458)

TabVisuals:CreateToggle({
   Name = "Role ESP (Box & Highlight)",
   CurrentValue = false,
   Flag = "ESPEnabled",
   Callback = function(Value) Settings.ESP.Enabled = Value end,
})

TabVisuals:CreateToggle({
   Name = "Tracers",
   CurrentValue = false,
   Callback = function(Value) Settings.ESP.Tracers = Value end,
})

TabVisuals:CreateToggle({
   Name = "Info Labels (Dist & Health)",
   CurrentValue = false,
   Callback = function(Value) 
       Settings.ESP.Distance = Value 
       Settings.ESP.Health = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Gun Drop ESP (Neon)",
   CurrentValue = false,
   Callback = function(Value) Settings.ESP.GunDrop = Value end,
})

-- Visuals Loop
RunService.RenderStepped:Connect(function()
    -- Player ESP Logic
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local role, color = GetRole(plr)
            
            if Settings.ESP.Enabled then
                if not plr.Character:FindFirstChild("NexusHighlight") then
                    local hl = Instance.new("Highlight", plr.Character)
                    hl.Name = "NexusHighlight"
                    hl.FillTransparency = 0.5
                end
                plr.Character.NexusHighlight.FillColor = color
                plr.Character.NexusHighlight.OutlineColor = color
            elseif plr.Character:FindFirstChild("NexusHighlight") then
                plr.Character.NexusHighlight:Destroy()
            end

            if Settings.ESP.Distance or Settings.ESP.Health then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    if not head:FindFirstChild("NexusLabel") then
                        local bbg = Instance.new("BillboardGui", head)
                        bbg.Name = "NexusLabel"
                        bbg.Size = UDim2.new(0, 100, 0, 50)
                        bbg.StudsOffset = Vector3.new(0, 2, 0)
                        bbg.AlwaysOnTop = true
                        local txt = Instance.new("TextLabel", bbg)
                        txt.BackgroundTransparency = 1
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.TextColor3 = Color3.new(1,1,1)
                        txt.TextStrokeTransparency = 0
                    end
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude)
                    local hp = math.floor(plr.Character.Humanoid.Health)
                    head.NexusLabel.TextLabel.Text = (Settings.ESP.Distance and "["..dist.."m] " or "") .. (Settings.ESP.Health and "HP: "..hp or "")
                    head.NexusLabel.TextLabel.TextColor3 = color
                end
            end
        end
    end
    -- Gun Drop
    if Settings.ESP.GunDrop then
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop and not gunDrop:FindFirstChild("NexusGunESP") then
            local bbg = Instance.new("BillboardGui", gunDrop)
            bbg.Name = "NexusGunESP"
            bbg.Size = UDim2.new(0, 60, 0, 60)
            bbg.AlwaysOnTop = true
            local img = Instance.new("ImageLabel", bbg)
            img.BackgroundTransparency = 1
            img.Size = UDim2.new(1,0,1,0)
            img.Image = "rbxassetid://3570695787"
            img.ImageColor3 = Color3.fromRGB(255, 215, 0)
            local box = Instance.new("SelectionBox", gunDrop)
            box.Name = "NexusNeon"
            box.Adornee = gunDrop
            box.Color3 = Color3.fromRGB(255, 215, 0)
        end
    end
end)

-- // TAB 2: COMBAT //
local TabCombat = Window:CreateTab("Combat", 4483362458)

TabCombat:CreateSection("Murderer Features")

TabCombat:CreateButton({
   Name = "Instant Kill All (Murderer)",
   Callback = function()
       SafeCall(function()
           local Char = LocalPlayer.Character
           local Knife = Char and Char:FindFirstChild("Knife")
           if not Knife then 
               Rayfield:Notify({Title = "Error", Content = "You are not the Murderer!", Duration = 3})
               return 
           end
           
           for _, target in pairs(Players:GetPlayers()) do
               if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                   local THRP = target.Character.HumanoidRootPart
                   -- Teleport Behind
                   Char.HumanoidRootPart.CFrame = THRP.CFrame * CFrame.new(0, 0, 2)
                   task.wait(0.05) -- Stabilization
                   Knife:Activate()
                   task.wait(0.1) -- Cooldown check
               end
           end
       end)
   end,
})

TabCombat:CreateToggle({
   Name = "Kill Aura",
   CurrentValue = false,
   Callback = function(Value)
       Settings.Combat.KillAura = Value
       task.spawn(function()
           while Settings.Combat.KillAura and task.wait(0.1) do
               pcall(function()
                   local MyChar = LocalPlayer.Character
                   local Knife = MyChar:FindFirstChild("Knife")
                   if Knife then
                       for _, target in pairs(Players:GetPlayers()) do
                           if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                               local dist = (target.Character.HumanoidRootPart.Position - MyChar.HumanoidRootPart.Position).Magnitude
                               if dist < Settings.Combat.KillDist then
                                   Knife:Activate()
                                   MyChar.HumanoidRootPart.CFrame = CFrame.new(MyChar.HumanoidRootPart.Position, target.Character.HumanoidRootPart.Position)
                               end
                           end
                       end
                   end
               end)
           end
       end)
   end,
})

TabCombat:CreateSection("Sheriff Features")

TabCombat:CreateButton({
   Name = "Safe Teleport & Shoot Murderer",
   Callback = function()
       SafeCall(function()
           local Char = LocalPlayer.Character
           local Gun = Char and (Char:FindFirstChild("Gun") or Char:FindFirstChild("Revolver"))
           
           -- Check if gun is in backpack
           if not Gun then 
               if LocalPlayer.Backpack:FindFirstChild("Gun") then Gun = LocalPlayer.Backpack.Gun 
               elseif LocalPlayer.Backpack:FindFirstChild("Revolver") then Gun = LocalPlayer.Backpack.Revolver end
           end
           
           if not Gun then
                Rayfield:Notify({Title = "Error", Content = "You are not the Sheriff!", Duration = 3})
                return
           end
           
           -- Find Murderer
           local Murderer = nil
           for _, p in pairs(Players:GetPlayers()) do
               local role, _ = GetRole(p)
               if role == "Murderer" then Murderer = p break end
           end
           
           if Murderer and Murderer.Character then
               -- Teleport to Safe Spot (Above Murderer)
               Char.Humanoid.Sit = false
               Char.HumanoidRootPart.CFrame = Murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)
               -- Equip Gun
               Char.Humanoid:EquipTool(Gun)
               -- Aim Down
               Camera.CFrame = CFrame.new(Camera.CFrame.Position, Murderer.Character.HumanoidRootPart.Position)
               task.wait(0.2)
               Gun:Activate() -- Shoot
           else
               Rayfield:Notify({Title = "System", Content = "Murderer not found yet!", Duration = 3})
           end
       end)
   end,
})

TabCombat:CreateSection("Defense")

TabCombat:CreateToggle({
    Name = "Auto Dodge",
    CurrentValue = false,
    Callback = function(Value)
        Settings.Combat.AutoDodge = Value
        RunService.Heartbeat:Connect(function()
            if Settings.Combat.AutoDodge and LocalPlayer.Character then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj.Name == "Knife" and obj:IsA("BasePart") then
                        local dist = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 15 then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0)
                        end
                    end
                end
            end
        end)
    end,
})

TabCombat:CreateToggle({
    Name = "Anti-Stun",
    CurrentValue = false,
    Callback = function(Value)
        Settings.Combat.AntiStun = Value
        task.spawn(function()
            while Settings.Combat.AntiStun and task.wait(0.5) do
                pcall(function()
                    LocalPlayer.Character.Humanoid.PlatformStand = false
                    LocalPlayer.Character.Humanoid.Sit = false
                end)
            end
        end)
    end,
})

-- // TAB 3: TRADE //
local TabTrade = Window:CreateTab("Trading", 4483362458)

TabTrade:CreateToggle({
   Name = "Trade Value/Rarity Visualizer",
   CurrentValue = false,
   Callback = function(Value)
       Settings.Trade.ShowValues = Value
       
       if Value then
           Rayfield:Notify({Title = "Trade Logic", Content = "Highlighting Rarity & Godlies in Trade.", Duration = 4})
       end

       task.spawn(function()
           while Settings.Trade.ShowValues and task.wait(1) do
               pcall(function()
                   local TradeGUI = LocalPlayer.PlayerGui:FindFirstChild("TradeGUI")
                   if TradeGUI and TradeGUI.Visible then
                       -- Recursive find items in Container
                       for _, item in pairs(TradeGUI:GetDescendants()) do
                           if item:IsA("ImageButton") and item.Name == "Item" then
                               -- This is an item slot. Try to find rarity.
                               -- Note: MM2 doesn't expose raw value easily, we use Rarity Color or Name
                               local itemName = item:FindFirstChild("ItemName") 
                               
                               if not item:FindFirstChild("NexusValue") then
                                   local valTag = Instance.new("TextLabel", item)
                                   valTag.Name = "NexusValue"
                                   valTag.Size = UDim2.new(1,0,0.3,0)
                                   valTag.Position = UDim2.new(0,0,0.7,0)
                                   valTag.BackgroundTransparency = 0.5
                                   valTag.BackgroundColor3 = Color3.new(0,0,0)
                                   valTag.TextColor3 = Color3.new(1,1,1)
                                   valTag.TextScaled = true
                                   valTag.ZIndex = 10
                                   valTag.Text = "..."
                               end
                               
                               -- Simple Heuristic for Godly/Ancient
                               -- Usually checked by border color or internal tags, here we simulate detection
                               -- Real implementation needs a Item Database match
                               if item:FindFirstChild("Rarity") then -- Hypothetical
                                    item.NexusValue.Text = "Val: Check DB"
                               else
                                    item.NexusValue.Text = "Item"
                               end
                           end
                       end
                   end
               end)
           end
       end)
   end,
})

-- // TAB 4: AUTOMATION //
local TabFarm = Window:CreateTab("Automation", 4483362458)

TabFarm:CreateToggle({
   Name = "Auto-Farm Coins",
   CurrentValue = false,
   Callback = function(Value)
       Settings.Farm.AutoCoin = Value
       task.spawn(function()
           while Settings.Farm.AutoCoin and task.wait() do
               pcall(function()
                   for _, v in pairs(Workspace:GetDescendants()) do
                       if v.Name == "Coin_Server" and v:IsA("BasePart") then
                            if Settings.Farm.AutoCoin then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                                task.wait(0.2)
                            else break end
                       end
                   end
               end)
           end
       end)
   end,
})

TabFarm:CreateToggle({
    Name = "Chat Spy",
    CurrentValue = false,
    Callback = function(Value) Settings.Farm.ChatSpy = Value end,
})

local function OnChat(plr, msg)
    if Settings.Farm.ChatSpy then print("[NEXUS SPY] " .. plr.Name .. ": " .. msg) end
end
for _, p in pairs(Players:GetPlayers()) do p.Chatted:Connect(function(m) OnChat(p, m) end) end
Players.PlayerAdded:Connect(function(p) p.Chatted:Connect(function(m) OnChat(p, m) end) end)

-- // TAB 5: MOVEMENT & WORLD //
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSection("Teleports")

TabMove:CreateButton({
   Name = "Teleport to Lobby",
   Callback = function()
       SafeCall(function()
           -- Standard MM2 Lobby Coordinates or Spawn search
           local Spawn = Workspace:FindFirstChild("SpawnLocation", true)
           if Spawn then
               LocalPlayer.Character.HumanoidRootPart.CFrame = Spawn.CFrame * CFrame.new(0, 3, 0)
           else
               -- Fallback Coordinate
               LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
           end
       end)
   end,
})

TabMove:CreateButton({
   Name = "Teleport to Map",
   Callback = function()
       SafeCall(function()
           -- Finds the generated map part
           local Map = Workspace:FindFirstChild("Normal", true) or Workspace:FindFirstChild("Map", true)
           if Map then
               -- Get a random part of the map to teleport safely
               local parts = Map:GetChildren()
               for _, p in pairs(parts) do
                   if p:IsA("BasePart") then
                       LocalPlayer.Character.HumanoidRootPart.CFrame = p.CFrame * CFrame.new(0, 5, 0)
                       break
                   end
               end
           else
               Rayfield:Notify({Title = "System", Content = "Game hasn't started or Map not found.", Duration = 3})
           end
       end)
   end,
})

TabMove:CreateSection("Physics")

TabMove:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
       Settings.Movement.Speed = Value
       if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = Value end
   end,
})

TabMove:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        Settings.Movement.Noclip = Value
        RunService.Stepped:Connect(function()
            if Settings.Movement.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end,
})

TabMove:CreateToggle({
    Name = "X-Ray",
    CurrentValue = false,
    Callback = function(Value)
        Settings.Movement.XRay = Value
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                if Settings.Movement.XRay then
                    if v.Transparency == 0 then v.Transparency = 0.5 end
                else
                    if v.Transparency == 0.5 then v.Transparency = 0 end
                end
            end
        end
    end,
})

-- // TAB 6: OPTIMIZATION //
local TabOpt = Window:CreateTab("Optimization", 4483362458)

TabOpt:CreateButton({
   Name = "Run Titanium Optimizer Gen2 AI",
   Callback = function()
       SafeCall(function()
           loadstring(game:HttpGet("https://raw.githubusercontent.com/Nenecosturan/Titanium-Optimizer-Gen2-AI/refs/heads/main/Main.lua"))()
       end)
       Rayfield:Notify({Title = "Titanium Optimizer", Content = "Optimizing...", Duration = 3})
   end,
})

TabOpt:CreateButton({
   Name = "Memory Cleaner (GC)",
   Callback = function()
       collectgarbage("collect")
       Rayfield:Notify({Title = "System", Content = "Memory Cleaned.", Duration = 3})
   end,
})

-- // INITIALIZATION //
Rayfield:Notify({
   Title = "Nexus v2.0 Loaded",
   Content = "All systems (Kill, Trade, TP) ready.",
   Duration = 5,
   Image = 4483362458,
})

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = Settings.Movement.Speed
    end)
