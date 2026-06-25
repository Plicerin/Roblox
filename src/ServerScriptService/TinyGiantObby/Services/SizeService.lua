local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SizeConfig = require(ReplicatedStorage:WaitForChild("TinyGiantObby"):WaitForChild("Shared"):WaitForChild("SizeConfig"))
local FeedbackService = require(ServerScriptService:WaitForChild("TinyGiantObby"):WaitForChild("Services"):WaitForChild("FeedbackService"))

local SizeService = {}

local remoteFolder
local switchRemote
local slideSteerRemote
local lastSwitchByPlayer = {}

local function ensureRemotes()
	remoteFolder = ReplicatedStorage:FindFirstChild("TinyGiantObbyRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "TinyGiantObbyRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	switchRemote = remoteFolder:FindFirstChild("SwitchSize")
	if not switchRemote then
		switchRemote = Instance.new("RemoteEvent")
		switchRemote.Name = "SwitchSize"
		switchRemote.Parent = remoteFolder
	end

	slideSteerRemote = remoteFolder:FindFirstChild("SlideSteer")
	if not slideSteerRemote then
		slideSteerRemote = Instance.new("RemoteEvent")
		slideSteerRemote.Name = "SlideSteer"
		slideSteerRemote.Parent = remoteFolder
	end
end

local function setBodyScale(humanoid, scale)
	local scaleNames = {
		"BodyDepthScale",
		"BodyHeightScale",
		"BodyWidthScale",
		"HeadScale",
	}

	for _, scaleName in ipairs(scaleNames) do
		local value = humanoid:FindFirstChild(scaleName)
		if value and value:IsA("NumberValue") then
			value.Value = scale
		end
	end
end

function SizeService.applyForm(player, formName)
	if not SizeConfig.isValidForm(formName) then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local form = SizeConfig.Forms[formName]
	player:SetAttribute("CurrentForm", formName)
	character:SetAttribute("CurrentForm", formName)

	humanoid.WalkSpeed = form.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = form.JumpPower
	setBodyScale(humanoid, form.Scale)
	FeedbackService.characterPulse(character, form.ButtonColor)

	return true
end

local function onCharacterAdded(player, character)
	character:WaitForChild("Humanoid", 8)
	task.wait(0.25)
	SizeService.applyForm(player, SizeConfig.DefaultForm)
end

local function onSwitchRequested(player, formName)
	if typeof(formName) ~= "string" or not SizeConfig.isValidForm(formName) then
		return
	end

	local now = os.clock()
	local lastSwitch = lastSwitchByPlayer[player] or 0
	if now - lastSwitch < SizeConfig.CooldownSeconds then
		return
	end

	lastSwitchByPlayer[player] = now
	SizeService.applyForm(player, formName)
end

function SizeService.start()
	ensureRemotes()
	switchRemote.OnServerEvent:Connect(onSwitchRequested)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("CurrentForm", SizeConfig.DefaultForm)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastSwitchByPlayer[player] = nil
	end)
end

return SizeService
