--- a moving read point for a surface

local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		position = Vec3.new(screen_width / 2, screen_height / 2, 10),
		ground_level = 0,
		altitude = 10,
		bpr = 1/4,
		angle = 0,
		radius = 23,
		value = 0
	}
	return setmetatable(probe, Probe)
end

--- move (change angle from center point)
function Probe:rotate(beats)
	self.angle = self.angle + beats * self.bpr * tau
	self.angle = self.angle % tau
	self.position.x = math.cos(self.angle) * self.radius + screen_width / 2
	self.position.y = math.sin(self.angle) * self.radius + screen_height / 2
	self.ground_level = surface:sample(self.position)
	self.position.z = self.ground_level + self.altitude
end

--- draw on screen
function Probe:draw()
	local x, y = self.position.x, self.position.y
	screen.circle(x, y, 3 + self.position.z / 32)
	screen.level(0)
	screen.fill()
	screen.circle(x, y, 1.5 + self.position.z / 32)
	screen.level(10)
	screen.fill()
end

return Probe