--- a terrain surface made up of multiple octaves of perlin noise

local Mesh = include 'lib/mesh'

local Surface = {}
Surface.__index = Surface

-- Surface.mesh_offset = Vector.new(0.5, 0.5) -- translate all meshes by this much so nodes aren't in screen corners

function Surface.new(width)
	local surface = {
		width = width,
		n_octaves = 0,
		octaves = {}
	}
	setmetatable(surface, Surface)
	-- TODO: these offsets allow cursor grid lines to line up,
	-- but they also line up the nodes and that may not look great
	--[[
	surface:add_mesh(3, 0, 0.125)
	surface:add_mesh(6, 0.5, 0.25)
	surface:add_mesh(12, 0.75, 0.5)
	surface:add_mesh(24, 0.875, 1)
	--]]
	surface:add_mesh(3, 0.5, 0.125)
	surface:add_mesh(6, 0.5, 0.25)
	surface:add_mesh(12, 0.5, 0.5)
	surface:add_mesh(24, 0.5, 1)
	return surface
end

--- add a mesh to octaves
function Surface:add_mesh(sample_size, offset, level)
	self.n_octaves = self.n_octaves + 1
	local mesh_width = math.ceil(screen_width / sample_size)
	self.octaves[self.n_octaves] = {
		mesh = Mesh.new(mesh_width),
		density = 1 / sample_size,
		offset = Vector.new(offset, offset),
		level = level
	}
end

--- transform a point in surface space to a point in mesh space
function Surface:transform_screen_point(point, o)
	return point * self.octaves[o].density - self.octaves[o].offset
end

--- transform a point in mesh space to a point in screen space
function Surface:transform_mesh_point(point, o)
	return (point + self.octaves[o].offset) / self.octaves[o].density
end

--- read value at a point
function Surface:sample(point, interpolation)
	local value = 0
	for o, octave in ipairs(self.octaves) do
		value = value + octave.mesh:sample(self:transform_screen_point(point, o), interpolation) * octave.level
	end
	return value
end

--- change something
function Surface:edit(point, o, delta)
	local mesh = self.octaves[o].mesh
	mesh:edit(self:transform_screen_point(point, o), delta)
	map.needs_update = true
end

return Surface