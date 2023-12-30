local Unity = {}

--// Initialization

local this = script
local Files = {"ClientAssets","Classes","Enums","GlobalData","Listeners","Modules","Utility"}

local Flags = require(this.GlobalData:WaitForChild("InternalFlags"))
local ExtensionsLoaded = false

for index, value in pairs (Files) do
	this:WaitForChild(value)
end

local DataStructures = require(this.Utility:WaitForChild("DataStructures"))

--// Functions

local function CopyTable(root)
	local Copy = { }
	for Index,Value in pairs (root) do
		Copy[Index] = Value
	end
	return Copy
end

local function DeepCopyTable(Root)
	local Copy = { }
	
	if type(Root) == "table" then
		for Index, Value in next, Root, nil do
			Copy[DeepCopyTable(Index)] = DeepCopyTable(Value)
		end
		
		setmetatable(Copy, DeepCopyTable(getmetatable(Root)))
	else
		Copy = Root
	end
	
	return Copy
end

local foldl_call = function(fun, start, state, ...)
    if state == nil then
        return nil, start
    end
    return state, fun(start, ...)
end

--// Eh, was looking up multipler inheritance
--// This isn't used yet for the global context so w/e
-- look up for `k' in list of tables `plist'
local function parentalSearch (k, plist)
  for i=1, #plist do
    local v = plist[i][k]     -- try `i'-th superclass
    if v then return v end
  end
end


--// Main

return function()
	for index, value in pairs(DataStructures) do
		getfenv(2)[index] = value
	end
	getfenv(2)["collect"] = function(f)
	 	-- This collects globals defined in the given function.
 	 	local collector = setmetatable({}, {__index = _G})
  		-- Call function in collector environment
  		setfenv(f, collector)()
  		-- Extract collected variables.
  		local result = {}; for k,v in pairs(collector) do result[k] = v end
 		 return result
	end
	getfenv(2)["table"] = {
		length = function(structure) 
					local count = 0 
					for index,value in pairs (structure) do 
						count = count + 1 
					end 
					return count 
		end;
		dictionaryLength = function(dict)
			local count = 0
			for k,v in pairs(dict) do
				count = count + 1
			end
			return count
		end;
		copy = function(originalTable) return CopyTable(originalTable) end;
		deepCopy = function(originalTable) return DeepCopyTable(originalTable) end;
		find = function(structure, value)
			for Index,Value in pairs (structure) do
				if structure[Index] == value then
					return Index
				end
			end
		end;
		binarySearch = function(structure, value)
			local lowestIndex = 1
			local highestIndex = #structure
			while(lowestIndex <= highestIndex) do
				local middle = math.floor((lowestIndex + highestIndex)/2)
				if structure[middle] == value then
					return middle
				elseif structure[middle] > value then
					highestIndex = middle - 1
				elseif structure[middle] < value then
					lowestIndex = middle + 1
				end
			end
			return nil
		end;
		remove_if = function(func, arr)
		  local new_array = {}
		  for _,v in arr do
		    if not func(v) then table.insert(new_array, v) end
		  end
		  return new_array
		end;
		map = function(array, func)
			local new_array = {}
			for i,v in ipairs(array) do
				new_array[i] = func(v)
			end
			return new_array
		end;
	}
	setmetatable(getfenv(2)["table"], {__index = table})
	--[[
		
local foldl_call = function(fun, start, state, ...)
    if state == nil then
        return nil, start
    end
    return state, fun(start, ...)
end
	--]]
	
	getfenv(2)["reduce"] = function(fun, start, gen_x, param_x, state_x)
	    while true do
	        state_x, start = foldl_call(fun, start, gen_x(param_x, state_x))
	        if state_x == nil then
	            break;
	        end
	    end
	    return start
	end
	
	getfenv(2)["range"] = function (i, to, inc)
	    if i == nil then return end -- range(--[[ no args ]]) -> return "nothing" to fail the loop in the caller
	
	   if not to then
	       to = i 
	       i  = to == 0 and 0 or (to > 0 and 1 or -1) 
	   end 
	
	   -- we don't have to do the to == 0 check
	   -- 0 -> 0 with any inc would never iterate
	   inc = inc or (i < to and 1 or -1) 
	
	   -- step back (once) before we start
	   i = i - inc 
	
	   return function () if i == to then return nil end i = i + inc return i, i end 
	end 
	
	getfenv(2)["any"] = function(iterable)
		for key,value in pairs(iterable) do
			if value then
				return true
			end
		end
		return false
	end
	
	getfenv(2)["require"] = function(Target)
		if type(Target) == ("userdata" or "number")  then
			return require(Target)
		end
		if type(Target) == "string" then
			local Module = require(this.Modules:WaitForChild(Target))
			return Module
		end
	end
	
	if Flags.DEBUG_VAR then
		getfenv(2)["print"] = function(...)
			local name = getfenv(2).script.Name
			if name ~= "Log" then
				print(getfenv(2).script.Name, " => ", ...)
			else
				print(...)
			end
		end
	else
		getfenv(2)["print"] = function() print("Unity API - Disabled Feature[LogSystem].") end
	end
	
	if Flags.EXT_INSTANCES then
		getfenv(2)["Instance"] = {
			new = function(Class,...)
				local Result = this.Classes:FindFirstChild(Class, true)
				if Result and Result.ClassName == "ModuleScript" then
					local Data = require(Result)
					return Data.new(...)
				else
					return Instance.new(Class,...)
				end
			end
		}
	end
	
	if Flags.EXT_ENUMS then
		local Old = Enum -- Old enums
		local New = { } -- New enums or the table we'll use for those values
		for Index,Child in pairs (this.Enums:GetChildren()) do
			New[Child.Name] = require(Child) -- Settings the enums to be accessed through "Enum.NameOfEnum" etc.
		end
		
		setmetatable(New,{__index = Old}) -- We'll need the old enums so we place them as a metatable for usage.
		-- The above will return the old enums if they're indexed/requested, preserving them.
		getfenv(2)["Enum"] = New -- We set our our new "Enum" access identifier in exchange for the old one.
	end
	
	if not ExtensionsLoaded then
		ExtensionsLoaded = true
		for Index, Child in pairs (this.Extensions:GetChildren()) do
			local Data = require(Child)
			for Index, Value in pairs (Data) do
				Unity[Index] = Value
			end
		end
	end
	
	return Unity
end
