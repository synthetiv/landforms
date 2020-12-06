-- landforms

test = include 'test'

Surface = include 'lib/surface'
Mosaic = include 'lib/mosaic'
Probe = include 'lib/probe'
Boid = include 'lib/boid'
Scope = include 'lib/scope'

screen_width = 128
screen_height = 64
tau = math.pi * 2
n_octaves = 4
bpr_labels = { '16', '12', '8', '6', '4', '3',  '2', '1', '1/2', '1/4' }
bpr_values = { 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2,    1,     2,     4 }

surface = Surface.new(screen_width)
mosaic = Mosaic.new(3, screen_width, screen_height)
probe = Probe.new()
scope = Scope.new(1.3)

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
				mosaic.needs_update = true
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

function redraw()
	screen.clear()
	screen.aa(1)
	screen.blend_mode('default')

	mosaic:draw()
	Boid.draw_all()
	probe:draw()
	scope:draw(1.3, 7)
	Boid.draw_scopes(1, 4)
	
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