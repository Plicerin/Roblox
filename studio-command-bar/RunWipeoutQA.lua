-- Paste into Roblox Studio Command Bar while the game is running in Play mode.
-- This runs the persistent QA worker installed as ServerScriptService/WipeoutQARunner.
-- Strict mode uses Humanoid movement and jumps after initial course placement.
-- Assisted mode is only a follow-up diagnostic pass so failures do not hide later bugs.

local qaInvoke = game:GetService("ReplicatedStorage"):FindFirstChild("WipeoutQAInvoke")
local qa = _G.WipeoutQA
if not qaInvoke and not qa then
	error("WipeoutQA is not loaded. Install the latest package, press Play, then run this again.")
end
local function runAll(options)
	if qaInvoke then
		return qaInvoke:Invoke("RunAll", options)
	end
	return qa.RunAll(options)
end
local function enhancementIdeas(report)
	if qaInvoke then
		return qaInvoke:Invoke("EnhancementIdeas", report)
	end
	return qa.EnhancementIdeas(report)
end

local strictReport = runAll({
	waypointTimeout = 8,
	timerTimeout = 3,
	settleTime = 0.35,
	waypointPause = 0.1,
	motionSampleSeconds = 1.25,
})

print("=== Wipeout QA Strict Summary ===")
print(strictReport.summary)

local needsAssisted = false
for _, course in ipairs(strictReport.courses) do
	print(string.format(
		"%s: mode=%s completed=%s time=%.1fs waypoints=%d/%d resets=%d checkpoints=%d coins=%d wins=%d fail=%s",
		course.title,
		course.mode or "unknown",
		tostring(course.completed),
		course.timeSeconds or 0,
		course.waypointsReached or 0,
		course.waypointsTotal or 0,
		course.resetCount or 0,
		course.checkpointsTouched or 0,
		course.coinsGained or 0,
		course.winsGained or 0,
		course.failReason or "none"
	))
	if course.stuckPoints and #course.stuckPoints > 0 then
		print("  stuck: " .. table.concat(course.stuckPoints, " | "))
	end
	if not course.completed then
		needsAssisted = true
	end
end

print("=== Geometry / Motion Audit ===")
print("missing critical: " .. tostring(#strictReport.geometry.missingCritical))
print("visible near-coplanar/z-fight suspects: " .. tostring(#strictReport.geometry.visibleNearCoplanar))
print("roof collision suspects: " .. tostring(#strictReport.geometry.roofCollisions))
print("large route gap suspects: " .. tostring(#strictReport.geometry.routeGaps))
if strictReport.geometry.motion then
	for label, sample in pairs(strictReport.geometry.motion) do
		print(string.format("%s: moving=%d total=%d stationary=%d", label, sample.moving or 0, sample.total or 0, #(sample.stationary or {})))
	end
end

local ideas = enhancementIdeas(strictReport)
print("=== Suggested Enhancements ===")
for index, idea in ipairs(ideas) do
	print(index .. ". " .. idea)
end

if needsAssisted then
	print("=== Assisted Diagnostic Pass ===")
	local assistedReport = runAll({
		assistAfterTimeout = true,
		waypointTimeout = 8,
		timerTimeout = 3,
		settleTime = 0.3,
		waypointPause = 0.08,
		motionSampleSeconds = 0.75,
	})
	print(assistedReport.summary)
	for _, course in ipairs(assistedReport.courses) do
		print(string.format(
			"%s assisted: completed=%s fail=%s",
			course.title,
			tostring(course.completed),
			course.failReason or "none"
		))
	end
	return {strict = strictReport, assisted = assistedReport}
end

return {strict = strictReport}

