local Mob = {
	Self = nil,
	Animations = nil,
	Settings = nil,
	Events = nil,
	Mind = nil,
	Info = {
		-- These are constant values.  Don't change them unless you know what you're doing.
	
		-- Services
		Players = game:GetService 'Players',
		PathfindingService = game:GetService 'PathfindingService',
	
		-- Advanced settings
		RecomputePathFrequency = 1, -- The monster will recompute its path this many times per second
		RespawnWaitTime = 5, -- How long to wait before the monster respawns
		JumpCheckFrequency = 1, -- How many times per second it will do a jump check
	},
}

--[[
	Basic Monster

	Information:
		Configurations.MaximumDetectionDistance (default 200)
			The monster will not detect players past this point.  If you set it to a negative number then the monster will be able to chase from any distance.
			
		Configurations.CanGiveUp (default true)
			If true, the monster will give up if its target goes past the MaximumDetectionDistance.  This is a pretty good idea if you have people teleporting around.
			
		Configurations.CanRespawn (default true)
			If true, the monster will respawn after it dies
			
		Configurations.AutoDetectSpawnPoint (default true)
			If true, the spawn point will be auto detected based on where the monster is when it starts
		
		Configurations.SpawnPoint (default 0,0,0)
			If Settings.AutoDetectSpawnPoint is disabled, this will be set to the monster's initial position.  This value will be used when the monster auto respawns to tell it where to spawn next.
			
		Configurations.FriendlyTeam (default Really black)
			The monster will not attack players on this team
		
		
		
		Mind:CurrentTargetHumanoid (Humanoid objects only)
			You can force the monster to follow a certain humanoid by setting this to that humanoid
		
		
		
		Mob:Respawn (Function)
			Arguments are: Vector3 point
			Info: Respawns the monster at the given point, or at the SpawnPoint setting if none if provided
		
		Mob:Died (Event)
			Info: Fired when the monster dies
		
		Mob:Respawned (Event)
			Info: Fired when the monster respawns
--]]

function Mob.new(Root)
	local object = {}
	setmetatable(object, {__index = Mob})
	object.Self = Root
	return object
end

function Mob:Set(entity)
	--self.Self = entity
	if self.Self:IsA'Model' then
		self.Animations = self.Self:FindFirstChild'Animations'
		self.Settings = self.Self:FindFirstChild'Configurations'
		self.Events = self.Self:FindFirstChild'Events'
		self.Mind = self.Self:FindFirstChild'Mind'
	else
		warn(tostring(self.Self) .. " is not a model. " .. tostring(self.Self) .. " (" .. tostring(self.Self.ClassName) .. ")")
	end
	assert(self.Self:FindFirstChild'Enemy' ~= nil, "")
	assert(self.Settings ~= nil, "self does not have a Configurations object")
		assert(self.Settings:FindFirstChild'MaximumDetectionDistance',"")
		assert(self.Settings:FindFirstChild'CanGiveUp' ~= nil and self.Settings.CanGiveUp:IsA'BoolValue', 'self does not have a CanGiveUp (BoolValue) setting')
		assert(self.Settings:FindFirstChild'CanRespawn' ~= nil and self.Settings.CanRespawn:IsA'BoolValue', 'self does not have a CanRespawn (BoolValue) setting')
		assert(self.Settings:FindFirstChild'SpawnPoint' ~= nil and self.Settings.SpawnPoint:IsA'Vector3Value', 'self does not have a SpawnPoint (Vector3Value) setting')
		assert(self.Settings:FindFirstChild'AutoDetectSpawnPoint' ~= nil and self.Settings.AutoDetectSpawnPoint:IsA'BoolValue', 'self does not have a AutoDetectSpawnPoint (BoolValue) setting')
		assert(self.Settings:FindFirstChild'FriendlyTeam' ~= nil and self.Settings.FriendlyTeam:IsA'BrickColorValue', 'self does not have a FriendlyTeam (BrickColorValue) setting')
		assert(self.Settings:FindFirstChild'AttackDamage' ~= nil and self.Settings.AttackDamage:IsA'NumberValue', 'self does not have a AttackDamage (NumberValue) setting')
		assert(self.Settings:FindFirstChild'AttackFrequency' ~= nil and self.Settings.AttackFrequency:IsA'NumberValue', 'self does not have a AttackFrequency (NumberValue) setting')
		assert(self.Settings:FindFirstChild'AttackRange' ~= nil and self.Settings.AttackRange:IsA'NumberValue', 'self does not have a AttackRange (NumberValue) setting')
	assert(self.Mind ~= nil, 'self does not have a Mind object')
		assert(self.Mind:FindFirstChild'CurrentTargetHumanoid' ~= nil and self.Mind.CurrentTargetHumanoid:IsA'ObjectValue', 'self does not have a CurrentTargetHumanoid (ObjectValue) mind setting')
	assert(self.Events:FindFirstChild'Respawn' and self.Events.Respawn:IsA'BindableFunction', 'self does not have a Respawn BindableFunction')
	assert(self.Events:FindFirstChild'Died' and self.Events.Died:IsA'BindableEvent', 'self does not have a Died BindableEvent')
	assert(self.Events:FindFirstChild'Respawned' and self.Events.Respawned:IsA'BindableEvent', 'self does not have a Respawned BindableEvent')
	assert(self.Events:FindFirstChild'Attacked' and self.Events.Attacked:IsA'BindableEvent', 'self does not have a Attacked BindableEvent')
	assert(self.Animations:FindFirstChild'Attack' and self.Animations.Attack:IsA'Animation', 'self does not have a selfScript.Attack Animation')
	
	self.Data = {
		-- These are variable values used internally by the script.  Advanced users only.
	
		LastRecomputePath = 0,
		Recomputing = false, -- Reocmputing occurs async, meaning this script will still run while it's happening.  This variable will prevent the script from running two recomputes at once.
		PathCoords = {},
		IsDead = false,
		TimeOfDeath = 0,
		CurrentNode = nil,
		CurrentNodeIndex = 1,
		AutoRecompute = true,
		LastJumpCheck = 0,
		LastAttack = 0,
		
		BaseMonster = self.Self:Clone(),
		AttackTrack = nil,
		DeathTrack = nil,
		OtherTrack = nil
	}
	
	self.Settings.Health.Value = self.Settings.MaximumHealth.Value
end

function Mob:GetCFrame()
	-- Returns the CFrame of the monster's humanoidrootpart

	local humanoidRootPart = self.Self:FindFirstChild('HumanoidRootPart')

	if humanoidRootPart ~= nil and humanoidRootPart:IsA('BasePart') then
		return humanoidRootPart.CFrame
	else
		return CFrame.new()
	end
end

function Mob:GetMaximumDetectionDistance()
	-- Returns the maximum detection distance
	
	local setting = self.Settings.MaximumDetectionDistance.Value

	if setting < 0 then
		return math.huge
	else
		return setting
	end
end


function Mob:SearchForTarget()
	-- Finds the closest player and sets the target

	local players = self.Info.Players:GetPlayers()
	local closestCharacter, closestCharacterDistance

	for i=1, #players do
		local player = players[i]
		
		if player.Neutral or player.TeamColor ~= self.Settings.FriendlyTeam.Value then
			local character = player.Character
	
			if character ~= nil and character:FindFirstChild('Humanoid') ~= nil and character.Humanoid:IsA('Humanoid') and character.Humanoid.Health > 0 then
				local distance = player:DistanceFromCharacter(self:GetCFrame().p)
	
				if distance < self:GetMaximumDetectionDistance() then
					if closestCharacter == nil then
						closestCharacter, closestCharacterDistance = character, distance
					else
						if closestCharacterDistance > distance then
							closestCharacter, closestCharacterDistance = character, distance
						end
					end
				end
			end
		end
	end


	if closestCharacter ~= nil then
		self.Mind.CurrentTargetHumanoid.Value = closestCharacter.Humanoid
	end
end

function Mob:TryRecomputePath()
	if self.Data.AutoRecompute or tick() - self.Data.LastRecomputePath > 1/self.Info.RecomputePathFrequency then
		self:RecomputePath()
	end
end

function Mob:GetTargetCFrame()
	local targetHumanoid = self.Mind.CurrentTargetHumanoid.Value
	
	if self:TargetIsValid() then
		return targetHumanoid.Torso.CFrame
	else
		return CFrame.new()
	end
end

function Mob:IsAlive()
	return self.Settings.Health.Value > 0 and self.Self.Enemy ~= nil and self.Self.HumanoidRootPart ~= nil
end

function Mob:TargetIsValid()
	local targetHumanoid = self.Mind.CurrentTargetHumanoid.Value
	
	if targetHumanoid ~= nil and targetHumanoid:IsA 'Humanoid' and targetHumanoid.Torso ~= nil and targetHumanoid.Torso:IsA 'BasePart' then
		return true
	else
		return false
	end
end

function Mob:HasClearLineOfSight()
	-- Going to cast a ray to see if I can just see my target
	local myPos, targetPos = self:GetCFrame().p, self:GetTargetCFrame().p
	
	local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(
		Ray.new(
			myPos,
			targetPos - myPos
		),
		{
			self.Self,
			self.Mind.CurrentTargetHumanoid.Value.Parent
		}
	)
	
	
	if hit == nil then
		return true
	else
		return false
	end
end

function Mob:Limit()
	if (self:GetCFrame().p - self:GetTargetCFrame().p).magnitude <= self.Settings.AttackRange.Value then
		self.Self.Enemy.WalkSpeed = 0
	else
		self.Self.Enemy.WalkSpeed = self.Settings.MovementSpeed.Value
	end
end

function Mob:RecomputePath()
	if not self.Data.Recomputing then
		if self:IsAlive() and self:TargetIsValid() then
			if self:HasClearLineOfSight() then
				self.Data.AutoRecompute = true
				self.Data.PathCoords = {
					self:GetCFrame().p,
					self:GetTargetCFrame().p
				}
				
				self.Data.LastRecomputePath = tick()
				self.Data.CurrentNode = nil
				self.Data.CurrentNodeIndex = 2 -- Starts chasing the target without evaluating its current position
			else
				-- Do pathfinding since you can't walk straight
				self.Data.Recomputing = true -- Basically a debounce.
				self.Data.AutoRecompute = false
				
				
				local path = self.Info.PathfindingService:ComputeSmoothPathAsync(
					self:GetCFrame().p,
					self:GetTargetCFrame().p,
					500
				)
				self.Data.PathCoords = path:GetPointCoordinates()
				
				
				self.Data.Recomputing = false
				self.Data.LastRecomputePath = tick()
				self.Data.CurrentNode = nil
				self.Data.CurrentNodeIndex = 1
			end
		end
	end
end

function Mob:Update()
	self:ReevaluateTarget()
	self:SearchForTarget()
	self:TryRecomputePath()
	self:TravelPath()
	self:Limit()
end

function Mob:TravelPath()
	local closest, closestDistance, closestIndex
	local myPosition = self:GetCFrame().p
	local skipCurrentNode = self.Data.CurrentNode ~= nil and (self.Data.CurrentNode - myPosition).magnitude < 3
	
	for i=self.Data.CurrentNodeIndex, #self.Data.PathCoords do
		local coord = self.Data.PathCoords[i]
		if not (skipCurrentNode and coord == self.Data.CurrentNode) then
			local distance = (coord - myPosition).magnitude
			
			if closest == nil then
				closest, closestDistance, closestIndex = coord, distance, i
			else
				if distance < closestDistance then
					closest, closestDistance, closestIndex = coord, distance, i
				else
					break
				end
			end
		end
	end
	
	
	--
	if closest ~= nil and not self.GivenUp then
		self.Data.CurrentNode = closest
		self.Data.CurrentNodeIndex = closestIndex
		
		local humanoid = self.Self:FindFirstChild 'Enemy'
		
		if humanoid ~= nil and humanoid:IsA'Humanoid' then
			humanoid:MoveTo(closest)
		end
		
		if self:IsAlive() and self:TargetIsValid() then
			self:TryJumpCheck()
			self:TryAttack()
		end
		
		if closestIndex == #self.Data.PathCoords then
			-- Reached the end of the path, force a new check
			self.Data.AutoRecompute = true
		end
	end
end


function Mob:TryJumpCheck()
	if tick() - self.Data.LastJumpCheck > 1/self.Info.JumpCheckFrequency then
		self:JumpCheck()
	end
end

function Mob:TryAttack()
	if tick() - self.Data.LastAttack > 1/self.Settings.AttackFrequency.Value then
		self:Attack()
	end
end

function Mob:Attack()
	local myPos, targetPos = self:GetCFrame().p, self:GetTargetCFrame().p
	
	if self.Mind.CurrentTargetHumanoid.Value.Health > 0 and (myPos - targetPos).magnitude <= self.Settings.AttackRange.Value then
		self.Mind.CurrentTargetHumanoid.Value:TakeDamage(self.Settings.AttackDamage.Value)
		self.Data.LastAttack = tick()
		self.Data.AttackTrack:Play()
	end
end

function Mob:JumpCheck()
	-- Do a raycast to check if we need to jump
	local myCFrame = self:GetCFrame()
	local checkVector = (self:GetTargetCFrame().p - myCFrame.p).unit*2
	
	local hit, pos = game.Workspace:FindPartOnRay(
		Ray.new(
			myCFrame.p + Vector3.new(0, -2.4, 0),
			checkVector
		),
		self.Self
	)
	
	if hit ~= nil and not hit:IsDescendantOf(self.Mind.CurrentTargetHumanoid.Value.Parent) then
		-- Do a slope check to make sure we're not walking up a ramp
		
		local hit2, pos2 = game.Workspace:FindPartOnRay(
			Ray.new(
				myCFrame.p + Vector3.new(0, -2.3, 0),
				checkVector
			),
			self.Self
		)
		
		if hit2 == hit then
			if ((pos2 - pos)*Vector3.new(1,0,1)).magnitude < 0.05 then -- Will pass for any ramp with <2 slope
				self.Self.Enemy.Jump = true
			end
		end
	end
	
	self.Data.LastJumpCheck = tick()
end

function Mob:Connect()
	self.Mind.CurrentTargetHumanoid.Changed:connect(function(humanoid)
		if humanoid ~= nil then
			assert(humanoid:IsA'Humanoid', 'Monster target must be a humanoid')
			
			self:RecomputePath()
		end
	end)
	
	self.Events.Respawn.OnInvoke = function(point)
		self:Respawn(point)
	end
	
	self.Events.Died.Event:connect(function()
		self.Data.DeathTrack = self.Self.Enemy:LoadAnimation(self.Animations.Death)
		self.Data.DeathTrack:Play()
	end)
end

function Mob:Initialize()
	self:Connect()
	
	if self.Settings.AutoDetectSpawnPoint.Value then
		self.Settings.SpawnPoint.Value = self:GetCFrame().p
	end
end

function Mob:Respawn(point)
	local point = point or self.Settings.SpawnPoint.Value
	
	for index, obj in next, self.Data.BaseMonster:Clone():GetChildren() do
		if obj.Name == 'Configurations' or obj.Name == 'Events' then
			obj:Destroy()
		else
			self.Self[obj.Name]:Destroy()
			obj.Parent = self.Self
		end
	end
	
	self:Set(self.Self)
	self:InitializeUnique()
	
	self.Self.Parent = game.Workspace
	
	self.Self.HumanoidRootPart.CFrame = CFrame.new(point)
	self.Settings.SpawnPoint.Value = point
	self.Events.Respawned:Fire()
end

function Mob:InitializeUnique()
	self.Data.AttackTrack = self.Self.Enemy:LoadAnimation(self.Animations.Attack)
end

function Mob:ReevaluateTarget()
	local currentTarget = self.Mind.CurrentTargetHumanoid.Value
	
	if currentTarget ~= nil and currentTarget:IsA'Humanoid' then
		local character = currentTarget.Parent
		self.GivenUp = false
		if character ~= nil then
			local player = self.Info.Players:GetPlayerFromCharacter(character)
			
			if player ~= nil then
				if not player.Neutral and player.TeamColor == self.Settings.FriendlyTeam.Value then
					self.Mind.CurrentTargetHumanoid.Value = nil
				end
			end
		end
		
		
		if currentTarget == self.Mind.CurrentTargetHumanoid.Value then
			local torso = currentTarget.Torso
			
			if torso ~= nil and torso:IsA 'BasePart' then
				if self.Settings.CanGiveUp.Value and (torso.Position - self:GetCFrame().p).magnitude > self:GetMaximumDetectionDistance() then
					self.Mind.CurrentTargetHumanoid.Value = nil
				end
			end
		end
	else
		if (self:GetCFrame().p ~= self.Settings.SpawnPoint.Value) and not self.GivenUp then
			self.GivenUp = true
			self.Self.Enemy:MoveTo(self.Settings.SpawnPoint.Value)
		end
	end
end

function Mob:Execute()
	if self.Self:IsA'Model' then
		self:Initialize()
		self:InitializeUnique()
	end

	while self.Self:IsA'Model' do
		if not self:IsAlive() then
			if self.Data.IsDead == false then
				self.Data.IsDead = true
				self.Data.TimeOfDeath = tick()
				self.Events.Died:Fire()
			end
			if self.Data.IsDead == true then
				if tick()- self.Data.TimeOfDeath > self.Info.RespawnWaitTime then
					self:Respawn()
				end
			end
		end
	
		if self:IsAlive() then
			self:Update()
		end
	
		wait()
	end
end


return Mob