local ServerScriptService = game:GetService("ServerScriptService")

local root = ServerScriptService:WaitForChild("TinyGiantObby")
local services = root:WaitForChild("Services")

require(services:WaitForChild("CurrencyService")).start()
require(services:WaitForChild("SizeService")).start()
require(services:WaitForChild("CheckpointService")).start()
require(services:WaitForChild("ObstacleService")).start()
