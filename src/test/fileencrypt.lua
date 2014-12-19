-- Usage: fileencrypt.lua [file] [password] > encryptedfile
--
-- Encrypts everything from [file] and writes encrypted data to stdout.
-- Do not use for real encryption, because the password is easily viewable
-- while encrypting.
--
os.unloadAPI("aeslua"); os.loadAPI(shell.resolve("../aeslua"))
local arg = {...}

if (#arg ~= 3) then
	print("Usage: fileencrypt.lua [file] [password] [encryptedfile]\n")
	print("Do not use for real encryption, because the password is easily viewable while encrypting.")
	return 1
end

local file = fs.open(arg[1], "r")
local text = file.readAll()
local cipher = aeslua.encrypt(arg[2], text)
file.close()

local out = fs.open(arg[3], "w")
out.write(cipher)
out.close()
