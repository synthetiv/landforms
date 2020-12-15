-- landforms

test = include 'test'

Vec2 = include 'lib/vec2'
Vec3 = include 'lib/vec3'
Mesh = include 'lib/mesh'
Surface = include 'lib/surface'
Map = include 'lib/map'
Pattern = include 'lib/pattern'
Probe = include 'lib/probe'
Boid = include 'lib/boid'
Scope = include 'lib/scope'
Ratio = include 'lib/ratio'
Scala = include 'lib/scala'
Scale = include 'lib/scale'
Voice = include 'lib/voice'

engine.name = 'Blips'
voice_id = 0

screen_width = 128
screen_height = 64
half_width = 64
half_height = 32
tau = math.pi * 2
n_octaves = 4
bpr_labels = { '16', '12', '8', '6', '4', '3',  '2', '1', '1/2', '1/4' }
bpr_values = { 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2,    1,     2,     4 }

surface = Surface.new(4)
map = Map.new(3, screen_width, screen_height)
probe = Probe.new()
scope = Scope.new(1.3)

cursor = Vec2.new(half_width, half_height)
cursor_octave = 4
cursor_moved = 0
cursor_level = 0

held_keys = { false, false, false }

Boid.new(1.5, 0.5, 1.8)
Boid.new(2.1, 1.1, 2.1)
Boid.new(2.3, 1.5, 2.3)

probe_clock = nil
redraw_metro = nil

-- screen capture
capturing = false
frames_to_capture = 0
frames_captured = 0

-- profiling
include 'lib/pepperfish_profiler'
profiler = newProfiler('time', 10000)
profiling = false
profile_end_time = 0
profile_path = '/home/we/dust/data/landforms/profile.txt'

function crow.add()
	crow.clear()
	for o = 1, 4 do
		crow.output[o].scale{ 0, 2, 3, 5, 7, 8, 10 }
	end
end

local surface_cursor = Vec2.new()
function enc(n, d)
	if held_keys[2] and not held_keys[3] then
		if n == 2 then
			cursor_octave = util.clamp(cursor_octave + d, 1, surface.n_octaves)
			cursor_moved = util.time()
		end
	elseif held_keys[3] then
		if n == 3 then
			map:transform_screen_point_to_surface(cursor, surface_cursor)
			surface:edit(surface_cursor, cursor_octave, d * -0.1)
			cursor_moved = util.time()
		end
	else
		if n == 2 then
			cursor.x = util.clamp(cursor.x + d, 0, screen_width)
			cursor_moved = util.time()
		elseif n == 3 then
			cursor.y = util.clamp(cursor.y - d, 0, screen_height)
			cursor_moved = util.time()
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
		controlspec = controlspec.new(0.1, 2.2, 'lin', 0, probe.radius),
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
	
	profile_start()

	-- Boid.mute_all()

	probe_clock = clock.run(function()
		while true do
			clock.sync(1 / 32)
			probe:move()
			for b = 1, Boid.n_boids do
				Boid.boids[b]:call()
			end
		end
	end)
	
	frame_metro = metro.init{
		time = 1 / 16,
		event = function()
			Boid.update_all()
			scope:sample(probe.position.z)
			crow.output[1].volts = probe.position.z / 2 + 1
			for o = 2, 4 do
				crow.output[o].volts = Boid.boids[o - 1].position.z / 2 + 2
			end
			redraw()
			--[[
			if capturing and frames_captured < frames_to_capture then
				frames_captured = frames_captured + 1
				_norns.screen_export_png(string.format('/tmp/landframes/%04d.png', frames_captured))
				if frames_captured >= frames_to_capture then
					print('done')
				end
			end
			--]]
			if profiling then
				if profile_end_time < util.time() then
					profile_stop()
				end
			end
		end
	}
	frame_metro:start()
	capture(256)
end

function capture(frames)
	frames_to_capture = frames or 128
	os.execute('mkdir -p /tmp/landframes')
	frames_captured = 0
	capturing = true
end

function profile_start(seconds)
	seconds = seconds or 30
	profiler:start()
	profiling = true
	profile_end_time = util.time() + seconds
	print('profiling...')
end

function profile_stop()
	profiler:stop()
	local outfile = io.open(profile_path, 'w+')
	profiler:report(outfile)
	outfile:close()
	print('profile complete', profile_path)
	profiling = false
end

function draw_cursor_node(x, y, distance_x, distance_y, node, line_length)
	local distance = math.sqrt(distance_x * distance_x + distance_y * distance_y)
	local distance = math.max(0, 1 - distance)
	local level = math.floor(cursor_level * distance * 15 + 0.5)
	screen.level(level)
	x = util.round(x, 3) + 1
	y = util.round(y, 3)
	screen.rect(x - 1, y - 1, 3, 3)
	screen.fill()
	screen.move(x, y)
	screen.line_rel(node.x * line_length, node.y * line_length)
	screen.stroke()
end

local mesh_cursor = Vec2.new()
local mesh_cursor_min = Vec2.new()
local mesh_cursor_max = Vec2.new()
local cursor_min = Vec2.new()
local cursor_max = Vec2.new()
local mesh_cursor_distance = Vec2.new()
function draw_cursor()
	cursor_level = util.clamp((1.5 + cursor_moved - util.time()) * 4, 0, 1)
	if cursor_level == 0 then
		return
	end
	local mesh = surface.octaves[cursor_octave].mesh
	map:transform_screen_point_to_mesh(cursor, cursor_octave, mesh_cursor)
	local xl = math.floor(mesh_cursor.x)
	local yl = math.floor(mesh_cursor.y)
	mesh_cursor_min:set(xl, yl)
	mesh_cursor_max:set(xl + 1, yl + 1)
	map:transform_mesh_point_to_screen(mesh_cursor_min, cursor_octave, cursor_min)
	map:transform_mesh_point_to_screen(mesh_cursor_max, cursor_octave, cursor_max)
	local radius = cursor_max.x - cursor_min.x
	screen.line_width(1)

	local xl, xh, yl, yh = mesh:get_neighbors(mesh_cursor, mesh_cursor_distance)
	local length = radius / 3 + 2
	draw_cursor_node(cursor_min.x, cursor_min.y,     mesh_cursor_distance.x,     mesh_cursor_distance.y, mesh.nodes[xl][yl], length)
	draw_cursor_node(cursor_max.x, cursor_min.y, 1 - mesh_cursor_distance.x,     mesh_cursor_distance.y, mesh.nodes[xh][yl], length)
	draw_cursor_node(cursor_max.x, cursor_max.y, 1 - mesh_cursor_distance.x, 1 - mesh_cursor_distance.y, mesh.nodes[xh][yh], length)
	draw_cursor_node(cursor_min.x, cursor_max.y,     mesh_cursor_distance.x, 1 - mesh_cursor_distance.y, mesh.nodes[xl][yh], length)

	-- point cursor
	local width = util.round(radius / 3, 2) + 1
	screen.aa(1)
	screen.rect(cursor.x - width / 2, cursor.y - width / 2, width, width)
	screen.level(math.floor(3 * cursor_level + 0.5))
	screen.stroke()
end

function redraw()
	screen.clear()
	screen.aa(1)

	screen.blend_mode('default')
	map:draw()

	screen.blend_mode('add')
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
	if _profiler.running then
		profile_stop()
	end
end