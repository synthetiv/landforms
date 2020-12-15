--- boids will be boids...?

local Boid = {}
Boid.__index = Boid

-- keep track of all boids
Boid.n_boids = 0
Boid.boids = {}

Boid.attraction_distance = 1
Boid.repulsion_distance = 0.6
Boid.cos_max_steering_angle = math.cos(math.pi / 3)
Boid.sin_max_steering_angle = math.sin(math.pi / 3)
Boid.max_speed = 0.15

function Boid.new(x, y, z)
	local boid = {
		position = Vec3.new(x, y, z),
		last_position = Vec3.new(),
		velocity = Vec3.new(),
		next_velocity = Vec3.new(),
		ground_level = 0,
		altitude = z,
		value = 0,
		scope = Scope.new(1 + 0.1 * Boid.n_boids),
		voice = Voice.new()
	}
	Boid.n_boids = Boid.n_boids + 1
	Boid.boids[Boid.n_boids] = boid
	return setmetatable(boid, Boid)
end

--- compute a boid's velocity for the next frame
local distance_vector = Vec3.new()
local steering = Vec3.new()
local flock_position = Vec3.new()
local flock_velocity = Vec3.new()
local probe_distance = Vec3.new()
local heading = Vec3.new()
local perpendicular = Vec3.new()
function Boid:update_velocity()
	-- initialize scratch variables
	steering:set(0, 0, 0)
	flock_position:set(0, 0, 0)
	flock_velocity:set(0, 0, 0)
	-- gather data about neighbors
	local n_neighbors = 0
	for i, other in ipairs(Boid.boids) do
		if other ~= self then
			distance_vector:set(other.position)
			distance_vector:sub(self.position)
			local distance = distance_vector:get_magnitude()
			if distance < Boid.attraction_distance then
				-- neighbor alert!
				n_neighbors = n_neighbors + 1
				-- add position and velocity so we can average them later
				flock_position:add(other.position)
				flock_velocity:add(other.velocity)
				-- if we're too close, move away
				if distance < Boid.repulsion_distance then
					distance_vector:set_reciprocal()
					steering:sub(distance_vector)
				end
			end
		end
	end
	if n_neighbors > 0 then
		-- scale avoidance factor
		steering:div(4096)
		-- average neighbor positions and velocities
		flock_position:div(n_neighbors)
		flock_velocity:div(n_neighbors)
		-- gravitate toward flock center
		flock_position:sub(self.position)
		flock_position:div(64)
		steering:add(flock_position)
		-- match flock velocity
		flock_velocity:sub(self.velocity)
		flock_velocity:div(64)
		steering:add(flock_velocity)
	end
	-- gravitate toward the probe
	probe_distance:set(probe.position.x - self.position.x, probe.position.y - self.position.y, 0)
	probe_distance:div(64)
	steering:add(probe_distance)
	-- try to maintain a set distance from the ground
	steering.z = steering.z + (self.ground_level + self.altitude - self.position.z) / 16
	-- limit steering angle
	local steering_magnitude = steering:get_magnitude()
	if steering_magnitude ~= 0 then
		-- normalize to unit vectors
		steering:div(steering_magnitude)
		heading:set(self.velocity)
		heading:div(heading:get_magnitude())
		-- get the cosine of the angle between them
		local dot = steering:get_dot_product(heading)
		if dot < Boid.cos_max_steering_angle then
			-- get the component of the steering direction perpendicular to the
			-- current heading, and normalize it
			perpendicular:set(heading)
			perpendicular:mul(dot)
			perpendicular:sub(steering)
			perpendicular:unm()
			perpendicular:div(perpendicular:get_magnitude())
			-- we now have a right triangle whose hypotenuse is the normalized steering direction,
			-- one of whose legs is a portion of the current direction
			-- (or parallel to it, however you prefer to think of it).
			-- the other leg is longer than the radius of the max steering cone,
			-- so we need to reduce it, then increase the length of the other leg to
			-- hold the hypotenuse length of 1 constant.
			steering:set(heading)
			steering:mul(Boid.cos_max_steering_angle)
			perpendicular:mul(Boid.sin_max_steering_angle)
			steering:add(perpendicular)
			-- reapply original magnitude
			steering:mul(steering_magnitude)
		end
	end
	-- apply steering to current velocity
	self.next_velocity:set(self.velocity)
	self.next_velocity:add(steering)
	-- limit overall velocity
	local speed = self.next_velocity:get_magnitude()
	if speed > Boid.max_speed then
		self.next_velocity:mul(Boid.max_speed / speed)
	end
end

--- move a boid
function Boid:update_position()
	self.velocity:set(self.next_velocity)
	self.last_position:set(self.position)
	self.position:add(self.velocity)
	self.ground_level = surface:sample(self.position)
	self.scope:sample(self.position.z)
end

--- make a sound
function Boid:call()
	self.voice:move(self.position)
	self.voice:play()
end

function Boid.mute_all()
	for i, boid in ipairs(Boid.boids) do
		boid.voice:mute()
	end
end

function Boid.unmute_all()
	for i, boid in ipairs(Boid.boids) do
		boid.voice:unmute()
	end
end

--- update all boids
function Boid.update_all()
	for i, boid in ipairs(Boid.boids) do
		boid:update_velocity()
	end
	for i, boid in ipairs(Boid.boids) do
		boid:update_position()
	end
end

--- draw all boids on screen
local position = Vec2.new()
function Boid.draw_all()
	for i, boid in ipairs(Boid.boids) do
		map:transform_surface_point_to_screen(boid.position, position)
		local size = math.pow(1.5, boid.position.z) * 0.5
		screen.circle(position.x, position.y, size)
		screen.level(9)
		screen.fill()
	end
end

function Boid.draw_scopes(width, level)
	for i, boid in ipairs(Boid.boids) do
		boid.scope:draw(width, level)
	end
end

return Boid