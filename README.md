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
look into the file src/testcryptotest.lua.

To use AES directly, have a look at aes.lua and at the example usage in 
`testaes.lua`.


Speed
-----

The implementation is rather optimized (it uses tables for most AES operations) 
but still cannot compete with AES written in other languages. Typical AES 
implementations reach several 100 MBit per second, this implementation only 
reaches 400 kBit per second. The most plausible reason is the heavy reliance
of AES on bit operations. As lua numbers are doubles bitlib needs to convert
them to long values for each bit operation.

So if you need to encrypt much data with AES, do yourself a favor and use a 
C-Implementation. But if you only need to encrypt short strings and you have 
no control over the lua environment (like in games :-)) use this library.

Building
--------

AESLua is now build with [PPI](https://gist.github.com/SquidDev/ebd1c11dfeb1c7abe38a). Run `Combiner.lua aeslua.lua aeslua`

Idealy I would like to port [Squish](http://matthewwild.co.uk/projects/squish/home) to CC but that can wait...