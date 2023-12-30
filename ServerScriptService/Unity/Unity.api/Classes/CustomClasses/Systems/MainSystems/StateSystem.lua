local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Log = require("Log")

local StateSystem = {}
local StateSystem_mt = {__index = StateSystem}

function StateSystem.new()
	local self = {}
	self.initialized = false
	self.state = Enum.BrawlerCharacterState.Idle
	setmetatable(self, StateSystem_mt)
	return self
end

local function _implicitConversion(_state)
	if type(_state) == "string" then
		_state = Enum.BrawlerCharacterState[_state]
	end
	return _state
end

function StateSystem:Initialize()
	if not self.initialized then
		self.initialize = true
	end
end

function StateSystem:GetState()
	return self.state
end

function StateSystem:SetState(_state, entity, force)
	entity = entity or self.entity
	_state = _implicitConversion(_state)
	if self.state == _state then
		return true
	end
	if force then
		self.state = _state
		return true
	end
	if _state > self.state then
		self.state = _state
		return true
	end
	return false
end

function StateSystem:ReleaseState(_state, entity)
	_state = _implicitConversion(_state)
	if _state == self.state then
		self.state = Enum.BrawlerCharacterState.Idle
	end
end

function StateSystem:StateToString(_state)
	_state = _implicitConversion(_state)
	for str,val in pairs (Enum.BrawlerCharacterState) do
		if _state == val then
			return str
		end
	end
end

return StateSystem