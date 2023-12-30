local Class = {Name = ""}

function Class.new(InputObject)
	local object = InputObject or {}
	setmetatable(object, {__index = Class})
	return object
end

function Class:SetName(name)
	self.Name = name
	print(self.Name .. " has set its name successfully.")
end

return Class