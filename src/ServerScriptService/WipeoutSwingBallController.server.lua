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
