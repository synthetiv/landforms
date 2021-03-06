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
	Vec2.new(0, 0),
	Vec2.new(1, 2),
	Vec2.new(2, 1),
	Vec2.new(1, 0),
	Vec2.new(0, 2),
	Vec2.new(2, 0),
	Vec2.new(0, 1),
	Vec2.new(2, 2),
	Vec2.new(1, 1)
}

function Map.new(sample_size)
	local map = {
		sample_size = sample_size,
		density = 1 / sample_size,
		offset = Vec2.new(math.floor((screen_width % sample_size) / 2), math.floor((screen_height % sample_size) / 2)),
		samples = {},
		needs_update = true,
		doing_update = false,
		coroutine = nil,
		coroutine_status = 'dead'
	}
	map.dissolution_cols = math.ceil(screen_width / sample_size / Map.dissolution_matrix.width)
	map.dissolution_rows = math.ceil(screen_height / sample_size / Map.dissolution_matrix.height)
	map.width = map.dissolution_cols * Map.dissolution_matrix.width
	map.height = map.dissolution_rows * Map.dissolution_matrix.height
	for x = 0, map.width - 1 do
		map.samples[x] = {}
	end
	map.coroutine_function = function() map:update() end
	setmetatable(map, Map)
	map:clear()
	return map
end

--- reset all samples
function Map:clear()
	for x = 0, self.width - 1 do
		for y = 0, self.height - 1 do
			self.samples[x][y] = 0
		end
	end
end

--- transform a point in screen space to a point in map space
function Map:transform_screen_point_to_map(point, result)
	return result:set(point):sub(self.offset):mul(self.density)
end

--- transform a point in map space to a point in screen space
function Map:transform_map_point_to_screen(point, result)
	return result:set(point):div(self.density):add(self.offset)
end

--- transform a point in map space to a point in surface space
function Map:transform_map_point_to_surface(point, result)
	return result:set(point):mul(self.density / surface.width)
end

--- transform a point in surface space to a point in map space
function Map:transform_surface_point_to_map(point, result)
	return result:set(point):mul(surface.width / self.density)
end

--- transform a point in screen space to a point in surface space
function Map:transform_screen_point_to_surface(point, result)
	return result:set(point):mul(surface.width / screen_width)
end

--- transform a point in surface space to a point in screen space
function Map:transform_surface_point_to_screen(point, result)
	return result:set(point):mul(screen_width / surface.width)
end

--- transform a point in screen space to a point in mesh space
function Map:transform_screen_point_to_mesh(point, o, result)
	result:set(point):mul(surface.width / screen_width)
	return surface:transform_surface_point_to_mesh(result, o, result)
end

--- transform a point in screen space to a point in mesh space
function Map:transform_mesh_point_to_screen(point, o, result)
	surface:transform_mesh_point_to_surface(point, o, result)
	return result:mul(screen_width / surface.width)
end

--- update the whole map (must be used in a coroutine)
-- TODO: "shade" instead of just showing "elevation"?
local sample_point = Vec2.new()
function Map:update()
	self.needs_update = false
	local matrix = Map.dissolution_matrix
	for matrix_point = 1, matrix.size do
		local point = matrix[matrix_point]
		for col = 0, self.dissolution_cols - 1 do
			for row = 0, self.dissolution_rows - 1 do
				local x = point.x + col * matrix.width
				local y = point.y + row * matrix.height
				sample_point:set(x, y)
				self:transform_map_point_to_surface(sample_point, sample_point)
				self.samples[x][y] = surface:sample(sample_point)
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
			self.coroutine = coroutine.create(self.coroutine_function)
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
		for y = 0, self.height - 1 do
			local value = (self.samples[x][y] + 1) / 2
			value = value * value * value
			if value < 0 then
				value = 0
			elseif value > 1 then
				value = 15
			else
				value = math.floor(value * 15 + 0.5)
			end
			screen.rect(self.offset.x + x * self.sample_size, self.offset.y + y * self.sample_size, 1, 1)
			screen.level(value)
			screen.fill()
		end
	end
end

return Map