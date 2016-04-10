-- Simple API for encrypting strings.
--
AES128 = 16
AES192 = 24
AES256 = 32

ECBMODE = 1
CBCMODE = 2
OFBMODE = 3
CFBMODE = 4

local function pwToKey(password, keyLength, iv)
	local padLength = keyLength
	if (keyLength == AES192) then
		padLength = 32
	end

	if (padLength > #password) then
		local postfix = ""
		for i = 1,padLength - #password do
			postfix = postfix .. string.char(0)
		end
		password = password .. postfix
	else
		password = string.sub(password, 1, padLength)
	end

	local pwBytes = {string.byte(password,1,#password)}
	password = ciphermode.encryptString(pwBytes, password, ciphermode.encryptCBC, iv)

	password = string.sub(password, 1, keyLength)

	return {string.byte(password,1,#password)}
end

--
-- Encrypts string data with password password.
-- password  - the encryption key is generated from this string
-- data      - string to encrypt (must not be too large)
-- keyLength - length of aes key: 128(default), 192 or 256 Bit
-- mode      - mode of encryption: ecb, cbc(default), ofb, cfb
--
-- mode and keyLength must be the same for encryption and decryption.
--
function encrypt(password, data, keyLength, mode, iv)
	assert(password ~= nil, "Empty password.")
	assert(password ~= nil, "Empty data.")

	local mode = mode or CBCMODE
	local keyLength = keyLength or AES128

	local key = pwToKey(password, keyLength, iv)

	local paddedData = util.padByteString(data)

	if (mode == ECBMODE) then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptECB, iv)
	elseif (mode == CBCMODE) then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCBC, iv)
	elseif (mode == OFBMODE) then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptOFB, iv)
	elseif (mode == CFBMODE) then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCFB, iv)
	else
		return nil
	end
end




--
-- Decrypts string data with password password.
-- password  - the decryption key is generated from this string
-- data      - string to encrypt
-- keyLength - length of aes key: 128(default), 192 or 256 Bit
-- mode      - mode of decryption: ecb, cbc(default), ofb, cfb
--
-- mode and keyLength must be the same for encryption and decryption.
--
function decrypt(password, data, keyLength, mode, iv)
	local mode = mode or CBCMODE
	local keyLength = keyLength or AES128

	local key = pwToKey(password, keyLength, iv)

	local plain
	if (mode == ECBMODE) then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptECB, iv)
	elseif (mode == CBCMODE) then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCBC, iv)
	elseif (mode == OFBMODE) then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptOFB, iv)
	elseif (mode == CFBMODE) then
		plain = ciphermode.decryptString(key, data, ciphermode.decryptCFB, iv)
	end

	result = util.unpadByteString(plain)

	if (result == nil) then
		return nil
	end

	return result
end
