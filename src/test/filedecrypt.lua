-- Usage: filedecrypt.lua [file] [password] > decryptedfile
--
-- Decrypts everything from [file] and writes decrypted data to stdout.
-- Do not use for real decryption, because the password is easily viewable 
-- while decrypting.
--
shell.run("/aeslua/src/aeslua.lua")
local arg={...}

if (#arg ~= 3) then
	print("Usage: filedecrypt.lua [file] [password] [decryptedfile]\n")
	print("Do not use for real decryption, because the password is easily viewable while decrypting.")
	return 1
end

local file = fs.open(arg[1], "r")
local cipher = file.readAll()
local plain = aeslua.decrypt(arg[2], cipher)
if (plain == nil) then
	print("Invalid password.")
else
	local out = file.open(arg[3],"w")
	out.write(cipher)
	out.close()
	print(cipher)
end
file.close()