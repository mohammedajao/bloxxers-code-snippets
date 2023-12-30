local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local UIS = game:GetService("UserInputService")
local Log = require("Log")
local Network = require("Network")
local Controller = {}
local Controller_mt = {__index = Controller}

function Controller.new()
	local self = {}
	self.initialized = false
	self.bindings = {}
	self.bindings_key_map = {}
	self.bindings_id_map = {}
	self.input_buffer = nil
	Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.InputSystem, "Controller initialized")
	return setmetatable(self, Controller_mt)
end

function Controller:Initialize()
	if not self.initialized then
		--Settings
		local deviceType = "keyboard"
		if UIS.GamepadEnabled then deviceType = "gamepad" else deviceType = "keyboard" end
		-- Set user preferences or set a preset based on device used
		-- Later also check if settings can be obtained from Datastore
		self.KeyMap = Unity:LoadClientConfig("KeyMap").presets[deviceType]
		self.input_buffer = Instance.new("InputBuffer")
		self.initialized = true
	end
end

function Controller:BindToInput(_action, _callback, ...)
	self:Initialize()
	local binds = {...}
	self.bindings[_action] = {}
	for i = 1, #binds do
		local keycode = binds[i]
		if not self.bindings_id_map[keycode] then
			self.bindings_id_map[keycode] = {}
		end
		if not self.bindings_key_map[_action] then
			self.bindings_key_map[_action] = {}
		end
		table.insert(self.bindings_id_map[keycode], _action)
		--self.bindings_id_map[keycode] = _action
		--self.bindings_key_map[_action] = keycode
		table.insert(self.bindings_key_map[_action], keycode)
		self.bindings[_action][keycode] = Instance.new("ButtonWrapper", _action, keycode, _callback)
	end
end

function Controller:IsKeyHeld(_enums)
	self:Initialize()
	local output = true
	for i,kc in ipairs(_enums) do
		if not self.bindings_id_map[kc] then
			return false
		end
	end
	for i,kc in ipairs(_enums) do
		if not UIS:IsKeyDown(kc) then
			output = false
		end
	end
	return output
end

function Controller:GetSmoothedInput(_distanceBack, _maxMagnitude)
	if not _maxMagnitude then _maxMagnitude = 1 end
	if not _distanceBack then
		_distanceBack = self.KeyMap.timing_windows.smoothing_window
	end
	local hold_buffer = self.input_buffer:GetLastNKeys(_distanceBack)
	local smoothed_x, smoothed_y = 0,0
	local left =  0
	local right = 0
	local up = 0
	local down = 0
	if self:IsKeyHeld(self.KeyMap.left) then left = 1 end
	if self:IsKeyHeld(self.KeyMap.right) then right = 1 end
	if self:IsKeyHeld(self.KeyMap.up) then up = 1 end
	if self:IsKeyHeld(self.KeyMap.down) then down = 1 end
	smoothed_x = -left+right
	smoothed_y = -up+down
	
	local final_magnitude = Vector3.new(smoothed_x, smoothed_y, 0)
    if final_magnitude.Magnitude > _maxMagnitude then
		smoothed_x = smoothed_x / (final_magnitude.Magnitude/_maxMagnitude)
		smoothed_y =  smoothed_y / (final_magnitude.Magnitude/_maxMagnitude)
	end
    return smoothed_x, smoothed_y
end

function Controller:GetSmoothedAngle(default)
	local inputVal = {self:GetSmoothedInput()}
	local angle = default or 90
	if inputVal == {0,0} then
		return angle
	else
		angle = math.atan2(inputVal[1], -inputVal[2])*180/math.pi
	end
	return angle
end

function Controller:GetInputBuffer()
	return self.initialized and self.input_buffer
end

function Controller:GetActionFromEnum(input)
	self:Initialize()
	if typeof(input) == "EnumItem" then
		return self.bindings_id_map[input]
	else
		local msg = "Invalid input detected: "
		Log.Write(Enum.LogLevel.Warning, Enum.LogSystem.InputSystem, msg, input)
	end
end

function Controller:UnbindAction(_action)
	self:Initialize()
	for keycode, button in pairs(self.bindings[_action]) do
		button:Disconnect()
	end
end

function Controller:UnbindAll()
	self:Initialize()
	for action, keycode in pairs(self.bindings) do
		self:UnbindAction(action)
	end
end

return Controller
