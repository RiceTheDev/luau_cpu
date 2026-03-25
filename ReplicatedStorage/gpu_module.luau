local AssetService = game:GetService("AssetService")
local GPU = {}

function GPU.Setup()
	local self = setmetatable({}, { __index = GPU })
	self.RAM_BASE = 0x000000
	-- a mouth watering 128 bytes of vram!!1!1!!11 ദ്ദി(˵•̀ᴗ-˵)
	self.Memory = table.create(128,0)
	self.width = 16
	self.height = 12
	self.buffer = buffer.create(self.width * self.height * 4)
	local screenGui = game.Workspace.Monitor.LoadingScreen.SurfaceGui
	local screen = screenGui.Frame
	screen.Parent = screenGui
	screen.Visible = true
	local AssetService = game:GetService("AssetService")
	self.image = AssetService:CreateEditableImage({["Size"] = Vector2.new(self.width, self.height)})
	local screenGui = game.Workspace.Monitor.LoadingScreen.SurfaceGui
	local screen = screenGui.Frame
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.fromScale(1, 1)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Parent = screen
	imageLabel.ImageContent = Content.fromObject(self.image)
	imageLabel.ResampleMode = 1 -- pixelated
	return self
end
function GPU:getAddressAndBit(x, y)
	local FB_START = 0x00FF00
	local byteOffset = y * 2 + math.floor(x / 8)
	local address = FB_START + byteOffset
	local bit = 7 - (x % 8)
	return address, bit
end
function GPU:setPixel(x, y)
	if x < 0 or x >= 16 or y < 0 or y >= 12 then return end
	local addr, bit = self:getAddressAndBit(x, y)
	local index = addr - self.RAM_BASE
	local value = self.Memory[index] or 0
	self.Memory[index] = bit32.bor(value, bit32.lshift(1, bit))
end
function GPU:getPixel(x, y)
	if x < 0 or x >= 16 or y < 0 or y >= 12 then return 0 end
	local addr, bit = self:getAddressAndBit(x, y)
	local index = addr - self.RAM_BASE
	local value = self.Memory[index] or 0
	return bit32.band(bit32.rshift(value, bit), 1)
end
function GPU:clearPixel(x, y)
	if x < 0 or x >= 16 or y < 0 or y >= 12 then return end
	local addr, bit = self:getAddressAndBit(x, y)
	local index = addr - self.RAM_BASE
	local value = self.Memory[index] or 0
	self.Memory[index] = bit32.band(value, bit32.bnot(bit32.lshift(1, bit)))
end
function GPU:Render()
	local i = 0
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local pixel = self:getPixel(x, y)
			local color = (pixel == 1) and 255 or 0
			buffer.writeu8(self.buffer, i, color)
			buffer.writeu8(self.buffer, i + 1, color)
			buffer.writeu8(self.buffer, i + 2, color)
			buffer.writeu8(self.buffer, i + 3, 255)
			i += 4
		end
	end
	self.image:WritePixelsBuffer(
		Vector2.new(0, 0),
		Vector2.new(self.width, self.height),
		self.buffer
	)
end
function GPU:Clear()
	for y = 0, 11 do
		for x = 0, 15 do
			self:clearPixel(x, y)
		end
	end
end
return GPU
