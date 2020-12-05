--- boids will be boids...?

local Boid = {}
Boid.__index = Boid

-- keep track of all boids
Boid.n_boids = 0
Boid.boids = {}

Boid.attraction_distance = 100
Boid.repulsion_distance = 3
Boid.max_speed = 3

function Boid.new(x, y)
	local boid = {
		position = Vector.new(x, y),
		velocity = Vector.new(0, 0),
		next_velocity = Vector.new(0, 0),
		scope = Scope.new(math.floor(screen_width + (math.random() - 0.5) * 20))
	}
	Boid.n_boids = Boid.n_boids + 1
	Boid.boids[Boid.n_boids] = boid
	return setmetatable(boid, Boid)
end

--- compute a boid's velocity for the next frame
function Boid:update_velocity()
	self.next_velocity = self.velocity
	local flock_position = Vector.new(0, 0)
	local flock_velocity = Vector.new(0, 0)
	local n_neighbors = 0
	for i, other in ipairs(Boid.boids) do
		if other ~= self then
			local distance_vector = other.position - self.position
			local distance = distance_vector.magnitude
			-- if distance < Boid.attraction_distance then
				-- neighbor alert!
				n_neighbors = n_neighbors + 1
				-- add position and velocity so we can average them later
				flock_position = flock_position + other.position
				flock_velocity = flock_velocity + other.velocity
				-- if we're too close, move away
				if distance < Boid.repulsion_distance then
					self.next_velocity = self.next_velocity - distance_vector
				end
			-- end
		end
	end
	-- average neighbor positions and velocities
	flock_position = flock_position / n_neighbors
	flock_velocity = flock_velocity / n_neighbors
	-- gravitate toward flock center
	self.next_velocity = self.next_velocity + (flock_position - self.position) / 64
	-- match flock velocity
	self.next_velocity = self.next_velocity + (flock_velocity - self.velocity) / 128
	-- gravitate toward the probe
	self.next_velocity = self.next_velocity + (Vector.new(probe.x, probe.y) - self.position) / 128
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
end

--- update all boids
function Boid.update_all()
	for i, boid in ipairs(Boid.boids) do
		boid:update_velocity()
	end
	for i, boid in ipairs(Boid.boids) do
		boid:update_position()
		boid.scope:sample(surface:sample(boid.position.x, boid.position.y))
	end
end

--- draw all boids on screen
function Boid.draw_all()
	for i, boid in ipairs(Boid.boids) do
		screen.circle(boid.position.x, boid.position.y, 1.5)
		screen.level(0)
		screen.fill()
		screen.circle(boid.position.x, boid.position.y, 0.9)
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