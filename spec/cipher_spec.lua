describe('Check all cipher types', function()
	local aeslua, verbose, util

	aeslua = setmetatable({}, { __index = getfenv() })
	setfenv(loadfile(File "build/aeslua.lua"), aeslua)()
	util = aeslua.util

	local messages = {
		{"sp", "hello world!"},
		{"longpasswordlongerthant32bytesjustsomelettersmore", "hello world!"}
	}

	setup(function()
		math.randomseed(os.time())
	end)

	for _, modeName in ipairs({"ECBMODE", "CBCMODE", "OFBMODE", "CFBMODE"}) do
		local mode = aeslua[modeName]
		for _, keyLengthName in ipairs({"AES128", "AES192", "AES256"}) do
			it("Encrypt " .. modeName .. " " .. keyLengthName, function()
				for _, message in ipairs(messages) do
					local password, data = unpack(message)
					local keyLength = aeslua[keyLengthName]

					local cipher = aeslua.encrypt(password, data, keyLength, mode)
					local plain = aeslua.decrypt(password, cipher, keyLength, mode)

					assert.are.equal(plain, data)
				end
			end)
		end
	end
end)
