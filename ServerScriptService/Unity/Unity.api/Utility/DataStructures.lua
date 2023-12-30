return {
	Stack = {
		new = function()
			getfenv(2)["Stack"].__index = getfenv(2)["Stack"]
			local stack = {}
			stack._size = 0
			return setmetatable(stack, getfenv(2)["Stack"])
		end;
		push = function(self, input)
			self[#self+1] = input
			self._size = self._size + 1
		end;
		pop = function(self)
			assert(#self > 0, "Stack underflow")
			local output = self[#self]
			self[#self] = nil
			self._size = self._size - 1
			return output
		end;
		clear = function(self)
			for k,v in pairs(self) do
		        self[k] = nil
			end
			self._size = 0
		end;
		peek = function(self)
			return self[self._size]
		end
	},
	Queue = {
		new = function()
			getfenv(2)["Queue"].__index = getfenv(2)["Queue"]
			return setmetatable({first = 0, last = -1, size = 0}, getfenv(2)["Queue"])
		end;
		enqueueFront = function(self, val)
			local first = self.first - 1
			self.first = first
			self[first] = val
			self.size = self.size + 1
		end;
		enqueue = function(self, val)
			local last = self.last + 1
			self.last = last
			self[last] = val
			self.size = self.size + 1
		end;
		dequeueFront = function(self)
			local first = self.first
			if first > self.last then error("Queue is empty") end
			local val = self[first]
			self[first] = nil
			self.first = first + 1
			self.size = self.size - 1
			return val
		end;
		dequeue = function(self)
			local last = self.last
			if self.first > last then error("Queue is empty") end
			local val = self[last]
			self[last] = nil
			self.last = last 
			self.size = self.size - 1
			return val
		end;
		peek = function(self)
			return self[self.first]
		end;
	}
}