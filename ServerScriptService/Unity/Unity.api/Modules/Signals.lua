-- Signals Version 2 by BlueTaslem
-- A Functional-Reactive-Programming module.

-- ## LIBRARIES ####################################################
-- For your convenience, the Signals module provides a replacement
-- for the `math` library.
-- Use
--[[
	math = S.math
--]]
-- to be able to use `math` functions on Signals. For example,
--[[
	local x = S.Time
	wait(4)
	print( math.sqrt(x):get() ) -- 2
--]]

-- ## Signal T METHODS #############################################
-- signal:connect(fn)
--   RETURNS a connection with a `:disconnect` method.
--   Same effect as :connect on a ROBLOX Event

-- signal:get() :: -> T
--   RETURNS the value represented by the signal.
--   AVOID USE OF GET! See :map and :set instead.

-- signal:index(p)
--   RETURNS a signal representing signal:get()[p]
--   Fires as often as `signal`.

-- signal:getter() :: -> (-> T)
--   RETURNS a function equivalent to `function() return signal:get() end`.

-- signal:map(fn) :: (T -> X) -> Signal X
--   RETURNS a Signal representing a transformation over `signal` by `fn`
--   See Signals.Merge for transforming multiple signals together
--   See Signals.Max, Signals.Min for taking the minimum/maximum signal.
--   Result fires as often as `signal`.

-- signal:sort(fn) :: Signal[T]:sort (T, T -> boolean)? -> Signal[T]
--   RETURNS a Signal representing the transformation of `signal` being
--   sorted by comparator `fn`. Comparator takes the same form as the
--   second argument to `table.sort`.
--   If not specified, `fn` is `function(a, b) return a < b end`.
--   Fires as often as `signal`.

-- signal:smooth(kind, rate, damping) (enum, number, number) -> Signal X
--   RETURNS a Signal that is smoothed over time.
--   `kind` is one of
--   "exponential" -- exponential smoothing (fast start, slow stop)
--   - `rate` is multiplier
--   - `damping` unused
--   "linear" -- linear smoothing (fast start, fast stop)
--   - `rate` is X / second
--   - `damping` unused
--   "spring" -- springy smoothing (slow start, slow stop, overshoots target)
--   For motion that feels like it has inertia.
--   - `rate` is factor / second
--   - `damping` is factor / speed / second
--   This is sugar based on `:fold`.
--   Fires as often as possible.

-- signal:ifelse(positive, negative)
--   RETURNS a Signal representing either `positive` or `negative` based
--   on whether signal's value is truthy or falsy.
--   equivalent to
-- `signal:map(function(x) if x then return positive else return negative end end)`
--   Fires as often as `signal`.

-- signal:fold(fn, initial) :: (Y, T, time -> Y) -> Signal Y
--   RETURNS a Signal representing a transformation over time by `fn`.
--   fn(previousOut, currentIn, deltaTime)
--   `previousOut` is the previous value returned by `fn`
--   `currentIn` is the current value of `signal`
--   `deltaTime` is the time since `previousOut` was retrieved.
--   Useful for "smoothing" signals over time.
--   Ex.: Exponential smoothing
	--   signal:fold(function(last, now, dt)
	--		local w = math.exp(-dt * 4)
	--		return last * w + (1 - w) * now
	--	end, 0)
--  Fires as often as possible.

-- signal:set(object, property)
--   Updates `object[property]` to have the value of this signal.
--   Equivalent to `signal:connect(function(x) object[property] = x end)`

-- signal:filter(fun)
--   RETURNS a signal with the same underlying value. Only fires its
--   event when `signal` fires and when `fun` returns `true`.
--   For example, "time since health was low" might be
--   S.Since(
--		S.FromProperty(humanoid, "Health"):filter(function(x) return x < 10 end))

-- ## CONSTRUCTORS #################################################
-- Make new signals.

-- Signals.Timer() -> Signal seconds
--   RETURNS a Signal representing the number of seconds passed since
--   this function was called.
--   Fires as often as possible.

-- Signals.FromProperty(object, property) -> Signal
--   RETURNS a Signal representing `object[property]`.
--   Fires as often as possible.

-- Signals.FromChanged(instance, property) -> Signal
--   RETURNS a Signal representing `instance[property]`.
--   Fires whenever `instance`'s `Changed` fires for `property`.
--   NOT VALID ON IntValue, StringValue, etc.
--   WARNING: Will not fire for things changed by user input or
--   physics, e.g., .Position, .Target, .Hit, .Velocity.
--   See `Signals.FromProperty` instead.

-- Signals.FromFunction(fn) :: (-> X) -> Signal X
--   RETURNS a Signal representing `fn()`.
--   Fires as often as possible.

-- Signals.FromValue(value) :: X -> Signal X
--   RETURNS a Signal representing `value`.
--   Fires never.

-- Signals.Recent(events, initial?) :: [Event X], X? -> Signal X
--   RETURNS a Signal representing the most recent value emitted by
--   an event in `events`.
--   Fires whenever any Event in `events` fires.
--   If initial is nil, uses events[1]:get()

-- Signals.Since(event, initial=math.huge) :: Event, time? -> time
--   RETURNS a Signal representing the time (in seconds) since `event`
--   last fired.
--   Fires as often as possible.

-- Signals.Merge {sources} (fn)
-- Signals.Lift {sources} (fn)
-- :: [Signal X, Signal Y, ...] -> (X, Y, ... -> A) -> Signal A
--   RETURNS a Signal "merging" several signals together
--   Fires whenever any source Signal fires.

-- Signals.Max {sources} (less=(a < b))
-- :: [Signal X] -> (X, X -> boolean)?, (X -> Y)? -> Y
--   RETURNS a Signal representing the maximum value taken on by any source.
--   LESS: a function to compare the values of the sources, in the same fashion
--   as the second parameter to `table.sort`. By default it is `<`.
--   Fires whenever any source Signal fires.

-- Signals.Min {sources} (less=(a < b))
-- :: [Signal X] -> (X, X -> boolean)?, (X -> Y)? -> Y
--   RETURNS a Signal representing the minimum value taken on by any source.
--   LESS: a function to compare the values of the sources, in the same fashion
--   as the second parameter to `table.sort`. By default it is `<`.
--   Fires whenever any source Signal fires.


--------------------------------------------------------------------


local module = {}

module.math = {}
setmetatable(module.math, {__index = function(_, key)
		if math[key] then
			local f = math[key]
			if type(f) == "function" then
				return function(...)
					local t = {...}
					local signals = false
					for i, v in pairs(t) do
						if isSignal(v) then
							signals = true
						end
					end
					if not signals then
						return f(...)
					end
					-- There is a signal among.
					-- Convert non-signals to signals
					for i, v in pairs(t) do
						if not isSignal(v) then
							t[i] = module.FromValue(v)
						end
					end
					-- Lift:
					return module.Lift(t)(f)
				end
			end
			return math[key]
		else
			return nil
		end
	end,
	__newindex = function(_, key)
		error("cannot change math library", 2)
	end
})

function pause()
	if game.Players.LocalPlayer then
		return game:GetService("RunService").RenderStepped:wait()
	else
		return wait()
	end
end

--------------------------------------------------------------------

function isNaN(x)
	return not rawequal(x, x)
end

function healthy(...)
	assert(not isNaN(...))
	return ...
end

local SignalClass = {}
function SignalClass.connect(self, fn)
	local x = {f = fn}
	table.insert( self._connected, x )
	x.disconnect = function()
		for i = #self._connected, 1, -1 do
			if self._connected[i] == x then
				table.remove(self._connected, i)
				return
			end
		end
		error("already disconnected", 2)
	end
	return x
end

function SignalClass.min(self, value, less)
	less = less or function(a, b) return a < b end
	return self:map(function(x)
		if less(x, value) then
			return x
		else
			return value
		end
	end)
end

function SignalClass.max(self, value, less)
	less = less or function(a, b) return a < b end
	return self:map(function(x)
		if less(x, value) then
			return value
		else
			return x
		end
	end)
end

function SignalClass.ifelse(self, positive, negative)
	return self:map(function(x)
		if x then
			return positive
		else
			return negative
		end
	end)
end

-- PRIVATE
function SignalClass._fire(self)
	for _, ev in pairs(self._connected) do
		ev.f(self:get())
	end
end

-- TODO: finish me
function SignalClass.Destroy(self)
	self._connected = {}
	if self._destroy then
		self._destroy()
	end
end

function SignalClass.filter(self, fun)
	local signal = new(function() return self:get() end)
	self:connect(function(...) if fun(...) then signal:_fire() end end)
	return signal
end

function SignalClass.getter(self)
	return function() return self:get() end
end

-- (Signal X):just(Y) -> Signal Y
function SignalClass.just(self, val)
	local signal = new(function() return val end)
	self:connect(function() signal:_fire() end)
	return signal
end

-- (Signal X):map( X -> Y ) -> Signal Y
function SignalClass.map(self, fn)
	local signal = new(function() return fn(self:get()) end)
	self:connect(function() signal:_fire() end)
	return signal
end

function SignalClass.sort(self, fn)
	fn = fn or function(a, b) return a < b end
	return self:map(function(input)
		local t = {unpack(input)} -- copy
		table.sort(t, fn)
		return t
	end)
end

function SignalClass.index(self, property)
	return self:map(function(x)
		return x[property]
	end)
end

function SignalClass.smooth(self, kind, rate, damping, zero)
	local s
	if kind == "exponential" then
		s = self:fold(function(last, now, dt)
			local w = math.exp(-dt * rate) -- Exponential
			return last * w + (1 - w) * now
		end, self:get())
	elseif kind == "linear" then
		s = self:fold(function(last, now, dt)
			local change = rate * dt
			if last < now then
				local x = last + change
				if now < x then
					return now
				end
				return x
			elseif last == now then
				return now
			else
				local x = last - change
				if x < now then
					return now
				end
				return x
			end
		end)
	elseif kind == "spring" then
		zero = zero or 0
		local i = self:fold(function(last, target, dt)
			if dt + 1 <= dt then -- infinity
				return last 
			end
			local a = (target - last.x) * 40 * (rate or 1)
			a = a - last.v * 5 * (damping or 1)
			local n = {}
			n.v = last.v + dt * a
			n.x = last.x + (dt / 2) * (n.v + last.v)
			return n
		end, {x=self:get(),v=zero})
		s = i:index("x")
	else
		error("unknown smooth kind `" .. tostring(kind) .. "`", 2)
	end
	metronome(s)
	return s
end

-- (Signal X):map( Y, X, time -> Y ) -> Signal Y
function SignalClass.fold(self, fn, initial)
	local previous = initial
	local lastTime = -math.huge
	local dt
	local signal = new(function()
		local dt = tick() - lastTime
		return fn(previous, self:get(), dt)
	end)
	self:connect(function()
		signal:_fire()
		previous = signal:get()
		lastTime = tick()
	end)
	return signal
end

function SignalClass.set(self, object, property)
	self:connect(function(value)
		object[property] = value
	end)
end

function isSignal(s)
	return type(s) == type{}
		and getmetatable(s)
		and rawequal(getmetatable(s).class, SignalClass)
end

local function ver(s)
	if isSignal(s) then
		return s:get()
	else
		return s
	end
end

local function firer(sig, ...)
	for _, source in pairs{...} do
		if isSignal(source) then
			source:connect(function() sig:_fire() end)
		end
	end
	return sig
end

function __add(left, right)
	local s = new(function() return ver(left) + ver(right) end)
	return firer(s, left, right)
end

function __sub(left, right)
	local s = new(function() return ver(left) - ver(right) end)
	return firer(s, left, right)
end

function __mul(left, right)
	local s = new(function() return ver(left) * ver(right) end)
	return firer(s, left, right)
end

function __index(sig, key)
	local r = new(function() return sig:get()[ver(key)] end)
	return firer(r, sig, key)
end

function __unm(val)
	local s = new(function() return -val:get() end)
	return firer(s, val)
end

--------------------------------------------------------------------

function new(get)
	local t = {}
	t._connected = {}
	t._alive = true -- PRIVATE
	setmetatable(t, {
		__index = function(_, key)
			if key == "get" then
				return get
			elseif SignalClass[key] then
				return SignalClass[key]
			end
		end,
		__newindex = function()
			error("sigals are immutable", 2)
		end,
		class = SignalClass,
		__add = __add,
		__sub = __sub,
		__mul = __mul,
		__unm = __unm,
		--__index = __index, -- experimental. TODO: fuse with other __index
	})
	return t
end

-- PRIVATE
function metronome(signal)
	assert(signal)
	spawn(function()
		while signal._alive do
			pause()
			signal:_fire()
		end
	end)
end

--------------------------------------------------------------------

function module.FromProperty(object, property)
	local signal = new(function() return object[property] end)
	metronome(signal)
	return signal
end

function module.FromChanged(object, property)
	local signal = new(function() return object[property] end)
	object.Changed:connect(function(p)
		if p == property then
			signal:_fire()
		end
	end)
	return signal
end

function module.FromFunction(value)
	local signal = new(value)
	metronome(signal)
	return signal
end

function module.FromValue(value)
	return new(function() return value end)
end

function module.FromEvent(event, ...)
	local value = {...}
	local signal = new(function() return unpack(value) end)
	event:connect(function(...) value = {...}; signal:_fire(...) end)
	return signal
end

function module.Recent(events, ...)
	local value = {...}
	if ... == nil then
		value = {events[1]:get()}
	end
	local signal = new(function() return unpack(value) end)
	for _, event in pairs(events) do
		event:connect(function(...) value = {...}; signal:_fire(...) end)
	end
	return signal
end

function module.Since(event, initial)
	local start = tick() - (initial or math.huge)
	local signal = new(function() return tick() - start end)
	event:connect(function() start = tick() end)
	metronome(signal)
	return signal
end

function module.Lift(sources)
	return function(fn)
		local signal = new(function()
			local vs = {}
			for i = 1, #sources do
				vs[i] = sources[i]:get()
			end
			return fn(unpack(vs))
		end)
		for _, source in pairs(sources) do
			source:connect(function() signal:_fire() end)
		end
		return signal
	end
end
module.Merge = module.Lift -- alias

function lessthan(x, y)
	return x < y
end
function id(...)
	return ...
end

function module.Max(sources)
	return function(less)
		less = less or lessthan
		local signal = new(function()
			local best = nil
			local first = true
			for _, source in pairs(sources) do
				local v = source:get()
				if first or less(best, v) then
					first = false
					best = v
				end
			end
			return best
		end)
		for _, source in pairs(sources) do
			source:connect(function() signal:_fire() end)
		end
		return signal
	end
end

function module.Timer()
	local start = tick()
	local s = new(function() return tick() - start end)
	metronome(s)
	return s
end

function module.Min(sources)
	return function(less)
		less = less or lessthan
		local signal = new(function()
			local best = nil
			local first = true
			for _, source in pairs(sources) do
				local v = source:get()
				if first or less(v, best) then
					first = false
					best = v
				end
			end
			return best
		end)
		for _, source in pairs(sources) do
			source:connect(function() signal:_fire() end)
		end
		return signal
	end
end

-- STATIC OBJECTS --------------------------------------------------

module.Random = new(function() return math.random() end)
metronome(module.Random)

local start = tick()
module.Time = new(function() return tick() - start end)
metronome(module.Time)

-- TESTS -----------------------------------------------------------

local m = module.FromValue(4)
assert(module.math.sqrt(m):get() == 2)
assert(module.math.sqrt(4) == 2)
assert(m:get() == 4)
assert(m:map(function(x) return math.sqrt(x) end):get() == 2)
assert((-m):get() == -4)
assert((m + m):get() == 8)

return module