local Debris = game:GetService("Debris")

local FeedbackService = {}

local function makeAttachment(parent)
	local attachment = Instance.new("Attachment")
	attachment.Name = "TG_FeedbackAttachment"
	attachment.Parent = parent
	return attachment
end

function FeedbackService.pulsePart(part, color)
	if not part or not part.Parent then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TG_FeedbackHighlight"
	highlight.Adornee = part
	highlight.FillColor = color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = part
	Debris:AddItem(highlight, 0.45)

	local light = Instance.new("PointLight")
	light.Name = "TG_FeedbackLight"
	light.Color = color
	light.Brightness = 3
	light.Range = 14
	light.Parent = part
	Debris:AddItem(light, 0.45)
end

function FeedbackService.burst(parent, color, amount)
	if not parent or not parent.Parent then
		return
	end

	local attachment = makeAttachment(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TG_FeedbackBurst"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.65
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = attachment
	emitter:Emit(amount or 18)

	Debris:AddItem(attachment, 1)
end

local function makeWorldEmitterPart(name, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = workspace
	return part
end

function FeedbackService.splashAt(position)
	local part = makeWorldEmitterPart("TG_WaterSplashFX", position)
	local attachment = makeAttachment(part)

	local splash = Instance.new("ParticleEmitter")
	splash.Name = "SplashDroplets"
	splash.Color = ColorSequence.new(Color3.fromRGB(130, 220, 255), Color3.fromRGB(245, 255, 255))
	splash.LightEmission = 0.45
	splash.Lifetime = NumberRange.new(0.35, 0.75)
	splash.Rate = 0
	splash.Speed = NumberRange.new(18, 30)
	splash.SpreadAngle = Vector2.new(55, 55)
	splash.Acceleration = Vector3.new(0, -55, 0)
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(1, 0),
	})
	splash.Parent = attachment
	splash:Emit(34)

	local foam = Instance.new("ParticleEmitter")
	foam.Name = "SplashFoam"
	foam.Color = ColorSequence.new(Color3.fromRGB(210, 245, 255))
	foam.LightEmission = 0.25
	foam.Lifetime = NumberRange.new(0.45, 0.85)
	foam.Rate = 0
	foam.Speed = NumberRange.new(3, 8)
	foam.SpreadAngle = Vector2.new(180, 180)
	foam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	foam.Parent = attachment
	foam:Emit(10)

	Debris:AddItem(part, 1.4)
end

function FeedbackService.confettiAt(position)
	local part = makeWorldEmitterPart("TG_FinishConfettiFX", position)
	local attachment = makeAttachment(part)

	local confetti = Instance.new("ParticleEmitter")
	confetti.Name = "FinishConfetti"
	confetti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 60)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(80, 210, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 255, 130)),
	})
	confetti.LightEmission = 0.4
	confetti.Lifetime = NumberRange.new(1.0, 1.8)
	confetti.Rate = 0
	confetti.Speed = NumberRange.new(18, 32)
	confetti.SpreadAngle = Vector2.new(65, 65)
	confetti.Acceleration = Vector3.new(0, -35, 0)
	confetti.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	confetti.Parent = attachment
	confetti:Emit(90)

	Debris:AddItem(part, 2.4)
end

function FeedbackService.characterPulse(character, color)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	FeedbackService.pulsePart(root, color)
	FeedbackService.burst(root, color, 22)
end

return FeedbackService
