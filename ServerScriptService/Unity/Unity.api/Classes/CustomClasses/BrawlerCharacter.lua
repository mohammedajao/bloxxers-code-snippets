local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()

---// ROBLOX Services
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

---// Managers
local SystemManager = require("SystemManager")

--// Input
local Log = require("Log")


local BrawlerCharacter = {}
local BrawlerCharacter_mt = {__index = BrawlerCharacter}

function BrawlerCharacter.new(_player)
	local self = {}
	self.combat_info = {
		max_ground_streak = 1;
		max_air_streak = 1;
	}
	self.stats = {}
	self.damage_triggers = {}
	self.damage = 0
	self.player = _player
	return setmetatable(self, BrawlerCharacter_mt)
end

local function elasticize(plr)
	for _,part in pairs(plr.Character:GetChildren()) do
		if part.ClassName == "Part" then
			part.CustomPhysicalProperties = true
			part.CustomPhysicalProperties.Elasticity = 1
		end
	end
end
function BrawlerCharacter:Initialize(champ)
	while not self.player.Character do wait() end
	elasticize(self.player)
	--Settings
	local deviceType = "keyboard"
	if UIS.GamepadEnabled then deviceType = "gamepad" else deviceType = "keyboard" end
	-- Set user preferences or set a preset based on device used
	-- Later also check if settings can be obtained from Datastore
	self.KeyMap = Unity:LoadClientConfig("KeyMap").presets[deviceType]
	
	local champions = Unity:LoadClientConfig("Champions")
	self.combat_info = champions[champ].combat_stats
	self.stats = champions[champ].stats
	self.damage_triggers = champions[champ].damage_triggers
	
	--Managers
	SystemManager:Initialize(self)
	
	-- Systems
	self.InputSystem = SystemManager:GetSubSystem("InputSystem")
	self.AnimationSystem = SystemManager:GetMainSystem("AnimationSystem")
	self.StateSystem = SystemManager:GetMainSystem("StateSystem")
	
	self.AnimationSystem:SetEntity(self)
	self.AnimationSystem:Initialize()
	self.AnimationSystem:LoadTracks()
	
	-- Input
	self.Controller = self.InputSystem:GetController()
	self.Controller:Initialize()
	self.InputBuffer = self.Controller:GetInputBuffer()
		
	-- Communication
	self.MessageQueue = Instance.new("MessageBroker")
	
	-- Movement
	self.player.Character:WaitForChild("Humanoid")
	self.player.Character:WaitForChild("Humanoid").AutoRotate = false
	
	-- Actions
	self.actions = {
		Move = Instance.new("Move"),
		Jump = Instance.new("Jump"),
		Action = Instance.new("AttackBase"),
		Crouch = Instance.new("Crouch")
	}
	
	-- Sets them to look horizontally
	for key,action in pairs(self.actions) do
		print("Setting up action", key)
		action:Setup(self)
	end
	
	-- Game Updates
	RunService:BindToRenderStep('BrawlerEntityUpdate', Enum.RenderPriority.Input.Value, function()
		self:Update()
	end)
	
	-- Reset
	self.player.Character.Humanoid.Died:connect(function()
		RunService:UnbindFromRenderStep("BrawlerEntityUpdate")
	end)
end

function BrawlerCharacter:ApplyDamage(_damage)
	self.damage = self.damage + math.floor(_damage)
	self.damage = math.min(999, self.damage)
end

function BrawlerCharacter:GetDamage()
	return self.damage
end

function BrawlerCharacter:Destroy()
	self.Controller:UnbindAll()
	self.MessageQueue = nil
	for i,_ in pairs(self.actions) do
		self.actions[i] = nil
	end
end

function BrawlerCharacter:SetState(_state, force)
	return self.StateSystem:SetState(_state, self, force)
end

function BrawlerCharacter:GetState(_state)
	return self.StateSystem:GetState()
end

function BrawlerCharacter:ReleaseState(_state)
	self.StateSystem:ReleaseState(_state, self)
end

function BrawlerCharacter:IsMoving()
	return math.abs(self.actions.Move.right_value - self.actions.Move.left_value) > 0
end

function BrawlerCharacter:IsInAir()
	return self.player.Character.Humanoid.FloorMaterial == Enum.Material.Air
end

function BrawlerCharacter:IsFalling()
	return self.Player.Character.HumanoidRootPart.Velocity.y < 0 and self:IsInAir()
end

function BrawlerCharacter:ApplyKnockback(_total_kb,_trajectory)
	-- Going to put this function into the Controller
	local trajectory_vec = {math.cos(_trajectory/180*math.pi), math.sin(_trajectory/180*math.pi)}
	
	local di_vec = self.getSmoothedInput(self.KeyMap.timing_window['smoothing_window'])
	local di_multiplier = 1+Vector3:Dot(Vector3.new(di_vec, unpack(trajectory_vec)))*.05
	
	local _trajectory = _trajectory + Vector3:Cross(Vector3.new(di_vec, unpack(trajectory_vec)))*13.5
	print(_total_kb)
	-- Rather than set speed, set state & add bodyForce or something
	--self.setSpeed((_total_kb)*di_multiplier, _trajectory)
end

function BrawlerCharacter:TestCheckForSpecial()
	local special = {Enum.KeyCode.D, Enum.KeyCode.D, Enum.KeyCode.J}
	local index = 1
	local last_time = 99999
	for i,v in pairs(self.InputBuffer:GetLastNKeys(3)) do
		if not v[1] or v[1] ~= special[index] then
			return false
		end
		index = index + 1
		last_time = v[3]
	end
	-- Need comparison greater than 1 due to data transfer delay
	return (index >= #special+1) and (tick() - last_time <= 1.5)
end

function BrawlerCharacter:Update()
	if self.player.Character then
		for _, action in pairs(self.actions) do
			action:Run()
		end
		if self:TestCheckForSpecial() then
			Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.InputSystem, "Special Right Right Attack combo activated!")
		end
		--Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.StateSystem, self.StateSystem:StateToString(self:GetState()))
		self.MessageQueue:Dispatch()
		self.InputBuffer:push()
		--Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.InputSystem, "Player is pushing at angle:", self.Controller:GetSmoothedAngle())
	end
end

return BrawlerCharacter