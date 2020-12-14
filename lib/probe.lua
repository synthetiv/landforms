--- a moving read point for a surface

local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		position = Vec3.new(surface.width / 2, surface.width / 4, 0),
		last_position = Vec3.new(surface.width / 2, surface.width / 4, 0),
		home = Vec3.new(surface.width / 2, surface.width / 4, 0),
		ground_level = 0,
		altitude = 0,
		bpr = 1/8,
		angle = 0,
		radius = 0.6,
		voice = Voice.new()
	}
	return setmetatable(probe, Probe)
end

--- move (change angle from center point)
function Probe:set_rotation(beats)
	self.angle = (beats * self.bpr % 1) * tau
	local cos = math.cos(self.angle)
	local sin = math.sin(self.angle)
	self.last_position = self.position
	self.position = Vec3.new(
		cos * self.radius + self.home.x,
		sin * self.radius + self.home.y,
		0
	)
	self.ground_level = surface:sample(self.position)
	self.position.z = self.ground_level + self.altitude
	self.heading = Vec2.new(-sin, cos)
end

--- make a sound
function Probe:call()
	self.voice:move(self.position)
	self.voice:play()
end

--- draw on screen
function Probe:draw()
	local position = map:transform_surface_point_to_screen(self.position)
	local voice_position = map:transform_surface_point_to_screen(self.voice.position or Vec2.new(2, 1))
	local now = util.time()
	local wave_radius = (now - self.voice.last_onset) * 40
	local wave_level = util.clamp(math.floor(20 / wave_radius + 0.5), 0, 15)
	if wave_level > 0 then
		screen.circle(voice_position.x, voice_position.y, wave_radius)
		screen.line_width(2)
		screen.level(wave_level)
		screen.stroke()
	end
	local size = math.pow(1.5, self.position.z) * 2.5
	screen.circle(position.x, position.y, size)
	screen.level(10)
	screen.fill()
end

return Probe