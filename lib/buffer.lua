local function new ()
	return {}
end

local function addString (stack, s)
	table.insert(stack, s)
end

local function toString (stack)
	return table.concat(stack)
end

return {
	new = new,
	addString = addString,
	toString = toString,
}
