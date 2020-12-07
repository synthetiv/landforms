-- landforms

test = include 'test'

Vector = include 'lib/vector'
Surface = include 'lib/surface'
Map = include 'lib/map'
Probe = include 'lib/probe'
Boid = include 'lib/boid'
Scope = include 'lib/scope'

screen_width = 128
screen_height = 64
half_width = 64
half_height = 32
tau = math.pi * 2
n_octaves = 4
bpr_labels = { '16', '12', '8', '6', '4', '3',  '2', '1', '1/2', '1/4' }
bpr_values = { 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2,    1,     2,     4 }

surface = Surface.new(screen_width)
map = Map.new(3, screen_width, screen_height)
probe = Probe.new()
scope = Scope.new(1.3)

cursor = Vector.new(half_width, half_height)
cursor_octave = 3
cursor_bounds = {
	min = Vector.new(half_width, half_height),
	max = Vector.new(half_width, half_height)
}

held_keys = { false, false, false }

for i = 1, 3 do
	Boid.new(screen_width / 2 + (math.random() - 0.5) * 30, screen_height / 2 + (math.random() - 0.5) * 30)
end

probe_clock = nil
redraw_metro = nil

function crow.add()
	crow.clear()
	for o = 1, 4 do
		crow.output[o].scale{ 0, 2, 3, 5, 7, 8, 10 }
	end
end

function enc(n, d)
	if held_keys[2] and not held_keys[3] then
		if n == 2 then
			cursor_octave = util.clamp(cursor_octave + d, 1, surface.n_octaves)
		end
	elseif held_keys[3] then
		if n == 3 then
			surface:edit(cursor, cursor_octave, d * -0.1)
		end
	else
		if n == 2 then
			cursor.x = util.clamp(cursor.x + d, 0, screen_width)
		elseif n == 3 then
			cursor.y = util.clamp(cursor.y - d, 0, screen_height)
		end
	end
end

function key(n, z)
	held_keys[n] = z == 1
	if n == 2 and z == 1 then
		norns.enc.sens(2, 12)
		norns.enc.accel(false)
	else
		norns.enc.sens(2, 2)
		norns.enc.accel(2, true)
	end
	if n == 3 and z == 1 then
		norns.enc.sens(3, 2)
		norns.enc.accel(3, false)
	else
		norns.enc.sens(3, 2)
		norns.enc.accel(3, true)
	end
end

function init()

	test()
	
	params:add_separator('probe')
	
	params:add{
		id = 'radius',
		name = 'radius',
		type = 'control',
		controlspec = controlspec.new(1, 32, 'lin', 0, probe.radius),
		action = function(value)
			probe.radius = value
		end
	}
	
	params:add{
		id = 'beats_per_rotation',
		name = 'beats per rotation',
		type = 'option',
		options = bpr_labels,
		default = 3,
		action = function(value)
			probe.bpr = bpr_values[value]
		end
	}
	
	params:add_separator('terrain')
	
	for o = 1, n_octaves do
		params:add{
			id = string.format('octave_%d_level', o),
			name = string.format('octave %d level', o),
			type = 'control',
			default = surface.octaves[o].level,
			controlspec = controlspec.BIPOLAR,
			action = function(value)
				surface.octaves[o].level = value
				map.needs_update = true
			end
		}
	end
	
	probe_clock = clock.run(function()
		local tick = clock.get_beats()
		local last_tick = 0
		while true do
			clock.sync(1 / 32)
			tick = clock.get_beats()
			probe:rotate(tick - last_tick)
			last_tick = tick
		end
	end)
	
	frame_metro = metro.init{
		time = 1 / 16,
		event = function()
			Boid.update_all()
			scope:sample(probe.value)
			crow.output[1].volts = probe.value + 1
			for o = 2, 4 do
				crow.output[o].volts = Boid.boids[o - 1].value + 2
			end
			redraw()
		end
	}
	frame_metro:start()
end

function draw_cursor()
	local mesh_cursor = surface:transform_screen_point(cursor, cursor_octave)
	local xl = math.floor(mesh_cursor.x)
	local yl = math.floor(mesh_cursor.y)
	local min = surface:transform_mesh_point(Vector.new(xl, yl), cursor_octave)
	local max = surface:transform_mesh_point(Vector.new(xl + 1, yl + 1), cursor_octave)
	cursor_bounds.min = cursor_bounds.min + (min - cursor_bounds.min) * 0.75
	cursor_bounds.max = cursor_bounds.max + (max - cursor_bounds.max) * 0.75
	min = cursor_bounds.min
	max = cursor_bounds.max
	-- cell edges
	screen.rect(min.x + 0.5, min.y + 0.5, max.x - min.x, max.y - min.y)
	screen.aa(0)
	screen.blend_mode('add')
	screen.level(1)
	screen.stroke()
	-- corners
	screen.pixel(min.x, min.y)
	screen.pixel(max.x, min.y)
	screen.pixel(max.x, max.y)
	screen.pixel(min.x, max.y)
	screen.level(8)
	screen.fill()
	-- point cursor
	screen.aa(1)
	screen.circle(cursor.x, cursor.y, surface.octaves[cursor_octave].sample_size / 4)
	screen.level(3)
	screen.stroke()
end

function redraw()
	screen.clear()
	screen.aa(1)
	screen.blend_mode('default')

	map:draw()
	Boid.draw_all()
	probe:draw()
	-- scope:draw(1.3, 7)
	-- Boid.draw_scopes(1, 4)
	draw_cursor()
	
	screen.update()
end

function cleanup()
	if probe_clock ~= nil then
		clock.cancel(probe_clock)
	end
	if frame_metro ~= nil then
		frame_metro:stop()
	end
end