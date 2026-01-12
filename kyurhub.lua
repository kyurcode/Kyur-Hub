--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

--// SETTINGS
local Settings = {
	Headlock = true,
	ESP = true,
	FOV = 140
}

local FOV_MIN = 80
local FOV_MAX = 300

local Holding = false
local LockedTarget = nil
local GUIVisible = true

--// ================= GUI =================
local Gui = Instance.new("ScreenGui", game.CoreGui)

--// ================= MAIN GUI =================
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.fromOffset(260, 215)
Main.Position = UDim2.fromOffset(30, 250)
Main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

--// ===== TOP BAR (DRAG ONLY)
local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1,0,0,30)
TopBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,12)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "ADMIN PANEL"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.new(1,1,1)

-- Drag logic
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = Main.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = i.Position - dragStart
		Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

--// ===== TOGGLE BUTTON
local function toggleButton(text, y, get, set)
	local b = Instance.new("TextButton", Main)
	b.Size = UDim2.new(1,-20,0,35)
	b.Position = UDim2.fromOffset(10,y)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)

	local function refresh()
		local state = get()
		b.Text = text.." : "..(state and "ON" or "OFF")
		b.BackgroundColor3 = state and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
	end

	b.MouseButton1Click:Connect(function()
		set(not get())
		refresh()
	end)

	refresh()
	return b
end

toggleButton("HEADLOCK", 45, function() return Settings.Headlock end, function(v) Settings.Headlock = v end)
toggleButton("ESP", 85, function() return Settings.ESP end, function(v) Settings.ESP = v end)

--// ===== SLIDER LABEL
local PercentLabel = Instance.new("TextLabel", Main)
PercentLabel.Size = UDim2.new(1,-20,0,20)
PercentLabel.Position = UDim2.fromOffset(10,120)
PercentLabel.BackgroundTransparency = 1
PercentLabel.TextXAlignment = Enum.TextXAlignment.Left
PercentLabel.Font = Enum.Font.GothamBold
PercentLabel.TextSize = 13
PercentLabel.TextColor3 = Color3.new(1,1,1)

--// ===== SLIDER BAR
local SliderBG = Instance.new("Frame", Main)
SliderBG.Size = UDim2.new(1,-20,0,10)
SliderBG.Position = UDim2.fromOffset(10,145)
SliderBG.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1,0)

local Slider = Instance.new("Frame", SliderBG)
Instance.new("UICorner", Slider).CornerRadius = UDim.new(1,0)

local sliding = false

local function gradientColor(p)
	return Color3.fromRGB(255*(1-p),255*p,0)
end

local function updateFromPercent(p)
	p = math.clamp(p,0,1)
	Slider.Size = UDim2.new(p,0,1,0)
	Slider.BackgroundColor3 = gradientColor(p)
	Settings.FOV = math.floor(FOV_MIN + (FOV_MAX - FOV_MIN) * p)
	PercentLabel.Text = "FOV : "..math.floor(p*100).."%"
end

updateFromPercent((Settings.FOV-FOV_MIN)/(FOV_MAX-FOV_MIN))

SliderBG.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
end)

UIS.InputChanged:Connect(function(i)
	if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
		updateFromPercent((i.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
end)

--// CTRL DROIT → SHOW / HIDE GUI + CURSOR + CROSSHAIR
UIS.InputBegan:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.RightControl then
		GUIVisible = not GUIVisible
		Main.Visible = GUIVisible
		Crosshair.Visible = GUIVisible
		UIS.MouseIconEnabled = GUIVisible
	end
end)

--// ================= FOV CIRCLE =================
local FOV = Instance.new("Frame", Gui)
FOV.AnchorPoint = Vector2.new(0.5,0.5)
FOV.BackgroundTransparency = 1
Instance.new("UICorner", FOV).CornerRadius = UDim.new(1,0)

local Stroke = Instance.new("UIStroke", FOV)
Stroke.Thickness = 2

--// ================= ESP =================
local function esp(char,color)
	if not Settings.ESP then
		if char:FindFirstChild("ESP") then char.ESP:Destroy() end
		return
	end
	local h = char:FindFirstChild("ESP") or Instance.new("Highlight", char)
	h.Name = "ESP"
	h.FillTransparency = 1
	h.OutlineColor = color
end

--// ================= TARGET =================
local function getTarget()
	local best, score
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
			local h = p.Character.Head
			local pos,on = Camera:WorldToViewportPoint(h.Position)
			if on then
				local dist = (Vector2.new(pos.X,pos.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude
				if dist < Settings.FOV then
					local look = Camera.CFrame.LookVector:Dot((h.Position-Camera.CFrame.Position).Unit)
					local s = dist - look*100
					if not score or s < score then
						score = s
						best = p
					end
				end
			end
		end
	end
	return best
end

--// INPUT
UIS.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = true
		LockedTarget = getTarget()
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = false
		LockedTarget = nil
	end
end)

--// ================= LOOP =================
RunService.RenderStepped:Connect(function()
	FOV.Size = UDim2.fromOffset(Settings.FOV*2, Settings.FOV*2)
	FOV.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
	Stroke.Color = (Holding and Settings.Headlock)
		and Color3.fromRGB(0,255,0)
		or Color3.fromRGB(255,0,0)

	for _,p in pairs(Players:GetPlayers()) do
		if p.Character then
			esp(p.Character, Color3.fromRGB(255,0,0))
		end
	end

	if Holding and Settings.Headlock and LockedTarget and LockedTarget.Character then
		local head = LockedTarget.Character.Head
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
		esp(LockedTarget.Character, Color3.fromRGB(0,255,0))
	end
end)
