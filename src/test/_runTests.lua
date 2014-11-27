local function pcallFile(file)
	local code = loadfile(file)

	if not code then
		return false, "Does not exist"
	end

	setfenv(code, getfenv())

	return pcall(code)
end


local function runTests(tests)
	local dir = fs.getDir(shell.getRunningProgram())
	local results = {}

	for _, file in ipairs(tests) do
		print("==" .. file .. "==")
		local stat, err = pcallFile(fs.combine(dir, file))
		results[file] = {stat, err}

		os.queueEvent("test")
		os.pullEvent("test")
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

formatResults(runTests(tests))