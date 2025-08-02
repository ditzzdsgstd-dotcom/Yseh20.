-- // Load OrionLib Nightmare
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()

local Window = OrionLib:MakeWindow({
	Name = "YoxanXHub - Hypershot Gunfight",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "YoxanXHub"
})

-- // Global Variables
getgenv().SilentAim = false
getgenv().UseFOV = false
getgenv().ShowFOV = false
getgenv().TeamCheck = false
getgenv().VisCheck = false
getgenv().TargetLine = false
getgenv().FOVSize = 100

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // Drawing Circle (FOV)
local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1
FOV.NumSides = 64
FOV.Filled = false
FOV.Radius = getgenv().FOVSize
FOV.Visible = false

-- // Drawing Target Line
local TargetLine = Drawing.new("Line")
TargetLine.Visible = false
TargetLine.Color = Color3.fromRGB(255, 0, 0)
TargetLine.Thickness = 1

-- // Function: Get Closest Target
function GetClosestTarget()
	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if getgenv().TeamCheck and player.Team == LocalPlayer.Team then continue end

			local rootPart = player.Character.HumanoidRootPart
			local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
			if not onScreen then continue end

			local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

			if getgenv().UseFOV and distance > getgenv().FOVSize then continue end

			if getgenv().VisCheck then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
				rayParams.FilterType = Enum.RaycastFilterType.Blacklist
				local result = workspace:Raycast(Camera.CFrame.Position, (rootPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
				if result and result.Instance and not player.Character:IsAncestorOf(result.Instance) then
					continue
				end
			end

			if distance < shortestDistance then
				closestPlayer = player
				shortestDistance = distance
			end
		end
	end

	return closestPlayer
end

-- // Hook __namecall (Silent Aim)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
	local args = {...}
	local method = getnamecallmethod()
	if method == "FindPartOnRayWithIgnoreList" and getgenv().SilentAim then
		local target = GetClosestTarget()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local origin = Camera.CFrame.Position
			local direction = (target.Character.HumanoidRootPart.Position - origin).Unit * 1000
			local ray = Ray.new(origin, direction)
			return oldNamecall(self, ray, unpack(args, 2))
		end
	end
	return oldNamecall(self, ...)
end)

-- // FOV & Target Line Rendering
RunService.RenderStepped:Connect(function()
	FOV.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
	FOV.Radius = getgenv().FOVSize
	FOV.Visible = getgenv().ShowFOV

	if getgenv().TargetLine and getgenv().SilentAim then
		local target = GetClosestTarget()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local targetPos, visible = Camera:WorldToViewportPoint(target.Character.HumanoidRootPart.Position)
			if visible then
				TargetLine.Visible = true
				TargetLine.From = Vector2.new(Mouse.X, Mouse.Y + 36)
				TargetLine.To = Vector2.new(targetPos.X, targetPos.Y)
			else
				TargetLine.Visible = false
			end
		else
			TargetLine.Visible = false
		end
	else
		TargetLine.Visible = false
	end
end)

-- // Aimbot Tab (UI)
local AimbotTab = Window:MakeTab({
	Name = "Aimbot",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

AimbotTab:AddToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(v)
		getgenv().SilentAim = v
	end
})

AimbotTab:AddToggle({
	Name = "Use FOV",
	Default = false,
	Callback = function(v)
		getgenv().UseFOV = v
	end
})

AimbotTab:AddToggle({
	Name = "Show FOV",
	Default = false,
	Callback = function(v)
		getgenv().ShowFOV = v
	end
})

AimbotTab:AddSlider({
	Name = "FOV Size",
	Min = 30,
	Max = 500,
	Default = 100,
	Increment = 1,
	Callback = function(v)
		getgenv().FOVSize = v
	end
})

AimbotTab:AddToggle({
	Name = "Target Line",
	Default = false,
	Callback = function(v)
		getgenv().TargetLine = v
	end
})

AimbotTab:AddToggle({
	Name = "Team Check",
	Default = false,
	Callback = function(v)
		getgenv().TeamCheck = v
	end
})

AimbotTab:AddToggle({
	Name = "Visible Check",
	Default = false,
	Callback = function(v)
		getgenv().VisCheck = v
	end
})

OrionLib:MakeNotification({
	Name = "Silent Aim Loaded",
	Content = "Aimbot Tab is ready and functional.",
	Image = "rbxassetid://4483345998",
	Time = 3
})

-- // Global ESP Toggles
getgenv().ESP_Enabled = false
getgenv().ESP_Box = false
getgenv().ESP_Name = false
getgenv().ESP_Health = false
getgenv().ESP_Weapon = false
getgenv().ESP_Distance = false
getgenv().ESP_TeamCheck = false
getgenv().ESP_BoxOutline = false
getgenv().Chams_Enabled = false
getgenv().Chams_Color = Color3.fromRGB(255, 0, 0)

-- // Table to store drawings
local drawings = {}

local function clearESP()
	for _, obj in pairs(drawings) do
		for _, d in pairs(obj) do
			if d and d.Remove then
				d:Remove()
			end
		end
	end
	drawings = {}
end

-- // ESP Tab
local ESPTab = Window:MakeTab({
	Name = "ESP",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

ESPTab:AddToggle({Name = "ESP Enabled", Default = false, Callback = function(v)
	getgenv().ESP_Enabled = v
	if not v then clearESP() end
end})

ESPTab:AddToggle({Name = "Box", Default = false, Callback = function(v) getgenv().ESP_Box = v end})
ESPTab:AddToggle({Name = "Show Name", Default = false, Callback = function(v) getgenv().ESP_Name = v end})
ESPTab:AddToggle({Name = "Healthbar", Default = false, Callback = function(v) getgenv().ESP_Health = v end})
ESPTab:AddToggle({Name = "Weapon", Default = false, Callback = function(v) getgenv().ESP_Weapon = v end})
ESPTab:AddToggle({Name = "Distance", Default = false, Callback = function(v) getgenv().ESP_Distance = v end})
ESPTab:AddToggle({Name = "Team Check", Default = false, Callback = function(v) getgenv().ESP_TeamCheck = v end})
ESPTab:AddToggle({Name = "Box Outline", Default = false, Callback = function(v) getgenv().ESP_BoxOutline = v end})

-- // Chams Section
ESPTab:AddToggle({Name = "Chams (Body Glow)", Default = false, Callback = function(v) getgenv().Chams_Enabled = v end})
ESPTab:AddColorpicker({
	Name = "Chams Color",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(v) getgenv().Chams_Color = v
	end
})

-- // ESP Drawing Loop
game:GetService("RunService").RenderStepped:Connect(function()
	if not getgenv().ESP_Enabled then
		clearESP()
		return
	end

	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player == game.Players.LocalPlayer then continue end
		if getgenv().ESP_TeamCheck and player.Team == game.Players.LocalPlayer.Team then continue end

		local char = player.Character
		if not (char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head")) then continue end
		local hrp = char.HumanoidRootPart
		local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
		if not onScreen then continue end

		if not drawings[player] then
			drawings[player] = {
				box = Drawing.new("Square"),
				name = Drawing.new("Text"),
				health = Drawing.new("Line"),
				weapon = Drawing.new("Text"),
				distance = Drawing.new("Text")
			}
		end

		local box = drawings[player].box
		local name = drawings[player].name
		local health = drawings[player].health
		local weapon = drawings[player].weapon
		local distance = drawings[player].distance

		local topLeft = Vector2.new(screenPos.X - 30, screenPos.Y - 60)

		box.Visible = getgenv().ESP_Box
		box.Size = Vector2.new(60, 120)
		box.Position = topLeft
		box.Color = Color3.fromRGB(255, 255, 255)
		box.Thickness = 1
		box.Transparency = 1
		box.Filled = false

		name.Visible = getgenv().ESP_Name
		name.Text = player.Name
		name.Position = Vector2.new(screenPos.X - name.TextBounds.X / 2, screenPos.Y - 70)
		name.Color = Color3.fromRGB(255, 255, 255)
		name.Size = 13
		name.Center = true
		name.Outline = true

		weapon.Visible = getgenv().ESP_Weapon
		weapon.Text = "Weapon"
		weapon.Position = Vector2.new(screenPos.X, screenPos.Y + 65)
		weapon.Size = 13
		weapon.Color = Color3.fromRGB(255, 255, 0)
		weapon.Center = true
		weapon.Outline = true

		distance.Visible = getgenv().ESP_Distance
		local dist = math.floor((game.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
		distance.Text = tostring(dist) .. "m"
		distance.Position = Vector2.new(screenPos.X, screenPos.Y + 80)
		distance.Size = 12
		distance.Color = Color3.fromRGB(0, 255, 255)
		distance.Center = true
		distance.Outline = true

		health.Visible = getgenv().ESP_Health
		local hp = char:FindFirstChild("Humanoid") and char.Humanoid.Health or 100
		health.From = Vector2.new(topLeft.X - 5, topLeft.Y + 120)
		health.To = Vector2.new(topLeft.X - 5, topLeft.Y + 120 - (hp / 100) * 120)
		health.Color = Color3.fromRGB(0, 255, 0)
		health.Thickness = 2
	end

	-- // Chams Glow
	for _, player in pairs(game.Players:GetPlayers()) do
		if player == game.Players.LocalPlayer then continue end
		local char = player.Character
		if char and getgenv().Chams_Enabled then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Material = Enum.Material.ForceField
					part.Color = getgenv().Chams_Color
				end
			end
		end
	end
end)

-- // Visual Tab
local VisualTab = Window:MakeTab({
	Name = "Visual",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

-- // FullBright Toggle
local lighting = game:GetService("Lighting")
getgenv().FullBright = false

VisualTab:AddToggle({
	Name = "FullBright",
	Default = false,
	Callback = function(v)
		getgenv().FullBright = v
		if v then
			lighting.Brightness = 2
			lighting.ClockTime = 12
			lighting.FogEnd = 100000
			lighting.GlobalShadows = false
			lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		else
			lighting.GlobalShadows = true
			lighting.ClockTime = 14
			lighting.FogEnd = 1000
			lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
		end
	end
})

-- // FPS Boost Toggle
VisualTab:AddButton({
	Name = "FPS Boost",
	Callback = function()
		for _, v in pairs(game:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Plastic
				v.Reflectance = 0
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v:Destroy()
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
				v.Lifetime = NumberRange.new(0)
			end
		end
		lighting.Ambient = Color3.fromRGB(0, 0, 0)
		lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
		lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
		lighting.FogEnd = 9999999
		lighting.Brightness = 1
	end
})

-- // Charms Arms
getgenv().CharmsArms = false
VisualTab:AddToggle({
	Name = "Charms (Arms)",
	Default = false,
	Callback = function(v)
		getgenv().CharmsArms = v
	end
})

VisualTab:AddColorpicker({
	Name = "Arms Color",
	Default = Color3.fromRGB(0, 255, 255),
	Callback = function(val)
		getgenv().CharmsArmsColor = val
	end
})

VisualTab:AddDropdown({
	Name = "Arms Material",
	Default = "Neon",
	Options = {"Neon", "ForceField", "Plastic", "SmoothPlastic"},
	Callback = function(mat)
		getgenv().CharmsArmsMat = Enum.Material[mat]
	end
})

-- // Charms Weapon
getgenv().CharmsWeapon = false
VisualTab:AddToggle({
	Name = "Charms (Weapon)",
	Default = false,
	Callback = function(v)
		getgenv().CharmsWeapon = v
	end
})

VisualTab:AddColorpicker({
	Name = "Weapon Color",
	Default = Color3.fromRGB(255, 255, 0),
	Callback = function(val)
		getgenv().CharmsWeaponColor = val
	end
})

VisualTab:AddDropdown({
	Name = "Weapon Material",
	Default = "ForceField",
	Options = {"Neon", "ForceField", "Plastic", "SmoothPlastic"},
	Callback = function(mat)
		getgenv().CharmsWeaponMat = Enum.Material[mat]
	end
})

-- // Visual Loop
game:GetService("RunService").RenderStepped:Connect(function()
	local char = game.Players.LocalPlayer.Character
	if char then
		-- Arms Charms
		if getgenv().CharmsArms then
			for _, part in pairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name:lower():find("arm") then
					part.Material = getgenv().CharmsArmsMat or Enum.Material.Neon
					part.Color = getgenv().CharmsArmsColor or Color3.fromRGB(0, 255, 255)
				end
			end
		end

		-- Weapon Charms
		if getgenv().CharmsWeapon then
			for _, tool in pairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					for _, part in pairs(tool:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Material = getgenv().CharmsWeaponMat or Enum.Material.ForceField
							part.Color = getgenv().CharmsWeaponColor or Color3.fromRGB(255, 255, 0)
						end
					end
				end
			end
		end
	end
end)

-- // GunMods Tab
local GunTab = Window:MakeTab({
	Name = "GunMods",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

-- // Function: Edit Gun Module Values
local function PatchGun(tool)
	local gunMod = tool:FindFirstChild("GunSettings") or tool:FindFirstChild("Settings")
	if gunMod and gunMod:IsA("ModuleScript") then
		local data = require(gunMod)
		pcall(function()
			data.Ammo = math.huge
			data.StoredAmmo = math.huge
			data.TotalAmmo = math.huge
			data.ReloadTime = 0
			data.FireRate = 0.001
			data.Spread = 0
			data.Bloom = 0
			data.Recoil = 0
			data.KickUp = 0
			data.Auto = true
		end)
	end
end

-- // Apply patch to tools
local function PatchAllGuns()
	local plr = game.Players.LocalPlayer
	for _, tool in pairs(plr.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			PatchGun(tool)
		end
	end
	for _, tool in pairs(plr.Character:GetChildren()) do
		if tool:IsA("Tool") then
			PatchGun(tool)
		end
	end
end

-- // Infinite Ammo Button
GunTab:AddButton({
	Name = "Infinite Ammo",
	Callback = PatchAllGuns
})

-- // Instant Reload Button
GunTab:AddButton({
	Name = "Instant Reload",
	Callback = PatchAllGuns
})

-- // Fire Rate Slider (Optional)
GunTab:AddSlider({
	Name = "Set FireRate (Lower = Faster)",
	Min = 0.001,
	Max = 1,
	Default = 0.01,
	Increment = 0.001,
	Callback = function(rate)
		local plr = game.Players.LocalPlayer
		for _, tool in pairs(plr.Backpack:GetChildren()) do
			local gunMod = tool:FindFirstChild("GunSettings")
			if gunMod and gunMod:IsA("ModuleScript") then
				local data = require(gunMod)
				pcall(function()
					data.FireRate = rate
				end)
			end
		end
	end
})
