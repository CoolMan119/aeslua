--[[
	Encrypts 50kb worth of data
]]

local function getRandomString(bits)
	local result = ""

	for i=1,bits do
		result = result .. string.char(math.random(0,255))

		if i % 10240 == 0 then
			aeslua.util.sleepCheckIn()
		end
	end

	return result
end

local function AesLarge()
	local key = getRandomString(128)
	local n = 50
	local plaintext = getRandomString(n * 1024)

	local start = os.clock()
	aeslua.encrypt(key,plaintext)

	local duration = os.clock() - start
	print(string.format("Encrypted %f kByte in %f sec", n, duration))
	print(string.format("kByte per second: %f", n/duration))
end

AesLarge()