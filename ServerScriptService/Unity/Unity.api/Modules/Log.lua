local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local LogService = game:GetService("LogService")
local Log = {}
local history = {}
local systems = {"Main","FileSystem","AnimationSystem","StateSystem","CommandSystem","SoundSystem","InputSystem","ActionSystem","PhysicsSystem"}

local function getCurrentLogTime()
	local os_time = os.date("*t", os.time())
	local timeperiod = "AM"
	if os_time.hour  > 12 then timeperiod = "PM" end 
	local logged_time = os_time.month .. "/" .. os_time.day .. "/" .. os_time.year .. " " .. (os_time.hour % 12) .. ":" .. os_time.min .. ":" .. os_time.sec .. timeperiod
	return logged_time .. " => "
end

local function fetchSystem(_s)
	if typeof(_s) ~= "number" then
		error("Do not give UnityLogger invalid LogSystem Enums", _s)
	end
	return "[" .. systems[_s] .. "]"
end

function Log.Record(...)
	table.insert(history, {...})
end

function Log.Write(_level, _system, msg, ...)
	_system = _system or 1
	local logged_time = getCurrentLogTime()
	local sys = fetchSystem(_system)
	if typeof(_level) == "string" then
		print(logged_time, sys, _level)
		return
	end
	if _level == 1 then
		print(logged_time, sys, msg, ...)
	elseif _level == 2 then
		warn(logged_time, sys, msg, ...)
	elseif _level == 3 then
		error(logged_time, 2, sys, msg, ...)
	end
end

function Log.Clear()
	history = {}
end

LogService.MessageOut:connect(Log.Record)

return Log