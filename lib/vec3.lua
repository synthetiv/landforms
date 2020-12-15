--- a 2D vector with overloaded math operations

local Vec3 = {}
Vec3.__index = Vec3
Vec3.callers = {}
Vec3.count = 0

function Vec3.new(x, y, z)
	local caller = debug.getinfo(2)
	caller = caller.short_src .. ':' .. caller.currentline
	Vec3.callers[caller] = (Vec3.callers[caller] or 0) + 1
	Vec3.count = Vec3.count + 1
	local vec = {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
	return setmetatable(vec, Vec3)
end

function Vec3:__tostring()
	return string.format('(%f, %f, %f)', self.x, self.y, self.z)
end

function Vec3:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.z = self.z + other.z
	return self
end

function Vec3:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	self.z = self.z - other.z
	return self
end

function Vec3:mul(other)
	if type(other) == 'table' then
		self.x = self.x * other.x
		self.y = self.y * other.y
		self.z = self.z * other.z
	else
		self.x = self.x * other
		self.y = self.y * other
		self.z = self.z * other
	end
	return self
end

function Vec3:set_reciprocal()
	self.x = 1 / self.x
	self.y = 1 / self.y
	self.z = 1 / self.z
	return self
end

function Vec3:div(other)
	if type(other) == 'table' then
		self.x = self.x / other.x
		self.y = self.y / other.y
		self.z = self.z / other.z
	else
		self.x = self.x / other
		self.y = self.y / other
		self.z = self.z / other
	end
	return self
end

function Vec3:unm()
	self.x = -self.x
	self.y = -self.y
	self.z = -self.z
	return self
end

function Vec3:mod(modulus)
	self.x = self.x % modulus
	self.y = self.y % modulus
	self.z = self.z % modulus
	return self
end

--- set this vector's values without creating a new vector
function Vec3:set(x, y, z)
	if y == nil and z == nil then
		x, y, z = x.x, x.y, x.z
	end
	self.x, self.y, self.z = x, y, z
	return self
end

function Vec3:get()
	return self.x, self.y, self.z
end

function Vec3:get_magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:get_dot_product(other)
	return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vec3:wrap_to_square(min, max)
	self.x = (self.x - min) % max + min
	self.y = (self.y - min) % max + min
	self.z = (self.z - min) % max + min
end

function Vec3:wrap_to_square_bipolar(width)
	self:wrap_to_square(-width / 2, width)
end

return Vec3