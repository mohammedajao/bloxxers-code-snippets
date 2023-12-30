local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local SystemManager = require("SystemManager")
local InputSystem = SystemManager:GetSubSystem("InputSystem")
local Controller = InputSystem:GetController()
local Log = require("Log")
local InputBuffer = {}
local InputBuffer_mt = {__index = InputBuffer}

function InputBuffer.new()
	local self = {}
	self.buffer = {} -- Holds enums
	self.action_buffer = {} -- Holds actions
	self.working_buffer = {}
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.InputSystem, "InputBuffer initialized.")
	return setmetatable(self, InputBuffer_mt)
end

function InputBuffer:FlushInputs()
	self.buffer = {}
	self.action_buffer = {}
end

function InputBuffer:append(_key)
	if typeof(_key) ~= "table" and typeof(_key[1]) ~= "EnumItem" then
		local msg = "InputBuffer was passed an invalid argument: "
		Log.Write(Enum.LogLevel.Error, Enum.LogSystem.InputSystem, msg, _key)
		return
	end
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.InputSystem, "Adding to InputBuffer", _key[1], _key[2])
	_key.last_time_pressed = tick()
	table.insert(self.working_buffer, _key)
end

function InputBuffer:push()
	for i = 1, #self.working_buffer do
		local _key = self.working_buffer[i]
		local action = Controller:GetActionFromEnum(_key[1])
		if action == nil then
			Log.Write(Enum.LogLevel.Error, Enum.LogSystem.InputSystem, _key)
		end
		table.insert(self.buffer, _key)
		table.insert(self.action_buffer, action)
	end
	self.working_buffer = {}
end

function InputBuffer:GetLastNKeys(_from, _to)
	_to = _to or 0
	local result_buffer = {}
	if _from > #self.buffer then return {{nil}} end
	if _to > #self.buffer then return {{nil}} end
	for i = #self.buffer - _from, #self.buffer - _to do
		table.insert(result_buffer, self.buffer[i - (_to-1)])
	end
	return result_buffer
end

function InputBuffer:AddAction(_action)
	table.insert(self.action_buffer, _action)
end

return InputBuffer