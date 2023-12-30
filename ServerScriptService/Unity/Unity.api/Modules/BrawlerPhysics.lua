local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Log = require("Log")
local Network = require("Network")
local SettingsManager = Unity:LoadServerConfig("SettingsManager")

local BrawlerPhysics = {}

local ANGLE_CONV = 180/math.pi
local VEL_MLTP = 1000

local function createKnockback(entity, velocity, force, aggression, xDecay, yDecay)
	local knockback = entity.player.Character.HumanoidRootPart:FindFirstChild("Knockback")
	if not knockback then
		local knockback = Instance.new("BodyVelocity")
		knockback.Parent = entity.player.Character.HumanoidRootPart
		knockback.Name = "Knockback"
	end
	knockback.Velocity = velocity
	knockback.MaxForce = force
	knockback.P = aggression
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "Knockback Data - [Velocity:", velocity, "], [MaxForce:", force, "], [P:", aggression, "]", "[Decay: X =", xDecay, "Y =", yDecay, "]")
	local dx = math.abs(knockback.MaxForce.X)/knockback.MaxForce.X
	local dy = math.abs(knockback.MaxForce.Y)/knockback.MaxForce.Y
	while math.floor(math.abs(knockback.Velocity.X)) > 0 or math.floor(math.abs(knockback.Velocity.Y)) > 0 do
		knockback.Velocity = Vector3.new(math.floor(knockback.Velocity.X * math.abs(xDecay)), math.floor(knockback.Velocity.Y * math.abs(yDecay)), 0)
		if math.abs(knockback.Velocity.X) == 1 then
			knockback.Velocity = Vector3.new(0,0,0)
		end
		if math.abs(knockback.Velocity.Y) == 1 then
			knockback.Velocity = Vector3.new(knockback.Velocity.X,0,0)
		end
		wait(0.1)
	end
	knockback.Velocity = Vector3.new(0,0,0)
	knockback.MaxForce = Vector3.new(0,0,0)
end

local function knockbackFormula(entity, dealt_damage, weight, knockback_growth, trajectory, bonuses)
	if not bonuses then bonuses = 1 end
	local damage = entity.damage
	local output = (((damage/10) + ((damage + dealt_damage)/20) * (200/(weight+100))) + 18) * knockback_growth * bonuses
	local x = output * math.cos(trajectory)
	local y = output * math.sin(trajectory)
	local velocity = Vector3.new(x,y,0)
	return output, velocity
end

local function getHorizontalVelocity(knockback, angle)
	if knockback < 80 then
		return 0
	end
	local initialVelocity = knockback * 0.03
	local horizontalAngle = math.cos(angle * ANGLE_CONV)
	local horizontalVelocity = initialVelocity * angle * 100
	horizontalVelocity = math.floor(horizontalVelocity * 100000) / 100000
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "Angles H:", angle, horizontalAngle*100, horizontalVelocity)
	return horizontalVelocity * VEL_MLTP
end

local function getVerticalVelocity(knockback, angle, trajectory, grounded)
	local initialVelocity = knockback * 0.03
	local verticalAngle = math.sin(angle * ANGLE_CONV)
	local verticalVelocity = initialVelocity * verticalAngle
	verticalVelocity = math.floor(verticalVelocity * 100000) / 100000
	if (knockback < 80 and grounded and (trajectory == 0 or math.abs(trajectory) == 180)) then
		verticalVelocity = 0;
	end
	return verticalVelocity * VEL_MLTP * -1 --Need to fix this later so I don't need a -1 -_-
end

local function getVerticalDecay(angle)
	local decay = 0.051 * math.sin(angle * ANGLE_CONV)
	decay = math.floor(decay * 100000) / 100000;
	return decay
end

local function getHorizontalDecay(angle)
	local decay = 0.051 * math.cos(angle * ANGLE_CONV)
	decay = math.floor(decay * 100000) / 100000;
 	return decay
end

function BrawlerPhysics:ApplyKnockback(entity, dealt_damage, total_kb, trajectory, knockback_growth, weight)
	local grounded = not (entity.player.Character.Humanoid.FloorMaterial == Enum.Material.Air)
	local yVel = getVerticalVelocity(total_kb, trajectory, trajectory, grounded)
	local xVel = getHorizontalVelocity(total_kb, trajectory)
	local yDec = getVerticalDecay(trajectory)
	local xDec = getHorizontalDecay(trajectory)
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "XVel", xVel, "- trajectory: ", trajectory, total_kb)
	createKnockback(entity, Vector3.new(xVel, yVel, 0), Vector3.new(30000,30000,30000), 5000, xDec, yDec)	
end

function BrawlerPhysics:ApplyScaledKnockback(entity, dealt_damage, base_knockback, knockback_growth, trajectory, weight_influence)
	if not base_knockback then base_knockback = 0 end
	if not knockback_growth then knockback_growth = 0 end
	if not trajectory then trajectory = 0 end
	if not weight_influence then weight_influence = 1 end
	
	local client_stat_weight = Network.Invoke("GetCharacterStat", Enum.Receiver.Client, entity.player, "weight")
	local percent_portion = (entity.damage/10) + (entity.damage*dealt_damage)/20
	local weight_portion = 200.0/(client_stat_weight*SettingsManager["weight"]*weight_influence+100)
   	local total_kb = (((percent_portion * weight_portion *1.4) + 5) * knockback_growth) 
	self:ApplyKnockback(entity, dealt_damage, total_kb, trajectory, knockback_growth, client_stat_weight)
end

function BrawlerPhysics:ApplyKnockbackV2(entity, dealt_damage, total_kb, trajectory, knockback_growth, weight)
	local knockback, velocity = knockbackFormula(entity, dealt_damage, weight, knockback_growth, trajectory)
	local trajectory_vec = Vector3.new(math.cos(trajectory/180*math.pi), math.sin(trajectory/180*math.pi), 1)
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "Trajectory vector: ", trajectory_vec)
	createKnockback(entity, velocity, velocity * Vector3.new(700,500,1), 5000)
end

function BrawlerPhysics:ApplyScaledKnockbackV2(entity, dealt_damage, base_knockback, knockback_growth, trajectory, weight_influence)
	if not base_knockback then base_knockback = 0 end
	if not knockback_growth then knockback_growth = 0 end
	if not trajectory then trajectory = 0 end
	if not weight_influence then weight_influence = 1 end
	
	local client_stat_weight = Network.Invoke("GetCharacterStat", Enum.Receiver.Client, entity.player, "weight")
	local percent_portion = (entity.damage/10) + (entity.damage*dealt_damage)/20
	local weight_portion = 200.0/(client_stat_weight*SettingsManager["weight"]*weight_influence+100)
   	local scaled_kb = (((percent_portion * weight_portion *1.4) + 5) * knockback_growth) 
	self:ApplyKnockback(entity, dealt_damage, scaled_kb, trajectory, knockback_growth, client_stat_weight)
end

function BrawlerPhysics:ApplyKnockbackV1(entity, _total_kb, _trajectory, knockback_growth)
	local true_angle = _trajectory
	local trajectory_vec = Vector3.new(math.cos(_trajectory/180*math.pi), math.sin(_trajectory/180*math.pi), 1)
	local smoothed_input = Network.Invoke("GetSmoothedInput", Enum.Receiver.Client, entity.player)
	print("Smoothed input:", smoothed_input)
	local di_vec = Vector3.new(smoothed_input, 1) + Vector3.new(_total_kb, _total_kb, 1)
	local di_multiplier = 1+di_vec:Dot(trajectory_vec)*.05
	print(di_vec, trajectory_vec)
	_trajectory = Vector3.new(_trajectory, _trajectory+5, 1) + di_vec:Cross(trajectory_vec)*13.5
	
	local knockback = entity.player.Character.HumanoidRootPart:FindFirstChild("Knockback")
	if not knockback then
		local knockback = Instance.new("BodyVelocity")
		knockback.Parent = entity.player.Character.HumanoidRootPart
		knockback.Name = "Knockback"
	end
	
	knockback.Velocity = _trajectory * Vector3.new(math.abs(true_angle)/true_angle, _trajectory.Y, 1)
	knockback.MaxForce = Vector3.new(math.abs((_total_kb)*di_multiplier) * ((entity.damage/(100*knockback_growth)) * 10), math.abs((_total_kb)*di_multiplier) * (entity.damage/(100*knockback_growth)), 0)
	knockback.P = 5000 * knockback_growth
	
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "Knockback: ", knockback.Velocity, knockback.MaxForce, knockback.P)
	
	wait(0.1 * knockback_growth*(entity.damage/250))
	
	knockback.Velocity = Vector3.new(0,0,0)
	knockback.MaxForce = Vector3.new(0,0,0)
	knockback.P = 0
	-- trajectory will be BodyVelocity vloecity
	-- (_total_kb)*di_multiplier will be force in all directions except z which is 0
	-- (_total_kb)*di_multiplier, _trajectory
	
end

--[[
	Base Knockback - Minimum knockback added
	Knockback Growth - How much knockback is affected by damage
	Trajectory - Given by entity dealing damage via angle calculation of attack
	Weigh Influence - A weight balancer
]]

function BrawlerPhysics:ApplyScaledKnockbackV1(entity, damage, base_knockback, knockback_growth, trajectory, weight_influence)
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.PhysicsSystem, "Creating knockback!")
	if not base_knockback then base_knockback = 0 end
	if not knockback_growth then knockback_growth = 0 end
	if not trajectory then trajectory = 0 end
	if not weight_influence then weight_influence = 1 end
	
	local client_stat_weight = Network.Invoke("GetCharacterStat", Enum.Receiver.Client, entity.player, "weight")
	local percent_portion = (entity.damage/10) + (entity.damage*damage)/20
	local weight_portion = 200.0/(client_stat_weight*SettingsManager["weight"]*weight_influence+100)
   	local scaled_kb = (((percent_portion * weight_portion *1.4) + 5) * knockback_growth) 
  	self:ApplyKnockback(entity, scaled_kb+base_knockback, trajectory, knockback_growth)
end

return BrawlerPhysics