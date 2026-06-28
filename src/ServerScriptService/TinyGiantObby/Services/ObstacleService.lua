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
