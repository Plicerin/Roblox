local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared")
local SizeConfig = require(shared:WaitForChild("SizeConfig"))
local remoteFolder = ReplicatedStorage:WaitForChild("TinyGiantObbyRemotes")
local switchRemote = remoteFolder:WaitForChild("SwitchSize")
local slideSteerRemote = remoteFolder:WaitForChild("SlideSteer")

local gui = Instance.new("ScreenGui")
gui.Name = "TinyGiantHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local missionFrame = Instance.new("Frame")
missionFrame.Name = "MissionPanel"
missionFrame.AnchorPoint = Vector2.new(0.5, 0)
missionFrame.Position = UDim2.fromScale(0.5, 0.035)
missionFrame.Size = UDim2.fromOffset(620, 92)
missionFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
missionFrame.BackgroundTransparency = 0.08
missionFrame.BorderSizePixel = 0
missionFrame.Parent = gui

local missionStroke = Instance.new("UIStroke")
missionStroke.Color = Color3.fromRGB(255, 220, 90)
missionStroke.Thickness = 3
missionStroke.Parent = missionFrame

local missionTitle = Instance.new("TextLabel")
missionTitle.Name = "MissionTitle"
missionTitle.BackgroundTransparency = 1
missionTitle.Position = UDim2.fromOffset(18, 8)
missionTitle.Size = UDim2.fromOffset(584, 26)
missionTitle.Font = Enum.Font.GothamBlack
missionTitle.Text = "WIPEOUT RUN"
missionTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
missionTitle.TextScaled = true
missionTitle.TextXAlignment = Enum.TextXAlignment.Left
missionTitle.Parent = missionFrame

local missionText = Instance.new("TextLabel")
missionText.Name = "MissionText"
missionText.BackgroundTransparency = 1
missionText.Position = UDim2.fromOffset(18, 40)
missionText.Size = UDim2.fromOffset(584, 42)
missionText.Font = Enum.Font.GothamBold
missionText.Text = "Follow the glowing arrows."
missionText.TextColor3 = Color3.fromRGB(255, 255, 255)
missionText.TextScaled = true
missionText.TextWrapped = true
missionText.TextXAlignment = Enum.TextXAlignment.Left
missionText.Parent = missionFrame

local toast = Instance.new("TextLabel")
toast.Name = "DoneToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.fromScale(0.5, 0.155)
toast.Size = UDim2.fromOffset(430, 46)
toast.BackgroundColor3 = Color3.fromRGB(70, 255, 130)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBlack
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(15, 20, 20)
toast.TextScaled = true
toast.Visible = false
toast.Parent = gui

local frame = Instance.new("Frame")
frame.Name = "ButtonStack"
frame.AnchorPoint = Vector2.new(1, 1)
frame.Position = UDim2.fromScale(0.975, 0.92)
frame.Size = UDim2.fromOffset(160, 180)
frame.BackgroundTransparency = 1
frame.Parent = gui
frame.Visible = false

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Parent = frame

local buttons = {}
local lastToast = 0

local function showToast(text)
	lastToast += 1
	local token = lastToast
	toast.Text = text
	toast.Visible = true
	toast.BackgroundTransparency = 0
	toast.TextTransparency = 0
	TweenService:Create(toast, TweenInfo.new(0.15), {Position = UDim2.fromScale(0.5, 0.14)}):Play()
	task.delay(1.2, function()
		if token == lastToast then
			TweenService:Create(toast, TweenInfo.new(0.35), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			task.wait(0.35)
			if token == lastToast then
				toast.Visible = false
				toast.Position = UDim2.fromScale(0.5, 0.155)
			end
		end
	end)
end

local function setActive(formName)
	for name, button in pairs(buttons) do
		button.Text = if name == formName then ("* " .. name) else name
		button.BorderSizePixel = if name == formName then 5 else 0
	end
end

local function requestForm(formName)
	if formName ~= "Normal" then
		return
	end
	if SizeConfig.isValidForm(formName) then
		switchRemote:FireServer(formName)
		setActive(formName)
	end
end

local function makeButton(formName)
	local button = Instance.new("TextButton")
	button.Name = formName .. "Button"
	button.Size = UDim2.fromOffset(150, 52)
	button.BackgroundColor3 = SizeConfig.Forms[formName].ButtonColor
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBlack
	button.Text = formName
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.TextScaled = true
	button.AutoButtonColor = true
	button.Parent = frame
	button.Activated:Connect(function()
		requestForm(formName)
	end)
	buttons[formName] = button
end

makeButton("Tiny")
makeButton("Normal")
makeButton("Giant")
setActive(SizeConfig.DefaultForm)

local function coursePart(name)
	local course = workspace:FindFirstChild("TinyGiantGraybox")
	return course and course:FindFirstChild(name, true)
end

local function activated(name)
	local p = coursePart(name)
	return p and p:GetAttribute("Activated") == true
end

local function currentZ()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and root.Position.Z or -math.huge
end

local objectives = {
	{
		text = "Obstacle 1: cross the floating step pads over the water.",
		done = function() return currentZ() > 84 end,
		doneText = "STEP PADS CLEARED!"
	},
	{
		text = "Obstacle 2: time your jump over the spinning yellow arm.",
		done = function() return currentZ() > 150 end,
		doneText = "SPINNER CLEARED!"
	},
	{
		text = "Obstacle 3: dodge the moving punch blocks.",
		done = function() return currentZ() > 232 end,
		doneText = "PUNCH BLOCKS CLEARED!"
	},
	{
		text = "Obstacle 4: stay on the narrow bridge over the water.",
		done = function() return currentZ() > 326 end,
		doneText = "FINAL BRIDGE CLEARED!"
	},
	{
		text = "Obstacle 5: keep your balance across the tilting tables.",
		done = function() return currentZ() > 468 end,
		doneText = "TILTING TABLES CLEARED!"
	},
	{
		text = "Obstacle 6: time the launch pads across the lagoon.",
		done = function() return currentZ() > 650 end,
		doneText = "LAUNCH LAGOON CLEARED!"
	},
	{
		text = "Obstacle 7: dodge the swinging red balls.",
		done = function() return currentZ() > 735 end,
		doneText = "SWING BALLS CLEARED!"
	},
	{
		text = "Finish: run through the yellow finish gate.",
		done = function() return player:GetAttribute("CourseFinished") == true end,
		doneText = "WIPEOUT RUN CLEARED!"
	},
}

local currentObjective = 1
local completed = {}
local lastSteerSent = 0
local lastSteerValue = 0
local heldLeft = 0
local heldRight = 0
local slideAnimationPaused = false
local slideAnimateScript = nil
local slideAnimateWasDisabled = nil
local lastSlideTrackStop = 0
local runTimerSeenValue = nil
local runTimerLocalStart = nil

local function updateMission()
	while objectives[currentObjective] and objectives[currentObjective].done() do
		if not completed[currentObjective] then
			completed[currentObjective] = true
			showToast(objectives[currentObjective].doneText)
		end
		currentObjective += 1
	end

	local objective = objectives[currentObjective]
	local startTime = player:GetAttribute("RunStartTime")
	local elapsedSeconds = player:GetAttribute("RunElapsedSeconds")
	local finishedTime = player:GetAttribute("RunTimeSeconds")
	local bestTime = player:GetAttribute("BestRunTimeSeconds")
	if startTime ~= runTimerSeenValue then
		runTimerSeenValue = startTime
		runTimerLocalStart = if typeof(startTime) == "number" then os.clock() else nil
	end
	local elapsed = if typeof(finishedTime) == "number" then finishedTime elseif typeof(elapsedSeconds) == "number" then elapsedSeconds else 0
	local timing = string.format("  %.1fs", elapsed)
	if typeof(bestTime) == "number" then
		timing ..= string.format(" | Best %.1fs", bestTime)
	end
	missionTitle.Text = "WIPEOUT RUN" .. timing
	missionText.Text = objective and objective.text or "Run it again: beat your time and grab more coins."
end

local function connectActivationWatchers()
	local course = workspace:FindFirstChild("TinyGiantGraybox")
	if not course then
		return
	end

	for _, inst in ipairs(course:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst:GetAttributeChangedSignal("Activated"):Connect(updateMission)
		end
	end
end

player:GetAttributeChangedSignal("CurrentForm"):Connect(function()
	setActive(player:GetAttribute("CurrentForm") or SizeConfig.DefaultForm)
end)
player:GetAttributeChangedSignal("CourseFinished"):Connect(updateMission)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "TinyGiantGraybox" then
		task.wait(0.25)
		connectActivationWatchers()
		updateMission()
	end
end)

task.defer(function()
	connectActivationWatchers()
	updateMission()
end)

RunService.RenderStepped:Connect(updateMission)

local function getCharacterAnimator()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	return character, humanoid, animator
end

local function stopCharacterAnimationTracks(animator)
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.08)
	end
end

local function setSlideAnimationPaused(paused)
	local character, _, animator = getCharacterAnimator()
	if paused then
		if not slideAnimationPaused then
			slideAnimateScript = character and character:FindFirstChild("Animate")
			slideAnimateWasDisabled = slideAnimateScript and slideAnimateScript.Disabled
			slideAnimationPaused = true
		end

		if slideAnimateScript and slideAnimateScript.Parent then
			slideAnimateScript.Disabled = true
		end
		stopCharacterAnimationTracks(animator)
		lastSlideTrackStop = os.clock()
	else
		if slideAnimationPaused then
			if slideAnimateScript and slideAnimateScript.Parent and slideAnimateWasDisabled ~= nil then
				slideAnimateScript.Disabled = slideAnimateWasDisabled
			end
			slideAnimationPaused = false
			slideAnimateScript = nil
			slideAnimateWasDisabled = nil
			lastSlideTrackStop = 0
		end
	end
end

player.CharacterAdded:Connect(function()
	slideAnimationPaused = false
	slideAnimateScript = nil
	slideAnimateWasDisabled = nil
	lastSlideTrackStop = 0
end)

local function readSlideSteer()
	local steer = 0
	steer += heldRight - heldLeft

	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		steer -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		steer += 1
	end

	for _, input in ipairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			if math.abs(input.Position.X) > 0.18 then
				steer = math.clamp(steer + input.Position.X, -1, 1)
			end
		end
	end

	return math.clamp(steer, -1, 1)
end

local function setSteerKey(input, value)
	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		heldLeft = value
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		heldRight = value
	end
end

RunService.RenderStepped:Connect(function()
	local isSliding = player:GetAttribute("IsSliding") == true
	setSlideAnimationPaused(isSliding)
	if isSliding and os.clock() - lastSlideTrackStop >= 0.2 then
		local _, _, animator = getCharacterAnimator()
		stopCharacterAnimationTracks(animator)
		lastSlideTrackStop = os.clock()
	end

	local steer = readSlideSteer()
	local now = os.clock()
	local shouldSend = isSliding
		or math.abs(steer) > 0.01
		or math.abs(lastSteerValue) > 0.01

	if shouldSend and (now - lastSteerSent >= 0.04 or math.abs(steer - lastSteerValue) >= 0.05) then
		lastSteerSent = now
		lastSteerValue = steer
		slideSteerRemote:FireServer(steer)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	setSteerKey(input, 1)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		requestForm("Tiny")
	elseif input.KeyCode == Enum.KeyCode.R then
		requestForm("Normal")
	elseif input.KeyCode == Enum.KeyCode.E then
		requestForm("Giant")
	elseif input.KeyCode == Enum.KeyCode.DPadLeft then
		requestForm("Tiny")
	elseif input.KeyCode == Enum.KeyCode.DPadUp then
		requestForm("Normal")
	elseif input.KeyCode == Enum.KeyCode.DPadRight then
		requestForm("Giant")
	end
end)

UserInputService.InputEnded:Connect(function(input)
	setSteerKey(input, 0)
end)
