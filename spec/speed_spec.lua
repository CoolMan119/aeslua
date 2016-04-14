describe('Performance checker for AES #performance', function()
	local aeslua, verbose

	setup(function()
		aeslua = setmetatable({}, { __index = getfenv() })
		loadfile(File "build/aeslua.lua", aeslua)()
		verbose = (Utils and Utils.Verbose) or Verbose or print
	end)

	it('1000', function()
		local n = 1000

		local key = aeslua.util.getRandomData(16)
		local keySched = aeslua.aes.expandEncryptionKey(key)
		local plaintext = aeslua.util.getRandomData(16)

		local encrypt = aeslua.aes.encrypt

		local start = os.clock()
		for _ = 1, n do
			encrypt(keySched, plaintext)
		end

		local kByte = (n*16)/1024
		local duration = os.clock() - start
		verbose(string.format("kByte per second: %g", kByte/duration))
	end)
end)
