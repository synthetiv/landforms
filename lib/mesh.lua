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
			self.nodes[x][y] = Vector.new(math.cos(angle), math.sin(angle))
		end
	end
end

--- wrap to [1, w]
function Mesh:wrap(n)
	return (n - 1) % self.width + 1
end

--- compute the dot product between `node`'s random vector and the distance between `node` and (x, y)
function Mesh:get_point_dot_product(point, node_x, node_y)
	local node = self.nodes[node_x][node_y]
	local distance = point - Vector.new(node_x, node_y)
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

--- get value at point (x, y)
function Mesh:sample(point, interpolation)
	-- choose interpolation style
	interpolation = interpolation or 'linear'
	interpolate = Mesh['interpolate_' .. interpolation]
	-- get corner coordinates
	local xl = self:wrap(math.floor(point.x))
	local xh = self:wrap(xl + 1)
	local yl = self:wrap(math.floor(point.y))
	local yh = self:wrap(yl + 1)
	-- get dot products
	local dot_a = self:get_point_dot_product(point, xl, yl)
	local dot_b = self:get_point_dot_product(point, xh, yl)
	local dot_c = self:get_point_dot_product(point, xh, yh)
	local dot_d = self:get_point_dot_product(point, xl, yh)
	-- get distance for interpolation
	local distance = point % 1
	-- interpolate vertically
	local dot_l = interpolate(dot_a, dot_d, distance.y)
	local dot_r = interpolate(dot_b, dot_c, distance.y)
	-- interpolate horizontally
	return interpolate(dot_l, dot_r, distance.x)
end

return Mesh