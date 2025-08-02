                                cfg.set_visible(false)
                            end
                        end
                    end)
                --

                config_flags[cfg.flag] = cfg.set
                cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})

                return setmetatable(cfg, library)
            end

            function library:button(options) 
                local cfg = {
                    name = options.name or "button",
                    callback = options.callback or function() end,
                }
                
                -- Instances 
                    local frame = library:create("TextButton", {
                        AnchorPoint = vec2(1, 0);
                        Text = "";
                        AutoButtonColor = false;
                        Parent = self.elements;
                        Position = dim2(1, 0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 0, 16);
                        BorderSizePixel = 0;
                        BackgroundColor3 = self.color
                    }); library:apply_theme(frame, tostring(self.count), "BackgroundColor3")
                    
                    local frame_inline = library:create("Frame", {
                        Parent = frame;
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = themes.preset.inline
                    }); library:apply_theme(frame_inline, "inline", "BackgroundColor3")
                    
                    local text = library:create("TextLabel", {
                        FontFace = fonts["ProggyClean"];
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = cfg.name;
                        Parent = frame;
                        Size = dim2(1, 0, 1, 0);
                        BackgroundTransparency = 1;
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.X;
                        TextSize = 12;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                -- 

                -- Connections 
                    frame.MouseButton1Click:Connect(function()
                        cfg.callback()
                    end)
                --
                
                return setmetatable(cfg, library)
            end 
        -- 
    -- 
-- 

if not writefile then notifications:create_notification({name = "Your exploit does not support writefile()"}) return end
if not isfile then notifications:create_notification({name = "Your exploit does not support isfile()"}) return end
if not delfile then notifications:create_notification({name = "Your exploit does not support delfile()"}) return end
if not makefolder then notifications:create_notification({name = "Your exploit does not support makefolder()"}) return end
if not isfolder then notifications:create_notification({name = "Your exploit does not support isfolder()"}) return end
if not delfolder then notifications:create_notification({name = "Your exploit does not support delfolder()"}) return end
if not Drawing then notifications:create_notification({name = "Your exploit does not support the library Drawing"}) return end
if not getgenv then notifications:create_notification({name = "Your exploit does not support getgenv()"}) return end
if not hookmetamethod then notifications:create_notification({name = "Your exploit does not support hookmetamethod"}) return end
if writefile and isfile and delfile and makefolder and isfolder and delfolder and Drawing and getgenv and hookmetamethod then notifications:create_notification({name = "Exploit check succefully"})end
if not hookmetamethod then notifications:create_notification({name = "Wait until script updated yo mouse aimbot!"})end

local window = library:window({
	name = "YoxanXHub",
})

notifications:create_notification({name = "loading menu..."})
local esp, esp_renderstep, framework = loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/ESP-Library/refs/heads/main/nomercy.rip/source.lua"))()

esp.Overrides.Get_Tool = function(Player)
    local Character = esp:Get_Character(Player)
    if Character then
        local Weapon1 = Character:GetAttribute("Weapon1") or "None"
        local Weapon2 = Character:GetAttribute("Weapon2") or "None"
        return Weapon1 .. (Weapon2 ~= "None" and (" / " .. Weapon2) or "")
    end
    return "Hands"
end

esp.Overrides.Get_Team = function(Player)
    local TeamNumber = Player:GetAttribute("Team") or 0
    return TeamNumber
end

if esp then
    notifications:create_notification({name = "loading modules..."})
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Drawing = Drawing

local Config = {
    AimBone = "Head",           -- Кость для прицеливания ("Head", "HumanoidRootPart", и т.д.)
    AimBoneEnabled = true,      -- Включить/выключить прицеливание по кости
    UseFOV = true,              -- Включить/выключить использование FOV круга
    FOVSize = 200,              -- Размер FOV круга
    ShowFOV = true,             -- Показывать FOV круг
    ShowTargetLine = true,      -- Показывать линию от центра к цели
    fovcolor = Color3.new(1, 0, 0),
    linecolor = Color3.new(0, 1, 0),
    TeamCheck = true,           -- Проверять команду (не целиться в союзников)
    VisibilityCheck = true,     -- Проверять видимость цели (не стрелять через стены)
}

local SilentAim = {
    Target = nil,
    IsTargeting = false,
    Enabled = true,
    FOV = Config.FOVSize
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Config.ShowFOV
FOVCircle.Color = Config.fovcolor
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Radius = Config.FOVSize
FOVCircle.Transparency = 0.5
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- Target Line
local TargetLine = Drawing.new("Line")
TargetLine.Visible = Config.ShowTargetLine
TargetLine.Color = Config.linecolor
TargetLine.Thickness = 2

-- Проверка видимости (Raycast)
local function IsVisible(targetPart)
    if not Config.VisibilityCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        return hitPart:IsDescendantOf(targetPart.Parent)
    end
    
    return true
end

-- Проверка команды (Team Check)
local function IsEnemy(player)
    if not Config.TeamCheck then return true end
    
    -- Если команда хранится в атрибуте "Team" (1, 2, 3...)
    local localTeam = LocalPlayer:GetAttribute("Team")
    local targetTeam = player:GetAttribute("Team")
    
    -- Если команды разные → враг
    return localTeam ~= targetTeam
end

-- Конвертация 3D → 2D
local function WorldToScreen(pos)
    local viewportPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(viewportPos.X, viewportPos.Y), onScreen
end

-- Поиск ближайшей цели
local function GetClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closestTarget = nil
    local shortestDistance = SilentAim.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Config.AimBone) then
            if not IsEnemy(player) then continue end -- Пропускаем союзников
            
            local bone = player.Character:FindFirstChild(Config.AimBone)
            local screenPos, onScreen = WorldToScreen(bone.Position)
            
            if onScreen and IsVisible(bone) then
                local dist = (mousePos - screenPos).Magnitude
                if Config.UseFOV and dist < shortestDistance then
                    shortestDistance = dist
                    closestTarget = bone
                elseif not Config.UseFOV then
                    closestTarget = bone
                    break
                end
            end
        end
    end

    -- Если есть мобы (NPC)
    if Workspace:FindFirstChild("Mobs") then
        for _, mob in pairs(Workspace.Mobs:GetChildren()) do
            if mob:FindFirstChild(Config.AimBone) then
                local bone = mob:FindFirstChild(Config.AimBone)
                local screenPos, onScreen = WorldToScreen(bone.Position)
                
                if onScreen and IsVisible(bone) then
                    local dist = (mousePos - screenPos).Magnitude
                    if Config.UseFOV and dist < shortestDistance then
                        shortestDistance = dist
                        closestTarget = bone
                    elseif not Config.UseFOV then
                        closestTarget = bone
                        break
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Обновление FOV и поиск цели
RunService.RenderStepped:Connect(function()
    if not SilentAim.Enabled then
        SilentAim.Target = nil
        SilentAim.IsTargeting = false
        FOVCircle.Visible = false
        TargetLine.Visible = false
        return
    end

    FOVCircle.Visible = Config.ShowFOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = Config.FOVSize
    SilentAim.FOV = Config.FOVSize

    local target = nil
    if Config.AimBoneEnabled then
        target = GetClosestTarget()
    end
    SilentAim.Target = target
    SilentAim.IsTargeting = target ~= nil

    if SilentAim.IsTargeting and Config.ShowTargetLine then
        local targetScreenPos, onScreen = WorldToScreen(target.Position)
        if onScreen then
            TargetLine.Visible = true
            TargetLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            TargetLine.To = targetScreenPos
        else
            TargetLine.Visible = false
        end
    else
        TargetLine.Visible = false
    end
end)

-- Хук для Raycast (Silent Aim)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and self == Workspace and method == "Raycast" and SilentAim.IsTargeting and SilentAim.Target then
        local origin = args[1]
        local targetPos = SilentAim.Target.Position

        local direction = (targetPos - origin).Unit * 1000
        args[2] = direction

        return oldNamecall(self, unpack(args))
    end

    return oldNamecall(self, ...)
end)


esp.Settings.Enabled = false
esp.Settings.Bold_Text = false
esp.Settings.Team_Check = false
esp.Settings.Improved_Visible_Check = false
esp.Settings.Maximal_Distance = 500

esp.Settings.Box.Enabled = false
esp.Settings.Box.Color = Color3.fromRGB(1, 1, 1)
esp.Settings.Box.Transparency = 0.5

esp.Settings.Box_Outline.Enabled = false
esp.Settings.Box_Outline.Color = Color3.fromRGB(0, 0, 0)
esp.Settings.Box_Outline.Transparency = 0.3
esp.Settings.Box_Outline.Outline_Size = 2

esp.Settings.Name.Enabled = false
esp.Settings.Name.Color = Color3.fromRGB(1, 1, 1)
esp.Settings.Name.Position = "Bottom"

esp.Settings.Distance.Enabled = false
esp.Settings.Distance.Color = Color3.fromRGB(255, 255, 255)
esp.Settings.Distance.Position = "Bottom"

esp.Settings.Healthbar.Enabled = false
esp.Settings.Healthbar.Position = "Left"
esp.Settings.Healthbar.Color = Color3.fromRGB(0, 0, 0)
esp.Settings.Healthbar.Color_Lerp = Color3.fromRGB(255, 0, 0)

esp.Settings.Chams.Enabled = false
esp.Settings.Chams.Color = Color3.fromRGB(1, 1, 1)
esp.Settings.Chams.Mode = "Visible"
esp.Settings.Chams.Transparency = 0.25
esp.Settings.Chams.OutlineTransparency = 0.5

esp.Settings.Tool.Enabled = false
esp.Settings.Tool.Position = "Top"
esp.Settings.Tool.Color = Color3.fromRGB(255, 165, 0)

local aimTab = window:tab({name = "aimbot"})
local silent0 = aimTab:column({})
local silent1 = aimTab:column({})
local silentSec0 = silent0:section({name = "Silent Global", size = 1})
local silentSec1 = silent1:section({name = "Silent Settings", size = 1})

local visualsTab = window:tab({name = "visuals"})
local column0 = visualsTab:column({})
local column1 = visualsTab:column({})
local column2 = visualsTab:column({})
local visualsSection = column0:section({name = "ESP Global", size = 1})
local visualsColorSection = column1:section({name = "ESP Color", size = 1})
local visualsPosSection = column2:section({name = "ESP Position", size = 1})

local miscTab = window:tab({name = "misc"})
local misccol0 = miscTab:column({})
local miscSec0 = misccol0:section({name = "Misc Settings", size = 1})

local Lighting = game:GetService("Lighting")

local FullBright = {}
FullBright.Enabled = false

-- Сохраняем оригинальные параметры освещения
local Original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

-- Применение фуллбрайта
function FullBright:Enable()
    if self.Enabled then return end
    self.Enabled = true

    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1, 1, 1)
end

-- Отключение фуллбрайта и возврат к оригиналу
function FullBright:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    Lighting.Brightness = Original.Brightness
    Lighting.ClockTime = Original.ClockTime
    Lighting.FogEnd = Original.FogEnd
    Lighting.GlobalShadows = Original.GlobalShadows
    Lighting.Ambient = Original.Ambient
end

function FullBright:Toggle(state)
    if state then
        self:Enable()
    else
        self:Disable()
    end
end

miscSec0:toggle({
    name = "Full Bright",
    flag = "full_bright",
    state = false,
    callback = function(state)
        FullBright:Toggle(state)
    end
})

local Camera = workspace.CurrentCamera

local OriginalCFrame = Camera.CFrame
local resconfig = {
	Resolution = 1
}

local Workspace = game:GetService("Workspace")

local FPSBoost = {}
FPSBoost.Enabled = false
FPSBoost.OriginalMaterials = {}

function FPSBoost:Enable()
    if self.Enabled then return end
    self.Enabled = true

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            self.OriginalMaterials[obj] = {
                Material = obj.Material,
                Reflectance = obj.Reflectance
            }
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        end
    end
end

function FPSBoost:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    for obj, data in pairs(self.OriginalMaterials) do
        if obj and obj.Parent then
            obj.Material = data.Material
            obj.Reflectance = data.Reflectance
        end
    end

    self.OriginalMaterials = {}
end

function FPSBoost:Toggle(state)
    if state then
        self:Enable()
    else
        self:Disable()
    end
end

miscSec0:toggle({
    name = "FPS Boost",
    flag = "fps_boost",
    state = false,
    callback = function(state)
        FPSBoost:Toggle(state)
    end,
})

miscSec0:slider({
	name = "Aspect Ratio",
	min = 0.1,
	max = 1.2,
	default = 1.0,
	interval = 0.01,
	flag = "res_scale",
	callback = function(value)
		resconfig.Resolution = value
	end,
})

local Camera = workspace.CurrentCamera

game:GetService("RunService").RenderStepped:Connect(function()
    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, resconfig.Resolution, 0, 0, 0, 1)
end)

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Chams = {
    Arms = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Material = Enum.Material.ForceField
    },
    Weapon = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 255),
        Material = Enum.Material.Neon
    }
}

local function applyChams(part, color, material)
    if part:IsA("BasePart") then
        part.Color = color
        part.Material = material
        part.Reflectance = 0
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("Texture") or child:IsA("Decal") then
                child:Destroy()
            end
        end
    end
end

local function updateArmsChams()
    if not Chams.Arms.Enabled then return end

    local arms = Workspace:FindFirstChild("IgnoreThese") and Workspace.IgnoreThese:FindFirstChild("MyArms")
    if not arms then return end

    local blockArms = arms:FindFirstChild("BlockArms")
    if blockArms then
        local left = blockArms:FindFirstChild("Left Arm")
        local right = blockArms:FindFirstChild("Right Arm")

        if left then applyChams(left, Chams.Arms.Color, Chams.Arms.Material) end
        if right then applyChams(right, Chams.Arms.Color, Chams.Arms.Material) end
    end
end

local function updateWeaponChams()
    if not Chams.Weapon.Enabled then return end

    local arms = Workspace:FindFirstChild("IgnoreThese") and Workspace.IgnoreThese:FindFirstChild("MyArms")
    if not arms then return end

    local wmodel = arms:FindFirstChild("WModel")
    if wmodel then
        for _, obj in ipairs(wmodel:GetDescendants()) do
            applyChams(obj, Chams.Weapon.Color, Chams.Weapon.Material)
        end
    end
end

-- автообновление при смене оружия
RunService.RenderStepped:Connect(function()
    if Chams.Arms.Enabled then updateArmsChams() end
    if Chams.Weapon.Enabled then updateWeaponChams() end
end)

-- ARMS TOGGLE
miscSec0:toggle({
    name = "Chams (Arms)",
    flag = "chams_arms",
    state = false,
    callback = function(state)
        Chams.Arms.Enabled = state
    end
})

-- ARMS COLOR
miscSec0:colorpicker({
    name = "Arms Color",
    flag = "chams_arms_color",
    color = Chams.Arms.Color,
    callback = function(newColor)
        Chams.Arms.Color = newColor
    end
})

-- ARMS MATERIAL
miscSec0:dropdown({
    name = "Arms Material",
    flag = "chams_arms_material",
    default = tostring(Chams.Arms.Material.Name),
    items = {"Plastic", "SmoothPlastic", "Neon", "ForceField", "Glass"},
    callback = function(selected)
        Chams.Arms.Material = Enum.Material[selected]
    end
})

-- WEAPON TOGGLE
miscSec0:toggle({
    name = "Chams (Weapon)",
    flag = "chams_weapon",
    state = false,
    callback = function(state)
        Chams.Weapon.Enabled = state
    end
})

-- WEAPON COLOR
miscSec0:colorpicker({
    name = "Weapon Color",
    flag = "chams_weapon_color",
    color = Chams.Weapon.Color,
    callback = function(newColor)
        Chams.Weapon.Color = newColor
    end
})

-- WEAPON MATERIAL
miscSec0:dropdown({
    name = "Weapon Material",
    flag = "chams_weapon_material",
    default = tostring(Chams.Weapon.Material.Name),
    items = {"Plastic", "SmoothPlastic", "Neon", "ForceField", "Glass"},
    callback = function(selected)
        Chams.Weapon.Material = Enum.Material[selected]
    end
})

silentSec0:toggle({name = "Silent Aim", flag = "silentaim", state = SilentAim.Enabled, callback = function(state)
    SilentAim.Enabled = state
end})

silentSec0:slider({
	name = "FOV Size",
	min = 1,
	max = 500,
	default = 100,
	interval = 1,
	flag = "fovsize",
	callback = function(value)
		Config.FOVSize = value
	end,
})

silentSec0:dropdown({name = "Aimbone", flag = "aimbone", default = Config.AimBone, items = {"Head","LowerTorso","RightFoot"}, callback = function(text)
    Config.AimBone = text
end})

silentSec0:toggle({name = "Target Line", flag = "target_line", state = Config.ShowTargetLine, callback = function(state)
    Config.ShowTargetLine = state
end})

silentSec0:toggle({name = "Show FOV", flag = "show_fov", state = Config.ShowFOV, callback = function(state)
    Config.ShowFOV = state
end})
silentSec0:toggle({name = "Use FOV", flag = "use_fov", state = Config.UseFOV, callback = function(state)
    Config.UseFOV = state
end})
silentSec0:toggle({name = "Team Check", flag = "team_check", state = Config.TeamCheck, callback = function(state)
    Config.TeamCheck = state
end})
silentSec0:toggle({name = "Vis Check", flag = "vics_check", state = Config.VisibilityCheck, callback = function(state)
    Config.VisibilityCheck = state
end})

silentSec1:colorpicker({name = "FOV", flag = "fov_color", color = Config.fovcolor, callback = function(color)
    Config.fovcolor = color
end})

silentSec1:colorpicker({name = "Line", flag = "target_line_color", color = Config.linecolor, callback = function(color)
    Config.linecolor = color
end})




visualsSection:toggle({name = "ESP Enabled", flag = "esp_enabled", state = esp.Settings.Enabled, callback = function(state)
    esp.Settings.Enabled = state
end})

visualsSection:toggle({name = "Team Check", flag = "team_check", state = esp.Settings.Team_Check, callback = function(state)
    esp.Settings.Team_Check = state
end})

visualsSection:toggle({name = "Bold Text", flag = "bold_text", state = esp.Settings.Bold_Text, callback = function(state)
    esp.Settings.Bold_Text = state
end})

visualsSection:toggle({name = "Box Enabled", flag = "box_enabled", state = esp.Settings.Box.Enabled, callback = function(state)
    esp.Settings.Box.Enabled = state
end})

visualsColorSection:colorpicker({name = "Box", flag = "box_color", color = color(1, 1, 1), callback = function(color)
    esp.Settings.Box.Color = color
end})

visualsSection:toggle({name = "Box Outline", flag = "box_outline_enabled", state = esp.Settings.Box_Outline.Enabled, callback = function(state)
    esp.Settings.Box_Outline.Enabled = state
end})

visualsColorSection:colorpicker({name = "Box Outline", flag = "box_outline_color", color = color(0, 0, 0), callback = function(color)
    esp.Settings.Box_Outline.Color = color
end})

visualsSection:toggle({name = "Show Name", flag = "name_enabled", state = esp.Settings.Name.Enabled, callback = function(state)
    esp.Settings.Name.Enabled = state
end})

visualsColorSection:colorpicker({name = "Name", flag = "name_color", color = color(1, 1, 1), callback = function(color)
    esp.Settings.Name.Color = color
end})

visualsPosSection:dropdown({name = "Name", flag = "name_position", default = esp.Settings.Name.Position, items = {"Top", "Bottom", "Left", "Right"}, callback = function(text)
    esp.Settings.Name.Position = text
end})

visualsSection:toggle({name = "Show Weapon", flag = "weapon_enabled", state = esp.Settings.Tool.Enabled, callback = function(state)
    esp.Settings.Tool.Enabled = state
end})

visualsColorSection:colorpicker({name = "Weapon", flag = "weapon_color", color = esp.Settings.Tool.Color, callback = function(color)
    esp.Settings.Tool.Color = color
end})

visualsPosSection:dropdown({name = "Weapon", flag = "weapon_position", default = esp.Settings.Tool.Position, items = {"Top", "Bottom", "Left", "Right"}, callback = function(text)
    esp.Settings.Tool.Position = text
end})

visualsSection:toggle({name = "Show Distance", flag = "distance_enabled", state = esp.Settings.Distance.Enabled, callback = function(state)
    esp.Settings.Distance.Enabled = state
end})

visualsColorSection:colorpicker({name = "Distance", flag = "distance_color", color = color(1, 1, 1), callback = function(color)
    esp.Settings.Distance.Color = color
end})

visualsPosSection:dropdown({name = "Distance", flag = "distance_position", default = esp.Settings.Distance.Position, items = {"Top", "Bottom", "Left", "Right"}, callback = function(text)
    esp.Settings.Distance.Position = text
end})

visualsSection:toggle({name = "Healthbar", flag = "healthbar_enabled", state = esp.Settings.Healthbar.Enabled, callback = function(state)
    esp.Settings.Healthbar.Enabled = state
end})

visualsPosSection:dropdown({name = "Healthbar", flag = "healthbar_position", default = esp.Settings.Healthbar.Position, items = {"Left", "Right"}, callback = function(text)
    esp.Settings.Healthbar.Position = text
end})

visualsSection:toggle({name = "Health Lerp", flag = "health_color_lerp", state = false, callback = function(state)
    esp.Settings.Healthbar.Color_Lerp_Enabled = state
end})

visualsColorSection:colorpicker({name = "Health Lerp", flag = "health_lerp_color", color = color(1, 0, 0), callback = function(color)
    esp.Settings.Healthbar.Color_Lerp = color
end})

visualsColorSection:colorpicker({name = "Healthbar", flag = "health_bar_color", color = color(0, 0, 0), callback = function(color)
    esp.Settings.Healthbar.Color_Lerp = color
end})

visualsSection:toggle({name = "Chams", flag = "chams_enabled", state = esp.Settings.Chams.Enabled, callback = function(state)
    esp.Settings.Chams.Enabled = state
end})

visualsColorSection:colorpicker({name = "Chams", flag = "chams_color", color = esp.Settings.Chams.Color, callback = function(color)
    esp.Settings.Chams.Color = color
end})

visualsPosSection:dropdown({name = "Chams Mode", flag = "chams_mode", default = esp.Settings.Chams.Mode, items = {"Visible", "Always", "Hidden"}, callback = function(text)
    esp.Settings.Chams.Mode = text
end})

visualsSection:toggle({name = "Chams Outline", flag = "chams_outline_enabled", state = esp.Settings.Chams.OutlineTransparency > 0, callback = function(state)
    esp.Settings.Chams.OutlineTransparency = state and 0.5 or 0
end})

local Settings = window:tab({ name = "Settings" })

-- -- Configs
local column = Settings:column({ fill = true })
local general = column:section({ name = "Configs" })

config_holder = general:list({ name = "Configs", flag = "config_name_list", scale = 100 })

general:textbox({ name = "Config Name", default = "", flag = "config_name_text_box" })

general:button({
	name = "Create",
	callback = function()
		if flags["config_name_text_box"] == "" then
			return
		end

		writefile(library.directory .. "/configs/" .. flags["config_name_text_box"] .. ".cfg", library:get_config())

		library:update_config_list()
	end,
})

general:button({
	name = "Delete",
	callback = function()
		delfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg")
		library:update_config_list()
	end,
})

general:button({
	name = "Load",
	callback = function()
		print(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg")
		library:load_config(readfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg"))
	end,
})
general:button({
	name = "Save",
	callback = function()
		writefile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg", library:get_config())
		library:update_config_list()
	end,
})

general:button({
	name = "Refresh configs",
	callback = function()
		library:update_config_list()
	end,
})
library:update_config_list()

-- Игроки и боты

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        esp:Player(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        esp:Player(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local obj = esp:GetObject(player)
    if obj then
        obj:Destroy()
    end
end)

local addedBots = {}

RunService.Heartbeat:Connect(function()
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if mobsFolder then
        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and not addedBots[mob] then
                addedBots[mob] = true

                local fakePlayer = {
                    Name = mob.Name,
                    Character = mob,
                    GetAttribute = function() return nil end,
                    IsA = function(_, className) return className == "Player" end,
                    Parent = game
                }

                esp:Player(fakePlayer, {
                    Color = Color3.fromRGB(255, 50, 50),
                    Transparency = 1,
                    Outline = true
                })

                mob.AncestryChanged:Connect(function()
                    if not mob:IsDescendantOf(game) then
                        local obj = esp:GetObject(fakePlayer)
                        if obj then
                            obj:Destroy()
                        end
                        addedBots[mob] = nil
                    end
                end)
            end
        end
    end
end)

if getgenv().loaded then
    notifications:create_notification({name = "loaded cheat true"})
end
