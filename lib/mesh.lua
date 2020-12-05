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
			local angle = math.random() * 2 * math.pi
			self.nodes[x][y] = {
				x = math.cos(angle),
				y = math.sin(angle)
			}
		end
	end
end

--- wrap to [1, w]
function Mesh:wrap(n)
	return (n - 1) % self.width + 1
end

--- wrap to [-w/2, s/2]
function Mesh:wrap_bipolar(n)
	while n > self.width / 2 do
		n = n - self.width
	end
	while n < -self.width / 2 do
		n = n + self.width
	end
	return n
end

--- compute the dot product between `node`'s random vector and the distance between `node` and (x, y)
function Mesh:get_point_dot_product(sample_x, sample_y, node_x, node_y)
	local node = self.nodes[node_x][node_y]
	local dx = self:wrap_bipolar(sample_x - node_x)
	local dy = self:wrap_bipolar(sample_y - node_y)
	return dx * node.y - node.x * dy
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

--- get value at node (x, y)
function Mesh:sample(x, y, interpolation)
	-- choose interpolation style
	interpolation = interpolation or 'linear'
	interpolate = Mesh['interpolate_' .. interpolation]
	-- get corner coordinates
	local xl = self:wrap(math.floor(x))
	local xh = self:wrap(xl + 1)
	local yl = self:wrap(math.floor(y))
	local yh = self:wrap(yl + 1)
	-- get dot products
	local dot_a = self:get_point_dot_product(x, y, xl, yl)
	local dot_b = self:get_point_dot_product(x, y, xh, yl)
	local dot_c = self:get_point_dot_product(x, y, xh, yh)
	local dot_d = self:get_point_dot_product(x, y, xl, yh)
	-- interpolate vertically
	local dot_l = interpolate(dot_a, dot_d, self:wrap_bipolar(y - yl))
	local dot_r = interpolate(dot_b, dot_c, self:wrap_bipolar(y - yl))
	-- interpolate horizontally
	return interpolate(dot_l, dot_r, self:wrap_bipolar(x - xl))
end

return Mesh