AES for Lua
===========

This files contain an implementation of AES in ComputerCraft (http://www.computercraft.info/) Lua.

Usage
-----

aeslua.lua contains a simple API to encrypt and decrypt lua strings.

To encrypt the string "geheim" with the password "password" use:
```lua
os.loadAPI("aeslua");
cipher = aeslua.encrypt("password", "secret");
```

and to decrypt the string again:
```lua
plain = aeslua.decrypt("password", cipher);
```

You can also specify the key size and the encryption mode. For further examples
look into the file [spec/cipher_spec.lua](https://github.com/SquidDev-CC/aeslua/blob/master/spec/cipher_spec.lua#L25-L26).

To use AES directly, have a look at [aeslua.lua](https://github.com/SquidDev-CC/aeslua/blob/master/aeslua.lua) and at the example usage in [spec/cipher_spec.lua](https://github.com/SquidDev-CC/aeslua/blob/master/spec/cipher_spec.lua#L25-L26).


Speed
-----

The implementation is rather optimized (it uses tables for most AES operations) 
but still cannot compete with AES written in other languages. Typical AES 
implementations reach several 100 MBit per second, this implementation only 
reaches 30 kB per second (245 kBit per second). The most plausible reason is the heavy reliance
of AES on bit operations. 

So if you need to encrypt much data with AES, do yourself a favor and use a 
C-Implementation. But if you only need to encrypt short strings and you have 
no control over the lua environment (like in games :-)) use this library.

Building
--------

AESLua is now build with [Howl](https://github.com/SquidDev-CC/Howl). Run `/Howl build` to build and run tests.
