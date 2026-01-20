--[[
    Project: Nexus Ultimate •|• MM2 (v3.0 Final)
    Library: Rayfield Interface Suite
    Theme: Amethyst
    Target: Mobile & PC Executors
    
    Change Log v3.0:
    + Added "Mole Mode" Safe Farming (No Instant TP)
    + Added Post-Farm Events (Reset, Kill All, Shoot, Fling)
    + Preserved all v2.0 Features (Trade, Combat, ESP)
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
local TweenService = game:GetService("TweenService")

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
        Enabled = false,
        Speed = 45, -- Smooth travel speed
        ResetOnFinish = false,
        KillAllOnFinish = false,
        ShootOnFinish = false,
        FlingOnFinish = false,
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
   LoadingTitle = "Nexus v3.0 (Farm Edition)",
   LoadingSubtitle = "by Zenith",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NexusMM2_v3",
      FileName = "NexusConfig"
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

local function IdentifyMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        local role, _ = GetRole(p)
        if role == "Murderer" then return p end
    end
    return nil
end

local function FlingTarget(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local T_HRP = target.Character.HumanoidRootPart
        local L_HRP = LocalPlayer.Character.HumanoidRootPart
        
        Rayfield:Notify({Title = "Flinging", Content = "Goodbye " .. target.Name, Duration = 3})
        
        local startTime = tick()
        local BodyVel = Instance.new("BodyVelocity")
        BodyVel.Velocity = Vector3.new(0,0,0)
        BodyVel.Parent = L_HRP
        
        local BodyAng = Instance.new("BodyAngularVelocity")
        BodyAng.AngularVelocity = Vector3.new(10000,10000,10000)
        BodyAng.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
        BodyAng.Parent = L_HRP
        
        local Connection
        Connection = RunService.Stepped:Connect(function()
            if not target.Character or not L_HRP or tick() - startTime > 3 then
                Connection:Disconnect()
                BodyVel:Destroy()
                BodyAng:Destroy()
                return
            end
            L_HRP.CanCollide = false
            L_HRP.CFrame = T_HRP.CFrame
            BodyVel.Velocity = Vector3.new(0,1000,0)
            L_HRP.RotVelocity = Vector3.new(10000,10000,10000)
        end)
    end
end

-- // TAB 1: COIN FARM (NEW & ADVANCED) //
local TabFarm = Window:CreateTab("Coin Farm", 4483362458)

TabFarm:CreateSection("Mole Mode Farm")

TabFarm:CreateToggle({
   Name = "Enable Mole Farm (Safe)",
   CurrentValue = false,
   Callback = function(Value)
       Settings.Farm.Enabled = Value
       
       if Value then
           Rayfield:Notify({Title = "Farm Started", Content = "Going underground...", Duration = 3})
           
           task.spawn(function()
               while Settings.Farm.Enabled and task.wait() do
                   pcall(function()
                       local Char = LocalPlayer.Character
                       local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
                       local Hum = Char and Char:FindFirstChild("Humanoid")
                       
                       if not HRP or not Hum then return end
                       
                       -- 1. Find Coins
                       local Coins = {}
                       for _, v in pairs(Workspace:GetDescendants()) do
                           if v.Name == "Coin_Server" and v:IsA("BasePart") then
                               table.insert(Coins, v)
                           end
                       end
                       
                       if #Coins == 0 then
                           -- FARM FINISHED LOGIC
                           Rayfield:Notify({Title = "Farm Done", Content = "Map clear!", Duration = 3})
                           Settings.Farm.Enabled = false
                           
                           -- Post Farm Events
                           if Settings.Farm.ResetOnFinish then Char:BreakJoints() return end
                           
                           local myRole, _ = GetRole(LocalPlayer)
                           local Murderer = IdentifyMurderer()
                           
                           if Settings.Farm.KillAllOnFinish and myRole == "Murderer" then
                               local Knife = Char:FindFirstChild("Knife")
                               if Knife then
                                   for _, t in pairs(Players:GetPlayers()) do
                                       if t~=LocalPlayer and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                                           HRP.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,2)
                                           Knife:Activate()
                                           task.wait(0.1)
                                       end
                                   end
                               end
                           end
                           
                           if Settings.Farm.ShootOnFinish and myRole == "Sheriff" and Murderer then
                               local Gun = Char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
                               if Gun then
                                   Hum:EquipTool(Gun)
                                   HRP.CFrame = Murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0,15,0)
                                   Camera.CFrame = CFrame.new(Camera.CFrame.Position, Murderer.Character.HumanoidRootPart.Position)
                                   task.wait(0.3)
                                   Gun:Activate()
                               end
                           end
                           
                           if Settings.Farm.FlingOnFinish and Murderer then
                               FlingTarget(Murderer)
                           end
                           return 
                       end
                       
                       -- 2. Mole Physics
                       Hum.PlatformStand = true 
                       for _, part in pairs(Char:GetChildren()) do
                           if part:IsA("BasePart") then part.CanCollide = false end
                       end
                       
                       -- 3. Move Logic
                       local TargetCoin = Coins[1]
                       if TargetCoin then
                           local CoinPos = TargetCoin.Position
                           local UnderPos = Vector3.new(CoinPos.X, CoinPos.Y - 10, CoinPos.Z)
                           
                           -- Move Under
                           local alpha = 0
                           local startCF = HRP.CFrame
                           local dist = (HRP.Position - UnderPos).Magnitude
                           local speed = Settings.Farm.Speed
                           
                           while alpha < 1 and Settings.Farm.Enabled do
                               alpha = alpha + (1 / (dist/speed * 60)) -- Frame independent-ish
                               HRP.CFrame = startCF:Lerp(CFrame.new(UnderPos), alpha)
                               RunService.Heartbeat:Wait()
                           end
                           
                           -- Pop Up & Collect
                           HRP.CFrame = CFrame.new(CoinPos)
                           task.wait(0.15)
                           HRP.CFrame = CFrame.new(UnderPos)
                       end
                   end)
               end
               -- Disable Physics
               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                   LocalPlayer.Character.Humanoid.PlatformStand = false
               end
           end)
       end
   end,
})

TabFarm:CreateSlider({
   Name = "Farm Speed (Lower = Less Ban Risk)",
   Range = {20, 100},
   Increment = 5,
   CurrentValue = 45,
   Callback = function(Value) Settings.Farm.Speed = Value end,
})

TabFarm:CreateSection("Post-Farm Events")

TabFarm:CreateToggle({
    Name = "Auto Reset (Lobby)",
    CurrentValue = false,
    Callback = function(Value) Settings.Farm.ResetOnFinish = Value end,
})

TabFarm:CreateToggle({
    Name = "Auto Kill All (If Murderer)",
    CurrentValue = false,
    Callback = function(Value) Settings.Farm.KillAllOnFinish = Value end,
})

TabFarm:CreateToggle({
    Name = "Auto Shoot Murderer (If Sheriff)",
    CurrentValue = false,
    Callback = function(Value) Settings.Farm.ShootOnFinish = Value end,
})

TabFarm:CreateToggle({
    Name = "Fling Murderer (Troll)",
    CurrentValue = false,
    Callback = function(Value) Settings.Farm.FlingOnFinish = Value end,
})

-- // TAB 2: VISUALS //
local TabVisuals = Window:CreateTab("Visuals", 4483362458)

TabVisuals:CreateToggle({
   Name = "Role ESP (Box & Highlight)",
   CurrentValue = false,
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
                        txt.BackgroundTransparency = 1; txt.Size = UDim2.new(1,0,1,0); txt.TextColor3 = Color3.new(1,1,1); txt.TextStrokeTransparency = 0
                    end
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude)
                    local hp = math.floor(plr.Character.Humanoid.Health)
                    head.NexusLabel.TextLabel.Text = (Settings.ESP.Distance and "["..dist.."m] " or "") .. (Settings.ESP.Health and "HP: "..hp or "")
                    head.NexusLabel.TextLabel.TextColor3 = color
                end
            end
        end
    end
    if Settings.ESP.GunDrop then
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop and not gunDrop:FindFirstChild("NexusGunESP") then
            local bbg = Instance.new("BillboardGui", gunDrop)
            bbg.Name = "NexusGunESP"
            bbg.Size = UDim2.new(0, 60, 0, 60)
            bbg.AlwaysOnTop = true
            local img = Instance.new("ImageLabel", bbg)
            img.BackgroundTransparency = 1; img.Size = UDim2.new(1,0,1,0); img.Image = "rbxassetid://3570695787"; img.ImageColor3 = Color3.fromRGB(255, 215, 0)
            local box = Instance.new("SelectionBox", gunDrop); box.Name = "NexusNeon"; box.Adornee = gunDrop; box.Color3 = Color3.fromRGB(255, 215, 0)
        end
    end
end)

-- // TAB 3: COMBAT //
local TabCombat = Window:CreateTab("Combat", 4483362458)

TabCombat:CreateSection("Murderer")

TabCombat:CreateButton({
   Name = "Instant Kill All",
   Callback = function()
       SafeCall(function()
           local Char = LocalPlayer.Character
           local Knife = Char and Char:FindFirstChild("Knife")
           if not Knife then Rayfield:Notify({Title = "Error", Content = "Not Murderer!", Duration = 3}) return end
           for _, target in pairs(Players:GetPlayers()) do
               if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                   Char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                   task.wait(0.05); Knife:Activate(); task.wait(0.1)
               end
           end
       end)
   end,
})

TabCombat:CreateToggle({
   Name = "Kill Aura",
   Callback = function(Value)
       Settings.Combat.KillAura = Value
       task.spawn(function()
           while Settings.Combat.KillAura and task.wait(0.1) do
               local MyChar = LocalPlayer.Character
               local Knife = MyChar and MyChar:FindFirstChild("Knife")
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
           end
       end)
   end,
})

TabCombat:CreateSection("Sheriff")

TabCombat:CreateButton({
   Name = "Safe Teleport & Shoot",
   Callback = function()
       SafeCall(function()
           local Char = LocalPlayer.Character
           local Gun = Char and (Char:FindFirstChild("Gun") or Char:FindFirstChild("Revolver") or (LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Revolver")))
           if not Gun then Rayfield:Notify({Title = "Error", Content = "Not Sheriff!", Duration = 3}) return end
           local Murderer = IdentifyMurderer()
           if Murderer and Murderer.Character then
               Char.Humanoid:EquipTool(Gun)
               Char.Humanoid.Sit = false
               Char.HumanoidRootPart.CFrame = Murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)
               Camera.CFrame = CFrame.new(Camera.CFrame.Position, Murderer.Character.HumanoidRootPart.Position)
               task.wait(0.2); Gun:Activate()
           else
               Rayfield:Notify({Title = "System", Content = "Murderer not found!", Duration = 3})
           end
       end)
   end,
})

TabCombat:CreateSection("Defense")

TabCombat:CreateToggle({
    Name = "Auto Dodge (Knife)",
    Callback = function(Value)
        Settings.Combat.AutoDodge = Value
        RunService.Heartbeat:Connect(function()
            if Settings.Combat.AutoDodge and LocalPlayer.Character then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj.Name == "Knife" and obj:IsA("BasePart") then
                        if (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 15 then
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
    Callback = function(Value)
        Settings.Combat.AntiStun = Value
        task.spawn(function()
            while Settings.Combat.AntiStun and task.wait(0.5) do
                pcall(function() LocalPlayer.Character.Humanoid.PlatformStand = false; LocalPlayer.Character.Humanoid.Sit = false end)
            end
        end)
    end,
})

-- // TAB 4: TRADE //
local TabTrade = Window:CreateTab("Trading", 4483362458)

TabTrade:CreateToggle({
   Name = "Trade Value/Rarity Visualizer",
   Callback = function(Value)
       Settings.Trade.ShowValues = Value
       if Value then Rayfield:Notify({Title = "Trade Logic", Content = "Highlighting Rarity & Godlies.", Duration = 4}) end
       task.spawn(function()
           while Settings.Trade.ShowValues and task.wait(1) do
               pcall(function()
                   local TradeGUI = LocalPlayer.PlayerGui:FindFirstChild("TradeGUI")
                   if TradeGUI and TradeGUI.Visible then
                       for _, item in pairs(TradeGUI:GetDescendants()) do
                           if item:IsA("ImageButton") and item.Name == "Item" then
                               if not item:FindFirstChild("NexusValue") then
                                   local valTag = Instance.new("TextLabel", item)

                                                                                   valTag.Name = "NexusValue"
                                   valTag.Size = UDim2.new(1, 0, 0.25, 0) -- Alt kısım %25
                                   valTag.Position = UDim2.new(0, 0, 0.75, 0) -- En alta hizalı
                                   valTag.BackgroundTransparency = 0.3
                                   valTag.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                   valTag.TextColor3 = Color3.fromRGB(255, 255, 255)
                                   valTag.TextStrokeTransparency = 0
                                   valTag.TextScaled = true
                                   valTag.Font = Enum.Font.GothamBold
                                   valTag.ZIndex = 10
                                   valTag.Text = "..."
                               end
                               
                               -- Rarity (Nadirlik) Kontrolü ve Renklendirme
                               if item:FindFirstChild("Rarity") or item:FindFirstChild("Valuable") then 
                                    item.NexusValue.Text = "Rare/Godly" 
                                    item.NexusValue.TextColor3 = Color3.fromRGB(255, 215, 0) -- Altın Rengi
                               else 
                                    item.NexusValue.Text = "Normal"
                                    item.NexusValue.TextColor3 = Color3.fromRGB(255, 255, 255) -- Beyaz
                               end
                           end
                       end
                   end
               end)
           end
       end)
   end,
})

-- // TAB 5: AUTOMATION (Utility) //
local TabAuto = Window:CreateTab("Utility", 4483362458)

TabAuto:CreateToggle({
    Name = "Chat Spy",
    Callback = function(Value) 
        Settings.Farm.ChatSpy = Value 
        if Value then
            Rayfield:Notify({Title = "Spy Active", Content = "Check F9 Console for hidden chats.", Duration = 3})
        end
    end,
})

-- Chat Spy Logic
local function OnChat(plr, msg) 
    if Settings.Farm.ChatSpy then 
        print("[NEXUS SPY] " .. plr.Name .. ": " .. msg) 
    end 
end
for _, p in pairs(Players:GetPlayers()) do p.Chatted:Connect(function(m) OnChat(p, m) end) end
Players.PlayerAdded:Connect(function(p) p.Chatted:Connect(function(m) OnChat(p, m) end) end)

TabAuto:CreateToggle({
    Name = "Instant Interact (Doors/Loots)",
    Callback = function(Value)
        Settings.Farm.InstantInteract = Value
        task.spawn(function()
            while Settings.Farm.InstantInteract and task.wait(1) do
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then 
                        v.HoldDuration = 0 
                    end
                end
            end
        end)
    end,
})

-- // TAB 6: MOVEMENT & WORLD //
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSection("Teleports")

TabMove:CreateButton({
   Name = "Teleport to Lobby",
   Callback = function()
       local Spawn = Workspace:FindFirstChild("SpawnLocation", true)
       if Spawn then 
           LocalPlayer.Character.HumanoidRootPart.CFrame = Spawn.CFrame * CFrame.new(0, 3, 0) 
       else
           Rayfield:Notify({Title = "Error", Content = "Lobby Spawn not found!", Duration = 3})
       end
   end,
})

TabMove:CreateButton({
   Name = "Teleport to Map",
   Callback = function()
       local Map = Workspace:FindFirstChild("Normal", true) or Workspace:FindFirstChild("Map", true)
       if Map then
           -- Haritanın içinden rastgele güvenli bir parça bul
           for _, p in pairs(Map:GetChildren()) do
               if p:IsA("BasePart") then 
                   LocalPlayer.Character.HumanoidRootPart.CFrame = p.CFrame * CFrame.new(0, 5, 0) 
                   break 
               end
           end
       else
            Rayfield:Notify({Title = "System", Content = "Game hasn't started yet.", Duration = 3})
       end
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
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then 
           LocalPlayer.Character.Humanoid.WalkSpeed = Value 
       end 
   end,
})

TabMove:CreateToggle({
    Name = "Noclip",
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
    Callback = function(Value)
        Settings.Movement.XRay = Value
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then 
                -- Eğer XRay açıksa ve parça opaksa (0), yarı saydam yap (0.5)
                -- Eğer XRay kapalıysa ve parça yarı saydamsa (0.5), eski haline getir (0)
                v.Transparency = (Settings.Movement.XRay and (v.Transparency == 0 and 0.5 or v.Transparency) or (v.Transparency == 0.5 and 0 or v.Transparency)) 
            end
        end
    end,
})

-- // TAB 7: OPTIMIZATION //
local TabOpt = Window:CreateTab("Optimization", 4483362458)

TabOpt:CreateButton({
   Name = "Run Titanium Optimizer Gen2 AI",
   Callback = function()
       SafeCall(function() 
           loadstring(game:HttpGet("https://raw.githubusercontent.com/Nenecosturan/Titanium-Optimizer-Gen2-AI/refs/heads/main/Main.lua"))() 
       end)
       Rayfield:Notify({Title = "Titanium Optimizer", Content = "Optimization script executed.", Duration = 3})
   end,
})

TabOpt:CreateButton({
   Name = "Memory Cleaner (GC)",
   Callback = function() 
       collectgarbage("collect")
       Rayfield:Notify({Title = "System", Content = "Memory Cleaned (Garbage Collected).", Duration = 3}) 
   end,
})

-- // INITIALIZATION //
Rayfield:Notify({
   Title = "Nexus v3.0 Loaded",
   Content = "Mole Farm & All Systems Ready.",
   Duration = 5,
   Image = 4483362458,
})

-- Karakter öldüğünde hız ayarını koruma
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = Settings.Movement.Speed
end)
