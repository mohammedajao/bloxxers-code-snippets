local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Network = require("Network")
local Log = require("Log")
---
local SubactionFactory = {}
local Subactions = script.Parent:WaitForChild("Subactions")
--// https://github.com/digiholic/universalSmashSystem/blob/master/engine/subaction.py

function SubactionFactory.new()
	local object = {
		initalized = false,
		subaction_dict = {},
		name_dict = {}
	}
	return setmetatable(object, {__index = SubactionFactory})
end

function SubactionFactory:Initialize(dir)
	--// We'll import all the subactions here
	--// We'll map them in the subaction dictionary
	if not dir then dir = Subactions end
	for _, module in ipairs(dir:GetChildren()) do
		if module.ClassName == "Folder" then
			self:Initialize(module)
		else
			Log.Write(Enum.LogLevel.Normal,Enum.LogSystem.StateSystem,"Mapping Transient Actions: " .. module.name)
			self.subaction_dict[module.name] = require(module)
		end
	end
	self.initialized = true
end

function SubactionFactory:GetSubaction(_name, ...)
	if not self.initialized then
		self:Initialize()
	end
	if self.subaction_dict[_name] then
		return self.subaction_dict[_name].new(...)
	end
end

function SubactionFactory:GetName(_subaction)
	if not self.initialized then
		self:Initialize()
	end
	for key, value in ipairs(self.subaction_dict) do
		if value == _subaction then
			return key
		end
	end
end

return SubactionFactory
