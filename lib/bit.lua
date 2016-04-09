--[[
	This bit API is designed to cope with unsigned integers instead of normal integers

	To do this we add checks for overflows: (x > 2^31 ? x - 2 ^ 32 : x)
	These are written in long form because no constant folding.
]]

local floor = math.floor

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
	band = bit.band,
	bor  = bit.bor,
	bxor = bit.bxor,
	rshift = rshift,
	lshift = lshift,
}
