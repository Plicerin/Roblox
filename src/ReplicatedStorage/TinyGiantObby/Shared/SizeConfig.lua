local SizeConfig = {}

SizeConfig.DefaultForm = "Normal"
SizeConfig.CooldownSeconds = 0.45

SizeConfig.Forms = {
	Tiny = {
		Scale = 0.45,
		WalkSpeed = 13,
		JumpPower = 35,
		ButtonColor = Color3.fromRGB(90, 210, 255),
	},
	Normal = {
		Scale = 1,
		WalkSpeed = 18,
		JumpPower = 50,
		ButtonColor = Color3.fromRGB(110, 255, 135),
	},
	Giant = {
		Scale = 2.2,
		WalkSpeed = 16,
		JumpPower = 75,
		ButtonColor = Color3.fromRGB(255, 185, 75),
	},
}

function SizeConfig.isValidForm(formName)
	return SizeConfig.Forms[formName] ~= nil
end

return SizeConfig
