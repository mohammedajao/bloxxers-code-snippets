local Unity = require(script.Parent.Parent)()

local Defaults = {}

local this = script.Parent.Parent
local Assets = this:WaitForChild("ClientAssets")
local Modules = this:WaitForChild("Modules")
local Network = require("Network")

function Defaults:LoadServerAsset(Asset, Root)
	if Asset == "__LIST" then
		return Network.Invoke("__reqa", Enum.Receiver.Server, "__LIST")
	end
	
	local Asset = Network.Invoke("__reqa",Enum.Receiver.Server, Asset)
	
	if Asset then
		Asset.Parent = Root and Root or Asset.Parent
		return Asset
	elseif Asset == nil then
		print("~The requested server asset is invalid.")
		return nil
	elseif Asset == "__DENIED" then
		print("~Server asset request has been denied.")
	end
end

function Defaults:LoadClientAsset(Asset, Root)
	local Asset = Assets:WaitForChild(Asset):Clone()
	Asset.Parent = Root and Root or Asset.Parent
	return Asset
end

function Defaults:LoadServerConfig(Name)
	return Network.Invoke("__reqcs", Enum.Receiver.Self, Name)
end

function Defaults:LoadClientConfig(Name)
	return Network.Invoke("__reqc", Enum.Receiver.Server, Name)
end

function Defaults:LoadLibrary(Name)
	return require(Modules:WaitForChild(Name))
end

function Defaults:GetDebugStatus()
	return require(this:WaitForChild("GlobalData"):WaitForChild("InternalFlags")).DEBUG_VAR
end

function Defaults:Help()
	local message = [[
Unity API Tutorial:
		
	Method Explanations:
	- :LoadLibrary(<String>Library) method directly loads a library under Unity's modules
	- require(<String>Library) or require(<Integer>ModuleId) will require any module under Unity/ROBLOX if the argument is a string
	  or any module that is free on the site.
	- Classes are wrapped ROBLOX objects or any custom objects created by the developer.
	- Unity/Enums can be used to set custom Enums for your game. Each must be assigned a value.
	- Listeners includes all client-binded events or functions and default events or functions to be directly loaded into the Network
	  when the server starts.
	- ClientAssets are any assets the client should load initially.
	- Assets are any assets to be loaded upon request from the server or client.
	- Any module additions to the Unity/Extensions folder will be directly inherited into the API's functionality
	]]
	print(message)
end

function Defaults:GetVersion()
	return "$Unity Alpha Build (1.0.0)"
end

function Defaults:GetCredits()
	local message = require(this:WaitForChild("GlobalData"):WaitForChild("Credits"))
	print(message)
	return message
end

return Defaults
