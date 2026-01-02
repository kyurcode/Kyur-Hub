-- Ultimate GUI: ESP + AimLock + Speed + NoClip
-- LocalScript à mettre dans StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- === Variables ===
local espEnabled = true
local aimLockEnabled = false
local aimLockActive = false
local speedValue = 50
local speedEnabled = false
local noclipEnabled = false
local espToggleKey = Enum.KeyCode.E
local noclipKey = Enum.KeyCode.N
local waitingForKeyChange = false
local waitingForNoclipKeyChange = false

local boxes = {}

-- === GUI Setup ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 250)
frame.Position = UDim2.new(1, -260, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Titre
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -25, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Ultimate GUI"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Bouton fermeture
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0,25,0,25)
closeButton.Position = UDim2.new(1, -25,0,0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255,100,100)
closeButton.BackgroundTransparency = 1
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = frame
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- === ESP Section ===
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0.9,0,0,25)
espButton.Position = UDim2.new(0.05,0,0,35)
espButton.Text = "ESP ON | Key: "..espToggleKey.Name
espButton.TextColor3 = Color3.fromRGB(255,255,255)
espButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
espButton.Font = Enum.Font.SourceSans
espButton.TextSize = 16
espButton.Parent = frame

-- === AimLock Section ===
local aimButton = Instance.new("TextButton")
aimButton.Size = UDim2.new(0.9,0,0,25)
aimButton.Position = UDim2.new(0.05,0,0,70)
aimButton.Text = "AimLock OFF"
aimButton.TextColor3 = Color3.fromRGB(255,255,255)
aimButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
aimButton.Font = Enum.Font.SourceSans
aimButton.TextSize = 16
aimButton.Parent = frame

-- === Speed Section ===
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.9,0,0,25)
speedLabel.Position = UDim2.new(0.05,0,0,105)
speedLabel.Text = "Speed: "..speedValue
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 16
speedLabel.Parent = frame

local speedPlus = Instance.new("TextButton")
speedPlus.Size = UDim2.new(0.4,0,0,25)
speedPlus.Position = UDim2.new(0.05,0,0,135)
speedPlus.Text = "+"
speedPlus.Font = Enum.Font.SourceSansBold
speedPlus.TextSize = 20
speedPlus.TextColor3 = Color3.fromRGB(255,255,255)
speedPlus.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedPlus.Parent = frame

local speedMinus = Instance.new("TextButton")
speedMinus.Size = UDim2.new(0.4,0,0,25)
speedMinus.Position = UDim2.new(0.55,0,0,135)
speedMinus.Text = "-"
speedMinus.Font = Enum.Font.SourceSansBold
speedMinus.TextSize = 20
speedMinus.TextColor3 = Color3.fromRGB(255,255,255)
speedMinus.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedMinus.Parent = frame

-- === NoClip Section ===
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9,0,0,25)
noclipButton.Position = UDim2.new(0.05,0,0,170)
noclipButton.Text = "NoClip OFF | Key: "..noclipKey.Name
noclipButton.TextColor3 = Color3.fromRGB(255,255,255)
noclipButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
noclipButton.Font = Enum.Font.SourceSans
noclipButton.TextSize = 16
noclipButton.Parent = frame

-- === ESP Functions ===
local function createBox(char)
	if char:FindFirstChild("HumanoidRootPart") then
		local box = Instance.new("BoxHandleAdornment")
		box.Adornee = char:FindFirstChild("HumanoidRootPart")
		box.AlwaysOnTop = true
		box.ZIndex = 10
		box.Size = Vector3.new(4,6,2)
		box.Color3 = Color3.fromRGB(255,0,0)
		box.Transparency = 0.5
		box.Parent = Workspace.CurrentCamera
		return box
	end
end

local function removeBox(box)
	if box then box:Destroy() end
end

local function updateESP()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player then
			if espEnabled then
				if not boxes[plr] and plr.Character then
					boxes[plr] = createBox(plr.Character)
				end
			else
				if boxes[plr] then
					removeBox(boxes[plr])
					boxes[plr] = nil
				end
			end
		end
	end
end

-- === AimLock Functions ===
local function getClosestPlayerToCursor()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local cam = Workspace.CurrentCamera
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
			local headPos, onScreen = cam:WorldToViewportPoint(plr.Character.Head.Position)
			if onScreen then
				local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
				local dist = (Vector2.new(headPos.X, headPos.Y)-center).Magnitude
				if dist < shortestDistance then
					shortestDistance = dist
					closestPlayer = plr
				end
			end
		end
	end
	return closestPlayer
end

-- === Events ===

-- ESP toggle
espButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if waitingForKeyChange then return end
	espButton.Text = (espEnabled and "ESP ON" or "ESP OFF").." | Key: "..espToggleKey.Name
	waitingForKeyChange = true
	espButton.Text = "Press any key..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if waitingForKeyChange and input.UserInputType == Enum.UserInputType.Keyboard then
		espToggleKey = input.KeyCode
		espButton.Text = (espEnabled and "ESP ON" or "ESP OFF").." | Key: "..espToggleKey.Name
		waitingForKeyChange = false
	elseif waitingForNoclipKeyChange and input.UserInputType == Enum.UserInputType.Keyboard then
		noclipKey = input.KeyCode
		noclipButton.Text = (noclipEnabled and "NoClip ON" or "NoClip OFF").." | Key: "..noclipKey.Name
		waitingForNoclipKeyChange = false
	elseif input.KeyCode == espToggleKey then
		espEnabled = not espEnabled
		espButton.Text = (espEnabled and "ESP ON" or "ESP OFF").." | Key: "..espToggleKey.Name
	elseif input.KeyCode == noclipKey then
		noclipEnabled = not noclipEnabled
		noclipButton.Text = (noclipEnabled and "NoClip ON" or "NoClip OFF").." | Key: "..noclipKey.Name
	end
end)

-- AimLock toggle
aimButton.MouseButton1Click:Connect(function()
	aimLockEnabled = not aimLockEnabled
	aimButton.Text = aimLockEnabled and "AimLock ON" or "AimLock OFF"
end)

-- Speed buttons
speedPlus.MouseButton1Click:Connect(function()
	speedValue = speedValue + 10
	speedLabel.Text = "Speed: "..speedValue
end)
speedMinus.MouseButton1Click:Connect(function()
	speedValue = math.max(10, speedValue-10)
	speedLabel.Text = "Speed: "..speedValue
end)

-- NoClip button
noclipButton.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	noclipButton.Text = (noclipEnabled and "NoClip ON" or "NoClip OFF").." | Key: "..noclipKey.Name
end)

-- RunService Loop
RunService.RenderStepped:Connect(function()
	updateESP()
	
	-- AimLock (clic droit)
	if aimLockEnabled and mouse:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local target = getClosestPlayerToCursor()
		if target and target.Character and target.Character:FindFirstChild("Head") then
			local cam = Workspace.CurrentCamera
			cam.CFrame = CFrame.new(cam.CFrame.Position, target.Character.Head.Position)
		end
	end
	
	-- Speed
	if speedEnabled then
		humanoid.WalkSpeed = speedValue
	else
		humanoid.WalkSpeed = 16
	end
	
	-- NoClip
	if noclipEnabled then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)
