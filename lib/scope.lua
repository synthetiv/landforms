--- a waveform display of values

local Scope = {}
Scope.__index = Scope

Scope.buffer_size = 64

function Scope.new(scale)
	local scope = {
		scale = scale or 1,
		head = 1,
		buffer = {}
	}
	for i = 1, Scope.buffer_size do
		scope.buffer[i] = 0
	end
	return setmetatable(scope, Scope)
end

--- store a value in the ring buffer
function Scope:sample(value)
	self.head = self.head % self.buffer_size + 1
	self.buffer[self.head] = value
end

--- read a value at an offset from `head`
function Scope:read(index)
	return self.buffer[(self.head + index - 1) % self.buffer_size + 1]
end

--- draw waveform on screen
function Scope:draw(width, level)
	for i = 1, self.buffer_size do
		local value = self:read(1 - i)
		local x = screen_width - i * screen_width * self.scale / self.buffer_size
		if x >= 0 then
			local y = screen_height / 2 - value * screen_height / 3
			if i == 1 then
				screen.move(x, y)
			else
				screen.line(x, y)
			end
		end
	end
	screen.line_join('bevel')
	screen.line_width(width)
	screen.level(level)
	screen.blend_mode('add')
	screen.stroke()
	screen.blend_mode('default')
end

return Scope