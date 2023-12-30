--TimeModule made by Merely, heavily modified by Usering.

local Time = {}

--[[
	Time.seconds(secs)
	Time.minutes(min) -- converts minutes to seconds
	Time.days(days) -- converts days to seconds
	Time.years(years)
	Time.now() -- os.time()
	Time.formatDate(secs) -- 
	Time.relative(secs) -- 3 months ago
	Time.isPast(secs) -- returns whether the time is in the past
--]]

local minutesPerHour = 60
local hoursPerDay = 24
local daysPerWeek = 7
local daysPerMonth = 30
local daysPerYear = 365.25
local secondsPerMinute = 60
local secondsPerHour = secondsPerMinute * minutesPerHour
local secondsPerDay = secondsPerHour * hoursPerDay
local secondsPerWeek = secondsPerDay * daysPerWeek
local secondsPerMonth = secondsPerDay * daysPerMonth
local secondsPerYear = secondsPerDay * daysPerYear

local regularYear = 365
local leapYear = 366

--[[NOLICAIK's Timestamp generator--]]
local ydays = {
	{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
	{31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
};
local days_abbrev = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
local months_abbrev = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

function gmtime_r(tsecs, tmbuf)
	local monthsize, yearsize
	local dayclock, dayno
	local year = 1970
	dayclock = math.floor(tsecs % secondsPerDay)
	dayno = math.floor(tsecs / secondsPerDay)
	tmbuf.sec = math.floor(dayclock % 60)
	tmbuf.min = math.floor((dayclock % secondsPerHour) / 60)
	tmbuf.hour = math.floor(dayclock / secondsPerHour)
	tmbuf.wday = math.floor((dayno + 4) % 7)
	yearsize = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and leapYear or regularYear
	while dayno >= yearsize do
		dayno = dayno - yearsize
		year = year + 1
		yearsize = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and leapYear or regularYear
	end
	tmbuf.year = year
	tmbuf.yday = dayno
	tmbuf.mon = 0
	monthsize = ydays[(year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 2 or 1][tmbuf.mon + 1]
	while dayno >= monthsize do
		dayno = dayno - monthsize
		tmbuf.mon = tmbuf.mon + 1
		monthsize = ydays[(year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 2 or 1][tmbuf.mon + 1]
	end
	tmbuf.mday = dayno + 1
	return tmbuf
end

function asctime(tmbuf)
	--return string.format("%s/%02u %02u:%02u", tmbuf.mon, tmbuf.mday, tmbuf.hour, tmbuf.min)
	local tdate = months_abbrev[tmbuf.mon+1] .. " " .. tmbuf.mday .. ", " .. tmbuf.year
	local ttime = (tmbuf.hour > 12 and ((tmbuf.hour-12 < 10 and "0" .. tmbuf.hour-12 or tmbuf.hour-12) .. ":" .. (tmbuf.min < 10 and "0" .. tmbuf.min or tmbuf.min) .. " PM")) or (tmbuf.hour < 10 and "0" .. tmbuf.hour or tmbuf.hour) .. ":" .. (tmbuf.min < 10 and "0" .. tmbuf.min or tmbuf.min) .. " AM"
	return tdate .. " @ " .. ttime,tmbuf.hour
end

function GMT(timestamp)
	return asctime(gmtime_r(timestamp, {}))
end

function Time.relative(stamp)
	local now = Time.now()
	local diff = Time.length(now - stamp)
	return diff .. ' ago'
end

function timeFormat(num, unitName)
	if num == 0 and (unitName == "day" or unitName == "hour" or unitName == "minute") then return "" end
	if (num == 1) then
		return tostring(num) .. ' ' .. unitName .. ''
	else
		return tostring(num) .. ' ' .. unitName .. 's'
	end
end

function Time.length(Seconds)
	local days = math.floor(Seconds/86400)
	Seconds = Seconds - (days * 86400)
	local hours = math.floor(Seconds/3600)
	Seconds = Seconds - (hours * 3600)
	local minutes = math.floor(Seconds/60)
	local seconds = Seconds - (minutes*60)
	--return timeFormat(days,"day") .. " " .. timeFormat(hours,"hour") .. " " .. timeFormat(minutes,"minute") .. " "..  timeFormat(seconds,"second")
	return days,hours,minutes,seconds
end

function Time.hour(timestamp)
	local date,hour = GMT(timestamp)
	return hour
end

function Time.seconds(seconds)
	return math.ceil( seconds  )
end

function Time.minutes(minutes)
	return math.ceil( minutes * secondsPerMinute )
end

function Time.days(days)
	return math.ceil( days * secondsPerDay  )
end

function Time.years(years)
	return math.ceil( secondsPerDay * daysPerYear * years )
end

function Time.now()
	return math.ceil( os.time() )
end

function Time.format(timestamp)
	return GMT(timestamp)
end

function Time.isPast(seconds)
	return (Time.now() > seconds)
end

return Time
