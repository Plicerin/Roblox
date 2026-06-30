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

