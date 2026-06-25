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
