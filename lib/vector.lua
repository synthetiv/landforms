--- a 2D vector with overloaded math operations

local Vector = {}

function Vector.new(x, y)
	return setmetatable({ x = x, y = y }, Vector)
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

function Vector:__index(index)
	if index == 'magnitude' then
		return math.sqrt(self.x * self.x + self.y * self.y)
	end
	return Vector[index]
end

function Vector:get_dot_product(other)
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