local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Log = require("Log")
---
local SubSystemManager = {}
local Systems = game.ReplicatedStorage:WaitForChild("Unity.Api"):WaitForChild("Classes"):WaitForChild("CustomClasses"):WaitForChild("Systems")
local LoadedSubSystems, LoadedMainSystems, Loaded = false, false, false
---// 

local function mediateLoadType(dir, dict)
	if not dict then dict = {} end
	for k,child in pairs(dir:GetChildren()) do
		if child.ClassName == "ModuleScript" then
			dict[child.Name] = Instance.new(child.Name)
			Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.Main, "Loading", dir.Name, ":", child.Name)
		elseif child.ClassName == "Folder" then
			 dict = mediateLoadType(child, dict)
		end
	end
	return dict
end


---------

function SubSystemManager:Initialize(_entity)
	self.subsystems = {}
	self.mainsysems = {}
	self.entity = _entity
	self:LoadAllSubSystems()
	self:LoadAllMainSystems()
	Loaded = true
end

function SubSystemManager:GetSubSystem(_name)
	if not Loaded then
		self:Initialize()
	end
	return self.subsystems[_name]
end

function SubSystemManager:GetMainSystem(_name)
	if not Loaded then
		self:Initialize()
	end
	return self.mainsystems[_name]
end

function SubSystemManager:LoadAllSubSystems()
	local folder = Systems:WaitForChild("SubSystems")
	self.subsystems = mediateLoadType(folder)
	for name,system in pairs(self.subsystems) do
		system:Initialize(self.entity)
	end
	LoadedSubSystems = true
end

function SubSystemManager:LoadAllMainSystems()
	local folder = Systems:WaitForChild("MainSystems")
	self.mainsystems = mediateLoadType(folder)
	for name,system in pairs(self.mainsystems) do
		system:Initialize(self.entity)
	end
	LoadedMainSystems = true
end


return SubSystemManager