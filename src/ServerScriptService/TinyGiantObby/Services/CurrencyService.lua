local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CurrencyService = {}

local DATASTORE_NAME = "WipeoutRunPlayerData_v1"
local SAVE_INTERVAL = 60

local storeOk, playerStore = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)
if not storeOk then
	playerStore = nil
end
local profiles = {}
local saving = {}

local function defaultProfile()
	return {
		Coins = 0,
		Wins = 0,
		LastDailyGiftDay = "",
		Purchases = {},
		EquippedCosmetic = "",
	}
end

local function dataKey(player)
	return "player_" .. tostring(player.UserId)
end

local function cleanNumber(value)
	if typeof(value) ~= "number" then
		return 0
	end
	return math.max(0, math.floor(value))
end

local function sanitizeProfile(data)
	local profile = defaultProfile()
	if typeof(data) ~= "table" then
		return profile
	end

	profile.Coins = cleanNumber(data.Coins)
	profile.Wins = cleanNumber(data.Wins)
	profile.LastDailyGiftDay = if typeof(data.LastDailyGiftDay) == "string" then data.LastDailyGiftDay else ""
	profile.EquippedCosmetic = if typeof(data.EquippedCosmetic) == "string" then data.EquippedCosmetic else ""

	if typeof(data.Purchases) == "table" then
		for key, value in pairs(data.Purchases) do
			if typeof(key) == "string" and value == true then
				profile.Purchases[key] = true
			end
		end
	end

	return profile
end

local function createStat(parent, name, value)
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Value = value
	stat.Parent = parent
	return stat
end

local function getStats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats,
		leaderstats and leaderstats:FindFirstChild("Size Coins"),
		leaderstats and leaderstats:FindFirstChild("Wins")
end

local function purchaseAttributeName(name)
	return "Purchased_" .. name:gsub("%W", "")
end

local function applyProfile(player, profile)
	local leaderstats, coins, wins = getStats(player)
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	if not wins then
		wins = createStat(leaderstats, "Wins", profile.Wins)
	end
	if not coins then
		coins = createStat(leaderstats, "Size Coins", profile.Coins)
	end

	coins.Value = profile.Coins
	wins.Value = profile.Wins
	player:SetAttribute("DailyGiftClaimed", profile.LastDailyGiftDay == os.date("!%Y-%j"))
	player:SetAttribute("EquippedCosmetic", profile.EquippedCosmetic)

	for name, owned in pairs(profile.Purchases) do
		if owned == true then
			player:SetAttribute(purchaseAttributeName(name), true)
		end
	end
end

local function syncStatsToProfile(player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local _, coins, wins = getStats(player)
	if coins then
		profile.Coins = cleanNumber(coins.Value)
	end
	if wins then
		profile.Wins = cleanNumber(wins.Value)
	end
	profile.EquippedCosmetic = player:GetAttribute("EquippedCosmetic") or profile.EquippedCosmetic or ""
end

local function markDirty(player)
	local profile = profiles[player]
	if profile then
		profile.Dirty = true
	end
end

local function loadProfile(player)
	if not playerStore then
		player:SetAttribute("DataStoreStatus", "SessionOnly")
		return defaultProfile()
	end

	local ok, data = pcall(function()
		return playerStore:GetAsync(dataKey(player))
	end)

	if ok then
		player:SetAttribute("DataStoreStatus", "Loaded")
		return sanitizeProfile(data)
	end

	player:SetAttribute("DataStoreStatus", "SessionOnly")
	return defaultProfile()
end

function CurrencyService.savePlayer(player)
	local profile = profiles[player]
	if not profile or saving[player] then
		return false
	end
	if not playerStore then
		player:SetAttribute("DataStoreStatus", "SessionOnly")
		return false
	end

	syncStatsToProfile(player)
	saving[player] = true

	local payload = {
		Coins = profile.Coins,
		Wins = profile.Wins,
		LastDailyGiftDay = profile.LastDailyGiftDay,
		Purchases = profile.Purchases,
		EquippedCosmetic = profile.EquippedCosmetic,
	}

	local ok = pcall(function()
		playerStore:SetAsync(dataKey(player), payload)
	end)

	saving[player] = nil
	if ok then
		profile.Dirty = false
		player:SetAttribute("DataStoreStatus", "Saved")
	else
		player:SetAttribute("DataStoreStatus", "SessionOnly")
	end
	return ok
end

function CurrencyService.addCoins(player, amount)
	local _, coins = getStats(player)
	if coins then
		coins.Value = math.max(0, coins.Value + math.floor(amount))
		markDirty(player)
	end
end

function CurrencyService.spendCoins(player, amount)
	local _, coins = getStats(player)
	amount = math.max(0, math.floor(amount))
	if not coins or coins.Value < amount then
		return false
	end

	coins.Value -= amount
	markDirty(player)
	return true
end

function CurrencyService.addWins(player, amount)
	local _, _, wins = getStats(player)
	if wins then
		wins.Value = math.max(0, wins.Value + math.floor(amount))
		markDirty(player)
	end
end

function CurrencyService.claimDailyGift(player, rewardCoins)
	local profile = profiles[player]
	if not profile then
		return false, "Data loading"
	end

	local today = os.date("!%Y-%j")
	if profile.LastDailyGiftDay == today then
		player:SetAttribute("DailyGiftClaimed", true)
		return false, "Gift already claimed"
	end

	profile.LastDailyGiftDay = today
	player:SetAttribute("DailyGiftClaimed", true)
	CurrencyService.addCoins(player, rewardCoins or 25)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
	return true
end

function CurrencyService.ownsCosmetic(player, name)
	local profile = profiles[player]
	return profile and profile.Purchases[name] == true
end

function CurrencyService.purchaseCosmetic(player, name, cost)
	local profile = profiles[player]
	if not profile then
		return false, "Data loading"
	end
	if profile.Purchases[name] == true then
		return true, "Owned"
	end
	if not CurrencyService.spendCoins(player, cost or 0) then
		return false, "Need " .. tostring(cost or 0) .. " coins"
	end

	profile.Purchases[name] = true
	player:SetAttribute(purchaseAttributeName(name), true)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
	return true, "Bought"
end

function CurrencyService.equipCosmetic(player, name)
	local profile = profiles[player]
	if profile then
		profile.EquippedCosmetic = name
	end
	player:SetAttribute("EquippedCosmetic", name)
	markDirty(player)
	task.defer(CurrencyService.savePlayer, player)
end

function CurrencyService.getEquippedCosmetic(player)
	local profile = profiles[player]
	return (profile and profile.EquippedCosmetic) or player:GetAttribute("EquippedCosmetic") or ""
end

local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local wins = createStat(leaderstats, "Wins", 0)
	local coins = createStat(leaderstats, "Size Coins", 0)

	local profile = loadProfile(player)
	profiles[player] = profile
	applyProfile(player, profile)
	player:SetAttribute("DataReady", true)

	coins:GetPropertyChangedSignal("Value"):Connect(function()
		local currentProfile = profiles[player]
		if currentProfile then
			currentProfile.Coins = cleanNumber(coins.Value)
			markDirty(player)
		end
	end)

	wins:GetPropertyChangedSignal("Value"):Connect(function()
		local currentProfile = profiles[player]
		if currentProfile then
			currentProfile.Wins = cleanNumber(wins.Value)
			markDirty(player)
		end
	end)
end

function CurrencyService.start()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		CurrencyService.savePlayer(player)
		profiles[player] = nil
		saving[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if player.Parent and profile.Dirty then
					task.spawn(CurrencyService.savePlayer, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player in pairs(profiles) do
			CurrencyService.savePlayer(player)
		end
	end)
end

return CurrencyService
