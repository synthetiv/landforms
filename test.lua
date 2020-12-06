-- landforms: test

Mesh = include 'lib/mesh'
Vector = include 'lib/vector'

function assert_equal(a, b)
	if a ~= b then
		-- local _, caller_name = debug.getupvalue(debug.getinfo(3).func, 1)
		error(debug.traceback(string.format('expected %s, got %s', a, b), 2))
	end
end

tests = {}

function tests.wrap()
	local m = Mesh.new(8)
	assert_equal(8, m:wrap(0))
	assert_equal(1, m:wrap(1))
	assert_equal(8, m:wrap(8))
	assert_equal(3, m:wrap(3))
end

function tests.wrap_bidirectional()
	local m = Mesh.new(1)
	assert_equal(0, m:wrap_bipolar(0))
	assert_equal(0, m:wrap_bipolar(2))
	assert_equal(0, m:wrap_bipolar(-2))
	assert_equal(0.5, m:wrap_bipolar(0.5))
end

function tests.interpolate_linear()
	local interpolate = Mesh.interpolate_linear
	assert_equal(0.5, interpolate(0, 1, 0.5))
	assert_equal(0, interpolate(0, 1, -1))
	assert_equal(1, interpolate(0, 1, 2))
	assert_equal(0, interpolate(0, 1, 0))
	assert_equal(1, interpolate(0, 2, 0.5))
end

function tests.interpolate_smooth()
	local interpolate = Mesh.interpolate_smooth
	assert_equal(0.5, interpolate(0, 1, 0.5))
	assert_equal(0, interpolate(0, 1, -1))
	assert_equal(1, interpolate(0, 1, 2))
	assert_equal(0, interpolate(0, 1, 0))
	assert_equal(1, interpolate(0, 2, 0.5))
end

function tests.interpolate_smoother()
	local interpolate = Mesh.interpolate_smoother
	assert_equal(0.5, interpolate(0, 1, 0.5))
	assert_equal(0, interpolate(0, 1, -1))
	assert_equal(1, interpolate(0, 1, 2))
	assert_equal(0, interpolate(0, 1, 0))
	assert_equal(1, interpolate(0, 2, 0.5))
end

function tests.sample_noise()
	local m = Mesh.new(8, 4)
	-- should always be zero at nodes
	assert_equal(0, m:sample(Vector.new(1, 1)))
	assert_equal(0, m:sample(Vector.new(1, 2)))
	-- don't actually assert this, it will be a random value:
	-- assert_equal(0, m:sample(Vector.new(1.5, 1.5)))
end

function tests.vector_math()
	local v1 = Vector.new(0, 0)
	local v2 = Vector.new(2, 3)
	local v3 = v1 + v2
	assert_equal(2, v3.x)
	assert_equal(3, v3.y)
	v3 = v1 - v2
	assert_equal(-2, v3.x)
	assert_equal(-3, v3.y)
	assert_equal(math.sqrt(13), v3.magnitude)
end

function tests.vector_wrapping()
	local v1 = Vector.new(1, 1)
	v1:wrap_to_square(3)
	assert_equal(1, v1.x)
	assert_equal(1, v1.y)
	v1:wrap_to_square_bipolar(3)
	assert_equal(1, v1.x)
	assert_equal(1, v1.y)
	local v2 = Vector.new(3, 3)
	v2:wrap_to_square(2)
	assert_equal(1, v2.x)
	assert_equal(1, v2.y)
	local v3 = Vector.new(4, 5)
	v3:wrap_to_square_bipolar(3)
	assert_equal(1, v3.x)
	assert_equal(-1, v3.y)
end

-- btw, just for fun... to understand getupvalue()...
--[[
function tests.upvalue()
	local val = 'zero'
	local func = function()
		-- we have to do something with `val` here in order for it to be added to the closure scope
		local use_of_val_in_function = val
		return 'one'
	end
	assert_equal('zero', val)
	assert_equal('one', func())
	local upvalue_name, upvalue_value = debug.getupvalue(func, 1)
	assert_equal('val', upvalue_name)
	assert_equal('zero', upvalue_value)
end
]]

function init()
	local success = true
	for name, test_function in pairs(tests) do
		print(string.format('- %s...', name))
		local status, errors = pcall(function() local name = name; test_function() end)
		if status then
			print('  passed')
		else
			print(errors)
			success = false
		end
	end
	if success then
		print('all passed :)')
	else
		print('ehh :(')
	end
end

return init