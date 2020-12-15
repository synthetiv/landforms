--- a moving read point for a surface

local Probe = {}
Probe.__index = Probe

function Probe.new()
	local probe = {
		position = Vec3.new(surface.width / 2, surface.width / 4, 0),
		screen_position = Vec2.new(64, 32),
		last_position = Vec3.new(surface.width / 2, surface.width / 4, 0),
		home = Vec3.new(surface.width / 2, surface.width / 4, 0),
		heading = Vec2.new(0, 1),
		ground_level = 0,
		altitude = 0,
		ticks = math.floor(clock.get_beats() * 32),
		bpr = 1/8,
		angle = 0,
		radius = 0.6,
		voice = Voice.new()
	}
	probe.pattern = Pattern.new({ 1, 1, 1, 0, 1, 0, 0, 1 }, function() probe:call() end)
	return setmetatable(probe, Probe)
end

--- move (change angle from center point)
function Probe:move()
	local new_ticks = math.floor(clock.get_beats() * 32)
	self.angle = (new_ticks / 32 * self.bpr % 1) * tau
	local cos = math.cos(self.angle)
	local sin = math.sin(self.angle)
	self.last_position:set(self.position)
	self.position.x = cos * self.radius + self.home.x
	self.position.y = sin * self.radius + self.home.y
	self.ground_level = surface:sample(self.position)
	self.position.z = self.ground_level + self.altitude
	self.heading:set(-sin, cos)
	self.pattern:advance(new_ticks - self.ticks)
	self.ticks = new_ticks
end

--- make a sound
function Probe:call()
	self.voice:move(self.position)
	self.voice:play()
end

--- draw on screen
local position = Vec2.new()
local voice_position = Vec2.new()
function Probe:draw()
	map:transform_surface_point_to_screen(self.position, position)
	map:transform_surface_point_to_screen(self.voice.position, voice_position)
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