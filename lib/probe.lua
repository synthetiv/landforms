local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		x = 0,
		y = 0,
		bpr = 1/4,
		angle = 0,
		radius = 23,
		value = 0
	}
	return setmetatable(probe, Probe)
end

function Probe:rotate(beats)
	self.angle = self.angle + beats * self.bpr * tau
	self.angle = self.angle % tau
	self.x = math.cos(self.angle) * self.radius + screen_width / 2
	self.y = math.sin(self.angle) * self.radius + screen_height / 2
end

function Probe:sample()
	self.value = 0
	for o = 1, n_octaves do
		local mesh = meshes[o]
		self.value = self.value + mesh:sample(self.x * mesh.width / screen_width, self.y * mesh.height / screen_height, 'smooth') * levels[o]
	end
	return self.value
end

function Probe:draw()
	screen.circle(self.x, self.y, 3 + self.value)
	screen.level(0)
	screen.fill()
	screen.circle(self.x, self.y, 1.5 + self.value)
	screen.level(10)
	screen.fill()
end

return Probe