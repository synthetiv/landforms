--- a moving read point for a surface

local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		position = Vec3.new(screen_width / 2, screen_height / 2, 10),
		ground_level = 0,
		altitude = 0,
		bpr = 1/8,
		angle = 0,
		radius = 23,
		value = 0,
		voice = Voice.new()
	}
	return setmetatable(probe, Probe)
end

--- move (change angle from center point)
function Probe:set_rotation(beats)
	self.angle = (beats * self.bpr % 1) * tau
	self.position.x = math.cos(self.angle) * self.radius + screen_width / 2
	self.position.y = math.sin(self.angle) * self.radius + screen_height / 2
	self.ground_level = surface:sample(self.position)
	self.position.z = self.ground_level + self.altitude
end

--- make a sound
function Probe:call()
	self.voice:start(self.position)
end

--- draw on screen
function Probe:draw()
	local x, y = self.position.x, self.position.y
	local now = util.time()
	local wave_radius = (now - self.voice.last_onset) * 40
	local wave_level = util.clamp(math.floor(20 / wave_radius + 0.5), 0, 15)
	if wave_level > 0 then
		screen.circle(self.voice.position.x, self.voice.position.y, wave_radius)
		screen.line_width(2)
		screen.level(wave_level)
		screen.stroke()
	end
	screen.circle(x, y, 1.5 + self.position.z / 32)
	screen.level(10)
	screen.fill()
end

return Probe