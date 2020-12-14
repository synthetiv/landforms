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
	surface:add_mesh(32, 0.5, 0.125)
	surface:add_mesh(16, 0.5, 0.25)
	surface:add_mesh(8, 0.5, 0.5)
	surface:add_mesh(4, 0.5, 1)
	return surface
end

--- add a mesh to octaves
function Surface:add_mesh(width, offset, level)
	self.n_octaves = self.n_octaves + 1
	self.octaves[self.n_octaves] = {
		mesh = Mesh.new(width),
		density = width / self.width,
		offset = Vec2.new(offset, offset),
		level = level
	}
end

--- transform a point in surface space to a point in mesh space
function Surface:transform_surface_point_to_mesh(point, o)
	return point * self.octaves[o].density - self.octaves[o].offset
end

--- transform a point in mesh space to a point in screen space
function Surface:transform_mesh_point_to_surface(point, o)
	return (point + self.octaves[o].offset) / self.octaves[o].density
end

--- read value [-1, 1] at a point
function Surface:sample(point, interpolation_function)
	local value = 0
	for o, octave in ipairs(self.octaves) do
		if point == nil then
			error()
			return
		end
		value = value + octave.mesh:sample(self:transform_surface_point_to_mesh(point, o), interpolation_function) * octave.level
	end
	return value
end

--- change something
function Surface:edit(point, o, delta)
	local mesh = self.octaves[o].mesh
	if self.octaves[o].level ~= 0 then
		delta = util.clamp(delta / self.octaves[o].level, -1, 1)
		mesh:edit(self:transform_surface_point_to_mesh(point, o), delta)
		map.needs_update = true
	end
end

return Surface