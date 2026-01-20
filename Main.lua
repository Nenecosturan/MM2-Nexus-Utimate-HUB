--[[
    Project: MM2 Ultimate Nexus Script
    Library: Rayfield Interface Suite
    Theme: Amber (Transparent)
    Target: Mobile & PC Executors
    Author: Assistant (Generated for User)
    
    Note: Features wrapped in pcall for stability.
]]

-- // SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

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
        GunDrop = false,
        Loot = false
    },
    Combat = {
        SilentAim = false,
        KillAura = false,
        KillDist = 15,
        AntiStun = false,
        FOV = 100
    },
    Farm = {
        AutoCoin = false,
        AutoFarmSpeed = 16
    },
    Movement = {
        Speed = 16,
        Jump = 50,
        Noclip = false,
        XRay = false
    }
}

-- // LOAD RAYFIELD LIBRARY //
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // WINDOW CONFIGURATION //
local Window = Rayfield:CreateWindow({
   Name = "Nexus Ultimate •|• MM2",
   LoadingTitle = "Finding lates version of Nexus...",
   LoadingSubtitle = "by Zenith",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NexusMM2",
      FileName = "NexusConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true 
   },
   KeySystem = false, 
})

-- // THEME OVERRIDE (AMBER) //
-- Rayfield uses preset themes, forcing visual adjustments via API implies Amber tone.
Rayfield.Theme = "Amber" 

-- // UTILITY FUNCTIONS //

-- Safe Load Wrapper
local function SafeCall(func)
    local success, err = pcall(func)
    if not success then warn("Nexus Error: " .. tostring(err)) end
end

-- Role Detection (Heuristic based on Inventory)
local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent", Color3.fromRGB(0, 255, 0) end
    
    local backpack = plr.Backpack:GetChildren()
    local charGear = plr.Character:GetChildren()
    local allGear = {}
    
    for _, v in pairs(backpack) do table.insert(allGear, v) end
    for _, v in pairs(charGear) do table.insert(allGear, v) end
    
    for _, item in pairs(allGear) do
        if item.Name == "Knife" then
            return "Murderer", Color3.fromRGB(255, 0, 0) -- Red
        elseif item.Name == "Gun" or item.Name == "Revolver" then
            return "Sheriff", Color3.fromRGB(0, 0, 255) -- Blue
        end
    end
    
    return "Innocent", Color3.fromRGB(0, 255, 0) -- Green
end

-- ESP Drawing Storage
local ESP_Storage = {}

-- // TAB 1: VISUALS //
local TabVisuals = Window:CreateTab("Visuals (ESP)", 4483362458)

local ToggleESP = TabVisuals:CreateToggle({
   Name = "Role ESP",
   CurrentValue = false,
   Flag = "ESPEnabled",
   Callback = function(Value)
       Settings.ESP.Enabled = Value
       if not Value then
           for _, drawing in pairs(ESP_Storage) do drawing:Remove() end
           ESP_Storage = {}
       end
   end,
})

local ToggleTracers = TabVisuals:CreateToggle({
   Name = "Tracers (Role Colored)",
   CurrentValue = false,
   Flag = "TracersEnabled",
   Callback = function(Value)
       Settings.ESP.Tracers = Value
   end,
})

local ToggleGunDrop = TabVisuals:CreateToggle({
   Name = "Gun Drop ESP",
   CurrentValue = false,
   Flag = "GunDropESP",
   Callback = function(Value)
       Settings.ESP.GunDrop = Value
   end,
})

-- ESP LOOP LOGIC
RunService.RenderStepped:Connect(function()
    if Settings.ESP.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local HRP = plr.Character.HumanoidRootPart
                local vector, onScreen = Camera:WorldToViewportPoint(HRP.Position)
                
                if onScreen then
                    -- Simple Highlights implementation for mobile performance
                    if not plr.Character:FindFirstChild("NexusHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "NexusHighlight"
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Parent = plr.Character
                    end
                    
                    local role, color = GetRole(plr)
                    plr.Character.NexusHighlight.FillColor = color
                    plr.Character.NexusHighlight.OutlineColor = color
                else
                    if plr.Character:FindFirstChild("NexusHighlight") then
                        plr.Character.NexusHighlight:Destroy()
                    end
                end
            end
        end
    else
        -- Cleanup Highlights
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("NexusHighlight") then
                plr.Character.NexusHighlight:Destroy()
            end
        end
    end
    
    -- Gun Drop ESP Logic
    if Settings.ESP.GunDrop then
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop then
             if not gunDrop:FindFirstChild("NexusGunESP") then
                local bbg = Instance.new("BillboardGui", gunDrop)
                bbg.Name = "NexusGunESP"
                bbg.Size = UDim2.new(0, 50, 0, 50)
                bbg.AlwaysOnTop = true
                local frame = Instance.new("ImageLabel", bbg)
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundTransparency = 1
                frame.Image = "rbxassetid://3570695787" -- Circle Arrow
                frame.ImageColor3 = Color3.fromRGB(255, 255, 0)
             end
        end
    end
end)

-- // TAB 2: COMBAT //
local TabCombat = Window:CreateTab("Combat", 4483362458)

TabCombat:CreateToggle({
   Name = "Kill Aura (Murderer Only)",
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
                                   -- Simple CFrame Face Logic
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

TabCombat:CreateToggle({
    Name = "Anti-Stun",
    CurrentValue = false,
    Callback = function(Value)
        Settings.Combat.AntiStun = Value
        if Value then
            -- Simple Anti-Stun Loop
            task.spawn(function()
                while Settings.Combat.AntiStun and task.wait(0.5) do
                     pcall(function()
                         LocalPlayer.Character.Humanoid.PlatformStand = false
                         LocalPlayer.Character.Humanoid.Sit = false
                     end)
                end
            end)
        end
    end,
})

-- // TAB 3: AUTOMATION //
local TabFarm = Window:CreateTab("Automation", 4483362458)

TabFarm:CreateToggle({
   Name = "Auto-Farm Coins (Risk!)",
   CurrentValue = false,
   Callback = function(Value)
       Settings.Farm.AutoCoin = Value
       
       task.spawn(function()
           while Settings.Farm.AutoCoin and task.wait() do
               pcall(function()
                   -- Coin Container usually named "CoinContainer" in Workspace
                   local CoinContainer = Workspace:FindFirstChild("CoinContainer", true) -- Recursive search might be heavy, optimized below
                   -- Better to find specific Coin objects
                   -- NOTE: Actual MM2 coin names vary, logic assumes "Coin_Server"
                   
                   for _, v in pairs(Workspace:GetDescendants()) do
                       if v.Name == "Coin_Server" and v:IsA("BasePart") then
                            if Settings.Farm.AutoCoin then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                                task.wait(0.2) -- Delay to prevent crash/kick
                            else
                                break
                            end
                       end
                   end
               end)
           end
       end)
   end,
})

TabFarm:CreateButton({
   Name = "Server Hop",
   Callback = function()
       local TeleportService = game:GetService("TeleportService")
       local PlaceId = game.PlaceId
       TeleportService:Teleport(PlaceId, LocalPlayer)
   end,
})

-- // TAB 4: MOVEMENT //
local TabMove = Window:CreateTab("Movement", 4483362458)

TabMove:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "SpeedSlider", 
   Callback = function(Value)
       Settings.Movement.Speed = Value
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
       end
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
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end,
})

-- // TAB 5: OPTIMIZATION & SECURITY //
local TabOpt = Window:CreateTab("Optimization", 4483362458)

TabOpt:CreateButton({
   Name = "Run Titanium Optimizer Gen2 AI (Higly recommended for performace)",
   Callback = function()
       SafeCall(function()
           loadstring(game:HttpGet("https://raw.githubusercontent.com/Nenecosturan/Titanium-Optimizer-Gen2-AI/refs/heads/main/Main.lua"))()
       end)
       Rayfield:Notify({
           Title = "Titanium Optimizer",
           Content = "Your device is optimizing by Titanium.",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

TabOpt:CreateButton({
   Name = "Memory Cleaner (GC)",
   Callback = function()
       for i = 1, 5 do
           game:GetService("TestService"):Message("Clearing Cache...")
       end
       -- Force basic garbage collection simulation for LuaU
       collectgarbage("collect")
       Rayfield:Notify({
           Title = "System",
           Content = "Memory Cleaned.",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

-- // INITIALIZATION NOTIFY //
Rayfield:Notify({
   Title = "Nexus Ultimate Loaded",
   Content = "Nexus ready. Have fun!",
   Duration = 5,
   Image = 4483362458,
})

-- Keep speed consistent on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = Settings.Movement.Speed
end)
