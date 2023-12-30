--- Helpers

local function rotate_indice(i, n)
    return ((i - 1) % n) + 1
end
-----

local CircularBuffer = {}
CircularBuffer.__index = CircularBuffer

CircularBuffer.metatable = {}
function CircularBuffer.metatable:__index(i)
	local length = #(self.items)
	if i == 0 or math.abs(i) > length then
        return nil
    elseif i >= 1 then
        local i_rotated = rotate_indice(self.oldest - i, length)
        return self.items[i_rotated]
    elseif i <= -1 then
        local i_rotated = rotate_indice(i + 1 + self.oldest, length)
        return self.items[i_rotated]
    end
end

function CircularBuffer.metatable:__len()
	return #(self.items)
end

function CircularBuffer:Filled()
	return #(self.items) == self.capacity
end

function CircularBuffer.new(capacity)
	if type(capacity) ~= "number" and capacity <= 1 then
		error("CircularBuffer - max_length must be a positive integer")
	end
	local object = setmetatable({capacity = capacity, oldest = 1}, CircularBuffer)
	return setmetatable(object, CircularBuffer.metatable)
end

function CircularBuffer:Read()
  if self.head == self.tail then error('CircularBuffer is empty') end
  self.tail = self.tail + 1
  return self.items[self.tail - 1]
end

function CircularBuffer:Write(item)
  if item == nil then return end
  if (self.head - self.tail) == self.capacity then error('CircularBuffer is full') end
  table.insert(self.items, self.head, item)
  self.head = self.head + 1
  self.oldest = self.oldest == self.capacity and 1 or self.oldest + 1
end

function CircularBuffer:Add(value)
    if self:Filled() then
        local value_to_be_removed = self.hitems[self.oldest]
        self.items[self.oldest] = value
        self.oldest = self.oldest == self.capacity and 1 or self.oldest + 1
    else
        self.items[#(self.items) + 1] = value
    end
end

function CircularBuffer:ForceWrite(item)
  if item == nil then return end
  if (self.head - self.tail) == self.capacity then self.tail = self.tail + 1 end
  self:Write(item)
end

function CircularBuffer:clear()
  self.items = {}
  self.head = 1
  self.tail = 1
end

return CircularBuffer