local util = aeslua.util

local function printQuiet(...) end
if Verbose then printQuiet = Verbose end -- Use verbose from Howl

math.randomseed(os.time())

local function testCrypto(password, data)
    local modes ={aeslua.ECBMODE, aeslua.CBCMODE, aeslua.OFBMODE, aeslua.CFBMODE};
    local keyLengths =  {aeslua.AES128, aeslua.AES192, aeslua.AES256};

    for i, mode in ipairs(modes) do
        for j, keyLength in ipairs(keyLengths) do
            printQuiet("--");
            cipher = aeslua.encrypt(password, data, keyLength, mode);
            printQuiet("Cipher: ", util.toHexString(cipher));
            plain = aeslua.decrypt(password, cipher, keyLength, mode);
            printQuiet("Mode: ", mode, " keyLength: ", keyLength, " Plain: ", plain);
            printQuiet("--");

            util.sleepCheckIn()
        end
    end
end

testCrypto("sp","hello world!");
testCrypto("longpasswordlongerthant32bytesjustsomelettersmore", "hello world!");
