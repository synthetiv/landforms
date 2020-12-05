local Mosaic = {}
Mosaic.__index = Mosaic

function Mosaic.new(sample_size, width, height)
	local mosaic = {
		sample_size = sample_size,
		width = math.ceil(width / sample_size),
		height = math.ceil(height / sample_size),
		samples = {}
	}
	for x = 1, width do
		mosaic.samples[x] = {}
	end
	setmetatable(mosaic, Mosaic)
	mosaic:clear()
	return mosaic
end

--- reset all samples
function Mosaic:clear()
	for x = 1, self.width do
		for y = 1, self.height do
			self.samples[x][y] = 0
		end
	end
end

--- get a sample
function Mosaic:get(x, y)
	return self.samples[x][y]
end

--- set a sample
function Mosaic:set(x, y, value)
	self.samples[x][y] = value
end

--- add to a sample
function Mosaic:add(x, y, value)
	self.samples[x][y] = self.samples[x][y] + value
end

return Mosaic