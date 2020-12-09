--- boids will be boids...?

local Boid = {}
Boid.__index = Boid

-- keep track of all boids
Boid.n_boids = 0
Boid.boids = {}

Boid.attraction_distance = 32
Boid.repulsion_distance = 18
Boid.cos_max_steering_angle = math.cos(math.pi / 3)
Boid.perpdist = math.sqrt(1 - Boid.cos_max_steering_angle * Boid.cos_max_steering_angle) -- TODO: rename this and explain yourself
Boid.max_acceleration = 1
Boid.max_speed = 3

function Boid.new(x, y, z)
	local boid = {
		position = Vec3.new(x, y, z),
		velocity = Vec3.new(0, 0, 0),
		next_velocity = Vec3.new(0, 0, 0),
		ground_level = 0,
		altitude = 10,
		value = 0,
		scope = Scope.new(1 + 0.1 * Boid.n_boids)
	}
	Boid.n_boids = Boid.n_boids + 1
	Boid.boids[Boid.n_boids] = boid
	return setmetatable(boid, Boid)
end

--- compute a boid's velocity for the next frame
function Boid:update_velocity()
	local steering = Vec3.new(0, 0, 0)
	local flock_position = Vec3.new(0, 0, 0)
	local flock_velocity = Vec3.new(0, 0, 0)
	local n_neighbors = 0
	for i, other in ipairs(Boid.boids) do
		if other ~= self then
			local distance_vector = other.position - self.position
			local distance = distance_vector.magnitude
			if distance < Boid.attraction_distance then
				-- neighbor alert!
				n_neighbors = n_neighbors + 1
				-- add position and velocity so we can average them later
				flock_position = flock_position + other.position
				flock_velocity = flock_velocity + other.velocity
				-- if we're too close, move away
				if distance < Boid.repulsion_distance then
					steering = steering - 1 / distance_vector
					-- this is the same as the above, right...?
					-- steering = steering - distance_vector / distance_vector:get_dot_product(distance_vector)
				end
			end
		end
	end
	if n_neighbors > 0 then
		-- scale avoidance factor
		steering = steering / 2
		-- average neighbor positions and velocities
		flock_position = flock_position / n_neighbors
		flock_velocity = flock_velocity / n_neighbors
		-- gravitate toward flock center
		steering = steering + (flock_position - self.position) / 64
		-- match flock velocity
		steering = steering + (flock_velocity - self.velocity) / 128
	end
	-- gravitate toward the probe
	local probe_projection = Vec3.new(probe.position.x, probe.position.y, self.position.y)
	steering = steering + (probe_projection - self.position) / 128
	-- maintain a set distance from the ground
	-- TODO: without also limiting overall z-axis travel, this is pretty weird
	-- oh, also they're being pulled between the probe z and their own, which isn't good
	steering.z = steering.z + (self.ground_level + self.altitude - self.position.z) / 32
	-- limit steering angle
	-- TODO: clean this up! it's lifted practically verbatim from OpenSteering
	local steering_magnitude = steering.magnitude
	if steering_magnitude ~= 0 then
		local steering_direction = steering / steering_magnitude
		local current_direction = self.velocity / self.velocity.magnitude
		local dot = steering_direction:get_dot_product(current_direction)
		if dot < Boid.cos_max_steering_angle then -- TODO: this is cos(angle between dir and steering); tweak it
			local parallel = current_direction * dot
			local perpendicular = steering_direction - parallel
			perpendicular = perpendicular / perpendicular.magnitude
			local c0 = current_direction * Boid.cos_max_steering_angle
			local c1 = perpendicular * Boid.perpdist
			steering = (c0 + c1) * steering_magnitude
		end
	end
	-- limit acceleration
	-- local acceleration = steering.magnitude
	-- if acceleration > Boid.max_acceleration then
		-- steering = steering * (Boid.max_speed / acceleration)
	-- end
	-- apply steering to velocity
	self.next_velocity = self.velocity + steering
	-- limit overall velocity
	local speed = self.next_velocity.magnitude
	if speed > Boid.max_speed then
		self.next_velocity = self.next_velocity * (Boid.max_speed / speed)
	end
end

--- move a boid
function Boid:update_position()
	self.velocity = self.next_velocity
	self.position = self.position + self.velocity
	self.ground_level = surface:sample(self.position)
	self.scope:sample(self.position.z)
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
function Boid.draw_all()
	for i, boid in ipairs(Boid.boids) do
		screen.circle(boid.position.x, boid.position.y, 0.5 + boid.position.z / 50)
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