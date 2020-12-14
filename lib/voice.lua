local Voice = {}
Voice.__index = Voice

local next_id = 1

function Voice.new()
	local voice = {
		id = next_id,
		active = true,
		position = Vec3.new(0, 0, 0),
		last_onset = 0,
		scale = Scale.new{ 1 }
	}
	next_id = next_id + 1
	setmetatable(voice, Voice)
	voice:read_scala_file('/home/we/dust/data/fretwork/scales/harmopent.scl')
	return voice
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
	self.position.x = position.x
	self.position.y = position.y
	self.position.z = position.z
end

function Voice:start(position)
	if self.active then
		self:move(position)
		self.last_onset = util.time()
		engine.start(self.id, self:get_frequency())
	end
end

function Voice:solo(position)
	if self.active then
		self:move(position)
		self.last_onset = util.time()
		engine.solo(self.id, self:get_frequency())
	end
end

function Voice:stop()
	engine.stop(self.id)
end

function Voice:mute()
	self.active = false
	self:stop()
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