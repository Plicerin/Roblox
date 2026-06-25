-- Wipeout Run one-paste Studio installer
-- Paste this whole file into Roblox Studio Command Bar and press Enter.

local function clearChild(parent, name)
	local child = parent:FindFirstChild(name)
	if child then
		child:Destroy()
	end
end

clearChild(game:GetService("ReplicatedStorage"), "TinyGiantObby")
clearChild(game:GetService("ReplicatedStorage"), "TinyGiantObbyRemotes")
clearChild(game:GetService("ServerScriptService"), "TinyGiantObby")
clearChild(game:GetService("ServerScriptService"), "WipeoutConveyorController")
clearChild(game:GetService("ServerScriptService"), "WipeoutSweeperController")
clearChild(game:GetService("ServerScriptService"), "WipeoutTilterController")
clearChild(game:GetService("ServerScriptService"), "WipeoutSwingBallController")
clearChild(game:GetService("ServerScriptService"), "WipeoutLobbyController")
clearChild(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "TinyGiantObby")

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local entries = {
	{ service = "ReplicatedStorage", folders = {"TinyGiantObby", "Shared"}, className = "ModuleScript", name = "ObstacleConfig", source = [================[
local ObstacleConfig = {}

ObstacleConfig.CheckpointReward = 10
ObstacleConfig.FinishCoins = 100
ObstacleConfig.FinishWins = 1

ObstacleConfig.Tags = {
	Checkpoint = "TG_Checkpoint",
	Finish = "TG_Finish",
	BreakableWall = "TG_BreakableWall",
	FragileFloor = "TG_FragileFloor",
	GiantButton = "TG_GiantButton",
	PushBlock = "TG_PushBlock",
	WeightPlate = "TG_WeightPlate",
	TinySwitch = "TG_TinySwitch",
	Laser = "TG_Laser",
	Crusher = "TG_Crusher",
	Sweeper = "TG_Sweeper",
	Kill = "TG_Kill",
	Coin = "TG_Coin",
	SlideForce = "TG_SlideForce",
	TinyGate = "TG_TinyGate",
	GiantGate = "TG_GiantGate",
	LaunchPad = "TG_LaunchPad",
	Conveyor = "TG_Conveyor",
}

return ObstacleConfig

]================] },
	{ service = "ReplicatedStorage", folders = {"TinyGiantObby", "Shared"}, className = "ModuleScript", name = "SizeConfig", source = [================[
local SizeConfig = {}

SizeConfig.DefaultForm = "Normal"
SizeConfig.CooldownSeconds = 0.45

SizeConfig.Forms = {
	Tiny = {
		Scale = 0.45,
		WalkSpeed = 13,
		JumpPower = 35,
		ButtonColor = Color3.fromRGB(90, 210, 255),
	},
	Normal = {
		Scale = 1,
		WalkSpeed = 18,
		JumpPower = 50,
		ButtonColor = Color3.fromRGB(110, 255, 135),
	},
	Giant = {
		Scale = 2.2,
		WalkSpeed = 16,
		JumpPower = 75,
		ButtonColor = Color3.fromRGB(255, 185, 75),
	},
}

function SizeConfig.isValidForm(formName)
	return SizeConfig.Forms[formName] ~= nil
end

return SizeConfig

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby"}, className = "Script", name = "Main", source = [================[
local ServerScriptService = game:GetService("ServerScriptService")

local root = ServerScriptService:WaitForChild("TinyGiantObby")
local services = root:WaitForChild("Services")

require(services:WaitForChild("CurrencyService")).start()
require(services:WaitForChild("SizeService")).start()
require(services:WaitForChild("CheckpointService")).start()
require(services:WaitForChild("ObstacleService")).start()

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby", "Services"}, className = "ModuleScript", name = "CheckpointService", source = [================[
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ObstacleConfig = require(ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared"):WaitForChild("ObstacleConfig"))
local CurrencyService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("CurrencyService"))
local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))

local CheckpointService = {}

local checkpointByPlayer = {}
local runStateByPlayer = {}
local checkpointParts = {}
local finishParts = {}
local scanAccumulator = 0
local COURSE_FORWARD = Vector3.new(0, 0, 1)
local TIMER_START_PART_NAME = "StepPad_1"

local function getPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function moveCharacterToCheckpoint(player, character)
	local checkpoint = checkpointByPlayer[player]
	local lobbySpawn = workspace:FindFirstChild("LobbySpawn", true)
	if player:GetAttribute("InLobby") == true or player:GetAttribute("CurrentCheckpoint") == "" then
		checkpoint = lobbySpawn or checkpoint
	end
	checkpoint = checkpoint
		or workspace:FindFirstChild("Checkpoint_1", true)
		or lobbySpawn
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if checkpoint and root then
		local spawnPosition = checkpoint.Position + Vector3.new(0, 5, 0)
		root.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + COURSE_FORWARD)
	end
end

local function beginRun(player)
	runStateByPlayer[player] = {
		completed = false,
		touchedCheckpoints = {},
		startedAt = nil,
	}
	player:SetAttribute("CourseFinished", false)
	player:SetAttribute("CurrentCheckpoint", "")
	player:SetAttribute("RunStartTime", nil)
	player:SetAttribute("RunElapsedSeconds", nil)
	player:SetAttribute("RunTimeSeconds", nil)
end

local function startRunTimer(player)
	local state = runStateByPlayer[player]
	if not state then
		beginRun(player)
		state = runStateByPlayer[player]
	end
	if state.completed or state.startedAt then
		return
	end

	local startedAt = workspace:GetServerTimeNow()
	state.startedAt = startedAt
	player:SetAttribute("RunStartTime", startedAt)
	player:SetAttribute("RunElapsedSeconds", 0)
end

local function getRunState(player)
	local state = runStateByPlayer[player]
	if not state then
		beginRun(player)
		state = runStateByPlayer[player]
	end
	return state
end

local function isCharacterNearPart(character, part)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part.Parent then
		return false
	end

	local localPosition = part.CFrame:PointToObjectSpace(root.Position)
	local horizontalLimit = math.max(part.Size.X, part.Size.Z) * 0.5 + 3
	local verticalLimit = part.Size.Y * 0.5 + 6
	return math.abs(localPosition.X) <= horizontalLimit
		and math.abs(localPosition.Z) <= horizontalLimit
		and math.abs(localPosition.Y) <= verticalLimit
end

local function processCheckpoint(player, part)
	local state = getRunState(player)
	if part.Name == "Checkpoint_1" and (state.completed or player:GetAttribute("InLobby") == true or player:GetAttribute("CurrentCheckpoint") == "") then
		beginRun(player)
		state = runStateByPlayer[player]
	end

	checkpointByPlayer[player] = part
	player:SetAttribute("CurrentCheckpoint", part.Name)
	player:SetAttribute("InLobby", false)

	local key = part:GetFullName()
	if not state.touchedCheckpoints[key] then
		state.touchedCheckpoints[key] = true
		CurrencyService.addCoins(player, ObstacleConfig.CheckpointReward)
		FeedbackService.pulsePart(part, Color3.fromRGB(70, 255, 130))
		FeedbackService.burst(part, Color3.fromRGB(70, 255, 130), 16)
	end
end

local function processFinish(player)
	local state = getRunState(player)
	if state.completed then
		return
	end
	if not state.startedAt then
		return
	end

	state.completed = true
	local elapsed = if state.startedAt then workspace:GetServerTimeNow() - state.startedAt else 0
	player:SetAttribute("CourseFinished", true)
	player:SetAttribute("RunElapsedSeconds", elapsed)
	player:SetAttribute("RunTimeSeconds", elapsed)
	local best = player:GetAttribute("BestRunTimeSeconds")
	if typeof(best) ~= "number" or best <= 0 or elapsed < best then
		player:SetAttribute("BestRunTimeSeconds", elapsed)
	end
	CurrencyService.addWins(player, ObstacleConfig.FinishWins)
	CurrencyService.addCoins(player, ObstacleConfig.FinishCoins)
	FeedbackService.pulsePart(workspace:FindFirstChild("FinishGate", true), Color3.fromRGB(255, 215, 0))
	if player.Character then
		FeedbackService.characterPulse(player.Character, Color3.fromRGB(255, 215, 0))
	end
end

local function connectCheckpoint(part)
	checkpointParts[part] = true

	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player then
			return
		end

		processCheckpoint(player, part)
	end)
end

local function connectFinish(part)
	finishParts[part] = true

	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player then
			return
		end

		processFinish(player)
	end)
end

function CheckpointService.start()
	for _, part in ipairs(CollectionService:GetTagged(ObstacleConfig.Tags.Checkpoint)) do
		connectCheckpoint(part)
	end
	for _, part in ipairs(CollectionService:GetTagged(ObstacleConfig.Tags.Finish)) do
		connectFinish(part)
	end

	CollectionService:GetInstanceAddedSignal(ObstacleConfig.Tags.Checkpoint):Connect(connectCheckpoint)
	CollectionService:GetInstanceAddedSignal(ObstacleConfig.Tags.Finish):Connect(connectFinish)

	RunService.Heartbeat:Connect(function(deltaTime)
		scanAccumulator += deltaTime
		if scanAccumulator < 0.25 then
			return
		end
		scanAccumulator = 0

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local state = runStateByPlayer[player]
			if state and state.startedAt and not state.completed then
				player:SetAttribute("RunElapsedSeconds", workspace:GetServerTimeNow() - state.startedAt)
			end
			if character then
				for part in pairs(checkpointParts) do
					if isCharacterNearPart(character, part) then
						processCheckpoint(player, part)
					end
				end
				local timerStartPart = workspace:FindFirstChild(TIMER_START_PART_NAME, true)
				if timerStartPart and isCharacterNearPart(character, timerStartPart) then
					startRunTimer(player)
				end
				for part in pairs(finishParts) do
					if isCharacterNearPart(character, part) then
						processFinish(player)
					end
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		beginRun(player)
		player:SetAttribute("InLobby", true)

		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				moveCharacterToCheckpoint(player, character)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		checkpointByPlayer[player] = nil
		runStateByPlayer[player] = nil
	end)
end

return CheckpointService

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby", "Services"}, className = "ModuleScript", name = "CurrencyService", source = [================[
local Players = game:GetService("Players")

local CurrencyService = {}

local function createStat(parent, name, value)
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Value = value
	stat.Parent = parent
	return stat
end

function CurrencyService.addCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Size Coins")
	if coins then
		coins.Value += amount
	end
end

function CurrencyService.addWins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value += amount
	end
end

function CurrencyService.start()
	Players.PlayerAdded:Connect(function(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		createStat(leaderstats, "Wins", 0)
		createStat(leaderstats, "Size Coins", 0)
	end)
end

return CurrencyService

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby", "Services"}, className = "ModuleScript", name = "FeedbackService", source = [================[
local Debris = game:GetService("Debris")

local FeedbackService = {}

local function makeAttachment(parent)
	local attachment = Instance.new("Attachment")
	attachment.Name = "TG_FeedbackAttachment"
	attachment.Parent = parent
	return attachment
end

function FeedbackService.pulsePart(part, color)
	if not part or not part.Parent then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TG_FeedbackHighlight"
	highlight.Adornee = part
	highlight.FillColor = color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = part
	Debris:AddItem(highlight, 0.45)

	local light = Instance.new("PointLight")
	light.Name = "TG_FeedbackLight"
	light.Color = color
	light.Brightness = 3
	light.Range = 14
	light.Parent = part
	Debris:AddItem(light, 0.45)
end

function FeedbackService.burst(parent, color, amount)
	if not parent or not parent.Parent then
		return
	end

	local attachment = makeAttachment(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TG_FeedbackBurst"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.65
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = attachment
	emitter:Emit(amount or 18)

	Debris:AddItem(attachment, 1)
end

function FeedbackService.characterPulse(character, color)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	FeedbackService.pulsePart(root, color)
	FeedbackService.burst(root, color, 22)
end

return FeedbackService

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby", "Services"}, className = "ModuleScript", name = "ObstacleService", source = [================[
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ObstacleConfig = require(ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared"):WaitForChild("ObstacleConfig"))
local SizeConfig = require(ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared"):WaitForChild("SizeConfig"))
local CurrencyService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("CurrencyService"))
local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))

local ObstacleService = {}

local breakableOriginals = {}
local breakableCooldown = {}
local fragileCooldown = {}
local pushCooldown = {}
local plateCooldown = {}
local switchCooldown = {}
local laserParts = {}
local killParts = {}
local crusherParts = {}
local sweeperParts = {}
local coinParts = {}
local slideForceParts = {}
local tinyGateParts = {}
local giantGateParts = {}
local launchPadParts = {}
local conveyorParts = {}
local coinCollectedByPlayer = {}
local resetCooldownByPlayer = {}
local launchCooldownByPlayer = {}
local slideStateByPlayer = {}
local slideSteerByPlayer = {}
local slideSteerUpdatedByPlayer = {}
local hazardScanAccumulator = 0
local slideScanAccumulator = 0
local COIN_SPIN_RADIANS_PER_SECOND = math.rad(160)

local SLIDE_START_Z = -22
local SLIDE_END_Z = 350
local SLIDE_START_Y = 46
local SLIDE_END_Y = 4
local SLIDE_SIDE_LIMIT = 13
local SLIDE_STEER_RESPONSE = 76
local SLIDE_TURN_LOOKAHEAD = 16
local SLIDE_BANK_DEGREES = 34
local SLIDE_SLOPE_AXIS = Vector3.new(0, SLIDE_END_Y - SLIDE_START_Y, SLIDE_END_Z - SLIDE_START_Z).Unit
local SLIDE_SIDE_AXIS = Vector3.xAxis

local function slideYAt(z)
	local alpha = math.clamp((z - SLIDE_START_Z) / (SLIDE_END_Z - SLIDE_START_Z), 0, 1)
	return SLIDE_START_Y + (SLIDE_END_Y - SLIDE_START_Y) * alpha
end

local function removeSlideConstraints(root)
	if not root then
		return
	end

	for _, name in ipairs({
		"TG_SlideLinearVelocity",
		"TG_SlideAlignOrientation",
		"TG_SlideAttachment",
	}) do
		local child = root:FindFirstChild(name)
		if child then
			child:Destroy()
		end
	end
end

local function ensureSlideConstraints(root)
	local attachment = root:FindFirstChild("TG_SlideAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "TG_SlideAttachment"
		attachment.Parent = root
	end

	local linearVelocity = root:FindFirstChild("TG_SlideLinearVelocity")
	if not linearVelocity then
		linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Name = "TG_SlideLinearVelocity"
		linearVelocity.Attachment0 = attachment
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		linearVelocity.ForceLimitsEnabled = false
		linearVelocity.Parent = root
	end
	linearVelocity.PrimaryTangentAxis = SLIDE_SIDE_AXIS
	linearVelocity.SecondaryTangentAxis = SLIDE_SLOPE_AXIS
	linearVelocity.Enabled = true

	local alignOrientation = root:FindFirstChild("TG_SlideAlignOrientation")
	if not alignOrientation then
		alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "TG_SlideAlignOrientation"
		alignOrientation.Attachment0 = attachment
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.RigidityEnabled = false
		alignOrientation.MaxTorque = 120000
		alignOrientation.MaxAngularVelocity = 18
		alignOrientation.Responsiveness = 80
		alignOrientation.Parent = root
	end
	alignOrientation.Enabled = true

	return linearVelocity, alignOrientation
end

local function setAnimateDisabled(animateScript, disabled)
	if not animateScript then
		return
	end

	pcall(function()
		animateScript.Disabled = disabled
	end)
end

local function getAnimateDisabled(animateScript)
	if not animateScript then
		return nil
	end

	local ok, disabled = pcall(function()
		return animateScript.Disabled
	end)
	if ok then
		return disabled
	end
	return nil
end

local function pauseSlideAnimations(character, humanoid, state)
	if state.AnimationsPaused then
		return
	end

	local animateScript = character and character:FindFirstChild("Animate")
	state.AnimateScript = animateScript
	state.AnimateWasDisabled = getAnimateDisabled(animateScript)
	setAnimateDisabled(animateScript, true)

	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.12)
		end
	end

	state.AnimationsPaused = true
end

local function restoreSlideAnimations(state)
	if not state or not state.AnimationsPaused then
		return
	end

	if state.AnimateScript and state.AnimateScript.Parent then
		setAnimateDisabled(state.AnimateScript, state.AnimateWasDisabled == true)
	end
end

local function spawnBreakChunks(part, character)
	local chunkFolder = Instance.new("Folder")
	chunkFolder.Name = part.Name .. "_BreakChunks"
	chunkFolder.Parent = part.Parent

	local xCount = part.Size.X >= 14 and 4 or 3
	local yCount = part.Size.Y >= 14 and 4 or 3
	local cellX = part.Size.X / xCount
	local cellY = part.Size.Y / yCount
	local chunkSize = Vector3.new(cellX * 0.86, cellY * 0.86, math.max(part.Size.Z * 0.9, 0.8))
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pushDirection = part.CFrame.LookVector
	if root then
		local fromPlayer = part.Position - root.Position
		if fromPlayer.Magnitude > 0.1 then
			pushDirection = fromPlayer.Unit
		end
	end

	for xIndex = 1, xCount do
		for yIndex = 1, yCount do
			local chunk = Instance.new("Part")
			chunk.Name = part.Name .. "_Chunk"
			chunk.Size = chunkSize
			chunk.CFrame = part.CFrame
				* CFrame.new(
					(xIndex - (xCount + 1) * 0.5) * cellX,
					(yIndex - (yCount + 1) * 0.5) * cellY,
					0
				)
			chunk.Color = part.Color
			chunk.Material = part.Material
			chunk.TopSurface = Enum.SurfaceType.Smooth
			chunk.BottomSurface = Enum.SurfaceType.Smooth
			chunk.Anchored = false
			chunk.CanCollide = false
			chunk.CanTouch = false
			chunk.CanQuery = false
			chunk.Parent = chunkFolder

			local sideScatter = part.CFrame.RightVector * ((xIndex - (xCount + 1) * 0.5) * 2.5)
			local upScatter = Vector3.new(0, 18 + yIndex * 3, 0)
			chunk.AssemblyLinearVelocity = pushDirection * (38 + yIndex * 4) + sideScatter + upScatter
			chunk.AssemblyAngularVelocity = Vector3.new(yIndex * 2.2, xIndex * 2.4, (xIndex - yIndex) * 1.6)
		end
	end

	Debris:AddItem(chunkFolder, 3)
	return xCount * yCount
end

local function getPlayerAndCharacter(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end
	return Players:GetPlayerFromCharacter(character), character
end

local function getForm(player, character)
	return player:GetAttribute("CurrentForm") or character:GetAttribute("CurrentForm") or "Normal"
end

local function getHeightScale(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local scale = humanoid and humanoid:FindFirstChild("BodyHeightScale")
	if scale and scale:IsA("NumberValue") then
		return scale.Value
	end
	return 1
end

local function isTiny(player, character)
	return getForm(player, character) == "Tiny" or getHeightScale(character) <= 0.65
end

local function isGiant(player, character)
	return getForm(player, character) == "Giant" or getHeightScale(character) >= 1.7
end

local function isCharacterNearPart(character, part, padding)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part.Parent then
		return false
	end

	local localPosition = part.CFrame:PointToObjectSpace(root.Position)
	local extra = padding or 2
	return math.abs(localPosition.X) <= part.Size.X * 0.5 + extra
		and math.abs(localPosition.Y) <= part.Size.Y * 0.5 + extra + 2
		and math.abs(localPosition.Z) <= part.Size.Z * 0.5 + extra
end

local function isCharacterTouchingLaser(character, part)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part.Parent then
		return false
	end

	local localPosition = part.CFrame:PointToObjectSpace(root.Position)
	local verticalTolerance = part:GetAttribute("LaserVerticalTolerance") or 1.2
	local zTolerance = part:GetAttribute("LaserDepthTolerance") or 1
	local xTolerance = part:GetAttribute("LaserWidthTolerance") or 1.5
	return math.abs(localPosition.X) <= part.Size.X * 0.5 + xTolerance
		and math.abs(localPosition.Y) <= verticalTolerance
		and math.abs(localPosition.Z) <= part.Size.Z * 0.5 + zTolerance
end

local function killCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		FeedbackService.characterPulse(character, Color3.fromRGB(255, 70, 70))
		humanoid.Health = 0
	end
end

local restoreMovement

local function moveCharacterToCurrentCheckpoint(player, character)
	local checkpointName = player:GetAttribute("CurrentCheckpoint")
	local checkpoint = checkpointName and checkpointName ~= "" and workspace:FindFirstChild(checkpointName, true)
	checkpoint = checkpoint or workspace:FindFirstChild("Checkpoint_1", true) or workspace:FindFirstChild("SlideStart", true)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if checkpoint and root then
		local spawnPosition = checkpoint.Position + Vector3.new(0, 6, -2)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(0, -0.1, 1))
	end
end

local function softReset(player, character, color)
	local now = os.clock()
	if resetCooldownByPlayer[player] and now - resetCooldownByPlayer[player] < 1.1 then
		return
	end

	resetCooldownByPlayer[player] = now
	if character then
		restoreMovement(player, character)
		FeedbackService.characterPulse(character, color or Color3.fromRGB(255, 85, 85))
		moveCharacterToCurrentCheckpoint(player, character)
	end
end

local function knockCharacterFromObstacle(part, character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root then
		return
	end

	local sideDirection = part:GetAttribute("KnockDirection")
	local direction
	if sideDirection == "Left" then
		direction = Vector3.new(-1, 0, 0)
	elseif sideDirection == "Right" then
		direction = Vector3.new(1, 0, 0)
	else
		local localPosition = part.CFrame:PointToObjectSpace(root.Position)
		direction = if localPosition.X >= 0 then part.CFrame.RightVector else -part.CFrame.RightVector
	end

	local strength = part:GetAttribute("KnockStrength") or 72
	local lift = part:GetAttribute("KnockLift") or 22
	root.AssemblyLinearVelocity = direction.Unit * strength + Vector3.new(0, lift, 0)
	root.AssemblyAngularVelocity = Vector3.new(0, 0, direction.X * -8)
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end
	FeedbackService.characterPulse(character, Color3.fromRGB(255, 222, 70))
end

restoreMovement = function(player, character)
	local state = slideStateByPlayer[player]
	if not state then
		return
	end

	slideStateByPlayer[player] = nil
	player:SetAttribute("IsSliding", false)
	player:SetAttribute("SlideVisualSteer", 0)

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	removeSlideConstraints(root)
	restoreSlideAnimations(state)
	if humanoid then
		local form = SizeConfig.Forms[getForm(player, character)] or SizeConfig.Forms[SizeConfig.DefaultForm]
		humanoid.Sit = false
		humanoid.PlatformStand = false
		humanoid.AutoRotate = if state.AutoRotate ~= nil then state.AutoRotate else true
		humanoid.EvaluateStateMachine = if state.EvaluateStateMachine ~= nil then state.EvaluateStateMachine else true
		humanoid.WalkSpeed = state.WalkSpeed or form.WalkSpeed
		humanoid.UseJumpPower = if state.UseJumpPower ~= nil then state.UseJumpPower else true
		humanoid.JumpPower = state.JumpPower or form.JumpPower
	end
end

local function applySlideMovement(player, character, root, speedZ, maxSide, deltaTime)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local state = slideStateByPlayer[player]
	if not state then
		state = {
			Progress = math.max(root.Position.Z, SLIDE_START_Z),
			Steer = 0,
			VisualSteer = 0,
			WalkSpeed = humanoid.WalkSpeed,
			UseJumpPower = humanoid.UseJumpPower,
			JumpPower = humanoid.JumpPower,
			AutoRotate = humanoid.AutoRotate,
			EvaluateStateMachine = humanoid.EvaluateStateMachine,
		}
		slideStateByPlayer[player] = state
	end

	player:SetAttribute("IsSliding", true)
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	local linearVelocity, alignOrientation = ensureSlideConstraints(root)
	pauseSlideAnimations(character, humanoid, state)
	humanoid.Sit = false
	humanoid.PlatformStand = false
	humanoid.AutoRotate = false
	humanoid.EvaluateStateMachine = false
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0

	local requestedSteer = slideSteerByPlayer[player]
	local steerUpdated = slideSteerUpdatedByPlayer[player] or 0
	local steerIsFresh = typeof(requestedSteer) == "number" and os.clock() - steerUpdated < 0.18
	local debugSteer = player:GetAttribute("DebugSlideSteerOverride")
	local steer = if typeof(debugSteer) == "number" then debugSteer elseif steerIsFresh then requestedSteer else humanoid.MoveDirection.X
	steer = math.clamp(steer, -1, 1)
	state.Steer = steer
	state.VisualSteer += (steer - state.VisualSteer) * math.min(deltaTime * 14, 1)
	player:SetAttribute("SlideVisualSteer", state.VisualSteer)

	state.Progress = math.max(state.Progress, root.Position.Z)
	local slopeSpeed = speedZ / math.max(SLIDE_SLOPE_AXIS.Z, 0.01)
	local physicalSteer = -steer
	linearVelocity.PlaneVelocity = Vector2.new(physicalSteer * maxSide, slopeSpeed)

	local turnLeadX = -state.VisualSteer * SLIDE_TURN_LOOKAHEAD
	local lookAt = SLIDE_SLOPE_AXIS * 10 + Vector3.new(turnLeadX, 0, 0)
	local bank = math.rad(-state.VisualSteer * SLIDE_BANK_DEGREES)
	alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, lookAt) * CFrame.Angles(math.rad(90), 0, bank)

	if root.Position.Z >= SLIDE_END_Z + 2 then
		restoreMovement(player, character)
	end
end

local function activateTarget(part, color)
	local targetName = part:GetAttribute("Target")
	local target = targetName and workspace:FindFirstChild(targetName, true)
	if target and target:IsA("BasePart") then
		target.CanCollide = part:GetAttribute("TargetCanCollide") ~= false
		target.Transparency = part:GetAttribute("TargetTransparency") or 0
		target:SetAttribute("Activated", true)
		FeedbackService.pulsePart(target, color)
	end
end

local function connectBreakableWall(part)
	if not breakableOriginals[part] then
		breakableOriginals[part] = {
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
		}
	end

	local function isGiantNearWall()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and getForm(player, character) == "Giant" then
				local offset = root.Position - part.Position
				local closeX = math.abs(offset.X) <= (part.Size.X * 0.5 + 6)
				local closeY = math.abs(offset.Y) <= (part.Size.Y * 0.5 + 8)
				local inFront = offset.Z >= -14 and offset.Z <= 4
				if closeX and closeY and inFront then
					return true
				end
			end
		end

		return false
	end

	local function breakWall(character)
		if breakableCooldown[part] then
			return
		end

		breakableCooldown[part] = true
		local chunkCount = spawnBreakChunks(part, character)
		part.Transparency = 1
		part.CanCollide = false
		part:SetAttribute("Broken", true)
		part:SetAttribute("LastChunkCount", chunkCount)
		FeedbackService.pulsePart(part, Color3.fromRGB(255, 185, 75))
		FeedbackService.burst(part, Color3.fromRGB(255, 185, 75), 28)
		local function resetWhenClear()
			if part.Parent then
				if isGiantNearWall() then
					task.delay(1, resetWhenClear)
					return
				else
					local original = breakableOriginals[part]
					part.Transparency = original.Transparency
					part.CanCollide = original.CanCollide
					part:SetAttribute("Broken", false)
				end
			end
			breakableCooldown[part] = nil
		end

		task.delay(5, resetWhenClear)
	end

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if not player or getForm(player, character) ~= "Giant" then
			return
		end

		breakWall(character)
	end)

end

local function connectFragileFloor(part)
	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		local requiredForm = part:GetAttribute("RequiredForm") or "Giant"
		if not player or fragileCooldown[part] then
			return
		end
		if requiredForm ~= "Any" and getForm(player, character) ~= requiredForm then
			return
		end

		fragileCooldown[part] = true
		task.delay(part:GetAttribute("DropDelay") or 0.25, function()
			if part.Parent then
				FeedbackService.pulsePart(part, Color3.fromRGB(255, 80, 80))
				FeedbackService.burst(part, Color3.fromRGB(255, 80, 80), 22)
				part.Transparency = part:GetAttribute("DroppedTransparency") or 0.75
				part.CanCollide = false
			end
		end)
		task.delay(part:GetAttribute("ResetDelay") or 3, function()
			if part.Parent then
				part.Transparency = part:GetAttribute("ReadyTransparency") or 0.08
				part.CanCollide = true
			end
			fragileCooldown[part] = nil
		end)
	end)
end

local function connectGiantButton(part)
	local targetName = part:GetAttribute("TargetDoor")
	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if not player or getForm(player, character) ~= "Giant" then
			return
		end

		local target = targetName and workspace:FindFirstChild(targetName, true)
		if target and target:IsA("BasePart") then
			FeedbackService.pulsePart(part, Color3.fromRGB(255, 185, 75))
			FeedbackService.pulsePart(target, Color3.fromRGB(255, 185, 75))
			target.CanCollide = false
			target.Transparency = 0.7
			task.delay(4, function()
				if target.Parent then
					target.CanCollide = true
					target.Transparency = 0
				end
			end)
		end
	end)
end

local function connectKill(part)
	killParts[part] = true

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if player then
			if part:GetAttribute("KnockOnly") == true then
				knockCharacterFromObstacle(part, character)
			elseif part:GetAttribute("SoftReset") == true then
				softReset(player, character, Color3.fromRGB(255, 90, 90))
			else
				killCharacter(character)
			end
		end
	end)
end

local function connectLaser(part)
	laserParts[part] = true

	-- Crusher damage is handled in the heartbeat hazard scan so form checks
	-- use the latest size state instead of a stale physics touch.
end

local function collectCoin(player, part)
	if not part.Parent or part:GetAttribute("Collected") == true then
		return
	end

	coinCollectedByPlayer[player] = coinCollectedByPlayer[player] or {}
	if coinCollectedByPlayer[player][part] then
		return
	end

	coinCollectedByPlayer[player][part] = true
	part:SetAttribute("Collected", true)
	part.Transparency = 1
	part.CanTouch = false
	part.CanQuery = false
	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		elseif descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CanCollide = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		elseif descendant:IsA("Light") then
			descendant.Enabled = false
		end
	end
	CurrencyService.addCoins(player, part:GetAttribute("CoinValue") or 1)
	FeedbackService.burst(part, Color3.fromRGB(255, 220, 70), 10)
end

local function connectCoin(part)
	coinParts[part] = true
	part.CanCollide = false

	part.Touched:Connect(function(hit)
		local player = getPlayerAndCharacter(hit)
		if player then
			collectCoin(player, part)
		end
	end)
end

local function connectSlideForce(part)
	slideForceParts[part] = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
end

local function connectTinyGate(part)
	tinyGateParts[part] = true
	part.CanCollide = false
end

local function connectGiantGate(part)
	giantGateParts[part] = true
	part.CanCollide = false
end

local function connectLaunchPad(part)
	launchPadParts[part] = true
	part.CanCollide = false
end

local function connectConveyor(part)
	conveyorParts[part] = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function connectWeightPlate(part)
	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if not player or getForm(player, character) ~= "Giant" or plateCooldown[part] then
			return
		end

		plateCooldown[part] = true
		part:SetAttribute("Activated", true)
		FeedbackService.pulsePart(part, Color3.fromRGB(255, 185, 75))
		FeedbackService.burst(part, Color3.fromRGB(255, 185, 75), 18)
		activateTarget(part, Color3.fromRGB(255, 185, 75))
	end)
end

local function connectTinySwitch(part)
	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if not player or getForm(player, character) ~= "Tiny" or switchCooldown[part] then
			return
		end

		switchCooldown[part] = true
		part:SetAttribute("Activated", true)
		FeedbackService.pulsePart(part, Color3.fromRGB(90, 210, 255))
		FeedbackService.burst(part, Color3.fromRGB(90, 210, 255), 18)
		activateTarget(part, Color3.fromRGB(90, 210, 255))
	end)
end

local function connectCrusher(part)
	local travelY = part:GetAttribute("TravelY")
	if travelY == nil then
		travelY = -6
	end

	crusherParts[part] = {
		Origin = part.CFrame,
		Travel = Vector3.new(part:GetAttribute("TravelX") or 0, travelY, part:GetAttribute("TravelZ") or 0),
		Period = part:GetAttribute("Period") or 1.8,
		Phase = part:GetAttribute("Phase") or 0,
	}
	part.Anchored = true
	if part:GetAttribute("KnockOnly") == true then
		part.CanCollide = false
	end

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if player then
			if part:GetAttribute("KnockOnly") == true then
				knockCharacterFromObstacle(part, character)
			elseif part:GetAttribute("SoftReset") == true then
				softReset(player, character, Color3.fromRGB(255, 90, 90))
			else
				killCharacter(character)
			end
		end
	end)
end

local function connectSweeper(part)
	sweeperParts[part] = {
		Origin = part.CFrame,
		Period = part:GetAttribute("Period") or 2.8,
		Phase = part:GetAttribute("Phase") or 0,
		Direction = part:GetAttribute("Direction") or 1,
	}
	part.Anchored = true

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if player then
			if part:GetAttribute("SoftReset") == true then
				softReset(player, character, Color3.fromRGB(255, 90, 90))
			else
				killCharacter(character)
			end
		end
	end)
end

local function connectPushBlock(part)
	part.Anchored = true
	local startCFrame = part.CFrame
	local pushedCFrame = part.CFrame * CFrame.new(part:GetAttribute("PushOffsetX") or 16, part:GetAttribute("PushOffsetY") or 0, part:GetAttribute("PushOffsetZ") or 18)
	local targetName = part:GetAttribute("TargetDoor")
	local keepSolid = part:GetAttribute("KeepSolidAfterPush") == true

	local function pushBlock(character)
		if pushCooldown[part] then
			return
		end

		pushCooldown[part] = true
		FeedbackService.pulsePart(part, Color3.fromRGB(255, 185, 75))
		FeedbackService.burst(part, Color3.fromRGB(255, 185, 75), 18)
		part.CanCollide = keepSolid
		part:SetAttribute("Pushed", true)
		part:SetAttribute("Activated", true)
		local target = targetName and workspace:FindFirstChild(targetName, true)
		if target and target:IsA("BasePart") then
			FeedbackService.pulsePart(target, Color3.fromRGB(255, 185, 75))
			target.CanCollide = false
			target.Transparency = 0.7
		end

		local elapsed = 0
		local duration = 0.45
		while elapsed < duration and part.Parent do
			elapsed += RunService.Heartbeat:Wait()
			local alpha = math.clamp(elapsed / duration, 0, 1)
			part.CFrame = startCFrame:Lerp(pushedCFrame, alpha)
		end

		if part.Parent then
			part.CFrame = pushedCFrame
			part.CanCollide = keepSolid
		end
	end

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if not player or getForm(player, character) ~= "Giant" or pushCooldown[part] then
			return
		end

		pushBlock(character)
	end)

	RunService.Heartbeat:Connect(function()
		if pushCooldown[part] or not part.Parent or part:GetAttribute("Pushed") == true then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and getForm(player, character) == "Giant" and isCharacterNearPart(character, part, 4) then
				pushBlock(character)
				return
			end
		end
	end)
end

function ObstacleService.start()
	local remoteFolder = ReplicatedStorage:FindFirstChild("TinyGiantObbyRemotes")
	local slideSteerRemote = remoteFolder and remoteFolder:FindFirstChild("SlideSteer")
	if slideSteerRemote and slideSteerRemote:IsA("RemoteEvent") then
		slideSteerRemote.OnServerEvent:Connect(function(player, steer)
			if typeof(steer) == "number" then
				slideSteerByPlayer[player] = math.clamp(steer, -1, 1)
				slideSteerUpdatedByPlayer[player] = os.clock()
				player:SetAttribute("SlideSteer", slideSteerByPlayer[player])
			end
		end)
	end

	local tagHandlers = {
		[ObstacleConfig.Tags.BreakableWall] = connectBreakableWall,
		[ObstacleConfig.Tags.FragileFloor] = connectFragileFloor,
		[ObstacleConfig.Tags.GiantButton] = connectGiantButton,
		[ObstacleConfig.Tags.PushBlock] = connectPushBlock,
		[ObstacleConfig.Tags.WeightPlate] = connectWeightPlate,
		[ObstacleConfig.Tags.TinySwitch] = connectTinySwitch,
		[ObstacleConfig.Tags.Laser] = connectLaser,
		[ObstacleConfig.Tags.Crusher] = connectCrusher,
		[ObstacleConfig.Tags.Kill] = connectKill,
		[ObstacleConfig.Tags.Coin] = connectCoin,
		[ObstacleConfig.Tags.SlideForce] = connectSlideForce,
		[ObstacleConfig.Tags.TinyGate] = connectTinyGate,
		[ObstacleConfig.Tags.GiantGate] = connectGiantGate,
		[ObstacleConfig.Tags.LaunchPad] = connectLaunchPad,
		[ObstacleConfig.Tags.Conveyor] = connectConveyor,
	}

	for tag, handler in pairs(tagHandlers) do
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do
			if instance:IsA("BasePart") then
				handler(instance)
			end
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if instance:IsA("BasePart") then
				handler(instance)
			end
		end)
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		local now = workspace:GetServerTimeNow()
		for part, state in pairs(crusherParts) do
			if not part.Parent then
				crusherParts[part] = nil
			else
				local period = math.max(state.Period, 0.4)
				local wave = (math.sin((now + state.Phase) * math.pi * 2 / period) + 1) * 0.5
				part.CFrame = state.Origin + (state.Travel * wave)
			end
		end

		for part in pairs(coinParts) do
			if not part.Parent then
				coinParts[part] = nil
			elseif part:GetAttribute("Collected") ~= true then
				part.CFrame *= CFrame.Angles(0, COIN_SPIN_RADIANS_PER_SECOND * deltaTime, 0)
			end
		end

		slideScanAccumulator += deltaTime
		if slideScanAccumulator >= 0.05 then
			slideScanAccumulator = 0
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if character and root then
					local holdingAfterReset = resetCooldownByPlayer[player] and os.clock() - resetCooldownByPlayer[player] < 0.65
					if holdingAfterReset then
						restoreMovement(player, character)
						root.AssemblyLinearVelocity = Vector3.zero
					else
						local inSlideForce = false
						local slideSpeed = 96
						local maxSide = 18
						for part in pairs(slideForceParts) do
							if not part.Parent then
								slideForceParts[part] = nil
							elseif isCharacterNearPart(character, part, 6) then
								inSlideForce = true
								slideSpeed = part:GetAttribute("SpeedZ") or slideSpeed
								maxSide = part:GetAttribute("MaxSideVelocity") or maxSide
							end
						end
						if inSlideForce or slideStateByPlayer[player] then
							applySlideMovement(player, character, root, slideSpeed, maxSide, deltaTime)
						end
						if not inSlideForce and slideStateByPlayer[player] then
							local state = slideStateByPlayer[player]
							if state and state.Progress > SLIDE_END_Z + 2 then
								restoreMovement(player, character)
							end
						end
					end

					for part in pairs(coinParts) do
						if not part.Parent then
							coinParts[part] = nil
						elseif part:GetAttribute("Collected") ~= true and isCharacterNearPart(character, part, 2) then
							collectCoin(player, part)
						end
					end

					for part in pairs(tinyGateParts) do
						if not part.Parent then
							tinyGateParts[part] = nil
						elseif isCharacterNearPart(character, part, 1.5) and not isTiny(player, character) then
							softReset(player, character, Color3.fromRGB(90, 210, 255))
						end
					end

					for part in pairs(giantGateParts) do
						if not part.Parent then
							giantGateParts[part] = nil
						elseif isCharacterNearPart(character, part, 2) and not isGiant(player, character) then
							softReset(player, character, Color3.fromRGB(255, 185, 75))
						end
					end

					for part in pairs(launchPadParts) do
						if not part.Parent then
							launchPadParts[part] = nil
						elseif isCharacterNearPart(character, part, 2) then
							local lastLaunch = launchCooldownByPlayer[player] or 0
							if os.clock() - lastLaunch >= 0.7 then
								launchCooldownByPlayer[player] = os.clock()
								restoreMovement(player, character)
								local humanoid = character:FindFirstChildOfClass("Humanoid")
								if humanoid then
									humanoid.Sit = false
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
								root.CFrame += Vector3.new(0, 1.2, 0)
								root.AssemblyLinearVelocity = Vector3.new(
									part:GetAttribute("LaunchX") or 0,
									part:GetAttribute("LaunchY") or 72,
									part:GetAttribute("LaunchZ") or 105
								)
								FeedbackService.characterPulse(character, Color3.fromRGB(255, 215, 80))
							end
						end
					end

					for part in pairs(conveyorParts) do
						if not part.Parent then
							conveyorParts[part] = nil
						elseif isCharacterNearPart(character, part, 0.2) then
							local current = root.AssemblyLinearVelocity
							local push = Vector3.new(part:GetAttribute("PushX") or 0, 0, part:GetAttribute("PushZ") or 0)
							root.AssemblyLinearVelocity = Vector3.new(
								push.X,
								current.Y,
								math.max(current.Z, part:GetAttribute("ForwardMin") or 0) + push.Z
							)
						end
					end
				end
			end
		end

		hazardScanAccumulator += deltaTime
		if hazardScanAccumulator < 0.12 then
			return
		end
		hazardScanAccumulator = 0

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character then
				for part in pairs(killParts) do
					if isCharacterNearPart(character, part, 2) then
						if part:GetAttribute("SoftReset") == true then
							softReset(player, character, Color3.fromRGB(255, 90, 90))
						else
							killCharacter(character)
						end
					end
				end
				for part in pairs(laserParts) do
					if (part:GetAttribute("KillsTiny") == true or getForm(player, character) ~= "Tiny") and isCharacterTouchingLaser(character, part) then
						killCharacter(character)
					end
				end
				for part in pairs(crusherParts) do
					if isCharacterNearPart(character, part, 1.5) then
						if part:GetAttribute("KnockOnly") == true then
							knockCharacterFromObstacle(part, character)
						elseif part:GetAttribute("SoftReset") == true then
							softReset(player, character, Color3.fromRGB(255, 90, 90))
						else
							killCharacter(character)
						end
					end
				end
				for part in pairs(sweeperParts) do
					if isCharacterNearPart(character, part, 1.5) then
						if part:GetAttribute("KnockOnly") == true then
							knockCharacterFromObstacle(part, character)
						elseif part:GetAttribute("SoftReset") == true then
							softReset(player, character, Color3.fromRGB(255, 90, 90))
						else
							killCharacter(character)
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		coinCollectedByPlayer[player] = nil
		resetCooldownByPlayer[player] = nil
		launchCooldownByPlayer[player] = nil
		slideStateByPlayer[player] = nil
		slideSteerByPlayer[player] = nil
		slideSteerUpdatedByPlayer[player] = nil
	end)
end

return ObstacleService

]================] },
	{ service = "ServerScriptService", folders = {"TinyGiantObby", "Services"}, className = "ModuleScript", name = "SizeService", source = [================[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SizeConfig = require(ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared"):WaitForChild("SizeConfig"))
local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))

local SizeService = {}

local remoteFolder
local switchRemote
local slideSteerRemote
local lastSwitchByPlayer = {}

local function ensureRemotes()
	remoteFolder = ReplicatedStorage:FindFirstChild("TinyGiantObbyRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "TinyGiantObbyRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	switchRemote = remoteFolder:FindFirstChild("SwitchSize")
	if not switchRemote then
		switchRemote = Instance.new("RemoteEvent")
		switchRemote.Name = "SwitchSize"
		switchRemote.Parent = remoteFolder
	end

	slideSteerRemote = remoteFolder:FindFirstChild("SlideSteer")
	if not slideSteerRemote then
		slideSteerRemote = Instance.new("RemoteEvent")
		slideSteerRemote.Name = "SlideSteer"
		slideSteerRemote.Parent = remoteFolder
	end
end

local function setBodyScale(humanoid, scale)
	local scaleNames = {
		"BodyDepthScale",
		"BodyHeightScale",
		"BodyWidthScale",
		"HeadScale",
	}

	for _, scaleName in ipairs(scaleNames) do
		local value = humanoid:FindFirstChild(scaleName)
		if value and value:IsA("NumberValue") then
			value.Value = scale
		end
	end
end

function SizeService.applyForm(player, formName)
	if not SizeConfig.isValidForm(formName) then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local form = SizeConfig.Forms[formName]
	player:SetAttribute("CurrentForm", formName)
	character:SetAttribute("CurrentForm", formName)

	humanoid.WalkSpeed = form.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = form.JumpPower
	setBodyScale(humanoid, form.Scale)
	FeedbackService.characterPulse(character, form.ButtonColor)

	return true
end

local function onCharacterAdded(player, character)
	character:WaitForChild("Humanoid", 8)
	task.wait(0.25)
	SizeService.applyForm(player, SizeConfig.DefaultForm)
end

local function onSwitchRequested(player, formName)
	if typeof(formName) ~= "string" or not SizeConfig.isValidForm(formName) then
		return
	end

	local now = os.clock()
	local lastSwitch = lastSwitchByPlayer[player] or 0
	if now - lastSwitch < SizeConfig.CooldownSeconds then
		return
	end

	lastSwitchByPlayer[player] = now
	SizeService.applyForm(player, formName)
end

function SizeService.start()
	ensureRemotes()
	switchRemote.OnServerEvent:Connect(onSwitchRequested)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("CurrentForm", SizeConfig.DefaultForm)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastSwitchByPlayer[player] = nil
	end)
end

return SizeService

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutConveyorController", source = [================[
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONVEYOR_TAG = "TG_Conveyor"
local scanAccumulator = 0

local function isCharacterInsideZone(character, zone)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not zone.Parent then
		return false, nil
	end

	local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
	return math.abs(localPosition.X) <= zone.Size.X * 0.5 + 1
		and math.abs(localPosition.Y) <= zone.Size.Y * 0.5 + 2.8
		and math.abs(localPosition.Z) <= zone.Size.Z * 0.5 + 1, root
end

local function configureZone(zone)
	if not zone:IsA("BasePart") then
		return
	end

	zone.CanCollide = false
	zone.CanTouch = false
	zone.CanQuery = false
	zone:SetAttribute("ConveyorControllerTracked", true)
end

for _, zone in ipairs(CollectionService:GetTagged(CONVEYOR_TAG)) do
	configureZone(zone)
end

CollectionService:GetInstanceAddedSignal(CONVEYOR_TAG):Connect(function(zone)
	configureZone(zone)
end)

RunService.Heartbeat:Connect(function(deltaTime)
	scanAccumulator += deltaTime
	if scanAccumulator < 0.05 then
		return
	end
	scanAccumulator = 0

	local zones = CollectionService:GetTagged(CONVEYOR_TAG)
	workspace:SetAttribute("ConveyorControllerTrackedCount", #zones)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		for _, zone in ipairs(zones) do
			if zone:IsA("BasePart") then
				local inside, root = isCharacterInsideZone(character, zone)
				if inside and root then
					local current = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(
						zone:GetAttribute("PushX") or 0,
						current.Y,
						math.max(current.Z, zone:GetAttribute("ForwardMin") or 0) + (zone:GetAttribute("PushZ") or 0)
					)
				end
			end
		end
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutSweeperController", source = [================[
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local sweeperStates = {}
local controllerStartTime = os.clock()

local function getPlayerAndCharacter(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end

	return Players:GetPlayerFromCharacter(character), character
end

local function knockCharacterFromSweeper(part, character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root then
		return
	end

	local offset = root.Position - part.Position
	local direction = Vector3.new(offset.X, 0, offset.Z)
	if direction.Magnitude < 0.1 then
		direction = part.CFrame.RightVector
	end

	root.AssemblyLinearVelocity = direction.Unit * (part:GetAttribute("KnockStrength") or 76) + Vector3.new(0, part:GetAttribute("KnockLift") or 20, 0)
	root.AssemblyAngularVelocity = Vector3.new(0, 0, 10)
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end
end

local function trackSweeper(part)
	if not part:IsA("BasePart") or sweeperStates[part] then
		return
	end

	sweeperStates[part] = {
		Origin = part.CFrame,
		Period = part:GetAttribute("Period") or 2.8,
		Phase = part:GetAttribute("Phase") or 0,
		Direction = part:GetAttribute("Direction") or 1,
	}

	part.Anchored = true
	part:SetAttribute("SweeperControllerTracked", true)

	part.Touched:Connect(function(hit)
		local player, character = getPlayerAndCharacter(hit)
		if player then
			knockCharacterFromSweeper(part, character)
		end
	end)
end

local function refreshSweepers()
	local trackedCount = 0
	for _, part in ipairs(CollectionService:GetTagged("TG_Sweeper")) do
		if part:IsA("BasePart") then
			trackSweeper(part)
		end
	end

	for part in pairs(sweeperStates) do
		if part.Parent then
			trackedCount += 1
		end
	end

	workspace:SetAttribute("SweeperControllerTrackedCount", trackedCount)
end

refreshSweepers()
CollectionService:GetInstanceAddedSignal("TG_Sweeper"):Connect(function(instance)
	if instance:IsA("BasePart") then
		trackSweeper(instance)
		refreshSweepers()
	end
end)

RunService.Heartbeat:Connect(function()
	local elapsed = os.clock() - controllerStartTime
	workspace:SetAttribute("SweeperControllerTick", elapsed)
	refreshSweepers()

	for part, state in pairs(sweeperStates) do
		if not part.Parent then
			sweeperStates[part] = nil
		else
			local period = math.max(state.Period, 0.4)
			local angle = (elapsed + state.Phase) * math.pi * 2 / period * state.Direction
			part.CFrame = state.Origin * CFrame.Angles(0, angle, 0)
		end
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutTilterController", source = [================[
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TILTER_TAG = "TG_Tilter"
local startTime = os.clock()

local tilters = {}

local function trackTilter(part)
	if not part:IsA("BasePart") or tilters[part] then
		return
	end

	part.Anchored = true
	tilters[part] = {
		Origin = part.CFrame,
		MaxAngle = math.rad(part:GetAttribute("MaxAngle") or 10),
		Period = part:GetAttribute("Period") or 4,
		Phase = part:GetAttribute("Phase") or 0,
		Axis = part:GetAttribute("TiltAxis") or "Z",
	}
	part:SetAttribute("TilterControllerTracked", true)
end

local function refresh()
	local count = 0
	for _, part in ipairs(CollectionService:GetTagged(TILTER_TAG)) do
		if part:IsA("BasePart") then
			trackTilter(part)
		end
	end

	for part in pairs(tilters) do
		if part.Parent then
			count += 1
		end
	end
	workspace:SetAttribute("TilterControllerTrackedCount", count)
end

refresh()
CollectionService:GetInstanceAddedSignal(TILTER_TAG):Connect(function(part)
	trackTilter(part)
	refresh()
end)

RunService.Heartbeat:Connect(function()
	local elapsed = os.clock() - startTime
	refresh()

	for part, state in pairs(tilters) do
		if not part.Parent then
			tilters[part] = nil
		else
			local angle = math.sin((elapsed + state.Phase) * math.pi * 2 / math.max(state.Period, 0.5)) * state.MaxAngle
			if state.Axis == "X" then
				part.CFrame = state.Origin * CFrame.Angles(angle, 0, 0)
			else
				part.CFrame = state.Origin * CFrame.Angles(0, 0, angle)
			end
		end
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutSwingBallController", source = [================[
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SWING_TAG = "TG_SwingBall"
local startTime = os.clock()

local balls = {}
local lastHitByPlayer = {}

local function getPlayerAndRoot(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end

	local player = Players:GetPlayerFromCharacter(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	return player, root
end

local function knockPlayer(player, root, ball, ballVelocity)
	local now = os.clock()
	local lastHit = lastHitByPlayer[player] or 0
	if now - lastHit < 0.55 then
		return false
	end
	lastHitByPlayer[player] = now

	local fallback = root.Position - ball.Position
	local sideDirection
	if ballVelocity.Magnitude > 0.05 then
		sideDirection = ballVelocity.Unit
	elseif fallback.Magnitude > 0.05 then
		sideDirection = fallback.Unit
	else
		sideDirection = Vector3.new(1, 0, 0)
	end

	local forwardCarry = Vector3.new(0, 0, 28)
	root.AssemblyLinearVelocity = Vector3.new(sideDirection.X * 135, 58, sideDirection.Z * 135) + forwardCarry
	return true
end

local function trackBall(ball)
	if not ball:IsA("BasePart") or balls[ball] then
		return
	end

	ball.Anchored = true
	ball.CanCollide = true
	ball:SetAttribute("SwingBallTracked", true)

	local pivot = Vector3.new(
		ball:GetAttribute("PivotX") or ball.Position.X,
		ball:GetAttribute("PivotY") or (ball.Position.Y + 18),
		ball:GetAttribute("PivotZ") or ball.Position.Z
	)

	balls[ball] = {
		Pivot = pivot,
		Length = ball:GetAttribute("CableLength") or 18,
		Amplitude = math.rad(ball:GetAttribute("Amplitude") or 34),
		Period = ball:GetAttribute("Period") or 3.6,
		Phase = ball:GetAttribute("Phase") or 0,
		Axis = ball:GetAttribute("SwingAxis") or "X",
		Cable = ball.Parent and ball.Parent:FindFirstChild(ball.Name .. "_Cable"),
		LastPosition = ball.Position,
	}

	ball.Touched:Connect(function(hit)
		local player, root = getPlayerAndRoot(hit)
		if not player or not root then
			return
		end

		local velocity = balls[ball] and (ball.Position - balls[ball].LastPosition) or Vector3.zero
		knockPlayer(player, root, ball, velocity)
	end)
end

local function refresh()
	local count = 0
	for _, ball in ipairs(CollectionService:GetTagged(SWING_TAG)) do
		if ball:IsA("BasePart") then
			trackBall(ball)
		end
	end

	for ball in pairs(balls) do
		if ball.Parent then
			count += 1
		else
			balls[ball] = nil
		end
	end

	workspace:SetAttribute("SwingBallControllerTrackedCount", count)
end

refresh()
CollectionService:GetInstanceAddedSignal(SWING_TAG):Connect(function(ball)
	trackBall(ball)
	refresh()
end)

RunService.Heartbeat:Connect(function()
	local elapsed = os.clock() - startTime
	refresh()

	for ball, state in pairs(balls) do
		if not ball.Parent then
			balls[ball] = nil
		else
			state.LastPosition = ball.Position

			local theta = math.sin((elapsed + state.Phase) * math.pi * 2 / math.max(state.Period, 0.5)) * state.Amplitude
			local offset
			if state.Axis == "Z" then
				offset = Vector3.new(0, -math.cos(theta) * state.Length, math.sin(theta) * state.Length)
			else
				offset = Vector3.new(math.sin(theta) * state.Length, -math.cos(theta) * state.Length, 0)
			end

			local position = state.Pivot + offset
			ball.CFrame = CFrame.new(position)

			if state.Cable and state.Cable.Parent then
				local center = (state.Pivot + position) * 0.5
				local direction = state.Pivot - position
				state.Cable.Size = Vector3.new(0.35, direction.Magnitude, 0.35)
				state.Cable.CFrame = CFrame.lookAt(center, state.Pivot) * CFrame.Angles(math.rad(90), 0, 0)
			end

			local radius = math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * 0.5
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - ball.Position).Magnitude <= radius + 3.2 then
					knockPlayer(player, root, ball, ball.Position - state.LastPosition)
				end
			end
		end
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutLobbyController", source = [================[
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local START_TAG = "TG_StartPortal"
local LOBBY_TAG = "TG_LobbyReturn"
local touchCooldown = {}

local function teleportCharacter(player, targetPart)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not targetPart then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local spawnPosition = targetPart.Position + Vector3.new(0, 6, -2)
	root.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(0, 0, 1))
end

local function getPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function canUse(player)
	local now = os.clock()
	local last = touchCooldown[player] or 0
	if now - last < 1.0 then
		return false
	end
	touchCooldown[player] = now
	return true
end

local function connectStartPortal(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player) then
			return
		end

		player:SetAttribute("InLobby", false)
		player:SetAttribute("CurrentCheckpoint", "")
		player:SetAttribute("CourseFinished", false)
		player:SetAttribute("RunStartTime", nil)
		player:SetAttribute("RunElapsedSeconds", nil)
		player:SetAttribute("RunTimeSeconds", nil)
		local start = workspace:FindFirstChild("Checkpoint_1", true) or workspace:FindFirstChild("WipeoutStart", true)
		teleportCharacter(player, start)
	end)
end

local function connectLobbyReturn(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player) then
			return
		end

		player:SetAttribute("InLobby", true)
		player:SetAttribute("CurrentCheckpoint", "")
		player:SetAttribute("CourseFinished", false)
		player:SetAttribute("RunStartTime", nil)
		player:SetAttribute("RunElapsedSeconds", nil)
		player:SetAttribute("RunTimeSeconds", nil)
		local lobby = workspace:FindFirstChild("LobbySpawn", true)
		teleportCharacter(player, lobby)
	end)
end

local function connectTagged(tagName, connect)
	for _, part in ipairs(CollectionService:GetTagged(tagName)) do
		if part:IsA("BasePart") then
			connect(part)
		end
	end
	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(part)
		if part:IsA("BasePart") then
			connect(part)
		end
	end)
end

connectTagged(START_TAG, connectStartPortal)
connectTagged(LOBBY_TAG, connectLobbyReturn)

Players.PlayerRemoving:Connect(function(player)
	touchCooldown[player] = nil
end)

]================] },
	{ service = "StarterPlayer", folders = {"StarterPlayerScripts", "TinyGiantObby"}, className = "LocalScript", name = "SizeClient", source = [================[
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

]================] },
}

for _, entry in ipairs(entries) do
	local parent = game:GetService(entry.service)
	for _, folderName in ipairs(entry.folders) do
		parent = ensureFolder(parent, folderName)
	end
	local instance = Instance.new(entry.className)
	instance.Name = entry.name
	instance.Source = entry.source
	instance.Parent = parent
end

-- Build the course.
-- Paste this into Roblox Studio's Command Bar after syncing/adding the scripts.
-- Wipeout Run: four readable obstacle zones with soft resets and clear checkpoints.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 14
Lighting.Brightness = 1.6
Lighting.Ambient = Color3.fromRGB(80, 90, 105)
Lighting.OutdoorAmbient = Color3.fromRGB(105, 120, 135)

for _, effect in ipairs(Lighting:GetChildren()) do
	if effect:IsA("BloomEffect") then
		effect.Enabled = false
	end
end

local existing = workspace:FindFirstChild("TinyGiantGraybox")
if existing then
	existing:Destroy()
end

for _, instance in ipairs(workspace:GetChildren()) do
	if instance:IsA("BasePart") and instance.Name == "Baseplate" then
		instance:Destroy()
	end
end

local course = Instance.new("Folder")
course.Name = "TinyGiantGraybox"
course.Parent = workspace

local COIN_ASSET_ID = "rbxassetid://14861633855"
local coinTemplate = nil

local COLORS = {
	Floor = Color3.fromRGB(70, 90, 112),
	FloorAlt = Color3.fromRGB(48, 64, 86),
	Wall = Color3.fromRGB(26, 32, 48),
	Trim = Color3.fromRGB(230, 190, 55),
	Checkpoint = Color3.fromRGB(80, 180, 105),
	Water = Color3.fromRGB(18, 58, 112),
	Pad = Color3.fromRGB(255, 210, 70),
	Landing = Color3.fromRGB(72, 108, 132),
	Sweeper = Color3.fromRGB(255, 236, 58),
	SweeperPost = Color3.fromRGB(255, 74, 86),
	Punch = Color3.fromRGB(65, 70, 85),
	Coin = Color3.fromRGB(255, 224, 50),
	Dark = Color3.fromRGB(18, 22, 34),
	Support = Color3.fromRGB(70, 76, 86),
	White = Color3.fromRGB(60, 125, 165),
}

local function part(name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = course
	return p
end

local function block(name, size, position, color, material)
	return part(name, size, CFrame.new(position), color, material)
end

local function neon(name, size, position, color)
	return block(name, size, position, color, Enum.Material.SmoothPlastic)
end

local function nonSolid(p)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function floorTile(name, z, length, color)
	local tile = block(name, Vector3.new(46, 1, length), Vector3.new(0, 0, z), color or COLORS.Floor)
	block(name .. "_LeftWall", Vector3.new(2.5, 8, length), Vector3.new(-24.25, 3.5, z), COLORS.Wall)
	block(name .. "_RightWall", Vector3.new(2.5, 8, length), Vector3.new(24.25, 3.5, z), COLORS.Wall)
	return tile
end

local function pit(name, z, length)
	local p = block(name, Vector3.new(54, 1.2, length), Vector3.new(0, -4.4, z), COLORS.Water, Enum.Material.SmoothPlastic)
	p.Transparency = 0.18
	p.CanCollide = false
	p.CanQuery = false
	p:SetAttribute("SoftReset", true)
	CollectionService:AddTag(p, "TG_Kill")

	for offset = -length * 0.5 + 8, length * 0.5 - 8, 12 do
		local wave = neon(name .. "_Wave_" .. tostring(math.floor(offset)), Vector3.new(38, 0.12, 1.2), Vector3.new(0, -3.72, z + offset), Color3.fromRGB(45, 115, 175))
		wave.Transparency = 0.5
		nonSolid(wave)
	end

	return p
end

local function checkpoint(index, z)
	local p = neon("Checkpoint_" .. index, Vector3.new(34, 0.55, 8), Vector3.new(0, 0.85, z), COLORS.Checkpoint)
	p.Transparency = 0.08
	p.CanCollide = false
	CollectionService:AddTag(p, "TG_Checkpoint")
	return p
end

local function getCoinTemplate()
	if coinTemplate and coinTemplate.Parent == nil then
		return coinTemplate
	end

	local ok, objects = pcall(function()
		return game:GetObjects(COIN_ASSET_ID)
	end)
	if ok and objects and objects[1] and objects[1]:IsA("BasePart") then
		coinTemplate = objects[1]
		coinTemplate.Name = "CoinTemplate"
		coinTemplate.Parent = nil
		return coinTemplate
	end

	return nil
end

local function coin(name, position, value)
	local template = getCoinTemplate()
	local p
	if template then
		p = template:Clone()
		p.Name = name
		p.Size = Vector3.new(3, 3, 0.68)
		p.CFrame = CFrame.new(position)
		p.Anchored = true
		p.Color = COLORS.Coin
		p.Material = Enum.Material.Metal
		p.Parent = course
	else
		p = block(name, Vector3.new(0.42, 3.2, 3.2), position, COLORS.Coin, Enum.Material.Metal)
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
	end
	p.Reflectance = 0.08
	p.CanCollide = false
	p.CanTouch = true
	p.CanQuery = true
	p:SetAttribute("CoinValue", value or 1)
	CollectionService:AddTag(p, "TG_Coin")

	local light = Instance.new("PointLight")
	light.Color = COLORS.Coin
	light.Brightness = 0.12
	light.Range = 5
	light.Parent = p
	return p
end

local function arrow(name, z, color)
	local base = neon(name .. "_ArrowBase", Vector3.new(9, 0.2, 1.1), Vector3.new(0, 1.05, z), color)
	nonSolid(base)
	local left = neon(name .. "_ArrowLeft", Vector3.new(4.8, 0.2, 1.1), Vector3.new(-2.2, 1.05, z + 2.2), color)
	left.Orientation = Vector3.new(0, 35, 0)
	nonSolid(left)
	local right = neon(name .. "_ArrowRight", Vector3.new(4.8, 0.2, 1.1), Vector3.new(2.2, 1.05, z + 2.2), color)
	right.Orientation = Vector3.new(0, -35, 0)
	nonSolid(right)
end

local function stepPad(index, position)
	local pad = block("StepPad_" .. index, Vector3.new(18, 1, 12), position, COLORS.Pad)
	pad.Material = Enum.Material.SmoothPlastic
	return pad
end

local function islandPad(name, position, size)
	local pad = block(name, size or Vector3.new(12, 1.2, 10), position, COLORS.Landing)
	pad.Material = Enum.Material.SmoothPlastic
	return pad
end

local function runway(name, z, length, width)
	local w = width or 10
	local deck = block(name, Vector3.new(w, 1.2, length), Vector3.new(0, 1.05, z), COLORS.Pad)
	nonSolid(neon(name .. "_LeftEdge", Vector3.new(0.3, 0.12, length), Vector3.new(-w * 0.5 - 0.15, 1.74, z), COLORS.White))
	nonSolid(neon(name .. "_RightEdge", Vector3.new(0.3, 0.12, length), Vector3.new(w * 0.5 + 0.15, 1.74, z), COLORS.White))
	return deck
end

local function sweeper(name, position, length, period, phase)
	local hub = block(name .. "_Hub", Vector3.new(4, 6, 4), position + Vector3.new(0, 1, 0), COLORS.SweeperPost)
	hub.Shape = Enum.PartType.Cylinder
	hub.Material = Enum.Material.Rubber
	hub.Orientation = Vector3.new(0, 0, 0)

	local cap = block(name .. "_Cap", Vector3.new(5, 0.5, 5), position + Vector3.new(0, 4.25, 0), COLORS.Trim)
	cap.Shape = Enum.PartType.Cylinder
	cap.Material = Enum.Material.SmoothPlastic

	local arm = block(name, Vector3.new(length, 1.15, 1.15), position + Vector3.new(0, 2.9, 0), COLORS.Sweeper, Enum.Material.SmoothPlastic)
	arm:SetAttribute("Period", period)
	arm:SetAttribute("Phase", phase or 0)
	arm:SetAttribute("KnockStrength", 78)
	arm:SetAttribute("KnockLift", 20)
	CollectionService:AddTag(arm, "TG_Sweeper")
	return arm
end

local function punchBlock(name, startPosition, size, travelX, period, phase)
	local p = block(name, size, startPosition, COLORS.Punch)
	p.CanCollide = false
	p:SetAttribute("TravelX", travelX)
	p:SetAttribute("TravelY", 0)
	p:SetAttribute("Period", period)
	p:SetAttribute("Phase", phase or 0)
	p:SetAttribute("KnockOnly", true)
	p:SetAttribute("KnockStrength", 56)
	p:SetAttribute("KnockLift", 16)
	p:SetAttribute("KnockDirection", if travelX > 0 then "Right" else "Left")
	CollectionService:AddTag(p, "TG_Crusher")
	return p
end

local function timingBumper(name, startPosition, travelX, period, phase)
	local p = block(name, Vector3.new(11, 5.5, 8), startPosition, Color3.fromRGB(215, 42, 48), Enum.Material.SmoothPlastic)
	p.CanCollide = false
	p:SetAttribute("TravelX", travelX)
	p:SetAttribute("TravelY", 0)
	p:SetAttribute("Period", period)
	p:SetAttribute("Phase", phase or 0)
	p:SetAttribute("KnockOnly", true)
	p:SetAttribute("KnockStrength", 78)
	p:SetAttribute("KnockLift", 18)
	p:SetAttribute("KnockDirection", if travelX > 0 then "Right" else "Left")
	CollectionService:AddTag(p, "TG_Crusher")
	return p
end

local function conveyorZone(name, z, pushX, color)
	local zone = neon(name, Vector3.new(9, 0.8, 16), Vector3.new(0, 2.4, z), color or Color3.fromRGB(255, 150, 60))
	zone.Transparency = 0.32
	zone:SetAttribute("PushX", pushX)
	zone:SetAttribute("ForwardMin", 12)
	CollectionService:AddTag(zone, "TG_Conveyor")
	nonSolid(zone)

	local arrowColor = if pushX > 0 then Color3.fromRGB(255, 120, 70) else Color3.fromRGB(120, 240, 255)
	local center = neon(name .. "_ArrowBase", Vector3.new(4.8, 0.14, 0.8), Vector3.new(pushX > 0 and 1.2 or -1.2, 2.9, z), arrowColor)
	center.Orientation = Vector3.new(0, pushX > 0 and -25 or 25, 0)
	nonSolid(center)
	local head = neon(name .. "_ArrowHead", Vector3.new(2.2, 0.14, 2.2), Vector3.new(pushX > 0 and 3.4 or -3.4, 2.9, z), arrowColor)
	head.Orientation = Vector3.new(0, 45, 0)
	nonSolid(head)
	return zone
end

local function tiltTable(name, position, size, maxAngle, period, phase, axis)
	local tableTop = block(name, size or Vector3.new(18, 1.2, 14), position, COLORS.Pad)
	tableTop:SetAttribute("MaxAngle", maxAngle or 9)
	tableTop:SetAttribute("Period", period or 4.2)
	tableTop:SetAttribute("Phase", phase or 0)
	tableTop:SetAttribute("TiltAxis", axis or "Z")
	CollectionService:AddTag(tableTop, "TG_Tilter")

	local pivot = block(name .. "_Pivot", Vector3.new(3.2, 1.8, 3.2), position + Vector3.new(0, -1.55, 0), COLORS.Dark)
	pivot.Shape = Enum.PartType.Cylinder
	return tableTop
end

local function launchStation(name, z, launchX, launchY, launchZ)
	local base = block(name .. "_OrangeRamp", Vector3.new(22, 1.2, 12), Vector3.new(0, 1.05, z), Color3.fromRGB(255, 142, 45), Enum.Material.SmoothPlastic)
	base.CFrame = CFrame.new(0, 1.05, z) * CFrame.Angles(math.rad(-7), 0, 0)

	local plate = neon(name .. "_LaunchPlate", Vector3.new(20, 0.16, 9), Vector3.new(0, 2.15, z), Color3.fromRGB(255, 226, 50))
	plate.Transparency = 0.12
	nonSolid(plate)

	local trigger = block(name .. "_LaunchTrigger", Vector3.new(21, 6, 11), Vector3.new(0, 4.2, z), Color3.fromRGB(255, 226, 50), Enum.Material.SmoothPlastic)
	trigger.Transparency = 1
	trigger:SetAttribute("LaunchX", launchX or 0)
	trigger:SetAttribute("LaunchY", launchY or 56)
	trigger:SetAttribute("LaunchZ", launchZ or 78)
	CollectionService:AddTag(trigger, "TG_LaunchPad")
	nonSolid(trigger)

	nonSolid(neon(name .. "_ArrowBase", Vector3.new(8, 0.14, 1), Vector3.new(0, 2.85, z + 0.5), COLORS.White))
	local arrowTip = neon(name .. "_ArrowTip", Vector3.new(4, 0.14, 4), Vector3.new(0, 2.85, z + 3.8), COLORS.White)
	arrowTip.Orientation = Vector3.new(0, 45, 0)
	nonSolid(arrowTip)
	return base
end

local function swingBall(name, z, x, amplitude, period, phase)
	local pivot = Vector3.new(x, 25, z)
	local cableLength = 18
	local ballRadius = 4.2

	local hanger = block(name .. "_Hanger", Vector3.new(3.8, 0.7, 3.8), pivot, COLORS.Support, Enum.Material.Metal)
	hanger.Shape = Enum.PartType.Cylinder
	hanger.CanCollide = false

	local cable = block(name .. "_Cable", Vector3.new(0.35, cableLength, 0.35), pivot + Vector3.new(0, -cableLength * 0.5, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	cable.CanCollide = false

	local ball = block(name, Vector3.new(ballRadius * 2, ballRadius * 2, ballRadius * 2), pivot + Vector3.new(0, -cableLength, 0), Color3.fromRGB(210, 36, 42), Enum.Material.SmoothPlastic)
	ball.Shape = Enum.PartType.Ball
	ball:SetAttribute("PivotX", pivot.X)
	ball:SetAttribute("PivotY", pivot.Y)
	ball:SetAttribute("PivotZ", pivot.Z)
	ball:SetAttribute("CableLength", cableLength)
	ball:SetAttribute("Amplitude", amplitude or 34)
	ball:SetAttribute("Period", period or 3.6)
	ball:SetAttribute("Phase", phase or 0)
	ball:SetAttribute("SwingAxis", "X")
	CollectionService:AddTag(ball, "TG_SwingBall")

	return ball
end

local function spawnLocation()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(22, 1, 14)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1, -145), Vector3.new(0, 1, -125))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.Color = COLORS.Checkpoint
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = course
	return spawn
end

local function labelBoard(name, position, size, title, body, titleColor)
	local board = block(name, size or Vector3.new(24, 9, 1), position, COLORS.Dark, Enum.Material.SmoothPlastic)
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Text"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromScale(0.06, 0.08)
	titleLabel.Size = UDim2.fromScale(0.88, 0.28)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor or COLORS.Trim
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.Parent = gui

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.Position = UDim2.fromScale(0.08, 0.42)
	bodyLabel.Size = UDim2.fromScale(0.84, 0.44)
	bodyLabel.Font = Enum.Font.GothamBold
	bodyLabel.Text = body
	bodyLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
	bodyLabel.TextScaled = true
	bodyLabel.TextWrapped = true
	bodyLabel.Parent = gui
	return board
end

local function portal(name, position, size, color, tag)
	local p = block(name, size, position, color, Enum.Material.SmoothPlastic)
	p.Transparency = 0.08
	p.CanCollide = false
	CollectionService:AddTag(p, tag)
	return p
end

local function lobbyArea()
	block("LobbyFloor", Vector3.new(96, 1, 82), Vector3.new(0, 0, -130), COLORS.FloorAlt)
	block("LobbyBackWall", Vector3.new(100, 9, 2.5), Vector3.new(0, 4, -171), COLORS.Wall)
	block("LobbyLeftWall", Vector3.new(2.5, 9, 82), Vector3.new(-49, 4, -130), COLORS.Wall)
	block("LobbyRightWall", Vector3.new(2.5, 9, 82), Vector3.new(49, 4, -130), COLORS.Wall)

	labelBoard("LobbyTitleBoard", Vector3.new(0, 8, -170), Vector3.new(42, 10, 1), "WIPEOUT HUB", "Pick a course. Fall in water, reset fast, run again.", COLORS.Trim)
	labelBoard("LobbyWipeoutBoard", Vector3.new(0, 8, -88), Vector3.new(32, 9, 1), "WIPEOUT RUN", "Portal opens the obstacle course.", COLORS.Trim)
	labelBoard("LobbyFactoryBoard", Vector3.new(-31, 7, -104), Vector3.new(24, 8, 1), "FACTORY CHAOS", "Coming next.", Color3.fromRGB(160, 180, 205))
	labelBoard("LobbyComputerBoard", Vector3.new(31, 7, -104), Vector3.new(24, 8, 1), "COMPUTER OBBY", "Next game prototype.", Color3.fromRGB(160, 180, 205))

	portal("Portal_WipeoutRun", Vector3.new(0, 3.2, -101), Vector3.new(18, 6, 2), COLORS.Trim, "TG_StartPortal")
	block("Portal_WipeoutRun_FrameTop", Vector3.new(22, 1, 2), Vector3.new(0, 6.5, -101), COLORS.Dark, Enum.Material.Metal)
	block("Portal_WipeoutRun_FrameLeft", Vector3.new(1, 7, 2), Vector3.new(-11, 3.6, -101), COLORS.Dark, Enum.Material.Metal)
	block("Portal_WipeoutRun_FrameRight", Vector3.new(1, 7, 2), Vector3.new(11, 3.6, -101), COLORS.Dark, Enum.Material.Metal)

	block("PracticeJumpPad", Vector3.new(16, 1, 10), Vector3.new(-24, 1.05, -139), COLORS.Pad)
	block("PracticeDodgeBlock", Vector3.new(9, 5, 5), Vector3.new(24, 3.5, -139), Color3.fromRGB(210, 36, 42))
	block("PracticeWaterSample", Vector3.new(22, 1, 12), Vector3.new(0, -1.2, -116), COLORS.Water).CanCollide = false
	coin("LobbyCoin_1", Vector3.new(-17, 4, -127), 1)
	coin("LobbyCoin_2", Vector3.new(17, 4, -127), 1)
end

-- Start zone.
lobbyArea()
spawnLocation()
floorTile("StartDeck", -32, 50, COLORS.Floor)
checkpoint(1, -48)
arrow("Start", -22, COLORS.Trim)

-- Obstacle 1: simple stepping pads over a soft-reset water pool.
floorTile("BallRun_EntryDeck", 2, 18, COLORS.FloorAlt)
pit("BallRun_ResetPit", 43, 70)
block("BallRun_LeftWall", Vector3.new(2.5, 8, 78), Vector3.new(-24.25, 3.5, 43), COLORS.Wall)
block("BallRun_RightWall", Vector3.new(2.5, 8, 78), Vector3.new(24.25, 3.5, 43), COLORS.Wall)
stepPad(1, Vector3.new(-8, 0.9, 16))
stepPad(2, Vector3.new(6, 0.9, 30))
stepPad(3, Vector3.new(-6, 0.9, 44))
stepPad(4, Vector3.new(8, 0.9, 58))
floorTile("BallRun_ExitDeck", 82, 30, COLORS.Floor)
checkpoint(2, 76)

-- Obstacle 2: introductory sweeper over water. The wide yellow runway eases in.
floorTile("SweeperEntryDeck", 105, 14, COLORS.Floor)
pit("SweeperDeck_ResetPit", 132, 54)
block("SweeperDeck_Runway", Vector3.new(30, 1.2, 54), Vector3.new(0, 1.05, 132), COLORS.Pad)
nonSolid(neon("SweeperDeck_LeftEdge", Vector3.new(0.3, 0.12, 54), Vector3.new(-15.15, 1.74, 132), COLORS.White))
nonSolid(neon("SweeperDeck_RightEdge", Vector3.new(0.3, 0.12, 54), Vector3.new(15.15, 1.74, 132), COLORS.White))
checkpoint(3, 102)
sweeper("SweeperArm_1", Vector3.new(0, 2.05, 132), 50, 4.2, 0)
arrow("Sweeper", 112, COLORS.Sweeper)

-- Obstacle 3: moving punch blocks over water. Hits knock players off; water resets.
pit("PunchCorridor_ResetPit", 188, 88)
block("PunchCorridor_WideRun", Vector3.new(24, 1.2, 82), Vector3.new(0, 1.05, 188), COLORS.Pad)
checkpoint(4, 152)
punchBlock("PunchBlock_1", Vector3.new(-18, 3.5, 174), Vector3.new(11, 5, 6), 28, 4.8, 0)
punchBlock("PunchBlock_2", Vector3.new(18, 3.5, 192), Vector3.new(11, 5, 6), -28, 4.5, 0.8)
punchBlock("PunchBlock_3", Vector3.new(-18, 3.5, 210), Vector3.new(11, 5, 6), 28, 4.2, 1.6)
punchBlock("PunchBlock_4", Vector3.new(18, 3.5, 226), Vector3.new(11, 5, 6), -28, 4.0, 2.4)

-- Obstacle 4: narrow final spinner bridge over a soft-reset water pool.
floorTile("FinalEntryDeck", 243, 28, COLORS.Floor)
checkpoint(5, 238)
pit("FinalBridge_ResetPit", 286, 72)
block("Final_LeftWall", Vector3.new(2.5, 8, 84), Vector3.new(-24.25, 3.5, 286), COLORS.Wall)
block("Final_RightWall", Vector3.new(2.5, 8, 84), Vector3.new(24.25, 3.5, 286), COLORS.Wall)
block("FinalBridge_WideRun", Vector3.new(22, 1.2, 76), Vector3.new(0, 1.05, 286), COLORS.Pad)
nonSolid(neon("FinalBridge_LeftEdge", Vector3.new(0.3, 0.12, 76), Vector3.new(-11.15, 1.74, 286), COLORS.White))
nonSolid(neon("FinalBridge_RightEdge", Vector3.new(0.3, 0.12, 76), Vector3.new(11.15, 1.74, 286), COLORS.White))
sweeper("FinalSweeper_1", Vector3.new(0, 2.05, 272), 46, 2.9, 0.2)
sweeper("FinalSweeper_2", Vector3.new(0, 2.05, 302), 46, 2.7, 1.1)

-- Rest deck before the added courses.
floorTile("RestDeck_AfterSpinner", 342, 42, COLORS.FloorAlt)

-- Added course 1: tilting tables over water. Slow, visible movement with safe water resets.
floorTile("TiltTables_EntryDeck", 374, 18, COLORS.Floor)
checkpoint(6, 368)
pit("TiltTables_ResetPit", 422, 82)
block("TiltTables_LeftWall", Vector3.new(2.5, 8, 90), Vector3.new(-24.25, 3.5, 422), COLORS.Wall)
block("TiltTables_RightWall", Vector3.new(2.5, 8, 90), Vector3.new(24.25, 3.5, 422), COLORS.Wall)
tiltTable("TiltTable_1", Vector3.new(0, 1.2, 394), Vector3.new(36, 1.2, 18), 6, 4.8, 0, "Z")
tiltTable("TiltTable_2", Vector3.new(0, 1.2, 414), Vector3.new(34, 1.2, 18), 8, 4.4, 1.1, "X")
tiltTable("TiltTable_3", Vector3.new(0, 1.2, 434), Vector3.new(32, 1.2, 18), 9, 4.1, 2.2, "Z")
floorTile("TiltTables_ExitDeck", 469, 48, COLORS.FloorAlt)

-- Added course 2: launch-pad lagoon. Orange ramps send players across clear water gaps.
floorTile("LaunchLagoon_EntryDeck", 502, 18, COLORS.Floor)
checkpoint(7, 496)
pit("LaunchLagoon_ResetPit", 576, 142)
block("LaunchLagoon_LeftWall", Vector3.new(2.5, 8, 148), Vector3.new(-24.25, 3.5, 576), COLORS.Wall)
block("LaunchLagoon_RightWall", Vector3.new(2.5, 8, 148), Vector3.new(24.25, 3.5, 576), COLORS.Wall)
launchStation("LaunchLagoon_Jump_1", 520, 0, 36, 84)
islandPad("LaunchLagoon_Landing_1", Vector3.new(0, 1.05, 552), Vector3.new(42, 1.2, 34))
timingBumper("LaunchLagoon_TimingBumper_1", Vector3.new(-18, 4.15, 552), 36, 2.9, 0)
launchStation("LaunchLagoon_Jump_2", 582, 0, 36, 84)
islandPad("LaunchLagoon_Landing_2", Vector3.new(0, 1.05, 617), Vector3.new(42, 1.2, 34))
timingBumper("LaunchLagoon_TimingBumper_2", Vector3.new(18, 4.15, 617), -36, 2.6, 1.2)
floorTile("LaunchLagoon_ExitDeck", 650, 30, COLORS.FloorAlt)

-- Added course 3: swinging red balls over water. Hits knock players off; water resets.
checkpoint(8, 626)
pit("SwingBalls_ResetPit", 686, 116)
block("SwingBalls_LeftWall", Vector3.new(2.5, 8, 122), Vector3.new(-24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_RightWall", Vector3.new(2.5, 8, 122), Vector3.new(24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_Bridge", Vector3.new(30, 1.2, 116), Vector3.new(0, 1.05, 686), COLORS.Pad)
local swingTube = part("SwingBalls_OverheadTube", Vector3.new(2.6, 116, 2.6), CFrame.new(0, 25, 686) * CFrame.Angles(math.rad(90), 0, 0), COLORS.Support, Enum.Material.Metal)
swingTube.Shape = Enum.PartType.Cylinder
swingTube.CanCollide = false
swingBall("SwingBall_1", 658, 0, 32, 4.2, 0.0)
swingBall("SwingBall_2", 678, 0, 36, 3.8, 1.1)
swingBall("SwingBall_3", 698, 0, 38, 3.5, 2.1)
swingBall("SwingBall_4", 718, 0, 34, 3.7, 2.8)

-- Finish.
floorTile("FinishDeck", 752, 44, COLORS.FloorAlt)
local finish = neon("FinishGate", Vector3.new(24, 1, 10), Vector3.new(0, 1, 736), COLORS.Trim)
finish.CanCollide = false
CollectionService:AddTag(finish, "TG_Finish")
block("FinishArch_Left", Vector3.new(2, 9, 2), Vector3.new(-14, 4.5, 736), COLORS.Trim, Enum.Material.Metal)
block("FinishArch_Right", Vector3.new(2, 9, 2), Vector3.new(14, 4.5, 736), COLORS.Trim, Enum.Material.Metal)
block("FinishArch_Top", Vector3.new(30, 2, 2), Vector3.new(0, 9, 736), COLORS.Trim, Enum.Material.Metal)
labelBoard("FinishResultBoard", Vector3.new(0, 7.5, 747), Vector3.new(34, 8, 1), "FINISH!", "Beat your best time, grab more coins, or return to the hub.", COLORS.Trim)
local replayPad = portal("ReplayWipeoutPad", Vector3.new(-13, 1.25, 766), Vector3.new(18, 0.45, 10), COLORS.Trim, "TG_StartPortal")
replayPad.Transparency = 0.02
local returnPad = portal("ReturnToLobbyPad", Vector3.new(13, 1.25, 766), Vector3.new(18, 0.45, 10), COLORS.Checkpoint, "TG_LobbyReturn")
returnPad.Transparency = 0.02
labelBoard("ReplayWipeoutBoard", Vector3.new(-13, 7, 776), Vector3.new(20, 7, 1), "RUN AGAIN", "Step on yellow.", COLORS.Trim)
labelBoard("ReturnToLobbyBoard", Vector3.new(13, 7, 776), Vector3.new(20, 7, 1), "HUB", "Step on green.", COLORS.Checkpoint)

-- Coins: visible drip through the lane plus a few risk-reward coins near hazards.
local coinIndex = 1
local function addCoin(x, y, z, value)
	coin("Coin_" .. coinIndex, Vector3.new(x, y, z), value)
	coinIndex += 1
end

for _, z in ipairs({-30, -18, -6, 98, 112, 140, 158, 168, 236, 246, 320, 335, 372, 390, 418, 442, 500, 520, 550, 566, 596, 630, 658, 678, 698, 718, 740}) do
	addCoin(0, 4, z, 1)
end

for _, spec in ipairs({
	{-7.5, 5.2, 18, 2},
	{5.5, 5.2, 34, 2},
	{-5, 5.2, 52, 2},
	{7.5, 5.2, 70, 2},
	{-8, 4, 126, 2},
	{8, 4, 126, 2},
	{-5, 4, 182, 1},
	{5, 4, 198, 1},
	{-5, 4, 214, 1},
	{0, 4, 272, 2},
	{0, 4, 302, 2},
	{-6, 4.2, 394, 2},
	{6, 4.2, 394, 2},
	{-5, 4.2, 418, 2},
	{5, 4.2, 442, 2},
	{-4, 4.2, 520, 2},
	{4, 4.2, 550, 2},
	{-4, 4.2, 566, 2},
	{4, 4.2, 596, 2},
	{-6, 4.2, 658, 2},
	{6, 4.2, 678, 2},
	{-4, 4.2, 698, 2},
	{5, 4.2, 718, 2},
}) do
	addCoin(spec[1], spec[2], spec[3], spec[4])
end

print("Built Wipeout Run with wider multiplayer lanes, split-lane tilting tables, launch-pad lagoon, swinging red balls, checkpoints, soft-reset water, knock hazards, and coins.")


print("Wipeout Run installed. Press Play to test the 7-zone course with wider lanes, launch lagoon, and swinging red ball finale.")
