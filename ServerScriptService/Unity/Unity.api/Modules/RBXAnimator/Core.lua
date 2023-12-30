-- RBXAnimator version 3.0 - The Tween (almost) Anything Library
-- Written by FriendlyBiscuit; with help from Digpoe/FiniteReality

-- Flags
LEGACY_MODE = true

-- Code
local RBXAnimator	= { Timeline = { } }

local Data			= script:WaitForChild("Data")
local Plugins		= script:WaitForChild("Plugins")
local RunService	= game:GetService("RunService")

local DefaultStyles	= require(Data:WaitForChild("EasingModule"))
local PropertyLib	= require(Data:WaitForChild("PropertyModule"))
local ThreadData	= { }

-- _TickStep(lua_int Duration, lua_function Callback)
-- Forces an operation to complete over time, not frames.
-- Performs a callback, passing the following arguments (in order):
-- lua_int Ratio: How far the task is in percentage (0 to 1). Use this for animations.
-- lua_int Elapsed: How long the task has actually taken.
function _TickStep(Duration, Thread, Property, Guid, Callback)
	local Time = 0
	local LastTime = 0
	local Delta = 0
	
	while Time < Duration do
		if Thread[Property] > Guid then break end
		LastTime = tick()
		RunService.RenderStepped:wait()
		
		Delta = tick() - LastTime
		Time = Time + Delta
		
		--print(Time / Duration, Time)
		Callback(Time / Duration , Time)
	end
	
	Callback(1, Time)
end

function _Tween(Object, Property, Target, Style, Duration, Callback, Guid)
	assert(type(Object) ~= "table", "The ::method version of RBXAnimator is not longer supported. Use a dot instead!")
	assert(Object and Property and Target and Duration, "Failed to tween; cannot tween a nil object, property, time, or end value.")
	assert(DefaultStyles[Style], "Failed to tween; cannot tween with a nil easing type.")
	
	if PropertyLib.IsUDim2(Target) then
		local Thread = ThreadData[Object]
		local Begin = Object[Property]
		
		if Begin ~= Target then
			_TickStep(Duration, Thread, Property, Guid, function(Ratio, Elapsed)
				if Object and Object.Parent == nil then return end
				if Thread[Property] > Guid then return end
				
				Object[Property] = UDim2.new(
					DefaultStyles[Style](Elapsed, Begin.X.Scale, (Target.X.Scale - Begin.X.Scale), Duration),
					DefaultStyles[Style](Elapsed, Begin.X.Offset, (Target.X.Offset - Begin.X.Offset), Duration),
					DefaultStyles[Style](Elapsed, Begin.Y.Scale, (Target.Y.Scale - Begin.Y.Scale), Duration),
					DefaultStyles[Style](Elapsed, Begin.Y.Offset, (Target.Y.Offset - Begin.Y.Offset), Duration)
				)
			end)
		end
		
		Object[Property] = Target
		ThreadData[Target] = nil
		if Callback then Callback() end
	elseif PropertyLib.IsCFrame(Target) then
		local Thread = ThreadData[Object]
		local Begin = Object[Property]
		local x, y, z, xx, xy, xz, yx, yy, yz, zx, zy, zz = Begin:components()
		local xe, ye, ze, xxe, xye, xze, yxe, yye, yze, zxe, zye, zze = Target:components()
		
		if Begin ~= Target then
			_TickStep(Duration, Thread, Property, Guid, function(Ratio, Elapsed)
				if Object and Object.Parent == nil then return end
				if Thread[Property] > Guid then return end
				
				Object[Property] = CFrame.new(
					DefaultStyles[Style](Elapsed, x, (xe - x), Duration),
					DefaultStyles[Style](Elapsed, y, (ye - y), Duration),
					DefaultStyles[Style](Elapsed, z, (ze - z), Duration),
					DefaultStyles[Style](Elapsed, xx, (xxe - xx), Duration),
					DefaultStyles[Style](Elapsed, xy, (xye - xy), Duration),
					DefaultStyles[Style](Elapsed, xz, (xze - xz), Duration),
					DefaultStyles[Style](Elapsed, yx, (yxe - yx), Duration),
					DefaultStyles[Style](Elapsed, yy, (yye - yy), Duration),
					DefaultStyles[Style](Elapsed, yz, (yze - yz), Duration),
					DefaultStyles[Style](Elapsed, zx, (zxe - zx), Duration),
					DefaultStyles[Style](Elapsed, zy, (zye - zy), Duration),
					DefaultStyles[Style](Elapsed, zz, (zze - zz), Duration)
				)
			end)
		end
		
		Object[Property] = Target
		ThreadData[Target] = nil
		if Callback then Callback() end
	elseif PropertyLib.IsVector3(Target) then
		local Thread = ThreadData[Object]
		local Begin = Object[Property]
		
		if Begin ~= Target then
			_TickStep(Duration, Thread, Property, Guid, function(Ratio, Elapsed)
				if Object and Object.Parent == nil then return end
				if Thread[Property] > Guid then return end
				
				Object[Property] = Vector3.new(
					DefaultStyles[Style](Elapsed, Begin.X, (Target.X - Begin.X), Duration),
					DefaultStyles[Style](Elapsed, Begin.Y, (Target.Y - Begin.Y), Duration),
					DefaultStyles[Style](Elapsed, Begin.Z, (Target.Z - Begin.Z), Duration)
				)
			end)
		end
		
		Object[Property] = Target
		ThreadData[Target] = nil
		if Callback then Callback() end
	elseif PropertyLib.IsColor3(Target) then
		local Thread = ThreadData[Object]
		local Begin = Object[Property]
		
		if Begin ~= Target then
			_TickStep(Duration, Thread, Property, Guid, function(Ratio, Elapsed)
				if Object and Object.Parent == nil then return end
				if Thread[Property] > Guid then return end
				
				Object[Property] = Color3.new(
					(Begin.r ~= Target.r and DefaultStyles[Style](Elapsed, Begin.r, (Target.r - Begin.r), Duration)) or Target.r,
					(Begin.g ~= Target.g and DefaultStyles[Style](Elapsed, Begin.g, (Target.g - Begin.g), Duration)) or Target.g,
					(Begin.b ~= Target.b and DefaultStyles[Style](Elapsed, Begin.b, (Target.b - Begin.b), Duration)) or Target.b
				)
			end)
		end
		
		Object[Property] = Target
		ThreadData[Target] = nil
		if Callback then Callback() end
	else
		local Thread = ThreadData[Object]
		local Begin = Object[Property]
		
		if Begin ~= Target then
			_TickStep(Duration, Thread, Property, Guid, function(Ratio, Elapsed)
				if Object and Object.Parent == nil then return end
				if Thread[Property] > Guid then return end
				
				Object[Property] = DefaultStyles[Style](Elapsed, Begin, (Target - Begin), Duration)
			end)
		end
		
		Object[Property] = Target
		ThreadData[Target] = nil
		if Callback then Callback() end
	end
end


function _RunTimeline(Self)
	if Self.Running then return end
	
	if Self.Waypoints and #Self.Waypoints > 0 then
		Self.Running = true
		for Index, Waypoint in pairs (Self.Waypoints) do
			if type(Waypoint) ~= "function" then
				if Waypoint[7] and Waypoint[7] > 0 then wait(Waypoint[7]) end
				
				if Waypoint[6] then
					--print(Waypoint[1], Waypoint[2], Waypoint[3], Waypoint[4], Waypoint[5])
					RBXAnimator.TweenAsync(Waypoint[1], Waypoint[2], Waypoint[3], Waypoint[4], Waypoint[5])
				else
					RBXAnimator.Tween(Waypoint[1], Waypoint[2], Waypoint[3], Waypoint[4], Waypoint[5])
				end
			else
				Waypoint()
			end
		end
		
		Self.Running = false
	else
		warn("!!! Failed to run timeline; no waypoints.")
	end
end

function RBXAnimator.Timeline.new(Timeline)
	return {
		Waypoints = Timeline and Timeline or { };
		Running = false;
		Start = function(Self)
			_RunTimeline(Self)
		end;
		StartAsync = function(Self)
			spawn(function()
				_RunTimeline(Self)
			end)
		end
	}
end

function RBXAnimator.Tween(Object, Property, Target, Style, Duration, Callback)
	local Guid = tick()
	if ThreadData[Object] then
		ThreadData[Object][Property] = Guid
	else
		ThreadData[Object] = { [Property] = Guid }
	end
	
	_Tween(Object, Property, Target, Style, Duration, Callback, Guid)
end

function RBXAnimator.TweenAsync(Object, Property, Target, Style, Duration, Callback)
	local Guid = tick()
	if ThreadData[Object] then
		ThreadData[Object][Property] = Guid
	else
		ThreadData[Object] = { [Property] = Guid }
	end
	
	spawn(function() _Tween(Object, Property, Target, Style, Duration, Callback, Guid) end)
end

if LEGACY_MODE then
	function RBXAnimator.TweenRender(Object, Property, Target, Style, Duration, Callback)
		local Guid = tick()
		if ThreadData[Object] then
			ThreadData[Object][Property] = Guid
		else
			ThreadData[Object] = { [Property] = Guid }
		end
		
		_Tween(Object, Property, Target, Style, Duration, Callback, Guid)
	end
	
	function RBXAnimator.TweenRenderAsync(Object, Property, Target, Style, Duration, Callback)
		local Guid = tick()
		if ThreadData[Object] then
			ThreadData[Object][Property] = Guid
		else
			ThreadData[Object] = { [Property] = Guid }
		end
		
		spawn(function() _Tween(Object, Property, Target, Style, Duration, Callback, Guid) end)
	end
	
	function RBXAnimator:LoadPlugin(Name)
		local Plugin = Plugins:FindFirstChild(Name)
		if Plugin then
			RBXAnimator[Name] = require(Plugin)
		end
	end
end

function RBXAnimator:Import(Name)
	local Plugin = Plugins:FindFirstChild(Name)
	if Plugin then
		RBXAnimator[Name] = require(Plugin)
	end
end

function RBXAnimator:GenerateEnvironmentThread()
	print("Not yet implemented;", "GetEnvironmentThread()")
end

return RBXAnimator
