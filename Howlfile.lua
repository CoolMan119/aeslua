Options:Default "trace"

local Sources = Dependencies(CurrentDirectory .. '/src')
Sources:Main "aeslua.lua"
	:Depends "ciphermode"
	:Depends "util"

Sources:File "lib/aes.lua"
	:Name "aes"
	:Depends "bit"
	:Depends "gf"
	:Depends "util"

Sources:File "lib/bit.lua"    :Name "bit"
Sources:File "lib/buffer.lua" :Name "buffer"

Sources:File "lib/ciphermode.lua"
	:Name "ciphermode"
	:Depends "aes"
	:Depends "buffer"
	:Depends "util"


Sources:File "lib/gf.lua"
	:Name "gf"
	:Depends "bit"

Sources:File "lib/util.lua"
	:Name "util"
	:Depends "bit"

Sources:Export(true)


Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/aeslua.lua", {"clean"})
Tasks:Minify("minify", "build/aeslua.lua", "build/aeslua.min.lua")

Tasks:Busted("test", {
	['exclude-tags'] = {'large'},
	env = {
		File = File,
		Verbose = Verbose,
		Log = Log,
	}
})
	:Requires "build/aeslua.lua"
	:Description "Run tests"

Tasks:Task "build"{"minify", "test"}
	:Description "Minify and test"