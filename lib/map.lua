--- a visual representation of a surface

local Map = {}
Map.__index = Map

-- ordered set of coordinates to update with each iteration of the update coroutine:
-- first iteration will update (1, 1) and (1 + width*n, 1 + height*n),
-- second iteration will update (2, 3) and (2 + width*n, 3 + height*n), and so on
Map.dissolution_matrix = {
	size = 9,
	width = 3,
	height = 3,
	Vector.new(0, 0),
	Vector.new(1, 2),
	Vector.new(2, 1),
	Vector.new(1, 0),
	Vector.new(0, 2),
	Vector.new(2, 0),
	Vector.new(0, 1),
	Vector.new(2, 2),
	Vector.new(1, 1)
}

function Map.new(sample_size, width, height)
	local map = {
		sample_size = sample_size,
		width = math.ceil(width / sample_size),
		height = math.ceil(height / sample_size),
		density = surface.width * sample_size / width,
		samples = {},
		needs_update = true,
		doing_update = false,
		coroutine = nil,
		coroutine_status = 'dead'
	}
	for x = 1, width do
		map.samples[x] = {}
	end
	setmetatable(map, Map)
	map:clear()
	return map
end

--- reset all samples
function Map:clear()
	for x = 1, self.width do
		for y = 1, self.height do
			self.samples[x][y] = 0
		end
	end
end

--- get a sample
function Map:get(x, y)
	return self.samples[x + 1][y + 1]
end

--- set a sample
function Map:set(x, y, value)
	self.samples[x + 1][y + 1] = value
end

--- update the whole map (must be used in a coroutine)
-- TODO: "shade" instead of just showing "elevation"?
function Map:update()
	self.needs_update = false
	local matrix = Map.dissolution_matrix
	-- TODO: might as well precalculate these
	local cols = math.ceil(self.width / matrix.width)
	local rows = math.ceil(self.height / matrix.height)
	for matrix_point = 1, matrix.size do
		local point = matrix[matrix_point]
		for col = 1, cols do
			for row = 1, rows do
				local x = point.x + (col - 1) * matrix.width
				local y = point.y + (row - 1) * matrix.height
				self:set(x, y, surface:sample(Vector.new(x, y) * self.density))
			end
		end
		coroutine.yield()
	end
	self.doing_update = false
end

--- update a chunk
function Map:do_update()
	if self.doing_update or self.needs_update then
		if not self.doing_update then
			self.coroutine = coroutine.create(function() self:update() end)
			self.doing_update = true
		end
		local success, message = coroutine.resume(self.coroutine)
		if not success and message ~= nil then
			self.doing_update = false
			self.needs_update = false
			error(message)
		end
	end
end

--- draw points
function Map:draw()
	-- (re)build if necessary
	self:do_update()
	-- draw
	for x = 0, self.width - 1 do
		for y = 0, self.height -1 do
			local value = (self:get(x, y) + 1) / 2
			screen.pixel(x * self.sample_size, y * self.sample_size)
			screen.level(util.round(util.clamp(value * value * value, 0, 1) * 15))
			screen.fill()
		end
	end
	--[[
	-- draw gradient vectors at nodes
	local mesh = surface.octaves[3].mesh
	local density = mesh.width / surface.width
	for x = 1, mesh.width do
		for y = 1, mesh.width do
			local node = mesh.nodes[x][y]
			local v = Vector.new(node.x, node.y)
			v.magnitude = 7
			screen.move(x / density, y / density)
			screen.line_rel(v.x, v.y)
			screen.level(15)
			screen.line_width(0.5)
			screen.stroke()
		end
	end
	--]]
end

return Map