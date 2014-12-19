--[[
	Performance checker for AES,
	Encrypts data 1000 times
]]

local aes = aeslua.aes

local function getRandomBits(bits)
	local result = {}

	for i=1,bits/8 do
		result[i] = math.random(0,255)
	end

	return result
end

local function AESspeed()
	key = getRandomBits(128)
	plaintext = getRandomBits(128)
	local n = 1000

	start = os.clock()
	keySched = aes.expandEncryptionKey(key)
	for i=1,n do
		aes.encrypt(keySched,plaintext)
	end
	endtime = os.clock()

	local kByte = (n*16)/1024
	local duration = endtime - start
	print(string.format("Encrypted %f kByte in %f sec", kByte, duration))
	print(string.format("kByte per second: %f", kByte/duration))
end

AESspeed()