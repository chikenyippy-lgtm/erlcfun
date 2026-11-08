--[[
    ER:LC Script
    Rayfield UI
    Tabs: Player | Vehicle | Visuals | Misc
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Helpers
local function getChar()
	return LocalPlayer.Character
end

local function getHum()
	local char = getChar()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = getChar()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getVehicle()
	local char = getChar()
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart then
		local seat = hum.SeatPart
		return seat:FindFirstAncestorOfClass("Model") or seat.Parent
	end
	return nil
end

--// State
local States = {
	InfStamina = false,
	Speed = false,
	InfJump = false,
	Fly = false,
	Noclip = false,
	ESP = false,
	AntiAFK = false,
	CarFly = false,
	CarMods = false,
}

local Connections = {}
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ERLC_ESP"
ESPFolder.Parent = game:GetService("CoreGui")

local FlyBV, FlyBG = nil, nil
local CarFlyBV, CarFlyBG = nil, nil

local SpeedValue = 50
local HorsepowerValue = 500
local TopSpeedValue = 200

--// ========== PLAYER FEATURES ==========

local function setInfStamina(enabled)
	States.InfStamina = enabled
	if Connections.Stamina then Connections.Stamina:Disconnect() Connections.Stamina = nil end

	if enabled then
		Connections.Stamina = RunService.Heartbeat:Connect(function()
			local hum = getHum()
			if hum then
				pcall(function()
					if hum:GetAttribute("Stamina") then
						hum:SetAttribute("Stamina", 100)
					end
				end)
			end
		end)
	end
end

local function setSpeed(enabled)
	States.Speed = enabled
	local hum = getHum()
	if hum then
		hum.WalkSpeed = enabled and SpeedValue or 16
	end
end

local function setInfJump(enabled)
	States.InfJump = enabled
	if Connections.InfJump then Connections.InfJump:Disconnect() Connections.InfJump = nil end

	if enabled then
		Connections.InfJump = UserInputService.JumpRequest:Connect(function()
			local hum = getHum()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end

local function setFly(enabled)
	States.Fly = enabled
	if Connections.Fly then Connections.Fly:Disconnect() Connections.Fly = nil end
	if FlyBV then FlyBV:Destroy() FlyBV = nil end
	if FlyBG then FlyBG:Destroy() FlyBG = nil end

	local root = getRoot()
	if not root then return end

	if enabled then
		FlyBV = Instance.new("BodyVelocity")
		FlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		FlyBV.Velocity = Vector3.zero
		FlyBV.Parent = root

		FlyBG = Instance.new("BodyGyro")
		FlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		FlyBG.P = 9e4
		FlyBG.Parent = root

		Connections.Fly = RunService.RenderStepped:Connect(function()
			if not States.Fly or not root or not root.Parent then return end
			local dir = Vector3.zero
			local camCF = Camera.CFrame

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

			FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * 60 or Vector3.zero
			FlyBG.CFrame = camCF
		end)
	end
end

local function setNoclip(enabled)
	States.Noclip = enabled
	if Connections.Noclip then Connections.Noclip:Disconnect() Connections.Noclip = nil end

	if enabled then
		Connections.Noclip = RunService.Stepped:Connect(function()
			local char = getChar()
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end

--// ========== VEHICLE FEATURES ==========

local function setCarFly(enabled)
	States.CarFly = enabled
	if Connections.CarFly then Connections.CarFly:Disconnect() Connections.CarFly = nil end
	if CarFlyBV then CarFlyBV:Destroy() CarFlyBV = nil end
	if CarFlyBG then CarFlyBG:Destroy() CarFlyBG = nil end

	if not enabled then return end

	Connections.CarFly = RunService.RenderStepped:Connect(function()
		local vehicle = getVehicle()
		if not vehicle then return end

		local primary = vehicle.PrimaryPart or vehicle:FindFirstChild("Chassis") or vehicle:FindFirstChildWhichIsA("BasePart")
		if not primary then return end

		if not CarFlyBV or CarFlyBV.Parent ~= primary then
			if CarFlyBV then CarFlyBV:Destroy() end
			if CarFlyBG then CarFlyBG:Destroy() end

			CarFlyBV = Instance.new("BodyVelocity")
			CarFlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			CarFlyBV.Velocity = Vector3.zero
			CarFlyBV.Parent = primary

			CarFlyBG = Instance.new("BodyGyro")
			CarFlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			CarFlyBG.P = 9e4
			CarFlyBG.Parent = primary
		end

		local dir = Vector3.zero
		local camCF = Camera.CFrame

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

		CarFlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * 80 or Vector3.zero
		CarFlyBG.CFrame = camCF
	end)
end

local function applyCarMods()
	local vehicle = getVehicle()
	if not vehicle then return end

	-- Common places ER:LC and similar games store vehicle stats
	for _, obj in pairs(vehicle:GetDescendants()) do
		if obj:IsA("NumberValue") or obj:IsA("IntValue") then
			local name = string.lower(obj.Name)
			if name:find("horse") or name:find("power") or name:find("torque") then
				obj.Value = HorsepowerValue
			elseif name:find("topspeed") or name:find("maxspeed") or name:find("speed") then
				obj.Value = TopSpeedValue
			end
		elseif obj:IsA("BasePart") and (obj.Name == "Chassis" or obj.Name == "Body") then
			-- Fallback mild boost
		end
	end

	-- Also try attributes
	pcall(function()
		vehicle:SetAttribute("Horsepower", HorsepowerValue)
		vehicle:SetAttribute("TopSpeed", TopSpeedValue)
		vehicle:SetAttribute("MaxSpeed", TopSpeedValue)
	end)
end

local function setCarMods(enabled)
	States.CarMods = enabled
	if Connections.CarMods then Connections.CarMods:Disconnect() Connections.CarMods = nil end

	if enabled then
		Connections.CarMods = RunService.Heartbeat:Connect(function()
			applyCarMods()
		end)
	end
end

--// ========== ESP ==========

local function clearESP()
	for _, v in pairs(ESPFolder:GetChildren()) do
		v:Destroy()
	end
end

local function createESP(player)
	if player == LocalPlayer then return end
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = player.Name
	billboard.Adornee = root
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = ESPFolder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.Name
	label.TextColor3 = Color3.fromRGB(0, 255, 128)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard
end

local function setESP(enabled)
	States.ESP = enabled
	clearESP()
	if Connections.ESP then Connections.ESP:Disconnect() Connections.ESP = nil end

	if enabled then
		for _, plr in pairs(Players:GetPlayers()) do
			createESP(plr)
		end
		Connections.ESP = Players.PlayerAdded:Connect(function(plr)
			plr.CharacterAdded:Connect(function()
				task.wait(1)
				if States.ESP then createESP(plr) end
			end)
		end)
	end
end

--// Anti AFK
local function setAntiAFK(enabled)
	States.AntiAFK = enabled
	if Connections.AntiAFK then Connections.AntiAFK:Disconnect() Connections.AntiAFK = nil end

	if enabled then
		Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end

--// Respawn handler
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if States.Speed then setSpeed(true) end
	if States.InfJump then setInfJump(true) end
	if States.Fly then setFly(true) end
	if States.Noclip then setNoclip(true) end
	if States.InfStamina then setInfStamina(true) end
end)

--// ========== RAYFIELD UI ==========

local Window = Rayfield:CreateWindow({
	Name = "ER:LC Script",
	LoadingTitle = "ER:LC",
	LoadingSubtitle = "Rayfield",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "ERLC_Script",
		FileName = "Config"
	},
	Discord = { Enabled = false },
	KeySystem = false,
})

-- Tabs
local PlayerTab = Window:CreateTab("Player", 4483362458)
local VehicleTab = Window:CreateTab("Vehicle", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- ===== PLAYER TAB =====
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
	Name = "Infinite Stamina",
	CurrentValue = false,
	Flag = "InfStamina",
	Callback = function(Value) setInfStamina(Value) end,
})

PlayerTab:CreateToggle({
	Name = "Speed",
	CurrentValue = false,
	Flag = "Speed",
	Callback = function(Value) setSpeed(Value) end,
})

PlayerTab:CreateSlider({
	Name = "Speed Value",
	Range = {16, 150},
	Increment = 1,
	CurrentValue = 50,
	Flag = "SpeedValue",
	Callback = function(Value)
		SpeedValue = Value
		if States.Speed then
			local hum = getHum()
			if hum then hum.WalkSpeed = Value end
		end
	end,
})

PlayerTab:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Flag = "InfJump",
	Callback = function(Value) setInfJump(Value) end,
})

PlayerTab:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Flag = "Fly",
	Callback = function(Value) setFly(Value) end,
})

PlayerTab:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Flag = "Noclip",
	Callback = function(Value) setNoclip(Value) end,
})

-- ===== VEHICLE TAB =====
VehicleTab:CreateSection("Vehicle Movement")

VehicleTab:CreateToggle({
	Name = "Car Fly",
	CurrentValue = false,
	Flag = "CarFly",
	Callback = function(Value) setCarFly(Value) end,
})

VehicleTab:CreateSection("Vehicle Mods")

VehicleTab:CreateToggle({
	Name = "Enable Car Mods",
	CurrentValue = false,
	Flag = "CarMods",
	Callback = function(Value) setCarMods(Value) end,
})

VehicleTab:CreateSlider({
	Name = "Horsepower",
	Range = {100, 2000},
	Increment = 50,
	CurrentValue = 500,
	Flag = "Horsepower",
	Callback = function(Value)
		HorsepowerValue = Value
		if States.CarMods then applyCarMods() end
	end,
})

VehicleTab:CreateSlider({
	Name = "Top Speed",
	Range = {50, 500},
	Increment = 10,
	CurrentValue = 200,
	Flag = "TopSpeed",
	Callback = function(Value)
		TopSpeedValue = Value
		if States.CarMods then applyCarMods() end
	end,
})

-- ===== VISUALS TAB =====
VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
	Name = "Player ESP",
	CurrentValue = false,
	Flag = "ESP",
	Callback = function(Value) setESP(Value) end,
})

-- ===== MISC TAB =====
MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
	Flag = "AntiAFK",
	Callback = function(Value) setAntiAFK(Value) end,
})

MiscTab:CreateButton({
	Name = "Destroy UI",
	Callback = function()
		clearESP()
		Rayfield:Destroy()
	end,
})

Rayfield:Notify({
	Title = "ER:LC Script",
	Content = "Loaded with Vehicle mods",
	Duration = 4,
})

Rayfield:LoadConfiguration()
