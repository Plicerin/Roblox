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
