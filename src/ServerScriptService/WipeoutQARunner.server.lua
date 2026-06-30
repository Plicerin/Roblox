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

