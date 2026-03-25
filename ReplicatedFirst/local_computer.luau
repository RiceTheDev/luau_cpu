repeat task.wait() until game:IsLoaded()
task.wait(1)
repeat task.wait() until workspace:FindFirstChild("TextDisplay")
repeat task.wait() until workspace.TextDisplay:FindFirstChild("MonitorDisplay")
repeat task.wait() until workspace.restart.ButtonPressPart.ClickDetector
repeat task.wait() until workspace.turn.ButtonPressPart.ClickDetector

repeat task.wait() until workspace:FindFirstChild("restart")
repeat task.wait() until workspace:FindFirstChild("turn")

local restartPart = workspace.restart:FindFirstChild("ButtonPressPart")
local powerPart = workspace.turn:FindFirstChild("ButtonPressPart")
repeat task.wait() until restartPart and restartPart:FindFirstChild("ClickDetector")
repeat task.wait() until powerPart and powerPart:FindFirstChild("ClickDetector")

local restartDetector = restartPart.ClickDetector
local powerDetector = powerPart.ClickDetector

local CPU = require(game.ReplicatedStorage:FindFirstChild("cpu_module"))
cpu = CPU.new()

function assembleGame()
	cpu:ResetProgram()

	cpu:DTS(1, "lets pong!\n")

	cpu:LOAD(7,  1)
	cpu:LOAD(8,  15)
	cpu:LOAD(9,  11)
	cpu:LOAD(10, 3)
	cpu:LOAD(12, 1)

	cpu:LABEL("reset_game")
	cpu:LOAD(1,  8)
	cpu:LOAD(2,  6)
	cpu:LOAD(3,  1)
	cpu:LOAD(4,  1)
	cpu:LOAD(5,  4)

	cpu:LABEL("main")

	cpu:CLS()

	cpu:PTS(12, 5, 1)
	cpu:MOV(13, 5)
	cpu:ADD(13, 7)
	cpu:PTS(12, 13, 1)
	cpu:ADD(13, 7)
	cpu:PTS(12, 13, 1)

	cpu:PTS(1, 2, 1)

	cpu:ADD(1, 3)
	cpu:ADD(2, 4)

	cpu:JGT(2, 0, "no_bounce_top")
	cpu:NEG(4)
	cpu:LOAD(2, 0)
	cpu:LABEL("no_bounce_top")

	cpu:JLT(2, 11, "no_bounce_bot")
	cpu:NEG(4)
	cpu:LOAD(2, 11)
	cpu:LABEL("no_bounce_bot")

	cpu:JLT(1, 15, "no_bounce_right")
	cpu:NEG(3)
	cpu:LOAD(1, 14)
	cpu:LABEL("no_bounce_right")

	cpu:JGT(1, 0, "no_death")
	cpu:DTS(1, "cpu halted, press the red\nbutton to try again\n")
	cpu:HALT()
	cpu:LABEL("no_death")

	cpu:JGT(1, 2, "no_paddle")
	cpu:JLT(1, 1, "no_paddle")
	cpu:MOV(6, 2)
	cpu:SUB(6, 5)
	cpu:JLT(6, 0, "no_paddle")
	cpu:MOV(6, 5)
	cpu:ADD(6, 10)
	cpu:SUB(6, 2)
	cpu:JLT(6, 0, "no_paddle")
	cpu:NEG(3)
	cpu:LABEL("no_paddle")

	cpu:BTN(6, 1)
	cpu:JEQ(6, 0, "skip_up")
	cpu:JLT(5, 1, "skip_up")
	cpu:SUB(5, 7)
	cpu:LABEL("skip_up")

	cpu:BTN(6, 2)
	cpu:JEQ(6, 0, "skip_down")
	cpu:JGT(5, 8, "skip_down")
	cpu:ADD(5, 7)
	cpu:LABEL("skip_down")

	cpu:JUMP("main")

	cpu:ResolveLabels()
end

cpu.Running = false

powerDetector.MouseClick:Connect(function()
	if cpu.Running then
		cpu.gpu:Clear()
		cpu.gpu:Render()
		cpu:ResetProgram()
		cpu.Running = false
		powerPart.Attachment.BillboardGui.TextLabel.Text = "Turn on"
	else
		cpu.Running = true
		assembleGame()
		powerPart.Attachment.BillboardGui.TextLabel.Text = "Turn off"
	end
end)

restartDetector.MouseClick:Connect(assembleGame)

-- exec loop
local RunService = game:GetService("RunService")
local TARGET_FPS, CPU_HZ = 260, 500
local FRAME_TIME = 1 / TARGET_FPS
local accumulator = 0

RunService.RenderStepped:Connect(function(dt)
	accumulator += math.min(dt, 0.25)
	while accumulator >= FRAME_TIME do
		accumulator -= FRAME_TIME
		if cpu.Running then
			for i = 1, (CPU_HZ / TARGET_FPS) do
				cpu:Step()
			end
		end
	end
	if cpu.Running then cpu.gpu:Render() end
end)
