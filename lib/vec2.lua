--- a 2D vector with overloaded math operations

local Vec2 = {}
Vec2.__index = Vec2
Vec2.callers = {}
Vec2.count = 0

function Vec2.new(x, y)
	local caller = debug.getinfo(2)
	caller = caller.short_src .. ':' .. caller.currentline
	Vec2.callers[caller] = (Vec2.callers[caller] or 0) + 1
	Vec2.count = Vec2.count + 1
	local vec = {
		x = x or 0,
		y = y or 0
	}
	return setmetatable(vec, Vec2)
end

function Vec2.new_polar(r, theta)
	return Vec2.new(Vec2.pol2rec(r, theta))
end

function Vec2:__eq(other)
	return self.x == other.x and self.y == other.y
end

function Vec2:__tostring()
	return string.format('(%f, %f)', self.x, self.y)
end

function Vec2:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	return self
end

function Vec2:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	return self
end

function Vec2:mul(other)
	if type(other) == 'table' then
		self.x = self.x * other.x
		self.y = self.y * other.y
	else
		self.x = self.x * other
		self.y = self.y * other
	end
	return self
end

function Vec2:div(other)
	if type(other) == 'table' then
		self.x = self.x / other.x
		self.y = self.y / other.y
	else
		self.x = self.x / other
		self.y = self.y / other
	end
	return self
end

function Vec2:unm()
	self.x = -self.x
	self.y = -self.y
	return self
end

function Vec2:mod(modulus)
	self.x = self.x % modulus
	self.y = self.y % modulus
	return self
end

function Vec2.pol2rec(r, theta)
	return math.cos(theta) * r, math.sin(theta) * r
end

function Vec2.rec2pol(x, y)
	local r = math.sqrt(x * x + y * y)
	local theta = 0
	if x == 0 then
		theta = y > 0 and (math.pi / 2) or (3 * math.pi / 2)
	elseif y == 0 then
		theta = x > 0 and 0 or math.pi
	else
		theta = math.atan(y / x)
		if x >= 0 then
			theta = theta % tau
		else
			theta = (theta + math.pi) % tau
		end
	end
	return r, theta
end

function Vec2:__newindex(index, value)
	error('Vec2:__newindex is deprecated')
end

function Vec2:set(x, y)
	-- if argument is a vector, match that vector
	if y == nil then
		x, y = x.x, x.y
	end
	self.x, self.y = x, y
	return self
end

function Vec2:get()
	return self.x, self.y
end

function Vec2:set_polar(r, theta)
	self.x, self.y = Vec2.pol2rec(r, theta)
	return self
end

function Vec2:get_polar()
	return Vec2.rec2pol(self.x, self.y)
end

function Vec2:get_magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

--- rotate a vector by `theta` radians
function Vec2:rotate(theta)
	local magnitude, angle = self:get_polar()
	local x, y = Vec2.pol2rec(magnitude, (angle + theta) % tau)
	self:set(x, y)
	return self
end

--- rotate to a particular angle
function Vec2:rotate_to(theta, amount)
	local magnitude, angle = self:get_polar()
	angle = angle % tau
	theta = theta % tau
	local diff = theta - angle
	if amount < 0 then
		amount = math.abs(amount)
		diff = diff + math.pi
	end
	diff = (diff + math.pi) % tau - math.pi
	return self:set_polar(magnitude, (angle + diff * amount) % tau)
end

function Vec2:get_dot_product(other)
	return self.x * other.x + self.y * other.y
end

function Vec2:get_cross_product(other)
	return self.x * other.y - other.x * self.y
end

function Vec2:round(quant)
	self.x = util.round(self.x, quant)
	self.y = util.round(self.y, quant)
end

function Vec2:wrap_to_square(min, max)
	self.x = (self.x - min) % max + min
	self.y = (self.y - min) % max + min
end

function Vec2:wrap_to_square_bipolar(width)
	self:wrap_to_square(-width / 2, width)
end

return Vec2