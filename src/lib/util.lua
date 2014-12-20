-- Cache some bit operators
local bxor = bit.bxor
local rshift = bit.rshift
local band = bit.band
local lshift = bit.lshift

local sleepCheckIn
--
-- calculate the parity of one byte
--
local function byteParity(byte)
	byte = bxor(byte, rshift(byte, 4))
	byte = bxor(byte, rshift(byte, 2))
	byte = bxor(byte, rshift(byte, 1))
	return band(byte, 1)
end

--
-- get byte at position index
--
local function getByte(number, index)
	if (index == 0) then
		return band(number,0xff)
	else
		return band(rshift(number, index*8),0xff)
	end
end


--
-- put number into int at position index
--
local function putByte(number, index)
	if (index == 0) then
		return band(number,0xff)
	else
		return lshift(band(number,0xff),index*8)
	end
end

--
-- convert byte array to int array
--
local function bytesToInts(bytes, start, n)
	local ints = {}
	for i = 0, n - 1 do
		ints[i] = putByte(bytes[start + (i*4)    ], 3)
				+ putByte(bytes[start + (i*4) + 1], 2)
				+ putByte(bytes[start + (i*4) + 2], 1)
				+ putByte(bytes[start + (i*4) + 3], 0)

		if n % 10000 == 0 then sleepCheckIn() end
	end
	return ints
end

--
-- convert int array to byte array
--
local function intsToBytes(ints, output, outputOffset, n)
	n = n or #ints
	for i = 0, n do
		for j = 0,3 do
			output[outputOffset + i*4 + (3 - j)] = getByte(ints[i], j)
		end

		if n % 10000 == 0 then sleepCheckIn() end
	end
	return output
end

--
-- convert bytes to hexString
--
local function bytesToHex(bytes)
	local hexBytes = ""

	for i,byte in ipairs(bytes) do
		hexBytes = hexBytes .. string.format("%02x ", byte)
	end

	return hexBytes
end

--
-- convert data to hex string
--
local function toHexString(data)
	local type = type(data)
	if (type == "number") then
		return string.format("%08x",data)
	elseif (type == "table") then
		return bytesToHex(data)
	elseif (type == "string") then
		local bytes = {string.byte(data, 1, #data)}

		return bytesToHex(bytes)
	else
		return data
	end
end

local function padByteString(data)
	local dataLength = #data

	local random1 = math.random(0,255)
	local random2 = math.random(0,255)

	local prefix = string.char(random1,
							   random2,
							   random1,
							   random2,
							   getByte(dataLength, 3),
							   getByte(dataLength, 2),
							   getByte(dataLength, 1),
							   getByte(dataLength, 0))

	data = prefix .. data

	local paddingLength = math.ceil(#data/16)*16 - #data
	local padding = ""
	for i=1,paddingLength do
		padding = padding .. string.char(math.random(0,255))
	end

	return data .. padding
end

local function properlyDecrypted(data)
	local random = {string.byte(data,1,4)}

	if (random[1] == random[3] and random[2] == random[4]) then
		return true
	end

	return false
end

local function unpadByteString(data)
	if (not properlyDecrypted(data)) then
		return nil
	end

	local dataLength = putByte(string.byte(data,5), 3)
					 + putByte(string.byte(data,6), 2)
					 + putByte(string.byte(data,7), 1)
					 + putByte(string.byte(data,8), 0)

	return string.sub(data,9,8+dataLength)
end

local function xorIV(data, iv)
	for i = 1,16 do
		data[i] = bxor(data[i], iv[i])
	end
end

-- Called every
local push, pull, time = os.queueEvent, coroutine.yield, os.time
local oldTime = time()
local function sleepCheckIn()
    local newTime = time()
    if newTime - oldTime >= 0.03 then -- (0.020 * 1.5)
        oldTime = newTime
        push("sleep")
        pull("sleep")
    end
end

return {
	byteParity = byteParity,
	getByte = getByte,
	putByte = putByte,
	bytesToInts = bytesToInts,
	intsToBytes = intsToBytes,
	bytesToHex = bytesToHex,
	toHexString = toHexString,
	padByteString = padByteString,
	properlyDecrypted = properlyDecrypted,
	unpadByteString = unpadByteString,
	xorIV = xorIV,

	sleepCheckIn = sleepCheckIn,
}