local PlrService = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Input = {}
Input.__index = Input

local instance = nil

local player = PlrService.LocalPlayer

local Gui = player.PlayerGui

local ButtonsGui = Gui:FindFirstChild("Buttons")
local frame = ButtonsGui:FindFirstChild("MainFrm")

local Btns = {
	[1] = frame.UpBtn;
	[2] = frame.DownBtn;
	[3] = frame.LeftBtn;
	[4] = frame.RightBtn;
}

function Input.Get()
	if instance then return instance end

	local self = setmetatable({}, Input)

	if UIS.TouchEnabled then
		ButtonsGui.Enabled = true
	end

	self.Buttons = {}
	self.Pressed = {}

	local keyMap = {
		-- we wont use the left and right for now, i think
		[Enum.KeyCode.Q] = 1,
		[Enum.KeyCode.E] = 2,
		[Enum.KeyCode.A] = 3,
		[Enum.KeyCode.D] = 4,
	}

	for i, Button:TextButton in Btns do
		Button.InputBegan:Connect(function()
			self.Buttons[i] = true
			self.Pressed[i] = true
		end)

		Button.InputEnded:Connect(function()
			self.Buttons[i] = false
			self.Pressed[i] = false
		end)
	end

	UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		local key = keyMap[input.KeyCode]
		if key then
			self.Buttons[key] = true
			self.Pressed[key] = true
		end
	end)

	UIS.InputEnded:Connect(function(input)
		local key = keyMap[input.KeyCode]
		if key then
			self.Buttons[key] = false
		end
	end)

	instance = self
	return self
end

return Input
