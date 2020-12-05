--- a moving read point for a surface

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

--- move (change angle from center point)
function Probe:rotate(beats)
	self.angle = self.angle + beats * self.bpr * tau
	self.angle = self.angle % tau
	self.x = math.cos(self.angle) * self.radius + screen_width / 2
	self.y = math.sin(self.angle) * self.radius + screen_height / 2
	self.value = surface:sample(self.x, self.y, 'smoother')
end

--- draw on screen
function Probe:draw()
	screen.circle(self.x, self.y, 3 + self.value)
	screen.level(0)
	screen.fill()
	screen.circle(self.x, self.y, 1.5 + self.value)
	screen.level(10)
	screen.fill()
end

return Probe