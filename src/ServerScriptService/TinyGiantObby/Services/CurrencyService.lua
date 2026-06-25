local Players = game:GetService("Players")

local CurrencyService = {}

local function createStat(parent, name, value)
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Value = value
	stat.Parent = parent
	return stat
end

function CurrencyService.addCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Size Coins")
	if coins then
		coins.Value += amount
	end
end

function CurrencyService.addWins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value += amount
	end
end

function CurrencyService.start()
	Players.PlayerAdded:Connect(function(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		createStat(leaderstats, "Wins", 0)
		createStat(leaderstats, "Size Coins", 0)
	end)
end

return CurrencyService
