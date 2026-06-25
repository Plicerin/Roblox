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
