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
clearChild(game:GetService("ServerScriptService"), "WipeoutLobbyFeatures")
clearChild(game:GetService("ServerScriptService"), "WipeoutCoinAnimator")
clearChild(game:GetService("ServerScriptService"), "WipeoutQARunner")
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
local TIMER_START_PART_NAMES = {
	"StepPad_1",
	"FactoryStartPad",
	"ComputerStartPad",
}

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

local function getCourseNameForPart(part)
	return part:GetAttribute("CourseName") or "WipeoutRun"
end

local function getBestTimeAttribute(courseName)
	if courseName == "FactoryChaos" then
		return "BestFactoryTimeSeconds"
	elseif courseName == "ComputerObby" then
		return "BestComputerTimeSeconds"
	end
	return "BestRunTimeSeconds"
end

local function courseMatchesPlayer(player, part)
	local courseName = getCourseNameForPart(part)
	local playerCourse = player:GetAttribute("CourseName")
	return playerCourse == nil or playerCourse == "" or playerCourse == courseName
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
	if part:GetAttribute("CourseStart") == true or (part.Name == "Checkpoint_1" and (state.completed or player:GetAttribute("InLobby") == true or player:GetAttribute("CurrentCheckpoint") == "")) then
		beginRun(player)
		state = runStateByPlayer[player]
	end

	checkpointByPlayer[player] = part
	player:SetAttribute("CurrentCheckpoint", part.Name)
	player:SetAttribute("CourseName", getCourseNameForPart(part))
	player:SetAttribute("InLobby", false)

	local key = part:GetFullName()
	if not state.touchedCheckpoints[key] then
		state.touchedCheckpoints[key] = true
		CurrencyService.addCoins(player, ObstacleConfig.CheckpointReward)
		FeedbackService.pulsePart(part, Color3.fromRGB(70, 255, 130))
		FeedbackService.burst(part, Color3.fromRGB(70, 255, 130), 16)
	end
end

local function processFinish(player, part)
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
	local courseName = part and getCourseNameForPart(part) or player:GetAttribute("CourseName")
	player:SetAttribute("CourseName", courseName or "WipeoutRun")
	local bestAttribute = getBestTimeAttribute(courseName)
	local best = player:GetAttribute(bestAttribute)
	if typeof(best) ~= "number" or best <= 0 or elapsed < best then
		player:SetAttribute(bestAttribute, elapsed)
	end
	CurrencyService.addWins(player, ObstacleConfig.FinishWins)
	CurrencyService.addCoins(player, ObstacleConfig.FinishCoins)
	local finishGate = part or workspace:FindFirstChild("FinishGate", true)
	FeedbackService.pulsePart(finishGate, Color3.fromRGB(255, 215, 0))
	if finishGate then
		FeedbackService.confettiAt(finishGate.Position + Vector3.new(0, 4, 0))
	end
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

		if courseMatchesPlayer(player, part) then
			processFinish(player, part)
		end
	end)
end

local function isTimerStartForPlayer(player, character, part)
	return part
		and part:IsA("BasePart")
		and (part:GetAttribute("StartsRun") == true or part.Name == "StepPad_1")
		and courseMatchesPlayer(player, part)
		and isCharacterNearPart(character, part)
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
				for _, timerStartPartName in ipairs(TIMER_START_PART_NAMES) do
					local timerStartPart = workspace:FindFirstChild(timerStartPartName, true)
					if isTimerStartForPlayer(player, character, timerStartPart) then
						startRunTimer(player)
					end
				end
				for part in pairs(finishParts) do
					if courseMatchesPlayer(player, part) and isCharacterNearPart(character, part) then
						processFinish(player, part)
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
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CurrencyService = {}

local DATASTORE_NAME = "WipeoutRunPlayerData_v1"
local SAVE_INTERVAL = 60

local storeOk, playerStore = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)
if not storeOk then
	playerStore = nil
end
local profiles = {}
local saving = {}

local function defaultProfile()
	return {
		Coins = 0,
		Wins = 0,
		LastDailyGiftDay = "",
		Purchases = {},
		EquippedCosmetic = "",
	}
end

local function dataKey(player)
	return "player_" .. tostring(player.UserId)
end

local function cleanNumber(value)
	if typeof(value) ~= "number" then
		return 0
	end
	return math.max(0, math.floor(value))
end

local function sanitizeProfile(data)
	local profile = defaultProfile()
	if typeof(data) ~= "table" then
		return profile
	end

	profile.Coins = cleanNumber(data.Coins)
	profile.Wins = cleanNumber(data.Wins)
	profile.LastDailyGiftDay = if typeof(data.LastDailyGiftDay) == "string" then data.LastDailyGiftDay else ""
	profile.EquippedCosmetic = if typeof(data.EquippedCosmetic) == "string" then data.EquippedCosmetic else ""

	if typeof(data.Purchases) == "table" then
		for key, value in pairs(data.Purchases) do
			if typeof(key) == "string" and value == true then
				profile.Purchases[key] = true
			end
		end
	end

	return profile
end

local function createStat(parent, name, value)
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Value = value
	stat.Parent = parent
	return stat
end

local function getStats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats,
		leaderstats and leaderstats:FindFirstChild("Size Coins"),
		leaderstats and leaderstats:FindFirstChild("Wins")
end

local function purchaseAttributeName(name)
	return "Purchased_" .. name:gsub("%W", "")
end

local function applyProfile(player, profile)
	local leaderstats, coins, wins = getStats(player)
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	if not wins then
		wins = createStat(leaderstats, "Wins", profile.Wins)
	end
	if not coins then
		coins = createStat(leaderstats, "Size Coins", profile.Coins)
	end

	coins.Value = profile.Coins
	wins.Value = profile.Wins
	player:SetAttribute("DailyGiftClaimed", profile.LastDailyGiftDay == os.date("!%Y-%j"))
	player:SetAttribute("EquippedCosmetic", profile.EquippedCosmetic)

	for name, owned in pairs(profile.Purchases) do
		if owned == true then
			player:SetAttribute(purchaseAttributeName(name), true)
		end
	end
end

local function syncStatsToProfile(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local _, coins, wins = getStats(player)
	if coins then
		profile.Coins = cleanNumber(coins.Value)
	end
	if wins then
		profile.Wins = cleanNumber(wins.Value)
	end
	profile.EquippedCosmetic = player:GetAttribute("EquippedCosmetic") or profile.EquippedCosmetic or ""
end

local function markDirty(player)
	local profile = profiles[player]
	if profile then
		profile.Dirty = true
	end
end

local function loadProfile(player)
	if not playerStore then
		player:SetAttribute("DataStoreStatus", "SessionOnly")
		return defaultProfile()
	end

	local ok, data = pcall(function()
		return playerStore:GetAsync(dataKey(player))
	end)

	if ok then
		player:SetAttribute("DataStoreStatus", "Loaded")
		return sanitizeProfile(data)
	end

	player:SetAttribute("DataStoreStatus", "SessionOnly")
	return defaultProfile()
end

function CurrencyService.savePlayer(player)
	local profile = profiles[player]
	if not profile or saving[player] then
		return false
	end
	if not playerStore then
		player:SetAttribute("DataStoreStatus", "SessionOnly")
		return false
	end

	syncStatsToProfile(player)
	saving[player] = true

	local payload = {
		Coins = profile.Coins,
		Wins = profile.Wins,
		LastDailyGiftDay = profile.LastDailyGiftDay,
		Purchases = profile.Purchases,
		EquippedCosmetic = profile.EquippedCosmetic,
	}

	local ok = pcall(function()
		playerStore:SetAsync(dataKey(player), payload)
	end)

	saving[player] = nil
	if ok then
		profile.Dirty = false
		player:SetAttribute("DataStoreStatus", "Saved")
	else
		player:SetAttribute("DataStoreStatus", "SessionOnly")
	end
	return ok
end

function CurrencyService.addCoins(player, amount)
	local _, coins = getStats(player)
	if coins then
		coins.Value = math.max(0, coins.Value + math.floor(amount))
		markDirty(player)
	end
end

function CurrencyService.spendCoins(player, amount)
	local _, coins = getStats(player)
	amount = math.max(0, math.floor(amount))
	if not coins or coins.Value < amount then
		return false
	end

	coins.Value -= amount
	markDirty(player)
	return true
end

function CurrencyService.addWins(player, amount)
	local _, _, wins = getStats(player)
	if wins then
		wins.Value = math.max(0, wins.Value + math.floor(amount))
		markDirty(player)
	end
end

function CurrencyService.claimDailyGift(player, rewardCoins)
	local profile = profiles[player]
	if not profile then
		return false, "Data loading"
	end

	local today = os.date("!%Y-%j")
	if profile.LastDailyGiftDay == today then
		player:SetAttribute("DailyGiftClaimed", true)
		return false, "Gift already claimed"
	end

	profile.LastDailyGiftDay = today
	player:SetAttribute("DailyGiftClaimed", true)
	CurrencyService.addCoins(player, rewardCoins or 25)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
	return true
end

function CurrencyService.ownsCosmetic(player, name)
	local profile = profiles[player]
	return profile and profile.Purchases[name] == true
end

function CurrencyService.purchaseCosmetic(player, name, cost)
	local profile = profiles[player]
	if not profile then
		return false, "Data loading"
	end
	if profile.Purchases[name] == true then
		return true, "Owned"
	end
	if not CurrencyService.spendCoins(player, cost or 0) then
		return false, "Need " .. tostring(cost or 0) .. " coins"
	end

	profile.Purchases[name] = true
	player:SetAttribute(purchaseAttributeName(name), true)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
	return true, "Bought"
end

function CurrencyService.equipCosmetic(player, name)
	local profile = profiles[player]
	if profile then
		profile.EquippedCosmetic = name
	end
	player:SetAttribute("EquippedCosmetic", name)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
end

function CurrencyService.getEquippedCosmetic(player)
	local profile = profiles[player]
	return (profile and profile.EquippedCosmetic) or player:GetAttribute("EquippedCosmetic") or ""
end

local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local wins = createStat(leaderstats, "Wins", 0)
	local coins = createStat(leaderstats, "Size Coins", 0)

	local profile = loadProfile(player)
	profiles[player] = profile
	applyProfile(player, profile)
	player:SetAttribute("DataReady", true)

	coins:GetPropertyChangedSignal("Value"):Connect(function()
		local currentProfile = profiles[player]
		if currentProfile then
			currentProfile.Coins = cleanNumber(coins.Value)
			markDirty(player)
		end
	end)

	wins:GetPropertyChangedSignal("Value"):Connect(function()
		local currentProfile = profiles[player]
		if currentProfile then
			currentProfile.Wins = cleanNumber(wins.Value)
			markDirty(player)
		end
	end)
end

function CurrencyService.start()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		CurrencyService.savePlayer(player)
		profiles[player] = nil
		saving[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if player.Parent and profile.Dirty then
					task.spawn(CurrencyService.savePlayer, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player in pairs(profiles) do
			CurrencyService.savePlayer(player)
		end
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

local function makeWorldEmitterPart(name, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = workspace
	return part
end

function FeedbackService.splashAt(position)
	local part = makeWorldEmitterPart("TG_WaterSplashFX", position)
	local attachment = makeAttachment(part)

	local splash = Instance.new("ParticleEmitter")
	splash.Name = "SplashDroplets"
	splash.Color = ColorSequence.new(Color3.fromRGB(130, 220, 255), Color3.fromRGB(245, 255, 255))
	splash.LightEmission = 0.45
	splash.Lifetime = NumberRange.new(0.35, 0.75)
	splash.Rate = 0
	splash.Speed = NumberRange.new(18, 30)
	splash.SpreadAngle = Vector2.new(55, 55)
	splash.Acceleration = Vector3.new(0, -55, 0)
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(1, 0),
	})
	splash.Parent = attachment
	splash:Emit(34)

	local foam = Instance.new("ParticleEmitter")
	foam.Name = "SplashFoam"
	foam.Color = ColorSequence.new(Color3.fromRGB(210, 245, 255))
	foam.LightEmission = 0.25
	foam.Lifetime = NumberRange.new(0.45, 0.85)
	foam.Rate = 0
	foam.Speed = NumberRange.new(3, 8)
	foam.SpreadAngle = Vector2.new(180, 180)
	foam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	foam.Parent = attachment
	foam:Emit(10)

	Debris:AddItem(part, 1.4)
end

function FeedbackService.confettiAt(position)
	local part = makeWorldEmitterPart("TG_FinishConfettiFX", position)
	local attachment = makeAttachment(part)

	local confetti = Instance.new("ParticleEmitter")
	confetti.Name = "FinishConfetti"
	confetti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 60)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(80, 210, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 255, 130)),
	})
	confetti.LightEmission = 0.4
	confetti.Lifetime = NumberRange.new(1.0, 1.8)
	confetti.Rate = 0
	confetti.Speed = NumberRange.new(18, 32)
	confetti.SpreadAngle = Vector2.new(65, 65)
	confetti.Acceleration = Vector3.new(0, -35, 0)
	confetti.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	confetti.Parent = attachment
	confetti:Emit(90)

	Debris:AddItem(part, 2.4)
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
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			FeedbackService.splashAt(root.Position + Vector3.new(0, -2, 0))
		end
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
local FACTORY_TAG = "TG_FactoryPortal"
local COMPUTER_TAG = "TG_ComputerPortal"
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

local function startCourseFromPortal(player, courseName, checkpointName)
	player:SetAttribute("InLobby", false)
	player:SetAttribute("CourseName", courseName)
	player:SetAttribute("CurrentCheckpoint", "")
	player:SetAttribute("CourseFinished", false)
	player:SetAttribute("RunStartTime", nil)
	player:SetAttribute("RunElapsedSeconds", nil)
	player:SetAttribute("RunTimeSeconds", nil)
	local start = workspace:FindFirstChild(checkpointName, true)
	teleportCharacter(player, start)
end

local function connectStartPortal(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player) then
			return
		end

		startCourseFromPortal(player, "WipeoutRun", "Checkpoint_1")
	end)
end

local function connectFactoryPortal(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player) then
			return
		end

		startCourseFromPortal(player, "FactoryChaos", "FactoryCheckpoint_1")
	end)
end

local function connectComputerPortal(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player) then
			return
		end

		startCourseFromPortal(player, "ComputerObby", "ComputerCheckpoint_1")
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
		player:SetAttribute("CourseName", "")
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
connectTagged(FACTORY_TAG, connectFactoryPortal)
connectTagged(COMPUTER_TAG, connectComputerPortal)
connectTagged(LOBBY_TAG, connectLobbyReturn)

Players.PlayerRemoving:Connect(function(player)
	touchCooldown[player] = nil
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutLobbyFeatures", source = [================[
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))
local CurrencyService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("CurrencyService"))

local DAILY_GIFT_TAG = "TG_DailyGiftPad"
local COSMETIC_PAD_TAG = "TG_CosmeticShopPad"
local touchCooldown = {}

local function getPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function canUse(player, part)
	local now = os.clock()
	local key = tostring(player.UserId) .. ":" .. part:GetFullName()
	local last = touchCooldown[key] or 0
	if now - last < 0.9 then
		return false
	end
	touchCooldown[key] = now
	return true
end

local function toast(player, text, color)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "LobbyToast"
	gui.Size = UDim2.fromOffset(260, 54)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 235, 90)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	Debris:AddItem(gui, 1.7)
end

local function equipTrail(player, color, name)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "LobbyCosmeticTrail" or child.Name == "LobbyTrailAttachmentA" or child.Name == "LobbyTrailAttachmentB" then
			child:Destroy()
		end
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "LobbyTrailAttachmentA"
	a0.Position = Vector3.new(-1.2, 1.1, 0.5)
	a0.Parent = root

	local a1 = Instance.new("Attachment")
	a1.Name = "LobbyTrailAttachmentB"
	a1.Position = Vector3.new(1.2, -1.1, 0.5)
	a1.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "LobbyCosmeticTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 0.45
	trail.Lifetime = 0.45
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new(0.9)
	trail.Parent = root

	player:SetAttribute("EquippedCosmetic", name)
end

local function connectDailyGift(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player, part) then
			return
		end

		local reward = part:GetAttribute("RewardCoins") or 25
		local claimed, reason = CurrencyService.claimDailyGift(player, reward)
		if not claimed then
			toast(player, reason or "Gift already claimed", Color3.fromRGB(235, 240, 250))
			FeedbackService.pulsePart(part, Color3.fromRGB(110, 130, 145))
			return
		end

		toast(player, "+" .. tostring(reward) .. " COINS", Color3.fromRGB(100, 255, 140))
		FeedbackService.pulsePart(part, Color3.fromRGB(100, 255, 140))
		FeedbackService.burst(part, Color3.fromRGB(100, 255, 140), 30)
	end)
end

local function connectCosmeticPad(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player, part) then
			return
		end

		local name = part:GetAttribute("CosmeticName") or "Trail"
		local cost = part:GetAttribute("Cost") or 25
		local alreadyOwned = CurrencyService.ownsCosmetic(player, name)
		local purchased, reason = CurrencyService.purchaseCosmetic(player, name, cost)
		if not purchased then
			toast(player, reason or ("Need " .. tostring(cost) .. " coins"), Color3.fromRGB(255, 120, 100))
			FeedbackService.pulsePart(part, Color3.fromRGB(255, 120, 100))
			return
		end
		if alreadyOwned then
			toast(player, "Equipped " .. name, Color3.fromRGB(120, 220, 255))
		elseif reason == "Bought" then
			toast(player, "Bought " .. name, Color3.fromRGB(255, 235, 90))
		else
			toast(player, "Equipped " .. name, Color3.fromRGB(120, 220, 255))
		end

		local color = part:GetAttribute("TrailColor")
		if typeof(color) ~= "Color3" then
			color = Color3.fromRGB(255, 225, 70)
		end
		CurrencyService.equipCosmetic(player, name)
		equipTrail(player, color, name)
		FeedbackService.pulsePart(part, color)
		FeedbackService.burst(part, color, 20)
	end)
end

local function ensureWinsBoardGui()
	local board = workspace:FindFirstChild("LobbyWinsBoard_Board", true)
	if not board or not board:IsA("BasePart") then
		return nil, nil, nil
	end

	local gui = board:FindFirstChild("WinsBoardGui")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "WinsBoardGui"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.06, 0.08)
		title.Size = UDim2.fromScale(0.88, 0.25)
		title.Font = Enum.Font.GothamBlack
		title.TextColor3 = Color3.fromRGB(80, 210, 255)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = gui

		local rows = Instance.new("TextLabel")
		rows.Name = "Rows"
		rows.BackgroundTransparency = 1
		rows.Position = UDim2.fromScale(0.08, 0.36)
		rows.Size = UDim2.fromScale(0.84, 0.54)
		rows.Font = Enum.Font.GothamBold
		rows.TextColor3 = Color3.fromRGB(245, 250, 255)
		rows.TextScaled = true
		rows.TextWrapped = true
		rows.TextXAlignment = Enum.TextXAlignment.Left
		rows.TextYAlignment = Enum.TextYAlignment.Top
		rows.Parent = gui
	end

	return board, gui:FindFirstChild("Title"), gui:FindFirstChild("Rows")
end

local function updateWinsBoard()
	local _, title, rows = ensureWinsBoardGui()
	if not title or not rows then
		return
	end

	local ranked = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local wins = leaderstats and leaderstats:FindFirstChild("Wins")
		table.insert(ranked, {
			Name = player.DisplayName or player.Name,
			Wins = wins and wins.Value or 0,
		})
	end
	table.sort(ranked, function(a, b)
		if a.Wins == b.Wins then
			return a.Name < b.Name
		end
		return a.Wins > b.Wins
	end)

	title.Text = "WINS BOARD"
	local lines = {}
	for i = 1, math.min(5, #ranked) do
		table.insert(lines, string.format("%d. %s  -  %d", i, ranked[i].Name, ranked[i].Wins))
	end
	if #lines == 0 then
		table.insert(lines, "No runners yet.")
	end
	rows.Text = table.concat(lines, "\n")
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

connectTagged(DAILY_GIFT_TAG, connectDailyGift)
connectTagged(COSMETIC_PAD_TAG, connectCosmeticPad)

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		local equipped = CurrencyService.getEquippedCosmetic(player)
		if equipped == "Gold Trail" then
			task.wait(0.3)
			equipTrail(player, Color3.fromRGB(255, 225, 70), equipped)
		elseif equipped == "Neon Trail" then
			task.wait(0.3)
			equipTrail(player, Color3.fromRGB(170, 95, 255), equipped)
		end
	end)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local wins = leaderstats and leaderstats:WaitForChild("Wins", 10)
	if wins then
		wins:GetPropertyChangedSignal("Value"):Connect(updateWinsBoard)
	end
	task.defer(updateWinsBoard)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	task.defer(updateWinsBoard)
	for key in pairs(touchCooldown) do
		if key:find(tostring(player.UserId) .. ":", 1, true) then
			touchCooldown[key] = nil
		end
	end
end)

task.spawn(function()
	while true do
		updateWinsBoard()
		task.wait(5)
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutCoinAnimator", source = [================[
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local COIN_TAG = "TG_Coin"
local SPIN_RADIANS_PER_SECOND = math.rad(360)
local ROLL_RADIANS_PER_SECOND = math.rad(252)
local BOB_HEIGHT = 0.28
local BOB_RADIANS_PER_SECOND = math.rad(150)
local RESCAN_SECONDS = 0.35

local coinStates = {}
local rescanElapsed = 0
local animationTime = 0

local function trackCoin(part)
	if not part:IsA("BasePart") then
		return
	end

	coinStates[part] = {
		BaseCFrame = part.CFrame,
		Phase = math.random() * math.pi * 2,
	}
end

local function rescanCoins()
	for _, part in ipairs(CollectionService:GetTagged(COIN_TAG)) do
		if coinStates[part] == nil then
			trackCoin(part)
		end
	end
end

CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(trackCoin)
CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(part)
	coinStates[part] = nil
end)

rescanCoins()

RunService.Heartbeat:Connect(function(deltaTime)
	rescanElapsed += deltaTime
	animationTime += deltaTime
	if rescanElapsed >= RESCAN_SECONDS then
		rescanElapsed = 0
		rescanCoins()
	end

	local now = animationTime
	for part, state in pairs(coinStates) do
		if not part.Parent or part:GetAttribute("Collected") == true then
			coinStates[part] = nil
		else
			local bob = math.sin(now * BOB_RADIANS_PER_SECOND + state.Phase) * BOB_HEIGHT
			part.CFrame = state.BaseCFrame
				* CFrame.new(0, bob, 0)
				* CFrame.Angles(0, now * SPIN_RADIANS_PER_SECOND + state.Phase, now * ROLL_RADIANS_PER_SECOND)
		end
	end
end)

]================] },
	{ service = "ServerScriptService", folders = {}, className = "Script", name = "WipeoutQARunner", source = [================[
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QA = {}
local running = false

local COURSE_ORDER = {"WipeoutRun", "FactoryChaos", "ComputerObby"}

local COURSES = {
	WipeoutRun = {
		title = "Wipeout Run",
		startCheckpoint = "Checkpoint_1",
		startPad = "StepPad_1",
		finish = "FinishGate",
		bestAttribute = "BestRunTimeSeconds",
		route = {
			{name = "StepPad_1"},
			{name = "StepPad_2", jump = true},
			{name = "StepPad_3", jump = true},
			{name = "StepPad_4", jump = true},
			{name = "Checkpoint_2"},
			{name = "SweeperDeck_Runway"},
			{name = "Checkpoint_3"},
			{name = "PunchCorridor_WideRun"},
			{name = "Checkpoint_4"},
			{name = "FinalBridge_WideRun"},
			{name = "Checkpoint_5"},
			{name = "TiltTable_1"},
			{name = "TiltTable_2"},
			{name = "TiltTable_3"},
			{name = "Checkpoint_7"},
			{name = "LaunchLagoon_Jump_1_OrangeRamp", pause = 0.25},
			{name = "LaunchLagoon_Landing_1", timeout = 5},
			{name = "LaunchLagoon_Jump_2_OrangeRamp", pause = 0.25},
			{name = "LaunchLagoon_Landing_2", timeout = 5},
			{name = "Checkpoint_8"},
			{name = "SwingBalls_Bridge"},
			{name = "FinishGate"},
		},
	},
	FactoryChaos = {
		title = "Factory Chaos",
		startCheckpoint = "FactoryCheckpoint_1",
		startPad = "FactoryStartPad",
		finish = "FactoryFinishGate",
		bestAttribute = "BestFactoryTimeSeconds",
		route = {
			{name = "FactoryStartPad"},
			{name = "FactoryCheckpoint_2", timeout = 10},
			{name = "FactoryPresses_Runway"},
			{name = "FactoryCheckpoint_3"},
			{name = "FactoryGearTable_264"},
			{name = "FactoryGearTable_294"},
			{name = "FactoryGearTable_324"},
			{name = "FactoryCheckpoint_4"},
			{name = "FactoryCrates_Bridge"},
			{name = "FactoryFinishGate"},
		},
	},
	ComputerObby = {
		title = "Escape CPU",
		startCheckpoint = "ComputerCheckpoint_1",
		startPad = "ComputerStartPad",
		finish = "ComputerFinishGate",
		bestAttribute = "BestComputerTimeSeconds",
		route = {
			{name = "ComputerStartPad"},
			{name = "ComputerCheckpoint_2", timeout = 10},
			{name = "ComputerFirewall_Runway"},
			{name = "ComputerCheckpoint_3"},
			{name = "ComputerFans_Bridge"},
			{name = "ComputerCheckpoint_4"},
			{name = "ComputerCache_Pad_376", jump = true},
			{name = "ComputerCache_Pad_398", jump = true},
			{name = "ComputerCache_Pad_420", jump = true},
			{name = "ComputerCache_Pad_442", jump = true},
			{name = "ComputerFinishGate"},
		},
	},
}

local function getCourseFolder()
	return workspace:FindFirstChild("TinyGiantGraybox")
end

local function findPart(name)
	local folder = getCourseFolder()
	local part = folder and folder:FindFirstChild(name, true)
	return part and part:IsA("BasePart") and part or nil
end

local function getFirstPlayer()
	return Players:GetPlayers()[1]
end

local function getCharacterParts(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function waitForCharacterReady(player, timeout)
	timeout = timeout or 6
	local started = os.clock()
	while os.clock() - started < timeout do
		local character, humanoid, root = getCharacterParts(player)
		if character and humanoid and root and humanoid.Health > 0 then
			return character, humanoid, root
		end
		task.wait(0.1)
	end
	return getCharacterParts(player)
end

local function leaderstatValue(player, name)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(name)
	return value and value.Value or 0
end

local function faceForward(root, position)
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, 1))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function teleportToPart(player, part)
	local _, _, root = getCharacterParts(player)
	if not root or not part then
		return false
	end
	faceForward(root, part.Position + Vector3.new(0, 5, -2))
	return true
end

local function setCourseState(player, courseName)
	player:SetAttribute("InLobby", false)
	player:SetAttribute("CourseName", courseName)
	player:SetAttribute("CurrentCheckpoint", "")
	player:SetAttribute("CourseFinished", false)
	player:SetAttribute("RunStartTime", nil)
	player:SetAttribute("RunElapsedSeconds", nil)
	player:SetAttribute("RunTimeSeconds", nil)
end

local function waitForRunStart(player, timeout)
	local started = os.clock()
	while os.clock() - started < timeout do
		if typeof(player:GetAttribute("RunStartTime")) == "number" then
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function horizontalDistance(a, b)
	local delta = a - b
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

local function waitForNear(root, target, tolerance, timeout)
	local started = os.clock()
	local closest = math.huge
	local lastPosition = root.Position
	local lastProgressAt = os.clock()
	while os.clock() - started < timeout do
		local distance = horizontalDistance(root.Position, target)
		closest = math.min(closest, distance)
		if distance <= tolerance then
			return true, closest, os.clock() - started, false
		end
		if (root.Position - lastPosition).Magnitude > 1.25 then
			lastPosition = root.Position
			lastProgressAt = os.clock()
		end
		if os.clock() - lastProgressAt > math.min(3.5, timeout * 0.5) then
			return false, closest, os.clock() - started, true
		end
		task.wait(0.1)
	end
	return false, closest, timeout, false
end

local function moveToPart(player, part, waypoint, timeout)
	local _, humanoid, root = getCharacterParts(player)
	if not humanoid or not root or not part then
		return false, "missing character or part", math.huge, 0
	end

	local target = part.Position + Vector3.new(0, 3, 0)
	if waypoint.jump then
		humanoid.Jump = true
	end
	humanoid:MoveTo(target)
	local tolerance = waypoint.tolerance or math.max(5, math.min(part.Size.X, part.Size.Z) * 0.55)
	local reached, closest, elapsed, stalled = waitForNear(root, target, tolerance, timeout)
	if reached then
		return true, nil, closest, elapsed
	end

	return false, stalled and "stalled" or "timeout", closest, elapsed
end

local function safeJson(value)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	return ok and encoded or "{}"
end

local function partExtentsOverlap(a, b)
	return math.abs(a.Position.X - b.Position.X) < (a.Size.X + b.Size.X) * 0.5
		and math.abs(a.Position.Z - b.Position.Z) < (a.Size.Z + b.Size.Z) * 0.5
end

local function scanNearCoplanar(folder)
	local results = {}
	local visibleParts = {}
	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 0.95 then
			table.insert(visibleParts, part)
		end
	end

	for i = 1, #visibleParts do
		local a = visibleParts[i]
		for j = i + 1, #visibleParts do
			local b = visibleParts[j]
			if partExtentsOverlap(a, b) then
				local aTop = a.Position.Y + a.Size.Y * 0.5
				local bBottom = b.Position.Y - b.Size.Y * 0.5
				local bTop = b.Position.Y + b.Size.Y * 0.5
				local aBottom = a.Position.Y - a.Size.Y * 0.5
				local gapAB = math.abs(bBottom - aTop)
				local gapBA = math.abs(aBottom - bTop)
				if (gapAB < 0.04 or gapBA < 0.04) and #results < 80 then
					table.insert(results, {
						a = a.Name,
						b = b.Name,
						gap = math.min(gapAB, gapBA),
					})
				end
			end
		end
	end
	return results
end

local function scanCourseGaps()
	local gaps = {}
	for courseName, course in pairs(COURSES) do
		local previousPart
		for _, waypoint in ipairs(course.route) do
			local part = findPart(waypoint.name)
			if previousPart and part then
				local edgeGap = horizontalDistance(previousPart.Position, part.Position)
					- math.max(previousPart.Size.X, previousPart.Size.Z) * 0.5
					- math.max(part.Size.X, part.Size.Z) * 0.5
				if edgeGap > 9 then
					table.insert(gaps, {
						course = courseName,
						from = previousPart.Name,
						to = part.Name,
						edgeGap = edgeGap,
					})
				end
			end
			previousPart = part or previousPart
		end
	end
	return gaps
end

local function countTaggedParts(tagName)
	local count = 0
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		if instance:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

local function sampleMovingParts(seconds)
	local trackedTags = {
		TG_Sweeper = "sweepers",
		TG_SwingBall = "swingBalls",
		TG_Crusher = "crushers",
		TG_Tilter = "tilters",
		TG_Conveyor = "conveyors",
	}
	local samples = {}
	for tagName, label in pairs(trackedTags) do
		samples[label] = {tag = tagName, total = 0, moving = 0, stationary = {}}
		for _, part in ipairs(CollectionService:GetTagged(tagName)) do
			if part:IsA("BasePart") then
				samples[label].total += 1
				table.insert(samples[label], {
					part = part,
					name = part.Name,
					start = part.CFrame,
				})
			end
		end
	end

	task.wait(seconds)

	for _, sample in pairs(samples) do
		for _, item in ipairs(sample) do
			if item.part and item.part.Parent then
				local positionDelta = (item.part.Position - item.start.Position).Magnitude
				local lookDelta = (item.part.CFrame.LookVector - item.start.LookVector).Magnitude
				if positionDelta > 0.15 or lookDelta > 0.08 then
					sample.moving += 1
				elseif sample.tag ~= "TG_Conveyor" then
					table.insert(sample.stationary, item.name)
				end
			end
			item.part = nil
			item.start = nil
		end
	end

	return samples
end

local function geometryAudit(options)
	options = options or {}
	local folder = getCourseFolder()
	local audit = {
		missingCritical = {},
		visibleNearCoplanar = {},
		routeGaps = {},
		roofCollisions = {},
		courseCounts = {},
		tagCounts = {
			coins = countTaggedParts("TG_Coin"),
			checkpoints = countTaggedParts("TG_Checkpoint"),
			finishGates = countTaggedParts("TG_Finish"),
			conveyors = countTaggedParts("TG_Conveyor"),
			sweepers = countTaggedParts("TG_Sweeper"),
			swingBalls = countTaggedParts("TG_SwingBall"),
			crushers = countTaggedParts("TG_Crusher"),
		},
		motion = {},
	}
	if not folder then
		table.insert(audit.missingCritical, "TinyGiantGraybox")
		return audit
	end

	for _, courseName in ipairs(COURSE_ORDER) do
		local course = COURSES[courseName]
		audit.courseCounts[courseName] = {
			checkpoints = 0,
			coins = 0,
			roofParts = 0,
		}
		for _, required in ipairs({course.startCheckpoint, course.startPad, course.finish}) do
			if not findPart(required) then
				table.insert(audit.missingCritical, courseName .. ":" .. required)
			end
		end
	end

	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			local courseName = part:GetAttribute("CourseName")
			if courseName and audit.courseCounts[courseName] and part.Name:find("Checkpoint") then
				audit.courseCounts[courseName].checkpoints += 1
			end
			if CollectionService:HasTag(part, "TG_Coin") then
				if part.Name:find("Factory") then
					audit.courseCounts.FactoryChaos.coins += 1
				elseif part.Name:find("Computer") then
					audit.courseCounts.ComputerObby.coins += 1
				elseif not part.Name:find("Lobby") then
					audit.courseCounts.WipeoutRun.coins += 1
				end
			end
			if part.Name:find("FactoryRoof") then
				audit.courseCounts.FactoryChaos.roofParts += 1
			elseif part.Name:find("ComputerRoof") then
				audit.courseCounts.ComputerObby.roofParts += 1
			end
			if (part.Name:find("Roof") or part.Name:find("Ceiling")) and part.CanCollide then
				table.insert(audit.roofCollisions, part.Name)
			end
		end
	end

	audit.visibleNearCoplanar = scanNearCoplanar(folder)
	audit.routeGaps = scanCourseGaps()
	audit.motion = sampleMovingParts(options.motionSampleSeconds or 1.25)
	return audit
end

local function runCourse(courseName, options)
	options = options or {}
	local course = COURSES[courseName]
	local player = options.player or getFirstPlayer()
	local report = {
		course = courseName,
		title = course and course.title or courseName,
		mode = options.assistAfterTimeout and "assisted-after-failure" or "strict-physics",
		completed = false,
		failReason = nil,
		timeSeconds = 0,
		waypointsReached = 0,
		waypointsTotal = course and #course.route or 0,
		stuckPoints = {},
		resetCount = 0,
		checkpointsTouched = 0,
		coinsGained = 0,
		winsGained = 0,
		bestTime = nil,
		minWaypointDistances = {},
		maxWaypointSeconds = 0,
	}
	if not course then
		report.failReason = "Unknown course"
		return report
	end
	if not player then
		report.failReason = "No player in Play mode"
		return report
	end

	local character, humanoid, root = waitForCharacterReady(player, options.characterTimeout or 6)
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		player:LoadCharacter()
		character, humanoid, root = waitForCharacterReady(player, options.characterTimeout or 6)
	end
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		report.failReason = "Player character not ready"
		return report
	end

	local startCheckpoint = findPart(course.startCheckpoint)
	local startPad = findPart(course.startPad)
	if not startCheckpoint or not startPad then
		report.failReason = "Missing start checkpoint or start pad"
		return report
	end

	local startCoins = leaderstatValue(player, "Size Coins")
	local startWins = leaderstatValue(player, "Wins")
	setCourseState(player, courseName)
	teleportToPart(player, startCheckpoint)
	task.wait(options.settleTime or 0.35)
	teleportToPart(player, startPad)
	task.wait(options.settleTime or 0.35)
	if not waitForRunStart(player, options.timerTimeout or 3) then
		report.failReason = "Timer did not start on start pad"
		return report
	end

	local startedAt = os.clock()
	local lastCheckpoint = player:GetAttribute("CurrentCheckpoint")
	local lastZ = root.Position.Z
	for _, waypoint in ipairs(course.route) do
		local part = findPart(waypoint.name)
		if not part then
			table.insert(report.stuckPoints, waypoint.name .. " missing")
			report.failReason = "Missing waypoint"
			break
		end

		local timeout = waypoint.timeout or options.waypointTimeout or 8
		local ok, reason, closest, elapsed = moveToPart(player, part, waypoint, timeout)
		table.insert(report.minWaypointDistances, {
			name = waypoint.name,
			closest = closest,
			seconds = elapsed,
		})
		report.maxWaypointSeconds = math.max(report.maxWaypointSeconds, elapsed or 0)

		local currentCheckpoint = player:GetAttribute("CurrentCheckpoint")
		if currentCheckpoint ~= lastCheckpoint then
			report.checkpointsTouched += 1
			lastCheckpoint = currentCheckpoint
		end

		local _, _, currentRoot = getCharacterParts(player)
		if currentRoot and currentRoot.Position.Z < lastZ - 18 then
			report.resetCount += 1
		end
		if currentRoot then
			lastZ = currentRoot.Position.Z
		end

		if not ok then
			local stuck = string.format("%s %s closest=%.1f", waypoint.name, reason or "failed", closest or -1)
			table.insert(report.stuckPoints, stuck)
			report.failReason = "Movement " .. (reason or "failed")
			if options.assistAfterTimeout then
				teleportToPart(player, part)
				task.wait(options.settleTime or 0.25)
			else
				break
			end
		else
			report.waypointsReached += 1
		end

		task.wait(waypoint.pause or options.waypointPause or 0.1)
	end

	local finish = findPart(course.finish)
	if finish and (options.assistAfterTimeout or not report.failReason) then
		moveToPart(player, finish, options.waypointTimeout or 8)
		task.wait(0.5)
	end

	report.completed = player:GetAttribute("CourseFinished") == true
	report.timeSeconds = player:GetAttribute("RunTimeSeconds") or player:GetAttribute("RunElapsedSeconds") or (os.clock() - startedAt)
	report.bestTime = player:GetAttribute(course.bestAttribute)
	report.coinsGained = leaderstatValue(player, "Size Coins") - startCoins
	report.winsGained = leaderstatValue(player, "Wins") - startWins
	if not report.completed and not report.failReason then
		report.failReason = "Finish did not complete"
	end

	return report
end

local function writeReport(report)
	local folder = ReplicatedStorage:FindFirstChild("WipeoutQAReports")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "WipeoutQAReports"
		folder.Parent = ReplicatedStorage
	end
	folder:ClearAllChildren()

	local summary = Instance.new("StringValue")
	summary.Name = "LatestSummary"
	summary.Value = report.summary
	summary.Parent = folder

	local json = Instance.new("StringValue")
	json.Name = "LatestJson"
	json.Value = safeJson(report)
	json.Parent = folder

	for index, courseReport in ipairs(report.courses) do
		local value = Instance.new("StringValue")
		value.Name = string.format("%02d_%s", index, courseReport.course)
		value.Value = string.format(
			"mode=%s completed=%s time=%.1f reached=%d/%d resets=%d checkpoints=%d coins=%d wins=%d fail=%s",
			courseReport.mode or "unknown",
			tostring(courseReport.completed),
			courseReport.timeSeconds or 0,
			courseReport.waypointsReached or 0,
			courseReport.waypointsTotal or 0,
			courseReport.resetCount or 0,
			courseReport.checkpointsTouched or 0,
			courseReport.coinsGained or 0,
			courseReport.winsGained or 0,
			courseReport.failReason or "none"
		)
		value.Parent = folder
	end
end

local function summarize(report)
	local completed = 0
	local totalTime = 0
	local totalResets = 0
	for _, courseReport in ipairs(report.courses) do
		if courseReport.completed then
			completed += 1
		end
		totalTime += courseReport.timeSeconds or 0
		totalResets += courseReport.resetCount or 0
	end
	report.summary = string.format(
		"mode=%s courses_completed=%d/3 total_time=%.1f total_resets=%d missing=%d zfight=%d roof_collisions=%d route_gaps=%d",
		report.mode,
		completed,
		totalTime,
		totalResets,
		#report.geometry.missingCritical,
		#report.geometry.visibleNearCoplanar,
		#report.geometry.roofCollisions,
		#report.geometry.routeGaps
	)
end

function QA.RunCourse(courseName, options)
	if running then
		return {error = "QA runner already active"}
	end
	running = true
	local ok, result = pcall(runCourse, courseName, options or {})
	running = false
	if not ok then
		return {error = tostring(result)}
	end
	return result
end

function QA.AuditGeometry(options)
	return geometryAudit(options)
end

function QA.RunAll(options)
	if running then
		return {error = "QA runner already active"}
	end
	running = true
	options = options or {}
	local report = {
		generatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		mode = options.assistAfterTimeout and "assisted-after-failure" or "strict-physics",
		geometry = geometryAudit(options),
		courses = {},
		summary = "",
	}
	for _, courseName in ipairs(COURSE_ORDER) do
		table.insert(report.courses, runCourse(courseName, options))
	end

	summarize(report)
	writeReport(report)
	print("[WipeoutQA] " .. report.summary)
	for _, courseReport in ipairs(report.courses) do
		print(string.format(
			"[WipeoutQA] %s mode=%s completed=%s time=%.1f waypoints=%d/%d resets=%d coins=%d wins=%d fail=%s",
			courseReport.course,
			courseReport.mode or "unknown",
			tostring(courseReport.completed),
			courseReport.timeSeconds or 0,
			courseReport.waypointsReached or 0,
			courseReport.waypointsTotal or 0,
			courseReport.resetCount or 0,
			courseReport.coinsGained or 0,
			courseReport.winsGained or 0,
			courseReport.failReason or "none"
		))
	end
	running = false
	return report
end

function QA.EnhancementIdeas(report)
	report = report or {geometry = geometryAudit(), courses = {}}
	local ideas = {}
	if report.geometry then
		if #report.geometry.visibleNearCoplanar > 0 then
			table.insert(ideas, "Fix visible near-coplanar geometry before adding more content.")
		end
		if #report.geometry.roofCollisions > 0 then
			table.insert(ideas, "Make roof/ceiling parts non-colliding so presentation never blocks play.")
		end
		if #report.geometry.routeGaps > 0 then
			table.insert(ideas, "Review large route gaps; mark intentional launch gaps separately from ordinary jumps.")
		end
	end
	for _, courseReport in ipairs(report.courses or {}) do
		if not courseReport.completed then
			table.insert(ideas, courseReport.title .. ": inspect " .. (courseReport.stuckPoints[1] or courseReport.failReason or "unknown blockage") .. ".")
		elseif courseReport.resetCount == 0 and courseReport.timeSeconds < 25 then
			table.insert(ideas, courseReport.title .. ": add one readable timing choice or coin risk path.")
		elseif courseReport.coinsGained <= 0 then
			table.insert(ideas, courseReport.title .. ": add coin placement along the expected line, not only risky side paths.")
		end
	end
	if #ideas == 0 then
		table.insert(ideas, "Add medal times, bonus coin routes, and a lobby board so repeat runs have goals.")
	end
	return ideas
end

_G.WipeoutQA = QA
print("[WipeoutQA] Loaded. In Play mode run: return _G.WipeoutQA.RunAll({waypointTimeout = 8})")

local qaInvoke = ReplicatedStorage:FindFirstChild("WipeoutQAInvoke")
if not qaInvoke then
	qaInvoke = Instance.new("BindableFunction")
	qaInvoke.Name = "WipeoutQAInvoke"
	qaInvoke.Parent = ReplicatedStorage
end

qaInvoke.OnInvoke = function(action, options, courseName)
	if action == "RunAll" then
		return QA.RunAll(options or {})
	elseif action == "RunCourse" then
		return QA.RunCourse(courseName, options or {})
	elseif action == "AuditGeometry" then
		return QA.AuditGeometry(options or {})
	elseif action == "EnhancementIdeas" then
		return QA.EnhancementIdeas(options)
	end
	return {error = "Unknown QA action: " .. tostring(action)}
end


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

local objectiveSets = {
	WipeoutRun = {
		title = "WIPEOUT RUN",
		bestAttribute = "BestRunTimeSeconds",
		objectives = {
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
		},
	},
	FactoryChaos = {
		title = "FACTORY CHAOS",
		bestAttribute = "BestFactoryTimeSeconds",
		objectives = {
			{
				text = "Step onto the green start pad, then ride the conveyor lanes.",
				done = function() return currentZ() > 70 end,
				doneText = "CONVEYORS CLEARED!"
			},
			{
				text = "Watch the warning stripes and slip past the stamp presses.",
				done = function() return currentZ() > 178 end,
				doneText = "STAMP PRESSES CLEARED!"
			},
			{
				text = "Cross the gear tables while the yellow arms sweep the lanes.",
				done = function() return currentZ() > 286 end,
				doneText = "GEAR FLOOR CLEARED!"
			},
			{
				text = "Dodge the swinging toy crates and run through the finish gate.",
				done = function() return player:GetAttribute("CourseFinished") == true end,
				doneText = "FACTORY CHAOS CLEARED!"
			},
		},
	},
	ComputerObby = {
		title = "ESCAPE CPU",
		bestAttribute = "BestComputerTimeSeconds",
		objectives = {
			{
				text = "Obstacle 1: ride the glowing data buses and dodge packet blocks.",
				done = function() return currentZ() > 108 end,
				doneText = "DATA BUS CLEARED!"
			},
			{
				text = "Obstacle 2: slip through the moving red firewall shutters.",
				done = function() return currentZ() > 232 end,
				doneText = "FIREWALL CLEARED!"
			},
			{
				text = "Obstacle 3: time your run through the cooling fan blades.",
				done = function() return currentZ() > 348 end,
				doneText = "COOLING FANS CLEARED!"
			},
			{
				text = "Obstacle 4: cross the cache pads and dodge corrupt swinging blocks.",
				done = function() return player:GetAttribute("CourseFinished") == true end,
				doneText = "CPU ESCAPED!"
			},
		},
	},
}

local currentObjective = 1
local completed = {}
local activeCourseName = nil
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
	local courseName = player:GetAttribute("CourseName")
	if courseName == nil or courseName == "" or player:GetAttribute("InLobby") == true then
		if activeCourseName ~= "Hub" then
			activeCourseName = "Hub"
			currentObjective = 1
			completed = {}
		end
		missionTitle.Text = "WIPEOUT HUB"
		missionText.Text = "Step on yellow for Wipeout, orange for Factory, or blue for Escape CPU."
		return
	end
	if courseName ~= activeCourseName then
		activeCourseName = courseName
		currentObjective = 1
		completed = {}
	end
	local objectiveSet = objectiveSets[courseName] or objectiveSets.WipeoutRun
	local objectives = objectiveSet.objectives

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
	local bestTime = player:GetAttribute(objectiveSet.bestAttribute)
	if startTime ~= runTimerSeenValue then
		runTimerSeenValue = startTime
		runTimerLocalStart = if typeof(startTime) == "number" then os.clock() else nil
	end
	local elapsed = if typeof(finishedTime) == "number" then finishedTime elseif typeof(elapsedSeconds) == "number" then elapsedSeconds else 0
	local timing = string.format("  %.1fs", elapsed)
	if typeof(bestTime) == "number" then
		timing ..= string.format(" | Best %.1fs", bestTime)
	end
	missionTitle.Text = objectiveSet.title .. timing
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
player:GetAttributeChangedSignal("CourseName"):Connect(updateMission)

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
	if effect:IsA("BloomEffect") or effect.Name == "WipeoutColorGrade" or effect.Name == "WipeoutSunRays" or effect.Name == "WipeoutAtmosphere" then
		if effect:IsA("PostEffect") then
			effect.Enabled = false
		end
		effect:Destroy()
	end
end

local colorGrade = Instance.new("ColorCorrectionEffect")
colorGrade.Name = "WipeoutColorGrade"
colorGrade.Brightness = 0.02
colorGrade.Contrast = 0.12
colorGrade.Saturation = 0.08
colorGrade.TintColor = Color3.fromRGB(245, 250, 255)
colorGrade.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "WipeoutSunRays"
sunRays.Intensity = 0.035
sunRays.Spread = 0.45
sunRays.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "WipeoutAtmosphere"
atmosphere.Density = 0.18
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(198, 230, 255)
atmosphere.Decay = Color3.fromRGB(120, 150, 180)
atmosphere.Glare = 0.06
atmosphere.Haze = 0.45
atmosphere.Parent = Lighting

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
	FactoryFloor = Color3.fromRGB(74, 83, 92),
	FactoryBelt = Color3.fromRGB(42, 50, 58),
	FactoryOrange = Color3.fromRGB(255, 142, 45),
	FactoryRed = Color3.fromRGB(220, 42, 48),
	ComputerBlue = Color3.fromRGB(55, 165, 230),
	ComputerGreen = Color3.fromRGB(80, 230, 150),
	ComputerFloor = Color3.fromRGB(38, 54, 76),
	ComputerVoid = Color3.fromRGB(38, 28, 86),
	Firewall = Color3.fromRGB(235, 50, 65),
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

local function addTrail(part, name, color, pos0, pos1, lifetime, width)
	local a0 = Instance.new("Attachment")
	a0.Name = name .. "_TrailA"
	a0.Position = pos0
	a0.Parent = part

	local a1 = Instance.new("Attachment")
	a1.Name = name .. "_TrailB"
	a1.Position = pos1
	a1.Parent = part

	local trail = Instance.new("Trail")
	trail.Name = name
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = lifetime or 0.22
	trail.LightEmission = 0.35
	trail.WidthScale = NumberSequence.new(width or 0.55)
	trail.Parent = part
	return trail
end

local function addCoinSparkle(coinPart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "CoinSparkleAttachment"
	attachment.Parent = coinPart

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "CoinSparkle"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 235, 80), Color3.fromRGB(255, 255, 210))
	sparkle.LightEmission = 0.55
	sparkle.Lifetime = NumberRange.new(0.45, 0.9)
	sparkle.Rate = 5
	sparkle.Speed = NumberRange.new(0.35, 1.25)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.13),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Parent = attachment
end

local function floorTile(name, z, length, color)
	local tile = block(name, Vector3.new(46, 1, length), Vector3.new(0, 0, z), color or COLORS.Floor)
	block(name .. "_LeftWall", Vector3.new(2.5, 8, length), Vector3.new(-24.25, 3.5, z), COLORS.Wall)
	block(name .. "_RightWall", Vector3.new(2.5, 8, length), Vector3.new(24.25, 3.5, z), COLORS.Wall)
	return tile
end

local function floorTileAt(name, x, z, length, width, color)
	local w = width or 48
	local tile = block(name, Vector3.new(w, 1, length), Vector3.new(x, 0, z), color or COLORS.Floor)
	block(name .. "_LeftWall", Vector3.new(2.5, 8, length), Vector3.new(x - w * 0.5 - 1.25, 3.5, z), COLORS.Wall)
	block(name .. "_RightWall", Vector3.new(2.5, 8, length), Vector3.new(x + w * 0.5 + 1.25, 3.5, z), COLORS.Wall)
	return tile
end

local function pit(name, z, length)
	local p = block(name, Vector3.new(54, 1.2, length), Vector3.new(0, -4.4, z), COLORS.Water, Enum.Material.SmoothPlastic)
	p.Transparency = 0.18
	p.CanCollide = false
	p.CanQuery = false
	p:SetAttribute("SoftReset", true)
	CollectionService:AddTag(p, "TG_Kill")

	local mistAttachment = Instance.new("Attachment")
	mistAttachment.Name = name .. "_MistAttachment"
	mistAttachment.Position = Vector3.new(0, p.Size.Y * 0.5 + 0.08, 0)
	mistAttachment.Parent = p

	local mist = Instance.new("ParticleEmitter")
	mist.Name = name .. "_Mist"
	mist.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255), Color3.fromRGB(235, 255, 255))
	mist.LightEmission = 0.18
	mist.Lifetime = NumberRange.new(1.2, 2.2)
	mist.Rate = 7
	mist.Speed = NumberRange.new(0.6, 1.8)
	mist.SpreadAngle = Vector2.new(180, 18)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	mist.Parent = mistAttachment

	for offset = -length * 0.5 + 8, length * 0.5 - 8, 12 do
		local wave = neon(name .. "_Wave_" .. tostring(math.floor(offset)), Vector3.new(38, 0.08, 1.2), Vector3.new(0, -3.48, z + offset), Color3.fromRGB(45, 115, 175))
		wave.Transparency = 0.5
		nonSolid(wave)
	end

	return p
end

local function pitAt(name, x, z, length, width)
	local p = block(name, Vector3.new(width or 58, 1.2, length), Vector3.new(x, -4.4, z), COLORS.Water, Enum.Material.SmoothPlastic)
	p.Transparency = 0.18
	p.CanCollide = false
	p.CanQuery = false
	p:SetAttribute("SoftReset", true)
	CollectionService:AddTag(p, "TG_Kill")

	local mistAttachment = Instance.new("Attachment")
	mistAttachment.Name = name .. "_MistAttachment"
	mistAttachment.Position = Vector3.new(0, p.Size.Y * 0.5 + 0.08, 0)
	mistAttachment.Parent = p

	local mist = Instance.new("ParticleEmitter")
	mist.Name = name .. "_Mist"
	mist.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255), Color3.fromRGB(235, 255, 255))
	mist.LightEmission = 0.18
	mist.Lifetime = NumberRange.new(1.2, 2.2)
	mist.Rate = 7
	mist.Speed = NumberRange.new(0.6, 1.8)
	mist.SpreadAngle = Vector2.new(180, 18)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	mist.Parent = mistAttachment

	for offset = -length * 0.5 + 8, length * 0.5 - 8, 12 do
		local wave = neon(name .. "_Wave_" .. tostring(math.floor(offset)), Vector3.new((width or 58) - 16, 0.08, 1.2), Vector3.new(x, -3.48, z + offset), Color3.fromRGB(45, 115, 175))
		wave.Transparency = 0.5
		nonSolid(wave)
	end

	return p
end

local function checkpoint(index, z)
	local p = neon("Checkpoint_" .. index, Vector3.new(34, 0.55, 8), Vector3.new(0, 0.98, z), COLORS.Checkpoint)
	p.Transparency = 0.08
	p.CanCollide = false
	CollectionService:AddTag(p, "TG_Checkpoint")
	return p
end

local function checkpointAt(name, x, z, width, courseName, courseStart)
	local p = neon(name, Vector3.new(width or 34, 0.55, 8), Vector3.new(x, 0.98, z), COLORS.Checkpoint)
	p.Transparency = 0.08
	p.CanCollide = false
	p:SetAttribute("CourseName", courseName or "WipeoutRun")
	p:SetAttribute("CourseStart", courseStart == true)
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

	local marker = Instance.new("Part")
	marker.Name = "SpinMarker"
	marker.Size = Vector3.new(0.16, 1.65, 0.12)
	marker.CFrame = p.CFrame * CFrame.new(0.58, 0, -0.38)
	marker.Anchored = false
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Color = Color3.fromRGB(80, 62, 18)
	marker.Material = Enum.Material.Metal
	marker.Parent = p

	local weld = Instance.new("WeldConstraint")
	weld.Name = "SpinMarkerWeld"
	weld.Part0 = p
	weld.Part1 = marker
	weld.Parent = marker
	addCoinSparkle(p)

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

	local cap = block(name .. "_Cap", Vector3.new(5, 0.5, 5), position + Vector3.new(0, 4.45, 0), COLORS.Trim)
	cap.Shape = Enum.PartType.Cylinder
	cap.Material = Enum.Material.SmoothPlastic

	local arm = block(name, Vector3.new(length, 1.15, 1.15), position + Vector3.new(0, 2.9, 0), COLORS.Sweeper, Enum.Material.SmoothPlastic)
	addTrail(arm, name .. "_MotionTrail", Color3.fromRGB(255, 238, 80), Vector3.new(-length * 0.5, 0.65, 0), Vector3.new(-length * 0.5, -0.65, 0), 0.2, 0.5)
	arm:SetAttribute("Period", period)
	arm:SetAttribute("Phase", phase or 0)
	arm:SetAttribute("KnockStrength", 78)
	arm:SetAttribute("KnockLift", 20)
	CollectionService:AddTag(arm, "TG_Sweeper")
	return arm
end

local function punchBlock(name, startPosition, size, travelX, period, phase, showTrail)
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
	addTrail(p, name .. "_MotionTrail", Color3.fromRGB(255, 80, 80), Vector3.new(0, 2.75, -4), Vector3.new(0, -2.75, -4), 0.22, 0.7)
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

local function stampPress(name, centerX, z, phase)
	local frame = block(name .. "_Frame", Vector3.new(20, 1.2, 2.2), Vector3.new(centerX, 8.5, z - 4.5), COLORS.Support, Enum.Material.Metal)
	frame.CanCollide = false
	local postLeft = block(name .. "_PostLeft", Vector3.new(1.2, 9, 1.2), Vector3.new(centerX - 10.5, 4.5, z), COLORS.Support, Enum.Material.Metal)
	postLeft.CanCollide = false
	local postRight = block(name .. "_PostRight", Vector3.new(1.2, 9, 1.2), Vector3.new(centerX + 10.5, 4.5, z), COLORS.Support, Enum.Material.Metal)
	postRight.CanCollide = false

	local p = block(name, Vector3.new(18, 2.4, 8.5), Vector3.new(centerX, 7.6, z), COLORS.FactoryOrange, Enum.Material.Metal)
	addTrail(p, name .. "_MotionTrail", Color3.fromRGB(255, 160, 70), Vector3.new(-9, -1.2, -4), Vector3.new(9, -1.2, -4), 0.18, 0.75)
	p.CanCollide = false
	p:SetAttribute("TravelY", -5.6)
	p:SetAttribute("Period", 2.8)
	p:SetAttribute("Phase", phase or 0)
	p:SetAttribute("KnockOnly", true)
	p:SetAttribute("KnockStrength", 58)
	p:SetAttribute("KnockLift", 22)
	CollectionService:AddTag(p, "TG_Crusher")

	for offsetX = -6, 6, 6 do
		local stripe = neon(name .. "_WarningStripe_" .. tostring(offsetX), Vector3.new(3, 0.12, 0.6), Vector3.new(centerX + offsetX, 1.74, z - 7), COLORS.FactoryOrange)
		stripe.Orientation = Vector3.new(0, 25, 0)
		nonSolid(stripe)
	end
	return p
end

local function conveyorZone(name, z, pushZ, color, centerX, width, length)
	local x = centerX or 0
	local zone = neon(name, Vector3.new(width or 9, 0.8, length or 16), Vector3.new(x, 2.4, z), color or Color3.fromRGB(255, 150, 60))
	zone.Transparency = 1
	zone:SetAttribute("PushX", 0)
	zone:SetAttribute("PushZ", math.abs(pushZ))
	zone:SetAttribute("ForwardMin", 14)
	CollectionService:AddTag(zone, "TG_Conveyor")
	nonSolid(zone)

	local arrowColor = Color3.fromRGB(255, 185, 45)
	local laneLength = length or 16
	for offset = -laneLength * 0.5 + 10, laneLength * 0.5 - 10, 18 do
		local markerName = name .. "_Direction_" .. tostring(math.floor(offset))
		local shaft = neon(markerName .. "_Shaft", Vector3.new(0.82, 0.14, 4.6), Vector3.new(x, 2.9, z + offset - 1.0), arrowColor)
		shaft.Transparency = 0
		nonSolid(shaft)
		local head = neon(markerName .. "_Head", Vector3.new(2.35, 0.14, 2.35), Vector3.new(x, 2.91, z + offset + 2.2), arrowColor)
		head.Orientation = Vector3.new(0, 45, 0)
		head.Transparency = 0
		nonSolid(head)
	end
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
	addTrail(ball, name .. "_MotionTrail", Color3.fromRGB(255, 70, 70), Vector3.new(0, ballRadius * 0.85, 0), Vector3.new(0, -ballRadius * 0.85, 0), 0.28, 0.85)
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

local function swingCrate(name, z, x, amplitude, period, phase)
	local pivot = Vector3.new(x, 23, z)
	local cableLength = 15

	local hanger = block(name .. "_Hanger", Vector3.new(4, 0.8, 4), pivot, COLORS.Support, Enum.Material.Metal)
	hanger.CanCollide = false

	local cable = block(name .. "_Cable", Vector3.new(0.35, cableLength, 0.35), pivot + Vector3.new(0, -cableLength * 0.5, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal)
	cable.CanCollide = false

	local crate = block(name, Vector3.new(7.5, 7.5, 7.5), pivot + Vector3.new(0, -cableLength, 0), COLORS.FactoryRed, Enum.Material.Wood)
	addTrail(crate, name .. "_MotionTrail", Color3.fromRGB(255, 90, 70), Vector3.new(0, 3.6, -3.6), Vector3.new(0, -3.6, -3.6), 0.25, 0.8)
	crate:SetAttribute("PivotX", pivot.X)
	crate:SetAttribute("PivotY", pivot.Y)
	crate:SetAttribute("PivotZ", pivot.Z)
	crate:SetAttribute("CableLength", cableLength)
	crate:SetAttribute("Amplitude", amplitude or 32)
	crate:SetAttribute("Period", period or 3.8)
	crate:SetAttribute("Phase", phase or 0)
	crate:SetAttribute("SwingAxis", "X")
	CollectionService:AddTag(crate, "TG_SwingBall")

	return crate
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
	block("LobbyFloor", Vector3.new(152, 1, 108), Vector3.new(0, 0, -136), COLORS.FloorAlt)
	block("LobbyBackWall", Vector3.new(156, 9, 2.5), Vector3.new(0, 4, -190), COLORS.Wall)
	block("LobbyLeftWall", Vector3.new(2.5, 9, 108), Vector3.new(-77, 4, -136), COLORS.Wall)
	block("LobbyRightWall", Vector3.new(2.5, 9, 108), Vector3.new(77, 4, -136), COLORS.Wall)

	labelBoard("LobbyTitleBoard", Vector3.new(0, 8, -189), Vector3.new(50, 10, 1), "WIPEOUT HUB", "Pick a course, grab a reward, then run it again.", COLORS.Trim)

	local function selectorCard(name, x, title, body, color, tag)
		labelBoard("Lobby" .. name .. "Board", Vector3.new(x, 10.5, -96), Vector3.new(25, 7, 1), title, body, color)
		local pad
		if tag then
			pad = portal("Portal_" .. name, Vector3.new(x, 1.25, -123), Vector3.new(20, 0.45, 13), color, tag)
			pad.Transparency = 0.02
		else
			pad = block("Portal_" .. name, Vector3.new(20, 0.45, 13), Vector3.new(x, 1.25, -123), color)
			pad.Transparency = 0.18
			pad.CanCollide = false
			pad.CanTouch = false
		end

		nonSolid(neon("Portal_" .. name .. "_ArrowBase", Vector3.new(8, 0.15, 1), Vector3.new(x, 1.65, -124), COLORS.Trim))
		local tip = neon("Portal_" .. name .. "_ArrowTip", Vector3.new(4, 0.15, 4), Vector3.new(x, 1.65, -119.8), COLORS.Trim)
		tip.Orientation = Vector3.new(0, 45, 0)
		nonSolid(tip)
		return pad
	end

	selectorCard("WipeoutRun", -30, "WIPEOUT RUN", "Step on the yellow floor pad.", COLORS.Trim, "TG_StartPortal")
	selectorCard("FactoryChaos", 0, "FACTORY CHAOS", "Step on the orange floor pad.", COLORS.FactoryOrange, "TG_FactoryPortal")
	selectorCard("ComputerObby", 30, "ESCAPE CPU", "Step on the blue floor pad.", COLORS.ComputerBlue, "TG_ComputerPortal")

	local function lobbyBooth(name, x, z, color, title, body)
		block(name .. "_Counter", Vector3.new(22, 2.2, 7), Vector3.new(x, 1.6, z), color, Enum.Material.SmoothPlastic)
		block(name .. "_Back", Vector3.new(24, 8, 1.5), Vector3.new(x, 4.4, z + 5.5), COLORS.Dark, Enum.Material.SmoothPlastic)
		labelBoard(name .. "_Board", Vector3.new(x, 7.4, z + 6.35), Vector3.new(22, 6, 1), title, body, color)
	end

	lobbyBooth("LobbyDailyGift", -58, -164, Color3.fromRGB(80, 180, 105), "DAILY GIFT", "Reward chest coming soon.")
	lobbyBooth("LobbyCoinShop", 58, -164, COLORS.Trim, "COIN SHOP", "Spend coins on flair.")
	lobbyBooth("LobbyCosmetics", -58, -112, Color3.fromRGB(170, 95, 220), "COSMETICS", "Trails and effects.")
	lobbyBooth("LobbyWinsBoard", 58, -112, Color3.fromRGB(70, 175, 215), "WINS BOARD", "Live server rankings.")

	local giftPad = portal("LobbyDailyGiftPad", Vector3.new(-58, 1.25, -151), Vector3.new(20, 0.45, 8), Color3.fromRGB(80, 220, 110), "TG_DailyGiftPad")
	giftPad.Transparency = 0.03
	giftPad:SetAttribute("RewardCoins", 25)

	local goldTrailPad = portal("LobbyGoldTrailPad", Vector3.new(52, 1.25, -151), Vector3.new(13, 0.45, 8), COLORS.Trim, "TG_CosmeticShopPad")
	goldTrailPad.Transparency = 0.03
	goldTrailPad:SetAttribute("Cost", 25)
	goldTrailPad:SetAttribute("CosmeticName", "Gold Trail")
	goldTrailPad:SetAttribute("TrailColor", COLORS.Trim)

	local neonTrailPad = portal("LobbyNeonTrailPad", Vector3.new(64, 1.25, -151), Vector3.new(13, 0.45, 8), Color3.fromRGB(170, 95, 255), "TG_CosmeticShopPad")
	neonTrailPad.Transparency = 0.03
	neonTrailPad:SetAttribute("Cost", 50)
	neonTrailPad:SetAttribute("CosmeticName", "Neon Trail")
	neonTrailPad:SetAttribute("TrailColor", Color3.fromRGB(170, 95, 255))

	labelBoard("LobbyGiftHint", Vector3.new(-58, 5.2, -148), Vector3.new(18, 4.4, 1), "CLAIM", "+25 coins", Color3.fromRGB(80, 220, 110))
	labelBoard("LobbyGoldTrailHint", Vector3.new(52, 5.2, -148), Vector3.new(13, 4.4, 1), "GOLD", "25 coins", COLORS.Trim)
	labelBoard("LobbyNeonTrailHint", Vector3.new(64, 5.2, -148), Vector3.new(13, 4.4, 1), "NEON", "50 coins", Color3.fromRGB(170, 95, 255))

	for _, spec in ipairs({
		{"ShopCoinDisplay_1", Vector3.new(53, 3.55, -165.2), Vector3.new(2.0, 1.7, 0.8), COLORS.Coin},
		{"ShopCoinDisplay_2", Vector3.new(63, 3.55, -165.2), Vector3.new(2.0, 1.7, 0.8), COLORS.Coin},
		{"CosmeticTrailSample", Vector3.new(-58, 3.5, -112), Vector3.new(10, 0.35, 1.2), Color3.fromRGB(170, 95, 220)},
		{"WinsTrophyBase", Vector3.new(58, 3.45, -112), Vector3.new(3, 1.5, 3), COLORS.Trim},
	}) do
		local prop = block(spec[1], spec[3], spec[2], spec[4], Enum.Material.SmoothPlastic)
		prop.CanCollide = false
	end

	coin("LobbyCoin_1", Vector3.new(-9, 4, -150), 1)
	coin("LobbyCoin_2", Vector3.new(9, 4, -150), 1)
	coin("LobbyCoin_3", Vector3.new(0, 4, -112), 1)
end

-- Start zone.
lobbyArea()
spawnLocation()

local function computerEscapeCourse()
	local x = 112
	local coinIndex = 1
	local function cpuCoin(cx, cy, cz, value)
		coin("ComputerCoin_" .. coinIndex, Vector3.new(cx, cy, cz), value)
		coinIndex += 1
	end
	local function staticPit(name, z, length)
		local p = pitAt(name, x, z, length, 64)
		p.Color = COLORS.ComputerVoid
		for _, child in ipairs(course:GetChildren()) do
			if child.Name:find(name .. "_Wave_") == 1 and child:IsA("BasePart") then
				child.Color = COLORS.ComputerBlue
				child.Transparency = 0.42
			end
		end
		return p
	end
	local function trace(name, localX, z, length, color)
		local line = neon(name, Vector3.new(1.1, 0.1, length), Vector3.new(x + localX, 2.05, z), color)
		line.Transparency = 0.14
		nonSolid(line)
		return line
	end
	local function chip(name, localX, z, color)
		local base = block(name, Vector3.new(12, 2, 9), Vector3.new(x + localX, 2.1, z), color or COLORS.Dark, Enum.Material.Metal)
		base.CanCollide = false
		for pin = -4, 4, 2 do
			block(name .. "_PinL_" .. tostring(pin), Vector3.new(1, 0.25, 0.45), Vector3.new(x + localX - 6.7, 2.85, z + pin), COLORS.Support, Enum.Material.Metal).CanCollide = false
			block(name .. "_PinR_" .. tostring(pin), Vector3.new(1, 0.25, 0.45), Vector3.new(x + localX + 6.7, 2.85, z + pin), COLORS.Support, Enum.Material.Metal).CanCollide = false
		end
	end
	local function ceilingPanel(name, z, length)
		local roof = block(name, Vector3.new(68, 1.2, length), Vector3.new(x, 29, z), COLORS.Dark, Enum.Material.Metal)
		roof.CanCollide = false
		roof.CastShadow = false
		for _, side in ipairs({-34.6, 34.6}) do
			local fascia = block(name .. "_SideWall_" .. tostring(side), Vector3.new(1.2, 21, length), Vector3.new(x + side, 18.2, z), COLORS.Wall, Enum.Material.Metal)
			fascia.CanCollide = false
			fascia.CastShadow = false
		end
		for offset = -24, 24, 16 do
			local strip = neon(name .. "_Light_" .. tostring(offset), Vector3.new(1.2, 0.12, length - 10), Vector3.new(x + offset, 28.28, z), COLORS.ComputerBlue)
			strip.Transparency = 0.08
			nonSolid(strip)
		end
		return roof
	end

	ceilingPanel("ComputerRoof_Start", -12, 70)
	ceilingPanel("ComputerRoof_DataBus", 68, 90)
	ceilingPanel("ComputerRoof_Firewall", 174, 112)
	ceilingPanel("ComputerRoof_Fans", 292, 112)
	ceilingPanel("ComputerRoof_Cache", 414, 116)

	floorTileAt("Computer_StartDeck", x, -35, 44, 52, COLORS.ComputerFloor)
	checkpointAt("ComputerCheckpoint_1", x, -50, 36, "ComputerObby", true)
	local startPad = neon("ComputerStartPad", Vector3.new(26, 0.4, 8), Vector3.new(x, 1.05, -20), COLORS.ComputerBlue)
	startPad:SetAttribute("StartsRun", true)
	startPad:SetAttribute("CourseName", "ComputerObby")
	nonSolid(startPad)
	labelBoard("ComputerIntroBoard", Vector3.new(x, 8, -66), Vector3.new(38, 9, 1), "ESCAPE CPU", "Cross data buses, firewalls, fan blades, and cache gaps.", COLORS.ComputerBlue)
	trace("ComputerStartTrace_1", -8, -20, 28, COLORS.ComputerGreen)
	trace("ComputerStartTrace_2", 8, -20, 28, COLORS.ComputerBlue)
	chip("ComputerStartChip_Left", -24, -24, COLORS.Dark)
	chip("ComputerStartChip_Right", 24, -8, COLORS.Dark)

	-- Zone 1: readable conveyor data buses. Wide lanes and soft-reset static below.
	staticPit("ComputerBus_StaticPit", 40, 116)
	block("ComputerBus_LeftWall", Vector3.new(2.5, 8, 124), Vector3.new(x - 32.25, 3.5, 40), COLORS.Wall)
	block("ComputerBus_RightWall", Vector3.new(2.5, 8, 124), Vector3.new(x + 32.25, 3.5, 40), COLORS.Wall)
	for _, lane in ipairs({
		{-16, COLORS.ComputerGreen, 13},
		{0, COLORS.ComputerBlue, -12},
		{16, COLORS.ComputerGreen, 13},
	}) do
		block("ComputerBus_Bridge_" .. tostring(lane[1]), Vector3.new(12, 1.15, 100), Vector3.new(x + lane[1], 1.05, 40), COLORS.ComputerFloor, Enum.Material.Metal)
		conveyorZone("ComputerBus_Stream_" .. tostring(lane[1]), 40, lane[3], lane[2], x + lane[1], 10, 90)
	end
	punchBlock("ComputerBus_Packet_1", Vector3.new(x - 27, 3.6, 22), Vector3.new(8, 4.2, 6), 42, 6.0, 0.4, false)
	punchBlock("ComputerBus_Packet_2", Vector3.new(x + 27, 3.6, 62), Vector3.new(8, 4.2, 6), -42, 5.8, 1.8, false)
	for _, z in ipairs({-4, 14, 32, 50, 68, 86}) do
		cpuCoin(x, 4.4, z, 1)
	end
	floorTileAt("ComputerBus_ExitDeck", x, 112, 24, 52, COLORS.ComputerFloor)
	checkpointAt("ComputerCheckpoint_2", x, 108, 36, "ComputerObby", false)

	-- Zone 2: firewall shutters. They knock players into the static, never instant-kill.
	staticPit("ComputerFirewall_StaticPit", 176, 104)
	block("ComputerFirewall_Runway", Vector3.new(34, 1.15, 96), Vector3.new(x, 1.05, 176), COLORS.Pad, Enum.Material.Metal)
	block("ComputerFirewall_LeftWall", Vector3.new(2.5, 8, 108), Vector3.new(x - 32.25, 3.5, 176), COLORS.Wall)
	block("ComputerFirewall_RightWall", Vector3.new(2.5, 8, 108), Vector3.new(x + 32.25, 3.5, 176), COLORS.Wall)
	for _, spec in ipairs({
		{142, -28, 56, 5.4, 0.0},
		{170, 28, -56, 5.1, 1.4},
		{198, -28, 56, 4.9, 2.6},
	}) do
		local shutter = punchBlock("ComputerFirewall_Shutter_" .. tostring(spec[1]), Vector3.new(x + spec[2], 4.1, spec[1]), Vector3.new(12, 6, 9), spec[3], spec[4], spec[5], false)
		shutter.Color = COLORS.Firewall
		shutter:SetAttribute("KnockStrength", 60)
		shutter:SetAttribute("KnockLift", 18)
		trace("ComputerFirewall_Warning_" .. tostring(spec[1]), 0, spec[1] - 8, 1.5, COLORS.Firewall).Size = Vector3.new(30, 0.13, 1.5)
	end
	for _, z in ipairs({136, 154, 180, 206, 220}) do
		cpuCoin(x + (z % 2 == 0 and 8 or -8), 4.5, z, 1)
	end
	floorTileAt("ComputerFirewall_ExitDeck", x, 238, 24, 52, COLORS.ComputerFloor)
	checkpointAt("ComputerCheckpoint_3", x, 232, 36, "ComputerObby", false)

	-- Zone 3: cooling fans. Slow sweepers make timing clear and push players into the reset field.
	staticPit("ComputerFans_StaticPit", 294, 104)
	block("ComputerFans_Bridge", Vector3.new(34, 1.2, 96), Vector3.new(x, 1.05, 294), COLORS.ComputerFloor, Enum.Material.Metal)
	block("ComputerFans_LeftWall", Vector3.new(2.5, 8, 112), Vector3.new(x - 32.25, 3.5, 294), COLORS.Wall)
	block("ComputerFans_RightWall", Vector3.new(2.5, 8, 112), Vector3.new(x + 32.25, 3.5, 294), COLORS.Wall)
	for _, spec in ipairs({
		{266, 0.2},
		{296, 1.3},
		{326, 2.4},
	}) do
		local fan = sweeper("ComputerFanBlade_" .. tostring(spec[1]), Vector3.new(x, 2.05, spec[1]), 54, 4.6, spec[2])
		fan.Color = COLORS.ComputerBlue
		fan:SetAttribute("KnockOnly", true)
		fan:SetAttribute("KnockStrength", 52)
		fan:SetAttribute("KnockLift", 18)
		cpuCoin(x, 4.8, spec[1] - 7, 2)
	end
	floorTileAt("ComputerFans_ExitDeck", x, 352, 28, 52, COLORS.ComputerFloor)
	checkpointAt("ComputerCheckpoint_4", x, 348, 36, "ComputerObby", false)

	-- Zone 4: cache gaps and swinging corrupt blocks. Continuous side walls prevent bypassing.
	staticPit("ComputerCache_StaticPit", 412, 110)
	block("ComputerCache_LeftWall", Vector3.new(2.5, 8, 116), Vector3.new(x - 32.25, 3.5, 412), COLORS.Wall)
	block("ComputerCache_RightWall", Vector3.new(2.5, 8, 116), Vector3.new(x + 32.25, 3.5, 412), COLORS.Wall)
	for _, spec in ipairs({
		{-10, 376, COLORS.ComputerGreen},
		{10, 398, COLORS.ComputerBlue},
		{-8, 420, COLORS.ComputerGreen},
		{8, 442, COLORS.ComputerBlue},
	}) do
		block("ComputerCache_Pad_" .. tostring(spec[2]), Vector3.new(24, 1.2, 18), Vector3.new(x + spec[1], 1.05, spec[2]), spec[3], Enum.Material.Metal)
		cpuCoin(x + spec[1], 4.6, spec[2], 2)
	end
	local rail = part("ComputerCache_OverheadBus", Vector3.new(2.2, 110, 2.2), CFrame.new(x, 23, 412) * CFrame.Angles(math.rad(90), 0, 0), COLORS.Support, Enum.Material.Metal)
	rail.Shape = Enum.PartType.Cylinder
	rail.CanCollide = false
	swingCrate("ComputerCorruptBlock_1", 392, x, 24, 4.5, 0.2)
	swingCrate("ComputerCorruptBlock_2", 432, x, 28, 4.1, 1.8)

	floorTileAt("ComputerFinishDeck", x, 480, 44, 52, COLORS.ComputerFloor)
	local finish = neon("ComputerFinishGate", Vector3.new(26, 1, 10), Vector3.new(x, 1.12, 462), COLORS.ComputerBlue)
	finish.CanCollide = false
	finish:SetAttribute("CourseName", "ComputerObby")
	CollectionService:AddTag(finish, "TG_Finish")
	block("ComputerFinishArch_Left", Vector3.new(2, 9, 2), Vector3.new(x - 15, 4.5, 462), COLORS.ComputerBlue, Enum.Material.Metal)
	block("ComputerFinishArch_Right", Vector3.new(2, 9, 2), Vector3.new(x + 15, 4.5, 462), COLORS.ComputerBlue, Enum.Material.Metal)
	block("ComputerFinishArch_Top", Vector3.new(32, 2, 2), Vector3.new(x, 9, 462), COLORS.ComputerBlue, Enum.Material.Metal)
	labelBoard("ComputerFinishBoard", Vector3.new(x, 7.5, 492), Vector3.new(36, 8, 1), "CPU ESCAPED!", "Replay Escape CPU or return to the hub.", COLORS.ComputerBlue)
	local replay = portal("ReplayComputerPad", Vector3.new(x - 13, 1.25, 506), Vector3.new(18, 0.45, 10), COLORS.ComputerBlue, "TG_ComputerPortal")
	replay.Transparency = 0.02
	local home = portal("ComputerReturnToLobbyPad", Vector3.new(x + 13, 1.25, 506), Vector3.new(18, 0.45, 10), COLORS.Checkpoint, "TG_LobbyReturn")
	home.Transparency = 0.02
	labelBoard("ReplayComputerBoard", Vector3.new(x - 13, 7, 516), Vector3.new(20, 7, 1), "ESCAPE AGAIN", "Step on blue.", COLORS.ComputerBlue)
	labelBoard("ComputerHubBoard", Vector3.new(x + 13, 7, 516), Vector3.new(20, 7, 1), "HUB", "Step on green.", COLORS.Checkpoint)
end

computerEscapeCourse()

local function factoryChaosCourse()
	local x = -112
	local coinIndex = 1
	local function factoryCoin(cx, cy, cz, value)
		coin("FactoryCoin_" .. coinIndex, Vector3.new(cx, cy, cz), value)
		coinIndex += 1
	end
	local function factoryCeilingPanel(name, z, length)
		local roof = block(name, Vector3.new(68, 1.2, length), Vector3.new(x, 29, z), COLORS.Dark, Enum.Material.Metal)
		roof.CanCollide = false
		roof.CastShadow = false
		for _, side in ipairs({-34.6, 34.6}) do
			local fascia = block(name .. "_SideWall_" .. tostring(side), Vector3.new(1.2, 21, length), Vector3.new(x + side, 18.2, z), COLORS.Wall, Enum.Material.Metal)
			fascia.CanCollide = false
			fascia.CastShadow = false
		end
		for offset = -24, 24, 16 do
			local strip = neon(name .. "_Light_" .. tostring(offset), Vector3.new(1.2, 0.12, length - 10), Vector3.new(x + offset, 28.28, z), COLORS.FactoryOrange)
			strip.Transparency = 0.08
			nonSolid(strip)
		end
		for zOffset = -length * 0.5 + 12, length * 0.5 - 12, 24 do
			local beam = block(name .. "_CrossBeam_" .. tostring(math.floor(zOffset)), Vector3.new(62, 0.7, 1.2), Vector3.new(x, 27.6, z + zOffset), COLORS.Support, Enum.Material.Metal)
			beam.CanCollide = false
			beam.CastShadow = false
		end
		return roof
	end

	factoryCeilingPanel("FactoryRoof_Start", -12, 70)
	factoryCeilingPanel("FactoryRoof_Conveyors", 68, 90)
	factoryCeilingPanel("FactoryRoof_Presses", 176, 112)
	factoryCeilingPanel("FactoryRoof_Gears", 294, 112)
	factoryCeilingPanel("FactoryRoof_Crates", 414, 116)

	floorTileAt("Factory_StartDeck", x, -35, 44, 52, COLORS.FactoryFloor)
	local factoryStart = checkpointAt("FactoryCheckpoint_1", x, -50, 36, "FactoryChaos", true)
	factoryStart.CFrame = CFrame.lookAt(factoryStart.Position, factoryStart.Position + Vector3.new(0, 0, 1))
	local startPad = neon("FactoryStartPad", Vector3.new(26, 0.4, 8), Vector3.new(x, 1.05, -20), COLORS.FactoryOrange)
	startPad:SetAttribute("StartsRun", true)
	startPad:SetAttribute("CourseName", "FactoryChaos")
	nonSolid(startPad)
	arrow("FactoryStart", -26, COLORS.FactoryOrange)
	for _, partName in ipairs({"FactoryStart_ArrowBase", "FactoryStart_ArrowLeft", "FactoryStart_ArrowRight"}) do
		local marker = course:FindFirstChild(partName)
		if marker then
			marker.Position += Vector3.new(x, 0, 0)
		end
	end
	labelBoard("FactoryIntroBoard", Vector3.new(x, 8, -66), Vector3.new(36, 9, 1), "FACTORY CHAOS", "Ride belts, dodge stampers, cross gears, survive the crates.", COLORS.FactoryOrange)

	-- Section 1: three conveyor lanes over water. Players can choose a lane but cannot bypass the water trough.
	pitAt("FactoryConveyors_ResetPit", x, 40, 118, 62)
	block("FactoryConveyors_LeftWall", Vector3.new(2.5, 8, 128), Vector3.new(x - 31.25, 3.5, 40), COLORS.Wall)
	block("FactoryConveyors_RightWall", Vector3.new(2.5, 8, 128), Vector3.new(x + 31.25, 3.5, 40), COLORS.Wall)
	for _, lane in ipairs({
		{-16, Color3.fromRGB(62, 78, 90), -18},
		{0, Color3.fromRGB(56, 62, 70), 16},
		{16, Color3.fromRGB(62, 78, 90), -16},
	}) do
		block("FactoryConveyor_Belt_" .. tostring(lane[1]), Vector3.new(12, 1.1, 104), Vector3.new(x + lane[1], 1.05, 40), COLORS.FactoryBelt, Enum.Material.Metal)
		conveyorZone("FactoryConveyor_Zone_" .. tostring(lane[1]), 40, lane[3], lane[2], x + lane[1], 11, 96)
	end
	punchBlock("FactoryConveyor_CratePusher_1", Vector3.new(x - 28, 3.7, 18), Vector3.new(9, 4.4, 6), 44, 6.0, 0.2)
	punchBlock("FactoryConveyor_CratePusher_2", Vector3.new(x + 28, 3.7, 48), Vector3.new(9, 4.4, 6), -44, 5.8, 1.3)
	punchBlock("FactoryConveyor_CratePusher_3", Vector3.new(x - 28, 3.7, 78), Vector3.new(9, 4.4, 6), 44, 5.6, 2.1)
	for _, z in ipairs({-8, 10, 28, 46, 64, 82}) do
		factoryCoin(x, 4.4, z, 1)
	end
	floorTileAt("Factory_ConveyorExit", x, 112, 22, 52, COLORS.FactoryFloor)
	checkpointAt("FactoryCheckpoint_2", x, 108, 36, "FactoryChaos", false)

	-- Section 2: stamp presses. The wide runway has water gutters, so mistakes knock players off instead of killing them.
	pitAt("FactoryPresses_ResetPit", x, 176, 104, 64)
	block("FactoryPresses_Runway", Vector3.new(32, 1.15, 96), Vector3.new(x, 1.05, 176), COLORS.Pad, Enum.Material.Metal)
	block("FactoryPresses_LeftWall", Vector3.new(2.5, 8, 108), Vector3.new(x - 32.25, 3.5, 176), COLORS.Wall)
	block("FactoryPresses_RightWall", Vector3.new(2.5, 8, 108), Vector3.new(x + 32.25, 3.5, 176), COLORS.Wall)
	stampPress("FactoryStampPress_1", x, 142, 0.0)
	stampPress("FactoryStampPress_2", x, 174, 1.1)
	stampPress("FactoryStampPress_3", x, 206, 2.2)
	for _, z in ipairs({136, 152, 168, 184, 200, 216}) do
		factoryCoin(x + (z % 2 == 0 and -8 or 8), 4.6, z, 1)
	end
	floorTileAt("Factory_PressExit", x, 238, 24, 52, COLORS.FactoryFloor)
	checkpointAt("FactoryCheckpoint_3", x, 232, 36, "FactoryChaos", false)

	-- Section 3: gear tables with sweepers. Platforms are broad, but the moving arms force timing.
	pitAt("FactoryGears_ResetPit", x, 294, 104, 64)
	block("FactoryGears_LeftWall", Vector3.new(2.5, 8, 112), Vector3.new(x - 32.25, 3.5, 294), COLORS.Wall)
	block("FactoryGears_RightWall", Vector3.new(2.5, 8, 112), Vector3.new(x + 32.25, 3.5, 294), COLORS.Wall)
	for _, spec in ipairs({
		{x - 12, 264, 0.0},
		{x + 12, 294, 1.1},
		{x - 10, 324, 2.0},
	}) do
		local gear = block("FactoryGearTable_" .. tostring(spec[2]), Vector3.new(26, 1.2, 24), Vector3.new(spec[1], 1.05, spec[2]), Color3.fromRGB(84, 122, 94), Enum.Material.Metal)
		for tooth = -10, 10, 5 do
			block("FactoryGearTooth_" .. tostring(spec[2]) .. "_" .. tostring(tooth), Vector3.new(3.5, 0.5, 2.2), Vector3.new(spec[1] + tooth, 1.95, spec[2] - 11.8), COLORS.FactoryOrange, Enum.Material.Metal)
		end
		sweeper("FactoryGearSweeper_" .. tostring(spec[2]), Vector3.new(spec[1], 2.05, spec[2]), 30, 4.1, spec[3])
		factoryCoin(spec[1], 4.8, spec[2] - 4, 2)
	end
	floorTileAt("Factory_GearExit", x, 352, 28, 52, COLORS.FactoryFloor)
	checkpointAt("FactoryCheckpoint_4", x, 348, 36, "FactoryChaos", false)

	-- Section 4: swinging toy crates over water, ending in a separate finish gate.
	pitAt("FactoryCrates_ResetPit", x, 412, 106, 64)
	block("FactoryCrates_Bridge", Vector3.new(34, 1.2, 96), Vector3.new(x, 1.05, 412), COLORS.Pad, Enum.Material.Metal)
	block("FactoryCrates_LeftWall", Vector3.new(2.5, 8, 112), Vector3.new(x - 32.25, 3.5, 412), COLORS.Wall)
	block("FactoryCrates_RightWall", Vector3.new(2.5, 8, 112), Vector3.new(x + 32.25, 3.5, 412), COLORS.Wall)
	local factoryRail = part("FactoryCrates_OverheadRail", Vector3.new(2.4, 112, 2.4), CFrame.new(x, 23, 412) * CFrame.Angles(math.rad(90), 0, 0), COLORS.Support, Enum.Material.Metal)
	factoryRail.Shape = Enum.PartType.Cylinder
	factoryRail.CanCollide = false
	swingCrate("FactorySwingCrate_1", 382, x, 28, 4.4, 0.0)
	swingCrate("FactorySwingCrate_2", 408, x, 32, 4.0, 1.2)
	swingCrate("FactorySwingCrate_3", 434, x, 30, 3.8, 2.4)
	for _, z in ipairs({372, 392, 414, 436}) do
		factoryCoin(x + 9, 4.4, z, 2)
	end

	floorTileAt("FactoryFinishDeck", x, 480, 44, 52, COLORS.FactoryFloor)
	local finish = neon("FactoryFinishGate", Vector3.new(26, 1, 10), Vector3.new(x, 1, 462), COLORS.FactoryOrange)
	finish.CanCollide = false
	finish:SetAttribute("CourseName", "FactoryChaos")
	CollectionService:AddTag(finish, "TG_Finish")
	block("FactoryFinishArch_Left", Vector3.new(2, 9, 2), Vector3.new(x - 15, 4.5, 462), COLORS.FactoryOrange, Enum.Material.Metal)
	block("FactoryFinishArch_Right", Vector3.new(2, 9, 2), Vector3.new(x + 15, 4.5, 462), COLORS.FactoryOrange, Enum.Material.Metal)
	block("FactoryFinishArch_Top", Vector3.new(32, 2, 2), Vector3.new(x, 9, 462), COLORS.FactoryOrange, Enum.Material.Metal)
	labelBoard("FactoryFinishBoard", Vector3.new(x, 7.5, 492), Vector3.new(36, 8, 1), "SHIFT COMPLETE!", "Replay Factory Chaos or return to the hub.", COLORS.FactoryOrange)
	local replay = portal("ReplayFactoryPad", Vector3.new(x - 13, 1.25, 506), Vector3.new(18, 0.45, 10), COLORS.FactoryOrange, "TG_FactoryPortal")
	replay.Transparency = 0.02
	local home = portal("FactoryReturnToLobbyPad", Vector3.new(x + 13, 1.25, 506), Vector3.new(18, 0.45, 10), COLORS.Checkpoint, "TG_LobbyReturn")
	home.Transparency = 0.02
	labelBoard("ReplayFactoryBoard", Vector3.new(x - 13, 7, 516), Vector3.new(20, 7, 1), "RUN FACTORY", "Step on orange.", COLORS.FactoryOrange)
	labelBoard("FactoryHubBoard", Vector3.new(x + 13, 7, 516), Vector3.new(20, 7, 1), "HUB", "Step on green.", COLORS.Checkpoint)
end

factoryChaosCourse()
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
floorTile("FinalToTiltConnector", 350, 48, COLORS.FloorAlt)

-- Added course 1: tilting tables over water. Slow, visible movement with safe water resets.
floorTile("TiltTables_EntryDeck", 374, 18, COLORS.Floor)
checkpoint(6, 368)
pit("TiltTables_ResetPit", 422, 82)
block("TiltTables_LeftWall", Vector3.new(2.5, 8, 90), Vector3.new(-24.25, 3.5, 422), COLORS.Wall)
block("TiltTables_RightWall", Vector3.new(2.5, 8, 90), Vector3.new(24.25, 3.5, 422), COLORS.Wall)
tiltTable("TiltTable_1", Vector3.new(0, 1.2, 394), Vector3.new(40, 1.2, 20), 4, 5.6, 0, "Z")
tiltTable("TiltTable_2", Vector3.new(0, 1.2, 414), Vector3.new(40, 1.2, 20), 5, 5.4, 1.1, "X")
tiltTable("TiltTable_3", Vector3.new(0, 1.2, 434), Vector3.new(40, 1.2, 20), 6, 5.2, 2.2, "Z")
floorTile("TiltTables_ExitDeck", 469, 48, COLORS.FloorAlt)

-- Added course 2: launch-pad lagoon. Orange ramps send players across clear water gaps.
floorTile("LaunchLagoon_EntryDeck", 502, 18, COLORS.Floor)
checkpoint(7, 496)
pit("LaunchLagoon_ResetPit", 576, 142)
block("LaunchLagoon_LeftWall", Vector3.new(2.5, 8, 148), Vector3.new(-24.25, 3.5, 576), COLORS.Wall)
block("LaunchLagoon_RightWall", Vector3.new(2.5, 8, 148), Vector3.new(24.25, 3.5, 576), COLORS.Wall)
launchStation("LaunchLagoon_Jump_1", 520, 0, 34, 70)
islandPad("LaunchLagoon_Landing_1", Vector3.new(0, 1.05, 552), Vector3.new(48, 1.2, 42))
timingBumper("LaunchLagoon_TimingBumper_1", Vector3.new(-18, 4.15, 552), 36, 2.9, 0)
launchStation("LaunchLagoon_Jump_2", 582, 0, 34, 70)
islandPad("LaunchLagoon_Landing_2", Vector3.new(0, 1.05, 612), Vector3.new(48, 1.2, 42))
timingBumper("LaunchLagoon_TimingBumper_2", Vector3.new(18, 4.15, 612), -36, 2.6, 1.2)
floorTile("LaunchLagoon_ExitDeck", 650, 30, COLORS.FloorAlt)

-- Added course 3: swinging red balls over water. Hits knock players off; water resets.
checkpoint(8, 626)
pit("SwingBalls_ResetPit", 686, 116)
block("SwingBalls_LeftWall", Vector3.new(2.5, 8, 122), Vector3.new(-24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_RightWall", Vector3.new(2.5, 8, 122), Vector3.new(24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_Bridge", Vector3.new(38, 1.2, 108), Vector3.new(0, 1.05, 690), COLORS.Pad)
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


-- Populate marketplace prop dressing.
-- Marketplace prop pass: imports free Creator Store props and places non-blocking set dressing.
-- Paste into Roblox Studio Command Bar after the course is built.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ASSETS = {
	FactoryCrate = { id = 51896886, name = "Factory Crate" },
	GiftBox = { id = 5141889759, name = "Gift Box" },
	ServerRack = { id = 150383271, name = "Basic Computer Server Rack" },
	ComputerMonitor = { id = 15287400519, name = "Computer Monitor" },
	SafetyBuoy = { id = 123021780, name = "Safety Buoy" },
}

local sources = ReplicatedStorage:FindFirstChild("MarketplacePropSources") or Instance.new("Folder")
sources.Name = "MarketplacePropSources"
sources.Parent = ReplicatedStorage

local placed = Workspace:FindFirstChild("MarketplaceProps") or Instance.new("Folder")
placed.Name = "MarketplaceProps"
placed.Parent = Workspace
placed:ClearAllChildren()

local function stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
end

local function prepareVisual(root)
	stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
	if root:IsA("BasePart") then
		root.Anchored = true
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
	end
end

local function getSource(key)
	local spec = ASSETS[key]
	local existing = sources:FindFirstChild(spec.name) or sources:FindFirstChild(key)
	if existing then
		prepareVisual(existing)
		return existing
	end

	local ok, model = pcall(function()
		return InsertService:LoadAsset(spec.id)
	end)
	if not ok or not model then
		warn("[MarketplaceProps] Could not load " .. spec.name .. " (" .. tostring(spec.id) .. ")")
		return nil
	end

	local asset = model:FindFirstChildWhichIsA("Model") or model:FindFirstChildWhichIsA("BasePart")
	if not asset then
		model:Destroy()
		warn("[MarketplaceProps] No model/part found in " .. spec.name)
		return nil
	end

	asset.Name = spec.name
	asset.Parent = sources
	model:Destroy()
	prepareVisual(asset)
	return asset
end

local function modelBounds(instance)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	return CFrame.new(), Vector3.zero
end

local function placeProp(key, name, position, yawDegrees, scale)
	local source = getSource(key)
	if not source then
		return nil
	end

	local clone = source:Clone()
	clone.Name = name
	clone.Parent = placed
	prepareVisual(clone)

	if clone:IsA("Model") and scale then
		pcall(function()
			clone:ScaleTo(scale)
		end)
	end

	local yaw = math.rad(yawDegrees or 0)
	if clone:IsA("Model") then
		clone:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw, 0))
		local cf, size = modelBounds(clone)
		local bottomY = cf.Position.Y - size.Y * 0.5
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))
	elseif clone:IsA("BasePart") then
		if scale then
			clone.Size *= scale
		end
		clone.CFrame = CFrame.new(position + Vector3.new(0, clone.Size.Y * 0.5, 0)) * CFrame.Angles(0, yaw, 0)
	end

	return clone
end

-- Lobby: perimeter dressing only. Keep spawn sightlines and portal pads clean.
placeProp("GiftBox", "Lobby_DailyGift_Present_A", Vector3.new(-63.5, 2.72, -165.2), 18, 0.24)
placeProp("GiftBox", "Lobby_DailyGift_Present_B", Vector3.new(-52.5, 2.72, -165.2), -18, 0.21)
placeProp("FactoryCrate", "Lobby_Practice_Crate", Vector3.new(70, 0.55, -181), -22, 0.46)
placeProp("ComputerMonitor", "Lobby_ComputerPreview_Monitor", Vector3.new(48, 0.55, -181), 160, 0.72)
placeProp("SafetyBuoy", "Lobby_WipeoutPreview_Buoy", Vector3.new(-46, 0.55, -181), -145, 0.78)

-- Wipeout lane: water-safety dressing at the sides, clear of the playable bridge.
placeProp("SafetyBuoy", "Wipeout_Buoy_Start_Left", Vector3.new(-27.5, 0.55, 18), 90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Start_Right", Vector3.new(27.5, 0.55, 78), -90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Launch_Left", Vector3.new(-27.5, 0.55, 246), 90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Final_Right", Vector3.new(27.5, 0.55, 332), -90, 1.0)

-- Factory: crates staged behind side walls and at the hub-facing edge.
for index, z in ipairs({18, 58, 154, 214, 374, 444}) do
	local side = if index % 2 == 0 then -1 else 1
	placeProp("FactoryCrate", "Factory_SetCrate_" .. index, Vector3.new(-112 + side * 38, 0.55, z), side * 18, 0.72)
end

-- CPU: monitors only. Server rack props had bright blue faces that read like broken shimmer in the course.
placeProp("ComputerMonitor", "CPU_Monitor_Start", Vector3.new(94, 0.55, -34), 20, 1.1)
placeProp("ComputerMonitor", "CPU_Monitor_Finish", Vector3.new(130, 0.55, 490), -20, 1.1)

print("[MarketplaceProps] Populated lobby and three levels with free non-colliding Creator Store props.")


print("Wipeout Run installed. Press Play to test the 7-zone course with wider lanes, launch lagoon, and swinging red ball finale.")

