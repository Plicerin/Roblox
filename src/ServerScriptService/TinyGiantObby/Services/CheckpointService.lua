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
