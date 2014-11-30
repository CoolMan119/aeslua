--
-- Implementation of AES with nearly pure lua
--
-- AES with lua is slow, really slow :-)
--
--@name aes
--@require util.lua
--@require gf.lua
--@require bit.lua

local putByte = util.putByte
local getByte = util.getByte

-- some constants
local ROUNDS = 'rounds'
local KEY_TYPE = "type"
local ENCRYPTION_KEY=1
local DECRYPTION_KEY=2

-- aes SBOX
local SBox = {}
local iSBox = {}

-- aes tables
local table0 = {}
local table1 = {}
local table2 = {}
local table3 = {}

local tableInv0 = {}
local tableInv1 = {}
local tableInv2 = {}
local tableInv3 = {}

-- round constants
local rCon = {
	0x01000000, 
	0x02000000, 
	0x04000000, 
	0x08000000, 
	0x10000000, 
	0x20000000, 
	0x40000000, 
	0x80000000, 
	0x1b000000, 
	0x36000000,
	0x6c000000,
	0xd8000000,
	0xab000000,
	0x4d000000,
	0x9a000000,
	0x2f000000,
}

--
-- affine transformation for calculating the S-Box of AES
--
local function affinMap(byte)
	mask = 0xf8
	result = 0
	for i = 1,8 do
		result = bit.lshift(result,1)

		parity = util.byteParity(bit.band(byte,mask)) 
		result = result + parity

		-- simulate roll
		lastbit = bit.band(mask, 1)
		mask = bit.band(bit.rshift(mask, 1),0xff)
		if (lastbit ~= 0) then
			mask = bit.bor(mask, 0x80)
		else
			mask = bit.band(mask, 0x7f)
		end
	end

	return bit.bxor(result, 0x63)
end

--
-- calculate S-Box and inverse S-Box of AES
-- apply affine transformation to inverse in finite field 2^8 
--
local function calcSBox() 
	for i = 0, 255 do
	if (i ~= 0) then
		inverse = gf.invert(i)
	else
		inverse = i
	end
		mapped = affinMap(inverse)                 
		SBox[i] = mapped
		iSBox[mapped] = i
	end
end

--
-- Calculate round tables
-- round tables are used to calculate shiftRow, MixColumn and SubBytes 
-- with 4 table lookups and 4 xor operations.
--
local function calcRoundTables()
	for x = 0,255 do
		byte = SBox[x]
		table0[x] = putByte(gf.mul(0x03, byte), 0)
						  + putByte(             byte , 1)
						  + putByte(             byte , 2)
						  + putByte(gf.mul(0x02, byte), 3)
		table1[x] = putByte(             byte , 0)
						  + putByte(             byte , 1)
						  + putByte(gf.mul(0x02, byte), 2)
						  + putByte(gf.mul(0x03, byte), 3)
		table2[x] = putByte(             byte , 0)
						  + putByte(gf.mul(0x02, byte), 1)
						  + putByte(gf.mul(0x03, byte), 2)
						  + putByte(             byte , 3)
		table3[x] = putByte(gf.mul(0x02, byte), 0)
						  + putByte(gf.mul(0x03, byte), 1)
						  + putByte(             byte , 2)
						  + putByte(             byte , 3)
	end
end

--
-- Calculate inverse round tables
-- does the inverse of the normal roundtables for the equivalent 
-- decryption algorithm.
--
local function calcInvRoundTables()
	for x = 0,255 do
		byte = iSBox[x]
		tableInv0[x] = putByte(gf.mul(0x0b, byte), 0)
							 + putByte(gf.mul(0x0d, byte), 1)
							 + putByte(gf.mul(0x09, byte), 2)
							 + putByte(gf.mul(0x0e, byte), 3)
		tableInv1[x] = putByte(gf.mul(0x0d, byte), 0)
							 + putByte(gf.mul(0x09, byte), 1)
							 + putByte(gf.mul(0x0e, byte), 2)
							 + putByte(gf.mul(0x0b, byte), 3)
		tableInv2[x] = putByte(gf.mul(0x09, byte), 0)
							 + putByte(gf.mul(0x0e, byte), 1)
							 + putByte(gf.mul(0x0b, byte), 2)
							 + putByte(gf.mul(0x0d, byte), 3)
		tableInv3[x] = putByte(gf.mul(0x0e, byte), 0)
							 + putByte(gf.mul(0x0b, byte), 1)
							 + putByte(gf.mul(0x0d, byte), 2)
							 + putByte(gf.mul(0x09, byte), 3)
	end
end


--
-- rotate word: 0xaabbccdd gets 0xbbccddaa
-- used for key schedule
--
local function rotWord(word)
	local tmp = bit.band(word,0xff000000)
	return (bit.lshift(word,8) + bit.rshift(tmp,24)) 
end

--
-- replace all bytes in a word with the SBox.
-- used for key schedule
--
local function subWord(word)
	return putByte(SBox[getByte(word,0)],0) 
		+ putByte(SBox[getByte(word,1)],1) 
		+ putByte(SBox[getByte(word,2)],2)
		+ putByte(SBox[getByte(word,3)],3)
end

--
-- generate key schedule for aes encryption
--
-- returns table with all round keys and
-- the necessary number of rounds saved in [ROUNDS]
--
local function expandEncryptionKey(key)
	local keySchedule = {}
	local keyWords = math.floor(#key / 4)
   
 
	if ((keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8) or (keyWords * 4 ~= #key)) then
		print("Invalid key size: ", keyWords)
		return nil
	end

	keySchedule[ROUNDS] = keyWords + 6
	keySchedule[KEY_TYPE] = ENCRYPTION_KEY
 
	for i = 0,keyWords - 1 do
		keySchedule[i] = putByte(key[i*4+1], 3) 
					   + putByte(key[i*4+2], 2)
					   + putByte(key[i*4+3], 1)
					   + putByte(key[i*4+4], 0)  
	end    
   
	for i = keyWords, (keySchedule[ROUNDS] + 1)*4 - 1 do
		local tmp = keySchedule[i-1]

		if ( i % keyWords == 0) then
			tmp = rotWord(tmp)
			tmp = subWord(tmp)
			
			local index = math.floor(i/keyWords)
			tmp = bit.bxor(tmp,rCon[index])
		elseif (keyWords > 6 and i % keyWords == 4) then
			tmp = subWord(tmp)
		end
		
		keySchedule[i] = bit.bxor(keySchedule[(i-keyWords)],tmp)
	end

	return keySchedule
end

--
-- Inverse mix column
-- used for key schedule of decryption key
--
local function invMixColumnOld(word)
	local b0 = getByte(word,3)
	local b1 = getByte(word,2)
	local b2 = getByte(word,1)
	local b3 = getByte(word,0)
	 
	return putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b1), 
											 gf.mul(0x0d, b2)), 
											 gf.mul(0x09, b3)), 
											 gf.mul(0x0e, b0)),3)
		 + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b2), 
											 gf.mul(0x0d, b3)), 
											 gf.mul(0x09, b0)), 
											 gf.mul(0x0e, b1)),2)
		 + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b3), 
											 gf.mul(0x0d, b0)), 
											 gf.mul(0x09, b1)), 
											 gf.mul(0x0e, b2)),1)
		 + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b0), 
											 gf.mul(0x0d, b1)), 
											 gf.mul(0x09, b2)), 
											 gf.mul(0x0e, b3)),0)
end

-- 
-- Optimized inverse mix column
-- look at http://fp.gladman.plus.com/cryptography_technology/rijndael/aes.spec.311.pdf
-- TODO: make it work
--
local function invMixColumn(word)
	local b0 = getByte(word,3)
	local b1 = getByte(word,2)
	local b2 = getByte(word,1)
	local b3 = getByte(word,0)
	
	local t = bit.bxor(b3,b2)
	local u = bit.bxor(b1,b0)
	local v = bit.bxor(t,u)
	v = bit.bxor(v,gf.mul(0x08,v))
	w = bit.bxor(v,gf.mul(0x04, bit.bxor(b2,b0)))
	v = bit.bxor(v,gf.mul(0x04, bit.bxor(b3,b1)))
	
	return putByte( bit.bxor(bit.bxor(b3,v), gf.mul(0x02, bit.bxor(b0,b3))), 0)
		 + putByte( bit.bxor(bit.bxor(b2,w), gf.mul(0x02, t              )), 1)
		 + putByte( bit.bxor(bit.bxor(b1,v), gf.mul(0x02, bit.bxor(b0,b3))), 2)
		 + putByte( bit.bxor(bit.bxor(b0,w), gf.mul(0x02, u              )), 3)
end

--
-- generate key schedule for aes decryption
--
-- uses key schedule for aes encryption and transforms each
-- key by inverse mix column. 
--
local function expandDecryptionKey(key)
	local keySchedule = expandEncryptionKey(key)
	if (keySchedule == nil) then
		return nil
	end
	
	keySchedule[KEY_TYPE] = DECRYPTION_KEY    

	for i = 4, (keySchedule[ROUNDS] + 1)*4 - 5 do
		keySchedule[i] = invMixColumnOld(keySchedule[i])
	end
	
	return keySchedule
end

--
-- xor round key to state
--
local function addRoundKey(state, key, round)
	for i = 0, 3 do
		state[i] = bit.bxor(state[i], key[round*4+i])
	end
end

--
-- do encryption round (ShiftRow, SubBytes, MixColumn together)
--
local function doRound(origState, dstState)
	dstState[0] =  bit.bxor(bit.bxor(bit.bxor(
				table0[getByte(origState[0],3)],
				table1[getByte(origState[1],2)]),
				table2[getByte(origState[2],1)]),
				table3[getByte(origState[3],0)])

	dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
				table0[getByte(origState[1],3)],
				table1[getByte(origState[2],2)]),
				table2[getByte(origState[3],1)]),
				table3[getByte(origState[0],0)])
	
	dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
				table0[getByte(origState[2],3)],
				table1[getByte(origState[3],2)]),
				table2[getByte(origState[0],1)]),
				table3[getByte(origState[1],0)])
	
	dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
				table0[getByte(origState[3],3)],
				table1[getByte(origState[0],2)]),
				table2[getByte(origState[1],1)]),
				table3[getByte(origState[2],0)])
end

--
-- do last encryption round (ShiftRow and SubBytes)
--
local function doLastRound(origState, dstState)
	dstState[0] = putByte(SBox[getByte(origState[0],3)], 3)
				+ putByte(SBox[getByte(origState[1],2)], 2)
				+ putByte(SBox[getByte(origState[2],1)], 1)
				+ putByte(SBox[getByte(origState[3],0)], 0)

	dstState[1] = putByte(SBox[getByte(origState[1],3)], 3)
				+ putByte(SBox[getByte(origState[2],2)], 2)
				+ putByte(SBox[getByte(origState[3],1)], 1)
				+ putByte(SBox[getByte(origState[0],0)], 0)

	dstState[2] = putByte(SBox[getByte(origState[2],3)], 3)
				+ putByte(SBox[getByte(origState[3],2)], 2)
				+ putByte(SBox[getByte(origState[0],1)], 1)
				+ putByte(SBox[getByte(origState[1],0)], 0)

	dstState[3] = putByte(SBox[getByte(origState[3],3)], 3)
				+ putByte(SBox[getByte(origState[0],2)], 2)
				+ putByte(SBox[getByte(origState[1],1)], 1)
				+ putByte(SBox[getByte(origState[2],0)], 0)
end

--
-- do decryption round 
--
local function doInvRound(origState, dstState)
	dstState[0] =  bit.bxor(bit.bxor(bit.bxor(
				tableInv0[getByte(origState[0],3)],
				tableInv1[getByte(origState[3],2)]),
				tableInv2[getByte(origState[2],1)]),
				tableInv3[getByte(origState[1],0)])

	dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
				tableInv0[getByte(origState[1],3)],
				tableInv1[getByte(origState[0],2)]),
				tableInv2[getByte(origState[3],1)]),
				tableInv3[getByte(origState[2],0)])
	
	dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
				tableInv0[getByte(origState[2],3)],
				tableInv1[getByte(origState[1],2)]),
				tableInv2[getByte(origState[0],1)]),
				tableInv3[getByte(origState[3],0)])
	
	dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
				tableInv0[getByte(origState[3],3)],
				tableInv1[getByte(origState[2],2)]),
				tableInv2[getByte(origState[1],1)]),
				tableInv3[getByte(origState[0],0)])
end

--
-- do last decryption round
--
local function doInvLastRound(origState, dstState)
	dstState[0] = putByte(iSBox[getByte(origState[0],3)], 3)
				+ putByte(iSBox[getByte(origState[3],2)], 2)
				+ putByte(iSBox[getByte(origState[2],1)], 1)
				+ putByte(iSBox[getByte(origState[1],0)], 0)

	dstState[1] = putByte(iSBox[getByte(origState[1],3)], 3)
				+ putByte(iSBox[getByte(origState[0],2)], 2)
				+ putByte(iSBox[getByte(origState[3],1)], 1)
				+ putByte(iSBox[getByte(origState[2],0)], 0)

	dstState[2] = putByte(iSBox[getByte(origState[2],3)], 3)
				+ putByte(iSBox[getByte(origState[1],2)], 2)
				+ putByte(iSBox[getByte(origState[0],1)], 1)
				+ putByte(iSBox[getByte(origState[3],0)], 0)

	dstState[3] = putByte(iSBox[getByte(origState[3],3)], 3)
				+ putByte(iSBox[getByte(origState[2],2)], 2)
				+ putByte(iSBox[getByte(origState[1],1)], 1)
				+ putByte(iSBox[getByte(origState[0],0)], 0)
end

--
-- encrypts 16 Bytes
-- key           encryption key schedule
-- input         array with input data
-- inputOffset   start index for input
-- output        array for encrypted data
-- outputOffset  start index for output
--
local function encrypt(key, input, inputOffset, output, outputOffset) 
	--default parameters
	inputOffset = inputOffset or 1
	output = output or {}
	outputOffset = outputOffset or 1

	local state = {}
	local tmpState = {}
	
	if (key[KEY_TYPE] ~= ENCRYPTION_KEY) then
		print("No encryption key: ", key[KEY_TYPE])
		return
	end

	state = util.bytesToInts(input, inputOffset, 4)
	addRoundKey(state, key, 0)

	local checkIn = util.sleepCheckIn

	local round = 1
	while (round < key[ROUNDS] - 1) do
		-- do a double round to save temporary assignments
		doRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round + 1

		doRound(tmpState, state)
		addRoundKey(state, key, round)
		round = round + 1

		if round % 32 == 0 then
			checkIn()
		end
	end

	checkIn()
	
	doRound(state, tmpState)
	addRoundKey(tmpState, key, round)
	round = round +1

	doLastRound(tmpState, state)
	addRoundKey(state, key, round)
	
	return util.intsToBytes(state, output, outputOffset)
end

--
-- decrypt 16 bytes
-- key           decryption key schedule
-- input         array with input data
-- inputOffset   start index for input
-- output        array for decrypted data
-- outputOffset  start index for output
---
local function decrypt(key, input, inputOffset, output, outputOffset) 
	-- default arguments
	inputOffset = inputOffset or 1
	output = output or {}
	outputOffset = outputOffset or 1

	local state = {}
	local tmpState = {}

	if (key[KEY_TYPE] ~= DECRYPTION_KEY) then
		print("No decryption key: ", key[KEY_TYPE])
		return
	end

	state = util.bytesToInts(input, inputOffset, 4)
	addRoundKey(state, key, key[ROUNDS])

	local checkIn = util.sleepCheckIn

	local round = key[ROUNDS] - 1
	while (round > 2) do
		-- do a double round to save temporary assignments
		doInvRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round - 1

		doInvRound(tmpState, state)
		addRoundKey(state, key, round)
		round = round - 1

		if round % 32 == 0 then
			checkIn()
		end
	end

	checkIn()
	
	doInvRound(state, tmpState)
	addRoundKey(tmpState, key, round)
	round = round - 1

	doInvLastRound(tmpState, state)
	addRoundKey(state, key, round)
	
	return util.intsToBytes(state, output, outputOffset)
end

-- calculate all tables when loading this file
calcSBox()
calcRoundTables()
calcInvRoundTables()

return {
	ROUNDS = ROUNDS,
	KEY_TYPE = KEY_TYPE,
	ENCRYPTION_KEY = ENCRYPTION_KEY,
	DECRYPTION_KEY = DECRYPTION_KEY,

	expandEncryptionKey = expandEncryptionKey,
	expandDecryptionKey = expandDecryptionKey,
	encrypt = encrypt,
	decrypt = decrypt,
}