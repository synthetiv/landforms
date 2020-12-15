local Pattern = {}
Pattern.__index = Pattern

function Pattern.new(steps, action)
	local pattern = {
		steps = steps,
		action = action,
		ticks_per_step = 8,
		tick = 0,
		step = 0
	}
	return setmetatable(pattern, Pattern)
end

function Pattern:advance(n_ticks)
	for i = 1, n_ticks do
		self.tick = self.tick + 1
		if self.tick % self.ticks_per_step == 1 then
			self.tick = 1
			self.step = self.step % #self.steps + 1
			if self.steps[self.step] > 0 then
				self.action()
			end
		end
	end
end

return Pattern