--- a moving read point for a surface

local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		position = Vector.new(0, 0),
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
	self.value = surface:sample(self.position, 'smoother')
end

--- draw on screen
function Probe:draw()
	local x, y = self.position.x, self.position.y
	screen.circle(x, y, 3 + self.value)
	screen.level(0)
	screen.fill()
	screen.circle(x, y, 1.5 + self.value)
	screen.level(10)
	screen.fill()
end

return Probe