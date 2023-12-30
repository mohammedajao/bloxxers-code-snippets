local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local UIS = game:GetService("UserInputService")
local SystemManager = require("SystemManager")
local InputSystem = SystemManager:GetSubSystem("InputSystem")
local Controller = InputSystem:GetController()
local InputBuffer = Controller:GetInputBuffer()
local Log = require("Log")
local ButtonWrapper = {}
local ButtonWrapper_mt = {__index = ButtonWrapper}

function ButtonWrapper.new(_action, _keycode, _callback)
	local self = {}
	if not _callback then
		local msg = "Instance [ButtonWrapper] for action (".._action..") was initialized without a function"
		Log.Write(Enum.LogLevel.Warning, Enum.LogSystem.InputSystem, msg)
	end
	self.callback = _callback
	self.keycode = _keycode
	self.action = _action
	self.last_time_pressed = tick()
	self.binded_events = {
		UIS.InputBegan:Connect(function(input, process)
			if (input.KeyCode == self.keycode) then
				InputBuffer:append({self.keycode, input.UserInputState, self.last_time_pressed})
				self.callback(self.action, input.UserInputState, input, self);
				self.last_time_pressed = tick()
			end
		end),
		
		UIS.InputChanged:Connect(function(input, process)
			if (input.KeyCode == self.keycode) then
				self.callback(self.action, input.UserInputState, input, self);
			end
		end),
		
		UIS.InputEnded:Connect(function(input, process)
			if (input.KeyCode == self.keycode) then
				self.callback(self.action, input.UserInputState, input, self);
			end
		end)
	}
	return setmetatable(self, ButtonWrapper_mt)
end
	
function ButtonWrapper:KeyReinput(_timeframe)
	local output = false
	if not _timeframe then _timeframe = 0.5 end
	if (tick() - self.last_time_pressed) <= _timeframe then
		output = true
	end
	return output
end

function ButtonWrapper:BindFunction(_callback)
	self.callback = _callback
end

function ButtonWrapper:Disconnect()
	for i = 1, #self.binded_events do
		self.binded_events[i]:Disconnect()
	end
end

return ButtonWrapper
