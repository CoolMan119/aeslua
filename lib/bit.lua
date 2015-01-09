--[[
  (c) 2008-2011 David Manura. Licensed under the same terms as Lua (MIT)
  https://github.com/davidm/lua-bit-numberlua
]]

local floor = math.floor
local MOD = 2^32

local lshift, rshift -- forward declare

local function rshift(a,disp) -- Lua5.2 insipred
	if disp < 0 then return lshift(a,-disp) end
	return floor(a % MOD / 2^disp)
end

local function lshift(a,disp) -- Lua5.2 inspired
	if disp < 0 then return rshift(a,-disp) end
	return (a * 2^disp) % MOD
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
