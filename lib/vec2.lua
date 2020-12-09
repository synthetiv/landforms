--- a 2D vector with overloaded math operations

local Vec2 = {}

function Vec2.new(x, y)
	return setmetatable({ x = x, y = y }, Vec2)
end

function Vec2.new_polar(r, theta)
	return setmetatable({ magnitude = r, angle = theta }, Vec2)
end

function Vec2:__add(other)
	return Vec2.new(self.x + other.x, self.y + other.y)
end

function Vec2:__sub(other)
	return Vec2.new(self.x - other.x, self.y - other.y)
end

function Vec2:__mul(other)
	if type(other) == 'table' then
		return Vec2.new(self.x * other.x, self.y * other.y)
	end
	return Vec2.new(self.x * other, self.y * other)
end

function Vec2:__div(other)
	if type(other) == 'table' then
		return Vec2.new(self.x / other.x, self.y / other.y)
	end
	return Vec2.new(self.x / other, self.y / other)
end

function Vec2:__unm()
	return Vec2.new(-self.x, -self.y)
end

function Vec2:__mod(modulus)
	return Vec2.new(self.x % modulus, self.y % modulus)
end

function Vec2:__tostring()
	return string.format('(%f, %f)', self.x, self.y)
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

--- access polar coordinates of a rectangular vector, or vice versa
function Vec2:__index(index)
	if index == 'magnitude' then
		local r, _ = Vec2.rec2pol(self.x, self.y)
		return r
	elseif index == 'angle' then
		local _, theta = Vec2.rec2pol(self.x, self.y)
		return theta
	elseif index == 'x' then
		local x, _ = Vec2.pol2rec(self.magnitude, self.angle)
		return x
	elseif index == 'y' then
		local _, y = Vec2.pol2rec(self.magnitude, self.angle)
		return y
	elseif index == 'z' then
		return 0
	end
	return Vec2[index]
end

--- set polar coordinates of a rectangular vector, or vice versa
function Vec2:__newindex(index, value)
	if index == 'magnitude' then
		self.x, self.y = Vec2.pol2rec(value, self.angle)
	elseif index == 'angle' then
		self.x, self.y = Vec2.pol2rec(self.magnitude, value)
	elseif index == 'x' then
		self.magnitude, self.angle = Vec2.rec2pol(value, self.y)
	elseif index == 'y' then
		self.magnitude, self.angle = Vec2.rec2pol(self.x, value)
	elseif index == 'z' then
		error('trying to set z of 2D vector')
	end
end

--- rotate a vector by `theta` radians
function Vec2:rotate(theta)
	return Vec2.new_polar(self.magnitude, (self.angle + theta) % tau)
end

--- rotate to a particular angle
function Vec2:rotate_to(theta, amount)
	theta = theta % tau
	local angle = self.angle % tau
	local diff = theta - angle
	if amount < 0 then
		amount = math.abs(amount)
		diff = diff + math.pi
	end
	diff = (diff + math.pi) % tau - math.pi
	return Vec2.new_polar(self.magnitude, (angle + diff * amount) % tau)
end

--- switch a vector from polar to rectangular
function Vec2:polarize()
	local r, theta = Vec2.rec2pol(self.x, self.y)
	rawset(self, 'x', nil)
	rawset(self, 'y', nil)
	rawset(self, 'magnitude', r)
	rawset(self, 'angle', theta)
end

--- switch a vector from rectangular to polar
function Vec2:rectangularize()
	local x, y = Vec2.pol2rec(self.magnitude, self.angle)
	rawset(self, 'x', x)
	rawset(self, 'y', y)
	rawset(self, 'magnitude', nil)
	rawset(self, 'angle', nil)
end

function Vec2:get_dot_product(other)
	return self.x * other.x + self.y * other.y
end

function Vec2:get_cross_product(other)
	return self.x * other.y - other.x * self.y
end

function Vec2:wrap_to_square(min, max)
	if max == nil then
		max = min
		min = 1
	end
	self.x = (self.x - min) % max + min
	self.y = (self.y - min) % max + min
end

function Vec2:wrap_to_square_bipolar(width)
	self:wrap_to_square(-width / 2, width)
end

return Vec2