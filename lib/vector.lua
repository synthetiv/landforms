--- a 2D vector with overloaded math operations

local Vector = {}

function Vector.new(x, y)
	return setmetatable({ x = x, y = y }, Vector)
end

function Vector.new_polar(r, theta)
	return setmetatable({ magnitude = r, angle = theta }, Vector)
end

function Vector:__add(other)
	return Vector.new(self.x + other.x, self.y + other.y)
end

function Vector:__sub(other)
	return Vector.new(self.x - other.x, self.y - other.y)
end

function Vector:__mul(other)
	if type(other) == 'table' then
		return Vector.new(self.x * other.x, self.y * other.y)
	end
	return Vector.new(self.x * other, self.y * other)
end

function Vector:__div(other)
	if type(other) == 'table' then
		return Vector.new(self.x / other.x, self.y / other.y)
	end
	return Vector.new(self.x / other, self.y / other)
end

function Vector:__unm()
	return Vector.new(-self.x, -self.y)
end

function Vector:__mod(modulus)
	return Vector.new(self.x % modulus, self.y % modulus)
end

function Vector:__tostring()
	return string.format('(%f, %f)', self.x, self.y)
end

function pol2rec(r, theta)
	return math.cos(theta) * r, math.sin(theta) * r
end

function rec2pol(x, y)
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
function Vector:__index(index)
	if index == 'magnitude' then
		local r, _ = rec2pol(self.x, self.y)
		return r
	elseif index == 'angle' then
		local _, theta = rec2pol(self.x, self.y)
		return theta
	elseif index == 'x' then
		local x, _ = pol2rec(self.magnitude, self.angle)
		return x
	elseif index == 'y' then
		local _, y = pol2rec(self.magnitude, self.angle)
		return y
	end
	return Vector[index]
end

--- set polar coordinates of a rectangular vector, or vice versa
function Vector:__newindex(index, value)
	if index == 'magnitude' then
		self.x, self.y = pol2rec(value, self.angle)
	elseif index == 'angle' then
		self.x, self.y = pol2rec(self.magnitude, value)
	elseif index == 'x' then
		self.magnitude, self.angle = rec2pol(value, self.y)
	elseif index == 'y' then
		self.magnitude, self.angle = rec2pol(self.x, value)
	end
end

--- rotate a vector by `theta` radians
function Vector:rotate(theta)
	return Vector.new_polar(self.magnitude, (self.angle + theta) % tau)
end

--- rotate to a particular angle
function Vector:rotate_to(theta, amount)
	theta = theta % tau
	local angle = self.angle % tau
	local diff = theta - angle
	if amount < 0 then
		amount = math.abs(amount)
		diff = diff + math.pi
	end
	diff = (diff + math.pi) % tau - math.pi
	return Vector.new_polar(self.magnitude, (angle + diff * amount) % tau)
end

--- switch a vector from polar to rectangular
function Vector:polarize()
	local r, theta = rec2pol(self.x, self.y)
	rawset(self, 'x', nil)
	rawset(self, 'y', nil)
	rawset(self, 'magnitude', r)
	rawset(self, 'angle', theta)
end

--- switch a vector from rectangular to polar
function Vector:rectangularize()
	local x, y = pol2rec(self.magnitude, self.angle)
	rawset(self, 'x', x)
	rawset(self, 'y', y)
	rawset(self, 'magnitude', nil)
	rawset(self, 'angle', nil)
end

function Vector:get_dot_product(other)
	return self.x * other.x + self.y * other.y
end

function Vector:get_cross_product(other)
	return self.x * other.y - other.x * self.y
end

function Vector:wrap_to_square(min, max)
	if max == nil then
		max = min
		min = 1
	end
	self.x = (self.x - min) % max + min
	self.y = (self.y - min) % max + min
end

function Vector:wrap_to_square_bipolar(width)
	self:wrap_to_square(-width / 2, width)
end

return Vector