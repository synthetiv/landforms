local Voice = {}
Voice.__index = Voice

local next_id = 1

function Voice.new()
	local voice = {
		id = next_id,
		active = true,
		position = Vec3.new(),
		last_position = Vec3.new(),
		last_onset = 0,
		scale = Scale.new{ 1 }
	}
	next_id = next_id + 1
	setmetatable(voice, Voice)
	voice:read_scala_file('/home/we/dust/data/fretwork/scales/harmopent.scl')
	return voice
end

for name, command in pairs(engine.commands) do
	Voice[name] = function(self, ...)
		engine[name](self.id, ...)
	end
end

function Voice:ztof(z)
	z = self.scale:snap(z * 2)
	local f = 220 * math.pow(2, z)
	return f
end

function Voice:get_frequency()
	return self:ztof(self.position.z)
end

function Voice:move(position)
	self.last_position = self.position
	self.position = position
	self:set_values()
end

function Voice:play()
	if self.active then
		self.last_onset = util.time()
		self:blip(1, self.frequency, self.bend, self.pan, self.amplitude, self.rolloff)
	end
end

function Voice:update()
	self:blip(0, self.frequency, self.bend, self.pan, self.amplitude, self.rolloff)
end

function Voice:set_values()
	self.frequency = self:ztof(self.position.z)
	self.bend = 1
	local distance_vector = self.position - probe.position
	local distance = distance_vector.magnitude
	if distance ~= 0 then
		local direction = distance_vector / distance
		local pan = probe.heading:get_cross_product(direction)
		self.pan = pan
		self.amplitude = math.min(0.5, 0.5 / ( 8 * (probe.position - self.position).magnitude))
		-- TODO: rolloff should respond to distance too,
		-- and should be closer to zero when pan == 1 or -1
		local rolloff = probe.heading:get_dot_product(-direction)
		self.rolloff = rolloff * 0.5 + 0.5 -- [0, 1]
	else
		self.pan = 0
		self.amplitude = 0.5
		self.rolloff = 0
	end
end

function Voice:mute()
	self.active = false
end

function Voice:unmute()
	self.active = true
end

function Voice:read_scala_file(filename)
	local ratios = Scala.read_file(filename)
	local values = {}
	for r, ratio in ipairs(ratios) do
		values[r] = ratio.value
	end
	self.scale:set_class_values(values, values[4])
	self.scale:set_active_values{
		0.2479,
		0.263,
		0.415,
		0.8073,
		1.0
	}
	self.scale:apply_edits()
end

return Voice