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
