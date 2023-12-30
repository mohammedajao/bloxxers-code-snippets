-- REQUIRE USAGE:
--[[

local F = require(script.Parent:WaitForChild("F"))
local L, __, _1, _2, _3, _4, _5, _6, _7, _8 = F.L, F.__, unpack(F)

]]--

-- SUMMARY #####################################################################

-- Short lambdas module by BlueTaslem.
-- Defines short lambdas -- small, pure anonymous functions.

-- Normally, lambdas are made with anonymous functions:
-- local add = function(x, y) return x + y end

-- With short lambdas:
-- local add = L{_1 + _2}

-- LIMITATIONS: does not support <, >, ==, ~=, not, and, or, #.
-- DOES support function calls, indexing, method calls, +, *, /, -, %, .., ^.

-- Helper functions ease that:
-- L.eq, L.equal, L.equals, L["=="]:
-- L{ L.eq(_1, _2) }     is equivalent to     function(x, y) return x == y end
-- L.less, L["<"]
-- L.more, L[">"]
-- L["not"], L.Not, L["!"], L["~"]
-- L["and"], L.And
-- L["or"], L.Or

-- EXAMPLES ####################################################################

-- function() return 0 end
-- L{0}
-- 82% shorter!

-- function(x, y) return x + y end
-- L{_1 + _2}
-- 67% shorter!

-- function(x, y) return x + x / y end
-- L{_1 + _1 / _2}
-- 57% shorter!

-- function(a) return Vector3.new(0, a, 0) end
-- L{ __[Vector3.new](0, _1, 0) }
-- 30% shorter!

-- function(v) return v.unit end
-- L{_1.unit}
-- 65% shorter!

-- function(o) return o:Clone() end
-- function(o) return o.Clone(o) end
-- L{ _1:Clone() }
-- 53% shorter!

-- CODE ########################################################################
-- Not configurable. Do not change. --------------------------------------------

local meta = {}

-- Execute a lambda expression.
function force(x, ...)
	if isVariable(x) then
		if rawget(x, "raw") then
			return x.underlying
		else
			return x.underlying(...)
		end
	else
		return x
	end
end

local L = {}

function L.__call(_, x)
	assert(type(x) == "table" and isVariable(x[1]) and not isVariable(x),
		"usage of lambdas: L{_1 + _2}", 2)
	return function(...)
		return force(x[1], ...)
	end
end

function L.__index(_, key)
	key = key:lower()
	if key == "less" or key == "<" then
		local l = new(function(x, y) return x < y end)
		l.raw = true
		return l
	elseif key == "more" or key == ">" then
		local l = new(function(x, y) return x > y end)
		l.raw = true
		return l
	elseif key == "equal" or key == "equals" or key == "eq" or key == "==" then
		local l = new(function(x, y) return x == y end)
		l.raw = true
		return l
	elseif key == "not" or key == "~" or key == "!" then
		local l = new(function(x) return not x end)
		l.raw = true
		return l
	elseif key == "&" or key == "and" then
		local l = new(function(x, y) return x and y end)
		l.raw = true
		return l
	elseif key == "|" or key == "or" then
		local l = new(function(x, y) return x or y end)
		l.raw = true
		return l
	else
		error("no such key `" .. key .. "` on lambda maker", 2)
	end
end

setmetatable(L, L)

function isVariable(x)
	return getmetatable(x) == meta
end

function new(underlying, content)
	local t = {underlying = underlying, content = content or "?"}
	setmetatable(t, meta)
	return t
end

function meta.__tostring(x, hide)
	return "lambda[" .. x.content .. "]"
end

function meta.__index(left, right)
	-- left[right]
	return new(function(...)
		return force(left, ...)[force(right, ...)]
	end)
end

function meta.__add(left, right)
	return new(function(...) return force(left,...) + force(right,...) end,
		tostring(left) .. "+" .. tostring(right))
end

function meta.__mul(left, right)
	return new(function(...) return force(left, ...) * force(right, ...) end,
		tostring(left) .. "*" .. tostring(right))
end

function meta.__sub(left, right)
	return new(function(...) return force(left, ...) - force(right, ...) end,
		tostring(left) .. "-" .. tostring(right))
end

function meta.__mod(left, right)
	return new(function(...) return force(left, ...) % force(right, ...) end,
		tostring(left) .. "%" .. tostring(right))
end

function meta.__unm(arg)
	return new(function(...) return -force(arg, ...) end,
		"-" .. tostring(arg))
end

function meta.__div(left, right)
	return new(function(...) return force(left, ...) / force(right, ...) end,
		tostring(left) .. "/" .. tostring(right))
end

function meta.__concat(left, right)
	return new(function(...) return force(left, ...) .. force(right, ...) end,
		tostring(left) .. ".." .. tostring(right))
end

function meta.__pow(left, right)
	return new(function(...) return force(left, ...) ^ force(right, ...) end,
		tostring(left) .. "^" .. tostring(right))
end

function meta.__call(base, ...)
	local args = {...}
	return new(function(...)
		local baseF = force(base, ...)
		local t = {}
		for i, v in pairs(args) do
			t[i] = force(v, ...)
		end
		return baseF(unpack(t))
	end, "()")
end

-- Make variables to return
local _1 = new(function(a) return a end)
local _2 = new(function(_, b) return b end)
local _3 = new(function(_, _, c) return c end)
local _4 = new(function(_, _, _, d) return d end)
local _5 = new(function(_, _, _, _, e) return e end)
local _6 = new(function(_, _, _, _, _, f) return f end)
local _7 = new(function(_, _, _, _, _, _, g) return g end)
local _8 = new(function(_, _, _, _, _, _, _, h) return h end)

-- Constant helper:
-- L{__[x]} is a lambda taking no parameters and returning x:
-- L{__[math.sqrt](_1 + _2)} is a lambda for function(x, y) math.sqrt(x + y) end
-- Allows lazy computations on non-lambda expressions by turning them into
-- lambda expressions.
local __ = {}
function _f(x)
	local l = new(x, "__")
	l.raw = true
	return l
end
setmetatable(__, {__index = function(_, f) return _f(f) end})


-- TESTS #######################################################################

local a = L{_1}
assert(a(1) == 1)
assert(a(2) == 2)
assert(a(a) == a)

local b = L{_2 .. _1}
assert(b("cat", "tom") == "tomcat")
assert(b("", "") == "")

local c = L{__[math.sqrt](_1 + _2)}
assert(c(3, 1) == 2)
assert(c(1, 3) == 2)
assert(c(5, 8) == c(8, 5))

local d = L{_1[_2 + _3]}
assert(d({1, 2, 3}, 2, 1) == 3)
assert(d({7, 2, 3}, 3, -2) == 7)

function boxCopy(box)
	return Box(box.value)
end

function Box(value)
	return {value = value, copy = boxCopy}
end

local e = L{_1.value}
assert(e(Box(5)) == 5)
assert(e(Box(e)) == e)

local f = L{_1:copy()}
assert(f(Box(5)).value == 5)
local x = Box(7)
assert(f(x) ~= x)
assert(f(x).value == x.value)

local g = L{_1:sub(2, -2)}
assert(g("glass") == "las")

local h = L{  L.less(_1, _2)  }
assert(h(1, 2))
assert(not h(1, 1))
assert(not h(2, 1))

local i = L{ L.eq(_1, _2 + _3) }
assert(i(1, 2, -1))
assert(not i(1, 2, -2))

return {_1, _2, _3, _4, _5, _6, _7, _8; __=__, L = L}
