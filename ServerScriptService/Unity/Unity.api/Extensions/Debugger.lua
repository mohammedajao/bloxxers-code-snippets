local Unity = require(script.Parent.Parent)()

local Debugger = {}

local this = script.Parent.Parent
local Network = require("Network")

function Debugger:StackTrace(level, max_level, max_tail_calls)
	level = level + 2
	if max_level == nil then
		max_level = math.huge
	else
		max_level = max_level + 2
	end
	max_tail_calls = max_tail_calls or 10
	local trace = {}
	local num_tail_calls = 0
	while level <= max_level and num_tail_calls <= max_tail_calls do
		local success, error_message = xpcall(function() error("-", level + 1) end, function(...) return ... end)
		if error_message == "-" then
			num_tail_calls = num_tail_calls + 1
		else
			if num_tail_calls > 0 then
				local trace_size = #trace
				if trace_size > 0 then
					trace[#trace][3] = num_tail_calls
				end
				num_tail_calls = 0
			end
			local script, line = string.match(error_message, "(.*):(%d+)")
			trace[#trace + 1] = {script, tonumber(line), 0}
		end
		level = level + 1
	end
	return trace
end



return Debugger
