local Module = {}
Module.__index = Module

local Input = require(game.ReplicatedStorage:FindFirstChild("input_module"))
local input = Input.Get()

function Module.SetGUI(Plr:Player)
	if not Plr then return end
	local self = setmetatable({}, Module)

	self.PlrGui = Plr.PlayerGui
	self.Guis = {}

	return self

end

function Module:CreateButtons()
	local Buttons = script.Buttons:Clone()
	Buttons.Parent = self.PlrGui
	Buttons.Enabled = true
	self.Guis["Buttons"] = Buttons

end

return Module
