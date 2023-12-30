local Unity = require(script.Parent.Parent)()

local module = {} 

local this = script.Parent.Parent
local root = script

print("Network created")

for index, child in pairs (this.Listeners:GetChildren()) do
	child.Parent = root
	if child.ClassName:find("Function") then
		child.Name = "f__" .. child.Name
	elseif child.ClassName:find("Event") then
		child.Name = "e__" .. child.Name
	end
end

--[[ Info ]]--
--[[
	The client has a numerical value of 1.
	The server has a numerical value of 2.
	The local scripts in the API have a numerical value of 3.
	
	Invoke Function Explanation:
	It uses a RemoteFunction to allow data to be returned after the function
	is called. This server-client communication allows for shared data. The data returned is a callback from the 
	OnClientInvoke or OnServerInvoke methods which can be any value.
	
	Binding Function Explanation:
	When we want our remoteEvents/functions to execute a function, the binding functions allow us 
	to associate their respective jobs to their callbacks - thus binding a value to them.
	
	(E.G. We assign a remoteEvent the job to create a part. We use BindEvent to create it by placing
	the function in the callback parameter. The same with BindFunction but those are used to return
	values.)
	
	In a simplified sense, just study this script and understand remoteEvents/functions.
	
	MAJOR NOTE:
		*Binding a function/event via the client will not allow the function to be replicated or accessed by the server. 
		 Please ensure the function/event is manually created. The binding functions will still execute the callback.
	
--]]

function module.BindFunction(name, receiver, callback)
	local object = root:FindFirstChild("f__" .. name)
	
	if not object then
		if receiver == 1 or receiver == 2 then
			object = Instance.new("RemoteFunction", root)
			object.Name = "f__" .. name
		elseif receiver == 3 then
			object = Instance.new("BindableFunction", root)
			object.Name = "f__" .. name
		end
	end
	
	if receiver == 1 then
		object.OnClientInvoke = callback
	elseif receiver == 2 then
		object.OnServerInvoke = callback
	elseif receiver == 3 then
		object.OnInvoke = callback
	end
end

function module.BindEvent(name, receiver, callback)
	local object = root:FindFirstChild("e__" .. name)
	
	if not object then
		if receiver == 1 or receiver == 2 then
			object = Instance.new("RemoteEvent", root)
			object.Name = "e__" .. name
		elseif receiver == 3 then
			object = Instance.new("BindableEvent", root)
			object.Name = "e__" .. name
		end
	end
	
	local connection
	if receiver == 1 then
		connection = object.OnClientEvent:connect(callback)
	elseif receiver == 2 then
		connection = object.OnServerEvent:connect(callback)
	elseif receiver == 3 then
		connection = object.Event:connect(callback)
	end
	return object, connection -- Return the connection *just in case*
end

function module.Invoke(name, receiver, ...)
	local object = root:WaitForChild("f__" .. name)
	if receiver == 1 then
		return object:InvokeClient(...)
	elseif receiver == 2 then
		return object:InvokeServer(...)
	elseif receiver == 3 then
		return object:Invoke(...)
	end
end

function module.Fire(name, receiver, ...)
	local object = root:WaitForChild("e__" .. name)
	
	if receiver == 1 then
		return object:FireClient(...)
	elseif receiver == 2 then
		return object:FireServer(...)
	elseif receiver == 3 then
		return object:Fire(...)
	end
end


return module
