--- a mesh of perlin noise

local Mesh = {}
Mesh.__index = Mesh

function Mesh.new(width)
	local mesh = {
		width = width,
		nodes = {}
	}
	for x = 1, width do
		mesh.nodes[x] = {}
	end
	setmetatable(mesh, Mesh)
	mesh:randomize()
	return mesh
end

--- assign each node a unit vector with a random angle
function Mesh:randomize()
	for x = 1, self.width do
		for y = 1, self.width do
			local angle = math.random() * tau
			local node = Vec2.new_polar(1, angle)
			node:rectangularize()
			self.nodes[x][y] = node
		end
	end
end

--- wrap to [1, w]
function Mesh:wrap(n)
	return (n - 1) % self.width + 1
end

--- compute the dot product between `node`'s random vector and the distance between `node` and (x, y)
function Mesh:get_point_dot_product(point, node_x, node_y)
	if self.nodes[node_x] == nil or self.nodes[node_x][node_y] == nil then
		debug.debug()
		print('nil node', node_x, node_y)
	end
	local node = self.nodes[node_x][node_y]
	local distance = point - Vec2.new(node_x, node_y)
	distance:wrap_to_square_bipolar(self.width)
	return distance:get_dot_product(node)
end

--- interpolate between two values
function Mesh.interpolate_linear(a, b, x)
	x = util.clamp(x, 0, 1)
	return a + (b - a) * x
end

--- interpolate between two values, v2
-- aka 'smoothstep'
function Mesh.interpolate_smooth(a, b, x)
	x = util.clamp(x, 0, 1)
	x = x * x * (3 - x * 2)
	return Mesh.interpolate_linear(a, b, x)
end

--- interpolate between two values, v3
-- aka 'smootherstep'
function Mesh.interpolate_smoother(a, b, x)
	-- no need to clamp here because sign is retained
	x = (x * x * x * (x * (x * 6 - 15) + 10))
	return Mesh.interpolate_linear(a, b, x)
end

--- get neighbor coordinates on a unit grid
function Mesh:get_neighbors(point)
	-- get corner coordinates
	local xl = self:wrap(math.floor(point.x))
	local xh = self:wrap(xl + 1)
	local yl = self:wrap(math.floor(point.y))
	local yh = self:wrap(yl + 1)
	-- get distance from top left corner (functionally the same as `point - Vec2.new(xl, yl)`)
	local distance = point % 1
	return xl, xh, yl, yh, distance
end

--- interpolate in 2D between four values, assigned adjacent points on a unit grid:
--  A (0, 0) | B (1, 0)
-- ----------+----------
--  D (0, 1) | C (1, 1)
function Mesh.interpolate2d(a, b, c, d, distance, interpolation_function)
	-- choose interpolation style
	interpolation_function = interpolation_function or Mesh.interpolate_smoother
	-- interpolate vertically
	local l = interpolation_function(a, d, distance.y)
	local r = interpolation_function(b, c, distance.y)
	-- interpolate horizontally
	return interpolation_function(l, r, distance.x)
end

--- get value at point (x, y)
function Mesh:sample(point, interpolation_function)
	local xl, xh, yl, yh, distance = self:get_neighbors(point)
	-- get dot products
	local dot_a = self:get_point_dot_product(point, xl, yl)
	local dot_b = self:get_point_dot_product(point, xh, yl)
	local dot_c = self:get_point_dot_product(point, xh, yh)
	local dot_d = self:get_point_dot_product(point, xl, yh)
	-- interpolate!
	return Mesh.interpolate2d(dot_a, dot_b, dot_c, dot_d, distance, interpolation_function)
end

--- change nodes to increase/decrease value at point (x, y)
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
			local distance_vector = (point - Vec2.new(x, y))
			distance_vector:wrap_to_square_bipolar(self.width)
			local node = self.nodes[x][y]
			local proximity = math.max(0, 1 - distance_vector.magnitude)
			node = node:rotate_to(distance_vector.angle, delta * proximity)
			node:rectangularize() -- otherwise map:update() get slower as more polar vectors are added
			self.nodes[x][y] = node
		end
	end
end

return Mesh