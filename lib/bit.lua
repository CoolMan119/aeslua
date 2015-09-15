--[[
	This bit API is designed to cope with unsigned integers instead of normal integers

	To do this we add checks for overflows: (x > 2^31 ? x - 2 ^ 32 : x)
	These are written in long form because no constant folding.
]]

local floor = math.floor

local bit_band, bit_bxor = bit.band, bit.bxor
local function band(a, b)
	if a > 2147483647 then a = a - 4294967296 end
	if b > 2147483647 then b = b - 4294967296 end
	return bit_band(a, b)
end

local function bxor(a, b)
	if a > 2147483647 then a = a - 4294967296 end
	if b > 2147483647 then b = b - 4294967296 end
	return bit_bxor(a, b)
end

local lshift, rshift

rshift = function(a,disp)
	return floor(a % 4294967296 / 2^disp)
end

lshift = function(a,disp)
	return (a * 2^disp) % 4294967296
end

return {
	-- bit operations
	bnot = bit.bnot,
	band = band,
	bor  = bit.bor,
	bxor = bxor,
	rshift = rshift,
	lshift = lshift,
}