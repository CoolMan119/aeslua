local function new ()
	return {}
end

local function addString (stack, s)
	table.insert(stack, s)
	for i = #stack - 1, 1, -1 do
		if #stack[i] > #stack[i+1] then 
				break
		end
		stack[i] = stack[i] .. table.remove(stack)
	end
end

local function toString (stack)
	for i = #stack - 1, 1, -1 do
		stack[i] = stack[i] .. table.remove(stack)
	end
	return stack[1]
end

return {
	new = new,
	addString = addString,
	toString = toString,
}