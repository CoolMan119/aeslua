local Sources = Dependencies(CurrentDirectory)
Sources:Main "aeslua.lua"
	:Depends "ciphermode"
	:Depends "util"

Sources:File "lib/aes.lua"
	:Name "aes"
	:Depends "bit"
	:Depends "gf"
	:Depends "util"

Sources:File "lib/bit.lua"    :Name "bit"    :Export(false)
Sources:File "lib/buffer.lua" :Name "buffer" :Export(false)

Sources:File "lib/ciphermode.lua"
	:Name "ciphermode"
	:Depends "aes"
	:Depends "buffer"
	:Depends "util"

Sources:File "lib/gf.lua"
	:Name "gf"
	:Depends "bit"
	:Export(false)

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
Tasks:Default "build"

Tasks:gist "upload" (function(spec)
	spec:summary "Pure Lua AES encryption (https://github.com/SquidDev-CC/aeslua)"
	spec:gist "86925e07cbabd70773e53d781bd8b2fe"
	spec:from "build" {
		include = { "aeslua.lua", "aeslua.min.lua" }
	}
end) :Requires { "build/aeslua.lua", "build/aeslua.min.lua" }
