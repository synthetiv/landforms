--- a 2D vector with overloaded math operations

local Vec3 = {}

function Vec3.new(x, y, z)
	-- print('vec3')
	local vec = {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
	return setmetatable(vec, Vec3)
end

function Vec3:__add(other)
	return Vec3.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vec3:__sub(other)
	return Vec3.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vec3:__mul(other)
	if type(other) == 'table' then
		return Vec3.new(self.x * other.x, self.y * other.y, self.z * other.z)
	end
	return Vec3.new(self.x * other, self.y * other, self.z * other)
end

function Vec3:__div(other)
	if type(self) ~= 'table' then -- this looks weird, but `self` is just the LH operand and sometimes it's a scalar
		return Vec3.new(self / other.x, self / other.y, self / other.z)
	end
	if type(other) == 'table' then
		return Vec3.new(self.x / other.x, self.y / other.y, self.z / other.z)
	end
	return Vec3.new(self.x / other, self.y / other, self.z / other)
end

function Vec3:__unm()
	return Vec3.new(-self.x, -self.y, -self.z)
end

function Vec3:__mod(modulus)
	return Vec3.new(self.x % modulus, self.y % modulus, self.z % modulus)
end

function Vec3:__tostring()
	return string.format('(%f, %f, %f)', self.x, self.y, self.z)
end

--- access polar coordinates of a rectangular vector, or vice versa
function Vec3:__index(index)
	if index == 'magnitude' then
		return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	end
	return Vec3[index]
end

function Vec3:get_dot_product(other)
	return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vec3:wrap_to_square(min, max)
	if max == nil then
		max = min
		min = 1
	end
	self.x = (self.x - min) % max + min
	self.y = (self.y - min) % max + min
	self.z = (self.z - min) % max + min
end

function Vec3:wrap_to_square_bipolar(width)
	self:wrap_to_square(-width / 2, width)
end

return Vec3