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

function FeedbackService.characterPulse(character, color)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	FeedbackService.pulsePart(root, color)
	FeedbackService.burst(root, color, 22)
end

return FeedbackService
