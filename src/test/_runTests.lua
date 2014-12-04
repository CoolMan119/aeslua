local options = {
	traceback = false
}

-- Load in aeslua, prefered to using os.loadAPI
local aeslua = setmetatable({}, { __index = getfenv() })
setfenv(loadfile(shell.resolve("../aeslua")), aeslua)()

local function pcallFile(file)
	local code = loadfile(file)

	if not code then
		return false, "Does not exist"
	end

	local env = setmetatable({ aeslua = aeslua }, { __index = getfenv() })
	setfenv(code, env)

	local success = true
	local messages = ""
	xpcall(code, function(message)
		success = false
		messages = message

		if options.traceback then
			for i =4, 15, 1 do
				local s, err = pcall(function() error("", i) end)

				if err:match("xpcall") then break end
				messages = messages .. "\n    Trace: ".. err
			end
		end
	end)

	return success, messages
end


local function runTests(tests)
	local dir = fs.getDir(shell.getRunningProgram())
	local results = {}

	for _, file in ipairs(tests) do
		print("==" .. file .. "==")
		local stat, err = pcallFile(fs.combine(dir, file))
		results[file] = {stat, err}

		sleep(0)
	end

	return results
end

local function formatResults(results)
	local total = 0
	local fails = 0

	for file, results in pairs(results) do
		local status, err = unpack(results)
		if term.isColor() then
			if status then
				term.setTextColor(colors.green)
			else
				term.setTextColor(colors.red)
			end
		end

		print(file)

		if not status then
			print(" - " .. tostring(err))
			fails = fails + 1
		end

		total = total + 1
	end
	term.setTextColor(colors.white)

	print(string.format("Ran %s tests, %s failed", total, fails))
end

local tests = {
	"aesspeed.lua",
	"testaes.lua",
	"testciphers.lua"
}

local args = {...}
if #args > 0 then
	local customTests = {}
	for _, arg in ipairs(args) do
		if arg == "-t" then
			options.traceback = true
		else
			table.insert(customTests, arg)
		end
	end

	if #customTests > 0 then
		tests = customTests
	end
end

formatResults(runTests(tests))