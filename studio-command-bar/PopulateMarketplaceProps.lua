-- Marketplace prop pass: imports free Creator Store props and places non-blocking set dressing.
-- Paste into Roblox Studio Command Bar after the course is built.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ASSETS = {
	FactoryCrate = { id = 51896886, name = "Factory Crate" },
	GiftBox = { id = 5141889759, name = "Gift Box" },
	ServerRack = { id = 150383271, name = "Basic Computer Server Rack" },
	ComputerMonitor = { id = 15287400519, name = "Computer Monitor" },
	SafetyBuoy = { id = 123021780, name = "Safety Buoy" },
}

local sources = ReplicatedStorage:FindFirstChild("MarketplacePropSources") or Instance.new("Folder")
sources.Name = "MarketplacePropSources"
sources.Parent = ReplicatedStorage

local placed = Workspace:FindFirstChild("MarketplaceProps") or Instance.new("Folder")
placed.Name = "MarketplaceProps"
placed.Parent = Workspace
placed:ClearAllChildren()

local function stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
end

local function prepareVisual(root)
	stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
	if root:IsA("BasePart") then
		root.Anchored = true
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
	end
end

local function getSource(key)
	local spec = ASSETS[key]
	local existing = sources:FindFirstChild(spec.name) or sources:FindFirstChild(key)
	if existing then
		prepareVisual(existing)
		return existing
	end

	local ok, model = pcall(function()
		return InsertService:LoadAsset(spec.id)
	end)
	if not ok or not model then
		warn("[MarketplaceProps] Could not load " .. spec.name .. " (" .. tostring(spec.id) .. ")")
		return nil
	end

	local asset = model:FindFirstChildWhichIsA("Model") or model:FindFirstChildWhichIsA("BasePart")
	if not asset then
		model:Destroy()
		warn("[MarketplaceProps] No model/part found in " .. spec.name)
		return nil
	end

	asset.Name = spec.name
	asset.Parent = sources
	model:Destroy()
	prepareVisual(asset)
	return asset
end

local function modelBounds(instance)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	return CFrame.new(), Vector3.zero
end

local function placeProp(key, name, position, yawDegrees, scale)
	local source = getSource(key)
	if not source then
		return nil
	end

	local clone = source:Clone()
	clone.Name = name
	clone.Parent = placed
	prepareVisual(clone)

	if clone:IsA("Model") and scale then
		pcall(function()
			clone:ScaleTo(scale)
		end)
	end

	local yaw = math.rad(yawDegrees or 0)
	if clone:IsA("Model") then
		clone:PivotTo(CFrame.new(position) * CFrame.Angles(0, yaw, 0))
		local cf, size = modelBounds(clone)
		local bottomY = cf.Position.Y - size.Y * 0.5
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, position.Y - bottomY, 0))
	elseif clone:IsA("BasePart") then
		if scale then
			clone.Size *= scale
		end
		clone.CFrame = CFrame.new(position + Vector3.new(0, clone.Size.Y * 0.5, 0)) * CFrame.Angles(0, yaw, 0)
	end

	return clone
end

-- Lobby: perimeter dressing only. Keep spawn sightlines and portal pads clean.
placeProp("GiftBox", "Lobby_DailyGift_Present_A", Vector3.new(-63.5, 2.72, -165.2), 18, 0.24)
placeProp("GiftBox", "Lobby_DailyGift_Present_B", Vector3.new(-52.5, 2.72, -165.2), -18, 0.21)
placeProp("FactoryCrate", "Lobby_Practice_Crate", Vector3.new(70, 0.55, -181), -22, 0.46)
placeProp("ComputerMonitor", "Lobby_ComputerPreview_Monitor", Vector3.new(48, 0.55, -181), 160, 0.72)
placeProp("SafetyBuoy", "Lobby_WipeoutPreview_Buoy", Vector3.new(-46, 0.55, -181), -145, 0.78)

-- Wipeout lane: water-safety dressing at the sides, clear of the playable bridge.
placeProp("SafetyBuoy", "Wipeout_Buoy_Start_Left", Vector3.new(-27.5, 0.55, 18), 90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Start_Right", Vector3.new(27.5, 0.55, 78), -90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Launch_Left", Vector3.new(-27.5, 0.55, 246), 90, 1.0)
placeProp("SafetyBuoy", "Wipeout_Buoy_Final_Right", Vector3.new(27.5, 0.55, 332), -90, 1.0)

-- Factory: crates staged behind side walls and at the hub-facing edge.
for index, z in ipairs({18, 58, 154, 214, 374, 444}) do
	local side = if index % 2 == 0 then -1 else 1
	placeProp("FactoryCrate", "Factory_SetCrate_" .. index, Vector3.new(-112 + side * 38, 0.55, z), side * 18, 0.72)
end

-- CPU: monitors only. Server rack props had bright blue faces that read like broken shimmer in the course.
placeProp("ComputerMonitor", "CPU_Monitor_Start", Vector3.new(94, 0.55, -34), 20, 1.1)
placeProp("ComputerMonitor", "CPU_Monitor_Finish", Vector3.new(130, 0.55, 490), -20, 1.1)

print("[MarketplaceProps] Populated lobby and three levels with free non-colliding Creator Store props.")
