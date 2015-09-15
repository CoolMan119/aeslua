--[[
  (c) 2008-2011 David Manura. Licensed under the same terms as Lua (MIT)
  https://github.com/davidm/lua-bit-numberlua
]]

local floor = math.floor
local MOD = 2^32
local MODM = MOD-1

local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	function mt:__index(k)
		local v = f(k); t[k] = v
		return v
	end
	return t
end

local function make_bitop_uncached(t, m)
	local function bitop(a, b)
		local res,p = 0,1
		while a ~= 0 and b ~= 0 do
			local am, bm = a%m, b%m
			res = res + t[am][bm]*p
			a = (a - am) / m
			b = (b - bm) / m
			p = p*m
		end
		res = res + (a+b)*p
		return res
	end
	return bitop
end

local function make_bitop(t)
	local op1 = make_bitop_uncached(t,2^1)
	local op2 = memoize(function(a)
		return memoize(function(b)
			return op1(a, b)
		end)
	end)
	return make_bitop_uncached(op2, 2^(t.n or 1))
end

local bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}

local function bnot(a)   return MODM - a end

local function band(a,b) return ((a+b) - bxor(a,b))/2 end

local function bor(a,b)  return MODM - band(MODM - a, MODM - b) end

local lshift, rshift -- forward declare

local function rshift(a,disp) -- Lua5.2 insipred
	if disp < 0 then return lshift(a,-disp) end
	return floor(a % MOD / 2^disp)
end

local function lshift(a,disp) -- Lua5.2 inspired
	if disp < 0 then return rshift(a,-disp) end
	return (a * 2^disp) % MOD
end


local function arshift(x, disp) -- Lua5.2 inspired
	local z = rshift(x, disp)
	if x >= 0x80000000 then z = z + lshift(2^disp-1, 32-disp) end
	return z
end

local function bit_bxor(a, b, c, ...)
	return bxor(a % MOD, b % MOD) % MOD
end

return {
	-- bit operations
	bnot = bnot,
	band = band,
	bor  = bor,
	bxor = bit_bxor,
	rshift = rshift,
	lshift = lshift,
}