--- a mesh of perlin noise

local Mesh = {}
Mesh.__index = Mesh

function Mesh.new(width)
	local mesh = {
		width = width,
		nodes = {}
	}
	for x = 0, width - 1 do
		mesh.nodes[x] = {}
	end
	setmetatable(mesh, Mesh)
	mesh:randomize()
	return mesh
end

--- assign each node a unit vector with a random angle
function Mesh:randomize()
	for x = 0, self.width - 1 do
		for y = 0, self.width - 1 do
			local angle = math.random() * tau
			local node = Vec2.new_polar(1, angle)
			self.nodes[x][y] = node
		end
	end
end

--- wrap to [1, w]
function Mesh:wrap(n)
	return n % self.width
end

--- compute the dot product between `node`'s random vector and the distance between `node` and (x, y)
local dot_distance = Vec2.new(0, 0)
function Mesh:get_point_dot_product(point, node_x, node_y)
	local node = self.nodes[node_x][node_y]
	dot_distance:set(point.x - node_x, point.y - node_y)
	dot_distance:wrap_to_square_bipolar(self.width)
	return dot_distance:get_dot_product(node)
end

--- interpolate between two values
function Mesh.interpolate_linear(a, b, x)
	return a + (b - a) * x
end

--- interpolate between two values, v2
-- aka 'smoothstep'
function Mesh.interpolate_smooth(a, b, x)
	x = x * x * (3 - x * 2)
	return Mesh.interpolate_linear(a, b, x)
end

--- interpolate between two values, v3
-- aka 'smootherstep'
function Mesh.interpolate_smoother(a, b, x)
	x = (x * x * x * (x * (x * 6 - 15) + 10))
	return Mesh.interpolate_linear(a, b, x)
end

--- get neighbor coordinates on a unit grid
function Mesh:get_neighbors(point, distance)
	-- get corner coordinates
	local xl = self:wrap(math.floor(point.x))
	local xh = self:wrap(xl + 1)
	local yl = self:wrap(math.floor(point.y))
	local yh = self:wrap(yl + 1)
	-- get distance from top left corner (functionally the same as `point - Vec2.new(xl, yl)`)
	distance:set(point):mod(1)
	return xl, xh, yl, yh
end

--- interpolate in 2D between four values, assigned adjacent points on a unit grid:
--  A (0, 0) | B (1, 0)
-- ----------+----------
--  D (0, 1) | C (1, 1)
function Mesh.interpolate2d(a, b, c, d, distance, interpolation_function)
	-- choose interpolation style
	interpolation_function = interpolation_function or Mesh.interpolate_smooth
	-- interpolate vertically
	local l = interpolation_function(a, d, distance.y)
	local r = interpolation_function(b, c, distance.y)
	-- interpolate horizontally
	return interpolation_function(l, r, distance.x)
end

--- get value at point (x, y)
local distance = Vec2.new()
function Mesh:sample(point, interpolation_function)
	local xl, xh, yl, yh = self:get_neighbors(point, distance)
	-- get dot products
	local dot_a = self:get_point_dot_product(point, xl, yl)
	local dot_b = self:get_point_dot_product(point, xh, yl)
	local dot_c = self:get_point_dot_product(point, xh, yh)
	local dot_d = self:get_point_dot_product(point, xl, yh)
	-- interpolate!
	return Mesh.interpolate2d(dot_a, dot_b, dot_c, dot_d, distance, interpolation_function)
end

--- change nodes to increase/decrease value at point (x, y)
local node_point = Vec2.new()
local distance_vector = Vec2:new()
function Mesh:edit(point, delta)
	-- get corner coordinates
	local xl = math.floor(point.x)
	local yl = math.floor(point.y)
	-- change nearby nodes' angles to be perpendicular to the angle of `point - node`
	-- for a lower value at `point`, node gradient vector to node-point vector angle should be math.pi/2 (clockwise)
	-- for a higher value, angle should be -math.pi/2 (counterclockwise)
	for x_offset = 0, 1 do
		for y_offset = 0, 1 do
			local x = self:wrap(xl + x_offset)
			local y = self:wrap(yl + y_offset)
			node_point:set(x, y)
			distance_vector:set(point):sub(node_point)
			distance_vector:wrap_to_square_bipolar(self.width)
			local node = self.nodes[x][y]
			local magnitude, angle = distance_vector:get_polar()
			local proximity = math.max(0, 1 - magnitude)
			node:rotate_to(angle, delta * proximity)
			self.nodes[x][y] = node
		end
	end
end

return Mesh