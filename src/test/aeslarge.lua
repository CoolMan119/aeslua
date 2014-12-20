--[[
	Encrypts 50kb worth of data
]]

local function getRandomString(bits)
	local char, random, sleep = string.char, math.random, aeslua.util.sleepCheckIn
	local result = ""

	for i=1,bits do
		result = result .. char(random(0,255))

		if i % 10240 == 0 then
			sleep()
		end
	end

	return result
end

local function AesLarge()
	print("Generating string")

	local key = getRandomString(128)
	local n = 150
	local plaintext = getRandomString(n * 1024)

	print("Generated string")

	local start = os.clock()
	aeslua.encrypt(key,plaintext)

	local duration = os.clock() - start
	print(string.format("Encrypted %f kByte in %f sec", n, duration))
	print(string.format("kByte per second: %f", n/duration))
end

AesLarge()