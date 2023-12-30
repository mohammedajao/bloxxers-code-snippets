local Message = {}
local Message_mt = {__index = Message}

function Message.new()
	local object = {}
	object.ClassName = "UnityMessage"
	object.receiver = nil --// Enum
	object.type = nil --// Name
	object.data = {}
	setmetatable(Message, Message_mt)
	return object
end

return Message