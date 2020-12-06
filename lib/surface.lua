--- a terrain surface made up of multiple octaves of perlin noise

local Mesh = include 'lib/mesh'

local Surface = {}
Surface.__index = Surface

function Surface.new(width)
	local surface = {
		width = width,
		n_octaves = 0,
		octaves = {}
	}
	setmetatable(surface, Surface)
	surface:add_mesh(32, 0.125)
	surface:add_mesh(16, 0.25)
	surface:add_mesh(8, 0.5)
	surface:add_mesh(4, 1)
	return surface
end

--- add a mesh to octaves
function Surface:add_mesh(width, level)
	self.n_octaves = self.n_octaves + 1
	self.octaves[self.n_octaves] = {
		mesh = Mesh.new(width),
		level = level
	}
end

--- read value at a point
function Surface:sample(point, interpolation)
	local value = 0
	for o, octave in ipairs(self.octaves) do
		local density = octave.mesh.width / self.width
		value = value + octave.mesh:sample(point * density, interpolation) * octave.level
	end
	return value
end

return Surface