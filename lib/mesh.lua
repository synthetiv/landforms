local Mesh = {}
Mesh.__index = Mesh

function Mesh.new(width, height)
	local mesh = {
		width = width,
		height = height,
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
		for y = 1, self.height do
			local angle = math.random() * 2 * math.pi
			self.nodes[x][y] = {
				x = math.cos(angle),
				y = math.sin(angle)
			}
		end
	end
end

--- wrap to [1, w]
function Mesh:wrap_x(x)
	return (x - 1) % self.width + 1
end

--- wrap to [1, h]
function Mesh:wrap_y(y)
	return (y - 1) % self.height + 1
end

--- wrap to [-max/2, max/2]
function Mesh.wrap_bidirectional(n, max)
	while n > max / 2 do
		n = n - max
	end
	while n < -max / 2 do
		n = n + max
	end
	return n
end

--- wrap to [-w/2, w/2]
function Mesh:wrap_dx(dx)
	return Mesh.wrap_bidirectional(dx, self.width)
end

--- wrap to [-h/2, h/2]
function Mesh:wrap_dy(dy)
	return Mesh.wrap_bidirectional(dy, self.height)
end

--- compute the dot product between `node`'s random vector and the distance between `node` and (x, y)
function Mesh:get_point_dot_product(sample_x, sample_y, node_x, node_y)
	local node = self.nodes[node_x][node_y]
	local dx = self:wrap_dx(sample_x - node_x)
	local dy = self:wrap_dy(sample_y - node_y)
	-- print(string.format('%f * %f - %f * %f', dx, node.y, node.y, dy))
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

--- interpolate between two values, v2
-- aka 'smootherstep'
function Mesh.interpolate_smoother(a, b, x)
	-- no need to clamp here because sign is retained
	x = (x * x * x * (x * (x * 6 - 15) + 10))
	return Mesh.interpolate_linear(a, b, x)
end

--- get value at node (x, y)
function Mesh:sample(x, y)
	-- get corner coordinates
	local xl = self:wrap_x(math.floor(x))
	local xh = self:wrap_x(xl + 1)
	local yl = self:wrap_y(math.floor(y))
	local yh = self:wrap_y(yl + 1)
	-- print(xl, xh, yl, yh)
	-- get dot products
	local dot_a = self:get_point_dot_product(x, y, xl, yl)
	local dot_b = self:get_point_dot_product(x, y, xh, yl)
	local dot_c = self:get_point_dot_product(x, y, xh, yh)
	local dot_d = self:get_point_dot_product(x, y, xl, yh)
	-- interpolate vertically
	local dot_l = Mesh.interpolate_linear(dot_a, dot_d, self:wrap_dy(y - yl))
	local dot_r = Mesh.interpolate_linear(dot_b, dot_c, self:wrap_dy(y - yl))
	-- interpolate horizontally
	return Mesh.interpolate_linear(dot_l, dot_r, self:wrap_dx(x - xl))
end

return Mesh