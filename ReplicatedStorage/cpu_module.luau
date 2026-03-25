local CPU = {}
CPU.__index = CPU

local GPU = require(game.ReplicatedStorage:FindFirstChild("gpu_module"))
local Input = require(game.ReplicatedStorage:FindFirstChild("input_module"))

-- TODO: move this text display bs to the gpu
local MonitorDisplay = workspace:FindFirstChild("TextDisplay").MonitorDisplay
local SurfaceGui = MonitorDisplay:FindFirstChild("SurfaceGui")
local ScrollingFrm = SurfaceGui:FindFirstChild("ScrollingFrame")
local screen_text = ScrollingFrm:FindFirstChild("TextLabel")


function CPU.new()
	local self = setmetatable({}, CPU)

	self.gpu = GPU.Setup(workspace:FindFirstChild("Monitor"))

	self.input = Input.Get()

	-- ram is too pricey, we only have 256 bytes, i hate AIs ╾━╤╦ (•-•)
	self.Memory = table.create(256, 0)
	self.Registers = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} -- whopping 8 registers (O_O)!
	self.PC = 1 -- program counter
	self.ProgramSize = 1
	self.Running = true
	self.Labels = {}
	self.Unresolved = {}

	self.OP_LOAD  = 0x01 -- load reg, val
	self.OP_ADD   = 0x02 -- add regA, regB
	self.OP_JUMP  = 0x03 -- jump to address
	self.OP_JEQ   = 0x04 -- jump if equal
	self.OP_SUB   = 0x05 -- subtract regA, regB
	self.OP_DTS   = 0x06 -- display value on text screen scr, val
	self.OP_PTS   = 0x07 -- set pixel to screen, reg(x), reg(y), val
	self.OP_CLT   = 0x08 -- clear screen
	self.OP_CLS   = 0x09 -- clear text screen
	self.OP_BTN   = 0x0A -- set reg to 1 if button pressed, reg, val
	self.OP_MUL   = 0x0B -- multiply regA, regB
	self.OP_JGT   = 0x0C -- jump if greater reg, val, address
	self.OP_JLT   = 0x0F -- jump if lesser reg, val, address
	self.OP_MOV   = 0x10 -- move register into another regA, regB
	self.OP_NEG   = 0x11 -- negate register reg
	self.OP_HALT  = 0xFF -- halt

	screen_text.Text = "hey! welcome to my tiny cpu, just a proof of concept. it's a 8-bit cpu with 8 registers \"emulating\" assembly, you can test pong by clicking the turn button on the PC.\nInput Keys: Q, E\n\nSource code in GitHub: ricethedev/luau_cpu"

	return self
end

function CPU:Fetch()
	local instruction = self.Memory[self.PC]
	self.PC += 1
	return instruction
end

function CPU:ResetProgram()
	self.PC = 1
	self.ProgramSize = 1
	self.Running = true
	table.clear(self.Memory)
	screen_text.Text = ""

end

function CPU:Emit(byte)
	self.Memory[self.ProgramSize] = byte
	self.ProgramSize += 1
end

function CPU:Step()
	local opcode = self:Fetch()

	if opcode == self.OP_LOAD then
		local regIdx = self:Fetch()
		local value = self:Fetch()
		self.Registers[regIdx] = value

	elseif opcode == self.OP_ADD then
		local regA = self:Fetch()
		local regB = self:Fetch()
		self.Registers[regA] += self.Registers[regB]

	elseif opcode == self.OP_SUB then
		local regA = self:Fetch()
		local regB = self:Fetch()
		self.Registers[regA] -= self.Registers[regB]

	elseif opcode == self.OP_JUMP then
		local address = self:Fetch()
		self.PC = address

	elseif opcode == self.OP_DTS then
		local scr = self:Fetch() -- we actually dont use this
		local val = self:Fetch()
		local value = self.Registers[val]
		screen_text.Text = screen_text.Text .. tostring(val);
		print("showing " .. tostring(val) .. " to screen " .. scr)

	elseif opcode == self.OP_HALT then
		self.Running = false

	elseif opcode == self.OP_JEQ then
		local regIdx = self:Fetch()
		local compareValue = self:Fetch()
		local targetAddress = self:Fetch()

		if self.Registers[regIdx] == compareValue then
			self.PC = targetAddress
		end

	elseif opcode == self.OP_PTS then
		local regA = self:Fetch()
		local regB = self:Fetch()
		local val = self:Fetch()

		local x = self.Registers[regA]
		local y = self.Registers[regB]

		if val == 1 then
			self.gpu:setPixel(x, y)
		elseif val == 0 then
			self.gpu:clearPixel(x, y)
		end


	elseif opcode == self.OP_CLT then
		screen_text.Text = ""

	elseif opcode == self.OP_CLS then
		self.gpu:Clear()


	elseif opcode == self.OP_BTN then
		local reg = self:Fetch()
		local val = self:Fetch()

		self.Registers[reg] = self.input.Buttons[val] and 1 or 0

	elseif opcode == self.OP_MUL then
		local regA = self:Fetch()
		local regB = self:Fetch()

		self.Registers[regA] = self.Registers[regA] * self.Registers[regB]

	elseif opcode == self.OP_JGT then
		local regIdx = self:Fetch()
		local compareValue = self:Fetch()
		local targetAddress = self:Fetch()

		if self.Registers[regIdx] > compareValue then
			self.PC = targetAddress
		end

	elseif opcode == self.OP_JLT then
		local regIdx = self:Fetch()
		local compareValue = self:Fetch()
		local targetAddress = self:Fetch()

		if self.Registers[regIdx] < compareValue then
			self.PC = targetAddress
		end

	elseif opcode == self.OP_MOV then
		local regA = self:Fetch()
		local regB = self:Fetch()

		self.Registers[regA] = self.Registers[regB]

	elseif opcode == self.OP_NEG then
		local reg = self:Fetch()

		self.Registers[reg] = self.Registers[reg] * -1

	else
		warn("unknown opcode: " .. opcode)
	end
end

function CPU:LABEL(name)
	self.Labels[name] = self.ProgramSize
end

function CPU:LOOP(name)
	self:LABEL(name)
end

function CPU:LOAD(reg, value)
	self:Emit(self.OP_LOAD)
	self:Emit(reg)
	self:Emit(value)
end

function CPU:ADD(r1, r2)
	self:Emit(self.OP_ADD)
	self:Emit(r1)
	self:Emit(r2)
end

function CPU:SUB(r1, r2)
	self:Emit(self.OP_SUB)
	self:Emit(r1)
	self:Emit(r2)
end

function CPU:DTS(scr, reg)
	self:Emit(self.OP_DTS)
	self:Emit(scr)
	self:Emit(reg)
end

function CPU:JUMP(addr)
	self:Emit(self.OP_JUMP)

	if type(addr) == "string" then
		table.insert(self.Unresolved, {
			pos = self.ProgramSize,
			label = addr
		})
		self:Emit(0)
	else
		self:Emit(addr)
	end
end

function CPU:JEQ(reg, value, addr)
	self:Emit(self.OP_JEQ)
	self:Emit(reg)
	self:Emit(value)

	if type(addr) == "string" then
		table.insert(self.Unresolved, {
			pos = self.ProgramSize,
			label = addr
		})
		self:Emit(0)
	else
		self:Emit(addr)
	end
end

function CPU:ResolveLabels()
	for _, entry in ipairs(self.Unresolved) do
		local addr = self.Labels[entry.label]

		if not addr then
			error("Undefined label: " .. entry.label)
		end

		self.Memory[entry.pos] = addr
	end
end

function CPU:HALT()
	self:Emit(self.OP_HALT)
end

function CPU:PTS(regA, regB, val)
	self:Emit(self.OP_PTS)
	self:Emit(regA)
	self:Emit(regB)
	self:Emit(val)
end

function CPU:CLT()
	self:Emit(self.OP_CLT)
end

function CPU:CLS()
	self:Emit(self.OP_CLS)
end

function CPU:BTN(reg, val)
	self:Emit(self.OP_BTN)
	self:Emit(reg)
	self:Emit(val)
end

function CPU:RTS()
	self:Emit(self.OP_RTS)
end

function CPU:MUL(regA, regB)
	self:Emit(self.OP_MUL)
	self:Emit(regA)
	self:Emit(regB)
end

function CPU:JGT(reg, val, addr)
	self:Emit(self.OP_JGT)
	self:Emit(reg)
	self:Emit(val)
	if type(addr) == "string" then
		table.insert(self.Unresolved, { pos = self.ProgramSize, label = addr })
		self:Emit(0)
	else
		self:Emit(addr)
	end
end

function CPU:JLT(reg, val, addr)
	self:Emit(self.OP_JLT)
	self:Emit(reg)
	self:Emit(val)
	if type(addr) == "string" then
		table.insert(self.Unresolved, { pos = self.ProgramSize, label = addr })
		self:Emit(0)
	else
		self:Emit(addr)
	end
end
function CPU:MOV(regA, regB)
	self:Emit(self.OP_MOV)
	self:Emit(regA)
	self:Emit(regB)
end

function CPU:NEG(reg)
	self:Emit(self.OP_NEG)
	self:Emit(reg)
end

-- returning our cute and powerful cpu :D
return CPU
