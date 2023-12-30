local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local LogService = game:GetService("LogService")
local Network = require("Network")
-------------------
local Broker = {}
local Broker_mt = {__index = Broker}

--// A MQ system

function Broker.new()
	local object = {}
	object.Messages = Queue.new() -- From Unity
	setmetatable(object, Broker_mt)
	return object
end

function Broker:Add(msg)
	self.Messages:enqueue(msg)
end

function Broker:Dispatch()
	while self.Messages.size > 0 do
		--// Execute messages
		--// Might use Network to fire Messages
		local msg = self.Messages:dequeue()
		Network.Fire(msg.type, msg.receiver, unpack(msg.data))
	end
end


return Broker