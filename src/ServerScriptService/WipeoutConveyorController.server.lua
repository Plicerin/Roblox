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
