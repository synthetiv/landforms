local Mosaic = {}
Mosaic.__index = Mosaic

function Mosaic.new(sample_size, width, height)
	local mosaic = {
		sample_size = sample_size,
		width = math.ceil(width / sample_size),
		height = math.ceil(height / sample_size),
		samples = {},
		cols_per_update = 4,
		needs_update = true,
		doing_update = false,
		coroutine = nil,
		coroutine_status = 'dead'
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

--- update the whole mosaic (must be used in a coroutine)
function Mosaic:update()
	self.needs_update = false
	local cols_updated = 0
	local center = util.round(self.width / 2)
	-- TODO: what about "dissolving" instead of "wiping"?
	-- create a table of all x/y coords ordered randomly, update in that order
	for col = 1, self.width do
		local direction = (col % 2) == 0 and -1 or 1
		local x = math.floor(center + (col / 2) * direction)
		for y = 1, self.height do
			self:set(x, y, 0)
			for o = 1, n_octaves do
				local mesh = meshes[o]
				local level = levels[o]
				local value = mesh:sample((x - 0.5) * mesh.width / self.width, (y - 0.5) * mesh.height / self.height)
				self:add(x, y, value * level)
			end
		end
		cols_updated = cols_updated + 1
		if cols_updated % self.cols_per_update == 0 then
			coroutine.yield()
		end
		if not self.doing_update then
			error() -- exit this coroutine so another can begin
		end
	end
	self.doing_update = false
end

--- update a chunk
function Mosaic:do_update()
	if self.needs_update or self.doing_update then
		if not self.doing_update then
			self.coroutine = coroutine.create(function() self:update() end)
			self.doing_update = true
		end
		coroutine.resume(self.coroutine)
		local status = coroutine.status(self.coroutine)
		self.doing_update = status ~= 'dead'
	end
end

--- cancel the current coroutine, if any, and get ready to start a new one
function Mosaic:trigger_update()
	self.needs_update = true
	-- self.doing_update = false
end

--- draw points
function Mosaic:draw()
	-- (re)build if necessary
	self:do_update()
	-- draw
	for x = 1, self.width do
		for y = 1, self.height do
			local value = (self:get(x, y) + 1) / 2
			screen.pixel((x - 1) * self.sample_size, (y - 1) * self.sample_size)
			screen.level(util.round(util.clamp(value * value * value, 0, 1) * 15))
			screen.fill()
		end
	end
end

return Mosaic