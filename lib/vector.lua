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

function Vector:__tostring()
	return string.format('(%f, %f)', self.x, self.y)
end

function Vector:__index(index)
	if index == 'magnitude' then
		return math.sqrt(self.x * self.x + self.y * self.y)
	end
	return Vector[index]
end

return Vector