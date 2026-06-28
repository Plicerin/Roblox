-- Paste this into Roblox Studio's Command Bar after syncing/adding the scripts.
-- Wipeout Run: four readable obstacle zones with soft resets and clear checkpoints.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 14
Lighting.Brightness = 1.6
Lighting.Ambient = Color3.fromRGB(80, 90, 105)
Lighting.OutdoorAmbient = Color3.fromRGB(105, 120, 135)

for _, effect in ipairs(Lighting:GetChildren()) do
	if effect:IsA("BloomEffect") then
		effect.Enabled = false
	end
end

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

local function floorTile(name, z, length, color)
	local tile = block(name, Vector3.new(46, 1, length), Vector3.new(0, 0, z), color or COLORS.Floor)
	block(name .. "_LeftWall", Vector3.new(2.5, 8, length), Vector3.new(-24.25, 3.5, z), COLORS.Wall)
	block(name .. "_RightWall", Vector3.new(2.5, 8, length), Vector3.new(24.25, 3.5, z), COLORS.Wall)
	return tile
end

local function pit(name, z, length)
	local p = block(name, Vector3.new(54, 1.2, length), Vector3.new(0, -4.4, z), COLORS.Water, Enum.Material.SmoothPlastic)
	p.Transparency = 0.18
	p.CanCollide = false
	p.CanQuery = false
	p:SetAttribute("SoftReset", true)
	CollectionService:AddTag(p, "TG_Kill")

	for offset = -length * 0.5 + 8, length * 0.5 - 8, 12 do
		local wave = neon(name .. "_Wave_" .. tostring(math.floor(offset)), Vector3.new(38, 0.12, 1.2), Vector3.new(0, -3.72, z + offset), Color3.fromRGB(45, 115, 175))
		wave.Transparency = 0.5
		nonSolid(wave)
	end

	return p
end

local function checkpoint(index, z)
	local p = neon("Checkpoint_" .. index, Vector3.new(34, 0.55, 8), Vector3.new(0, 0.85, z), COLORS.Checkpoint)
	p.Transparency = 0.08
	p.CanCollide = false
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

	local cap = block(name .. "_Cap", Vector3.new(5, 0.5, 5), position + Vector3.new(0, 4.25, 0), COLORS.Trim)
	cap.Shape = Enum.PartType.Cylinder
	cap.Material = Enum.Material.SmoothPlastic

	local arm = block(name, Vector3.new(length, 1.15, 1.15), position + Vector3.new(0, 2.9, 0), COLORS.Sweeper, Enum.Material.SmoothPlastic)
	arm:SetAttribute("Period", period)
	arm:SetAttribute("Phase", phase or 0)
	arm:SetAttribute("KnockStrength", 78)
	arm:SetAttribute("KnockLift", 20)
	CollectionService:AddTag(arm, "TG_Sweeper")
	return arm
end

local function punchBlock(name, startPosition, size, travelX, period, phase)
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

local function conveyorZone(name, z, pushX, color)
	local zone = neon(name, Vector3.new(9, 0.8, 16), Vector3.new(0, 2.4, z), color or Color3.fromRGB(255, 150, 60))
	zone.Transparency = 0.32
	zone:SetAttribute("PushX", pushX)
	zone:SetAttribute("ForwardMin", 12)
	CollectionService:AddTag(zone, "TG_Conveyor")
	nonSolid(zone)

	local arrowColor = if pushX > 0 then Color3.fromRGB(255, 120, 70) else Color3.fromRGB(120, 240, 255)
	local center = neon(name .. "_ArrowBase", Vector3.new(4.8, 0.14, 0.8), Vector3.new(pushX > 0 and 1.2 or -1.2, 2.9, z), arrowColor)
	center.Orientation = Vector3.new(0, pushX > 0 and -25 or 25, 0)
	nonSolid(center)
	local head = neon(name .. "_ArrowHead", Vector3.new(2.2, 0.14, 2.2), Vector3.new(pushX > 0 and 3.4 or -3.4, 2.9, z), arrowColor)
	head.Orientation = Vector3.new(0, 45, 0)
	nonSolid(head)
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
	block("LobbyFloor", Vector3.new(96, 1, 82), Vector3.new(0, 0, -130), COLORS.FloorAlt)
	block("LobbyBackWall", Vector3.new(100, 9, 2.5), Vector3.new(0, 4, -171), COLORS.Wall)
	block("LobbyLeftWall", Vector3.new(2.5, 9, 82), Vector3.new(-49, 4, -130), COLORS.Wall)
	block("LobbyRightWall", Vector3.new(2.5, 9, 82), Vector3.new(49, 4, -130), COLORS.Wall)

	labelBoard("LobbyTitleBoard", Vector3.new(0, 8, -170), Vector3.new(42, 10, 1), "WIPEOUT HUB", "Pick a course. Fall in water, reset fast, run again.", COLORS.Trim)
	labelBoard("LobbyWipeoutBoard", Vector3.new(0, 8, -88), Vector3.new(32, 9, 1), "WIPEOUT RUN", "Portal opens the obstacle course.", COLORS.Trim)
	labelBoard("LobbyFactoryBoard", Vector3.new(-31, 7, -104), Vector3.new(24, 8, 1), "FACTORY CHAOS", "Coming next.", Color3.fromRGB(160, 180, 205))
	labelBoard("LobbyComputerBoard", Vector3.new(31, 7, -104), Vector3.new(24, 8, 1), "COMPUTER OBBY", "Next game prototype.", Color3.fromRGB(160, 180, 205))

	portal("Portal_WipeoutRun", Vector3.new(0, 3.2, -101), Vector3.new(18, 6, 2), COLORS.Trim, "TG_StartPortal")
	block("Portal_WipeoutRun_FrameTop", Vector3.new(22, 1, 2), Vector3.new(0, 6.5, -101), COLORS.Dark, Enum.Material.Metal)
	block("Portal_WipeoutRun_FrameLeft", Vector3.new(1, 7, 2), Vector3.new(-11, 3.6, -101), COLORS.Dark, Enum.Material.Metal)
	block("Portal_WipeoutRun_FrameRight", Vector3.new(1, 7, 2), Vector3.new(11, 3.6, -101), COLORS.Dark, Enum.Material.Metal)

	block("PracticeJumpPad", Vector3.new(16, 1, 10), Vector3.new(-24, 1.05, -139), COLORS.Pad)
	block("PracticeDodgeBlock", Vector3.new(9, 5, 5), Vector3.new(24, 3.5, -139), Color3.fromRGB(210, 36, 42))
	block("PracticeWaterSample", Vector3.new(22, 1, 12), Vector3.new(0, -1.2, -116), COLORS.Water).CanCollide = false
	coin("LobbyCoin_1", Vector3.new(-17, 4, -127), 1)
	coin("LobbyCoin_2", Vector3.new(17, 4, -127), 1)
end

-- Start zone.
lobbyArea()
spawnLocation()
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

-- Added course 1: tilting tables over water. Slow, visible movement with safe water resets.
floorTile("TiltTables_EntryDeck", 374, 18, COLORS.Floor)
checkpoint(6, 368)
pit("TiltTables_ResetPit", 422, 82)
block("TiltTables_LeftWall", Vector3.new(2.5, 8, 90), Vector3.new(-24.25, 3.5, 422), COLORS.Wall)
block("TiltTables_RightWall", Vector3.new(2.5, 8, 90), Vector3.new(24.25, 3.5, 422), COLORS.Wall)
tiltTable("TiltTable_1", Vector3.new(0, 1.2, 394), Vector3.new(36, 1.2, 18), 6, 4.8, 0, "Z")
tiltTable("TiltTable_2", Vector3.new(0, 1.2, 414), Vector3.new(34, 1.2, 18), 8, 4.4, 1.1, "X")
tiltTable("TiltTable_3", Vector3.new(0, 1.2, 434), Vector3.new(32, 1.2, 18), 9, 4.1, 2.2, "Z")
floorTile("TiltTables_ExitDeck", 469, 48, COLORS.FloorAlt)

-- Added course 2: launch-pad lagoon. Orange ramps send players across clear water gaps.
floorTile("LaunchLagoon_EntryDeck", 502, 18, COLORS.Floor)
checkpoint(7, 496)
pit("LaunchLagoon_ResetPit", 576, 142)
block("LaunchLagoon_LeftWall", Vector3.new(2.5, 8, 148), Vector3.new(-24.25, 3.5, 576), COLORS.Wall)
block("LaunchLagoon_RightWall", Vector3.new(2.5, 8, 148), Vector3.new(24.25, 3.5, 576), COLORS.Wall)
launchStation("LaunchLagoon_Jump_1", 520, 0, 36, 84)
islandPad("LaunchLagoon_Landing_1", Vector3.new(0, 1.05, 552), Vector3.new(42, 1.2, 34))
timingBumper("LaunchLagoon_TimingBumper_1", Vector3.new(-18, 4.15, 552), 36, 2.9, 0)
launchStation("LaunchLagoon_Jump_2", 582, 0, 36, 84)
islandPad("LaunchLagoon_Landing_2", Vector3.new(0, 1.05, 617), Vector3.new(42, 1.2, 34))
timingBumper("LaunchLagoon_TimingBumper_2", Vector3.new(18, 4.15, 617), -36, 2.6, 1.2)
floorTile("LaunchLagoon_ExitDeck", 650, 30, COLORS.FloorAlt)

-- Added course 3: swinging red balls over water. Hits knock players off; water resets.
checkpoint(8, 626)
pit("SwingBalls_ResetPit", 686, 116)
block("SwingBalls_LeftWall", Vector3.new(2.5, 8, 122), Vector3.new(-24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_RightWall", Vector3.new(2.5, 8, 122), Vector3.new(24.25, 3.5, 686), COLORS.Wall)
block("SwingBalls_Bridge", Vector3.new(30, 1.2, 108), Vector3.new(0, 1.05, 690), COLORS.Pad)
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
