local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))
local CurrencyService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("CurrencyService"))

local DAILY_GIFT_TAG = "TG_DailyGiftPad"
local COSMETIC_PAD_TAG = "TG_CosmeticShopPad"
local touchCooldown = {}

local function getPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function canUse(player, part)
	local now = os.clock()
	local key = tostring(player.UserId) .. ":" .. part:GetFullName()
	local last = touchCooldown[key] or 0
	if now - last < 0.9 then
		return false
	end
	touchCooldown[key] = now
	return true
end

local function toast(player, text, color)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "LobbyToast"
	gui.Size = UDim2.fromOffset(260, 54)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 235, 90)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	Debris:AddItem(gui, 1.7)
end

local function equipTrail(player, color, name)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "LobbyCosmeticTrail" or child.Name == "LobbyTrailAttachmentA" or child.Name == "LobbyTrailAttachmentB" then
			child:Destroy()
		end
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "LobbyTrailAttachmentA"
	a0.Position = Vector3.new(-1.2, 1.1, 0.5)
	a0.Parent = root

	local a1 = Instance.new("Attachment")
	a1.Name = "LobbyTrailAttachmentB"
	a1.Position = Vector3.new(1.2, -1.1, 0.5)
	a1.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "LobbyCosmeticTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 0.45
	trail.Lifetime = 0.45
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new(0.9)
	trail.Parent = root

	player:SetAttribute("EquippedCosmetic", name)
end

local function connectDailyGift(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player, part) then
			return
		end

		local reward = part:GetAttribute("RewardCoins") or 25
		local claimed, reason = CurrencyService.claimDailyGift(player, reward)
		if not claimed then
			toast(player, reason or "Gift already claimed", Color3.fromRGB(235, 240, 250))
			FeedbackService.pulsePart(part, Color3.fromRGB(110, 130, 145))
			return
		end

		toast(player, "+" .. tostring(reward) .. " COINS", Color3.fromRGB(100, 255, 140))
		FeedbackService.pulsePart(part, Color3.fromRGB(100, 255, 140))
		FeedbackService.burst(part, Color3.fromRGB(100, 255, 140), 30)
	end)
end

local function connectCosmeticPad(part)
	part.CanCollide = false
	part.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player or not canUse(player, part) then
			return
		end

		local name = part:GetAttribute("CosmeticName") or "Trail"
		local cost = part:GetAttribute("Cost") or 25
		local alreadyOwned = CurrencyService.ownsCosmetic(player, name)
		local purchased, reason = CurrencyService.purchaseCosmetic(player, name, cost)
		if not purchased then
			toast(player, reason or ("Need " .. tostring(cost) .. " coins"), Color3.fromRGB(255, 120, 100))
			FeedbackService.pulsePart(part, Color3.fromRGB(255, 120, 100))
			return
		end
		if alreadyOwned then
			toast(player, "Equipped " .. name, Color3.fromRGB(120, 220, 255))
		elseif reason == "Bought" then
			toast(player, "Bought " .. name, Color3.fromRGB(255, 235, 90))
		else
			toast(player, "Equipped " .. name, Color3.fromRGB(120, 220, 255))
		end

		local color = part:GetAttribute("TrailColor")
		if typeof(color) ~= "Color3" then
			color = Color3.fromRGB(255, 225, 70)
		end
		CurrencyService.equipCosmetic(player, name)
		equipTrail(player, color, name)
		FeedbackService.pulsePart(part, color)
		FeedbackService.burst(part, color, 20)
	end)
end

local function ensureWinsBoardGui()
	local board = workspace:FindFirstChild("LobbyWinsBoard_Board", true)
	if not board or not board:IsA("BasePart") then
		return nil, nil, nil
	end

	local gui = board:FindFirstChild("WinsBoardGui")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "WinsBoardGui"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.06, 0.08)
		title.Size = UDim2.fromScale(0.88, 0.25)
		title.Font = Enum.Font.GothamBlack
		title.TextColor3 = Color3.fromRGB(80, 210, 255)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = gui

		local rows = Instance.new("TextLabel")
		rows.Name = "Rows"
		rows.BackgroundTransparency = 1
		rows.Position = UDim2.fromScale(0.08, 0.36)
		rows.Size = UDim2.fromScale(0.84, 0.54)
		rows.Font = Enum.Font.GothamBold
		rows.TextColor3 = Color3.fromRGB(245, 250, 255)
		rows.TextScaled = true
		rows.TextWrapped = true
		rows.TextXAlignment = Enum.TextXAlignment.Left
		rows.TextYAlignment = Enum.TextYAlignment.Top
		rows.Parent = gui
	end

	return board, gui:FindFirstChild("Title"), gui:FindFirstChild("Rows")
end

local function updateWinsBoard()
	local _, title, rows = ensureWinsBoardGui()
	if not title or not rows then
		return
	end

	local ranked = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local wins = leaderstats and leaderstats:FindFirstChild("Wins")
		table.insert(ranked, {
			Name = player.DisplayName or player.Name,
			Wins = wins and wins.Value or 0,
		})
	end
	table.sort(ranked, function(a, b)
		if a.Wins == b.Wins then
			return a.Name < b.Name
		end
		return a.Wins > b.Wins
	end)

	title.Text = "WINS BOARD"
	local lines = {}
	for i = 1, math.min(5, #ranked) do
		table.insert(lines, string.format("%d. %s  -  %d", i, ranked[i].Name, ranked[i].Wins))
	end
	if #lines == 0 then
		table.insert(lines, "No runners yet.")
	end
	rows.Text = table.concat(lines, "\n")
end

local function connectTagged(tagName, connect)
	for _, part in ipairs(CollectionService:GetTagged(tagName)) do
		if part:IsA("BasePart") then
			connect(part)
		end
	end
	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(part)
		if part:IsA("BasePart") then
			connect(part)
		end
	end)
end

connectTagged(DAILY_GIFT_TAG, connectDailyGift)
connectTagged(COSMETIC_PAD_TAG, connectCosmeticPad)

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		local equipped = CurrencyService.getEquippedCosmetic(player)
		if equipped == "Gold Trail" then
			task.wait(0.3)
			equipTrail(player, Color3.fromRGB(255, 225, 70), equipped)
		elseif equipped == "Neon Trail" then
			task.wait(0.3)
			equipTrail(player, Color3.fromRGB(170, 95, 255), equipped)
		end
	end)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local wins = leaderstats and leaderstats:WaitForChild("Wins", 10)
	if wins then
		wins:GetPropertyChangedSignal("Value"):Connect(updateWinsBoard)
	end
	task.defer(updateWinsBoard)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	task.defer(updateWinsBoard)
	for key in pairs(touchCooldown) do
		if key:find(tostring(player.UserId) .. ":", 1, true) then
			touchCooldown[key] = nil
		end
	end
end)

task.spawn(function()
	while true do
		updateWinsBoard()
		task.wait(5)
	end
end)
