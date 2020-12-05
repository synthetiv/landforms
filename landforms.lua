-- landforms

test = include 'test'

Mesh = include 'lib/mesh'
Mosaic = include 'lib/mosaic'

tau = math.pi * 2
n_octaves = 4
bpr_labels = { '16', '12', '8', '6', '4', '3',  '2', '1', '1/2', '1/4' }
bpr_values = { 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2,    1,     2,     4 }

meshes = {
	Mesh.new(32, 16),
	Mesh.new(16, 8),
	Mesh.new(8, 4),
	Mesh.new(4, 2)
}

-- TODO: parameterize
levels = {
	0.3,
	0.7,
	1,
	0.5
}

mosaic = Mosaic.new(4, 128, 64)
mosaic_dirty = true

probe_bpr = 1/4
probe_angle = 0
probe_radius = 23

probe_clock = nil
redraw_metro = nil

function init()

	test()
	
	params:add_separator('probe')
	
	params:add{
		id = 'radius',
		name = 'radius',
		type = 'control',
		controlspec = controlspec.new(1, 32, 'lin', 0, probe_radius),
		action = function(value)
			probe_radius = value
		end
	}
	
	params:add{
		id = 'beats_per_rotation',
		name = 'beats per rotation',
		type = 'option',
		options = bpr_labels,
		action = function(value)
			probe_bpr = bpr_values[value]
		end
	}
	
	params:add_separator('terrain')
	
	for o = 1, n_octaves do
		params:add{
			id = string.format('octave_%d_level', o),
			name = string.format('octave %d level', o),
			type = 'control',
			default = levels[o],
			controlspec = controlspec.BIPOLAR,
			action = function(value)
				levels[o] = value
				mosaic_dirty = true
			end
		}
	end
	
	probe_clock = clock.run(function()
		local tick = clock.get_beats()
		local last_tick = 0
		while true do
			clock.sync(1 / 32)
			tick = clock.get_beats()
			probe_angle = probe_angle + (tick - last_tick) * probe_bpr * tau
			probe_angle = probe_angle % tau
			last_tick = tick
		end
	end)
	
	redraw_metro = metro.init{
		time = 1 / 16,
		event = function()
			redraw()
		end
	}
	redraw_metro:start()

	redraw()
end

function build_mosaic()
	mosaic:clear()
	for x = 1, mosaic.width do
		for y = 1, mosaic.height do
			for o = 1, n_octaves do
				local mesh = meshes[o]
				local level = levels[o]
				local value = mesh:sample((x - 0.5) * mesh.width / mosaic.width, (y - 0.5) * mesh.height / mosaic.height)
				mosaic:add(x, y, value * level)
			end
		end
	end
end

function draw_mosaic()
	-- (re)build if necessary
	if mosaic_dirty then
		build_mosaic()
		mosaic_dirty = false
	end
	for x = 1, mosaic.width do
		for y = 1, mosaic.height do
			local value = (mosaic:get(x, y) + 1) / 2
			screen.rect((x - 1) * mosaic.sample_size, (y - 1) * mosaic.sample_size, mosaic.sample_size, mosaic.sample_size)
			screen.level(util.round(util.clamp(value, 0, 1) * 15))
			screen.fill()
		end
	end
end

function draw_probe()
	-- screen.circle(64, 32, probe_radius)
	-- screen.line_width(1)
	-- screen.level(0)
	-- screen.stroke()
	local x = math.cos(probe_angle) * probe_radius + 64
	local y = math.sin(probe_angle) * probe_radius + 32
	screen.circle(x, y, 6)
	screen.blend_mode('exclusion')
	screen.level(7)
	screen.fill()
	local value = 0
	for o = 1, n_octaves do
		local mesh = meshes[o]
		value = value + mesh:sample(x * mesh.width / 128, y * mesh.height / 64) * levels[o]
	end
	local level = (value * 2 + 1) / 2
	screen.circle(x, y, 2.5)
	screen.blend_mode('default')
	screen.level(util.round(util.clamp(level, 0, 1) * 15))
	screen.fill()
end

function redraw()
	screen.clear()
	screen.aa(0)
	screen.blend_mode('default')

	draw_mosaic()
	draw_probe()

	screen.update()
end

function cleanup()
	if probe_clock ~= nil then
		clock.cancel(probe_clock)
	end
	if redraw_metro ~= nil then
		redraw_metro:stop()
	end
end