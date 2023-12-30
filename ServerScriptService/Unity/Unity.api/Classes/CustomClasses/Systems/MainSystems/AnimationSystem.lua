local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local ContentProvider = game:GetService("ContentProvider")

local Log = require("Log")

local AnimationSystem = {}
local AnimationSystem_mt = {__index = AnimationSystem}

local PriorityList = {
	[Enum.AnimationPriority.Core] = 1;
	[Enum.AnimationPriority.Idle] = 2;
	[Enum.AnimationPriority.Movement] = 3;
	[Enum.AnimationPriority.Action] = 4;
}

function AnimationSystem.new()
	local self = {}
	self.initialized = false
	self.entity = nil
	self.animations = {}
	self.preloaded_anims = {}
	setmetatable(self, AnimationSystem_mt)
	return self
end

local function _loadAnimations(self, entity, parent)
	local char = entity.player.Character
	for _,anim in pairs (parent:GetChildren()) do
		if anim.ClassName == "Folder" then
			_loadAnimations(self, entity, anim)
		elseif anim.ClassName == "Animation" then
			local str = ""
			if parent.Name ~= "BloxxerAnimations" then str = parent.Name end
			Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.AnimationSystem, "Animation Loaded: ", str .. anim.Name)
			self.animations[str .. anim.Name] = char.Humanoid:LoadAnimation(anim)
			table.insert(self.preloaded_anims, char.Humanoid:LoadAnimation(anim))
		end
	end
	ContentProvider:PreloadAsync(self.preloaded_anims)
end

function AnimationSystem:Initialize()
	if not self.initialized and self.entity then
		self.initialized = true
	end
end

function AnimationSystem:SetEntity(_entity)
	self.entity = _entity
end

function AnimationSystem:LoadTracks()
	if self.entity and self.initialized then
		Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.AnimationSystem, "Loading Animations...")
		local char = self.entity.player.Character
		local anims = char:WaitForChild("BloxxerAnimations")
		_loadAnimations(self, self.entity, anims)
	else
		Log.Write(Enum.LogLevel.Error, Enum.LogSystem.AnimationSystem, "Not initialized or no entity added")
	end
end

function AnimationSystem:PlayAnimation(_name)
	self:StopLowerAnimations(_name)
	self.animations[_name]:Play()
end

function AnimationSystem:GetAnimation(_name)
	return self.animations[_name]
end

function AnimationSystem:StopAnimation(_name)
	self.animations[_name]:Stop()
end

function AnimationSystem:StopLowerAnimations(_name)
	local priority = self.animations[_name].Priority
	for _,anim in pairs (self.animations) do
		if PriorityList[anim.Priority] < PriorityList[priority] then
			anim:Stop()
		end
	end
end

function AnimationSystem:StopAllAnimations()
	for _,anim in pairs (self.animations) do
		anim:Stop()
	end
end

return AnimationSystem