local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local UIS = game:GetService("UserInputService")
local Log = require("Log")
local InputSystem = {}
local InputSystem_mt = {__index = InputSystem}

function InputSystem.new()
	local self = {}
	self.controller = nil
	self.initialized = false
	return setmetatable(self, InputSystem_mt)
end

function InputSystem:Initialize()
	if not self.initialized then
		self.initialized = true
		self.controller = Instance.new("Controller")
	end
end

function InputSystem:GetController()
	return self.initialized and self.controller
end

return InputSystem
