describe('Check all cipher types', function()
	local aeslua, verbose, util

	setup(function()
		math.randomseed(os.time())

		aeslua = setmetatable({}, { __index = getfenv() })
		loadfile(File "build/aeslua.lua", aeslua)()
		util = aeslua.util
	end)

	local messages = {
		{"sp", "hello world!"},
		{"longpasswordlongerthant32bytesjustsomelettersmore", "hello world!"}
	}

	for _, modeName in ipairs({"ECB", "CBC", "OFB", "CFB", "CTR"}) do
		describe("#" .. modeName, function()
			local mode = aeslua[modeName .. "MODE"]
			for _, keyLengthName in ipairs({"128", "192", "256"}) do
				describe("#" .. keyLengthName, function()
					local keyLength = aeslua["AES" .. keyLengthName]

					local iv = {}
					for i = 1, 16 do iv[i] = math.random(1, 255) end

					it("Encrypt", function()
						for _, message in ipairs(messages) do
							local password, data = unpack(message)

							local cipher = aeslua.encrypt(password, data, keyLength, mode, iv)
							local plain = aeslua.decrypt(password, cipher, keyLength, mode, iv)

							assert.are.equal(plain, data)
						end
					end)

					it("Multi Encrypt", function()
						for _, message in ipairs(messages) do
							local password, data = unpack(message)
							local keyLength = aeslua["AES" .. keyLengthName]

							local cipher1 = aeslua.encrypt(password, data, keyLength, mode, iv)
							local cipher2 = aeslua.encrypt(password, cipher1, keyLength, mode, iv)

							local plain2 = aeslua.decrypt(password, cipher2, keyLength, mode, iv)
							local plain1 = aeslua.decrypt(password, plain2, keyLength, mode, iv)

							assert.are.equal(plain1, data)
						end
					end)
				end)
			end
		end)
	end
end)
