describe('Tests encryption of large strings #performance #large', function()
	local aeslua

	setup(function()
		aeslua = setmetatable({}, { __index = getfenv() })
		setfenv(loadfile(File "build/aeslua.lua"), aeslua)()
	end)

	local function large(n)
		local key = aeslua.util.getRandomString(128)
		local plaintext = aeslua.util.getRandomString(n * 1024)

		local start = os.clock()
		aeslua.encrypt(key, plaintext)
		local time = os.clock() - start
		print(("%s in %s seconds: %skb/s"):format(n, time, n / time))
	end

	it('100kb', function()
		large(100)
	end)

	it('200kb', function()
		large(200)
	end)
end)
