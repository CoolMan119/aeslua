-- finite field with base 2 and modulo irreducible polynom x^8+x^4+x^3+x+1 = 0x11d
local bxor = bit.bxor
local lshift = bit.lshift

-- private data of gf
local n = 0x100
local ord = 0xff
local irrPolynom = 0x11b
local exp = {}
local log = {}

--
-- add two polynoms (its simply xor)
--
local function add(operand1, operand2) 
	return bxor(operand1,operand2)
end

-- 
-- subtract two polynoms (same as addition)
--
local function sub(operand1, operand2) 
	return bxor(operand1,operand2)
end

--
-- inverts element
-- a^(-1) = g^(order - log(a))
--
local function invert(operand)
	-- special case for 1 
	if (operand == 1) then
		return 1
	end
	-- normal invert
	local exponent = ord - log[operand]
	return exp[exponent]
end

--
-- multiply two elements using a logarithm table
-- a*b = g^(log(a)+log(b))
--
local function mul(operand1, operand2)
	if (operand1 == 0 or operand2 == 0) then
		return 0
	end
	
	local exponent = log[operand1] + log[operand2]
	if (exponent >= ord) then
		exponent = exponent - ord
	end
	return  exp[exponent]
end

--
-- divide two elements
-- a/b = g^(log(a)-log(b))
--
local function div(operand1, operand2)
	if (operand1 == 0)  then
		return 0
	end
	-- TODO: exception if operand2 == 0
	local exponent = log[operand1] - log[operand2]
	if (exponent < 0) then
		exponent = exponent + ord
	end
	return exp[exponent]
end

--
-- print logarithmic table
--
local function printLog()
	for i = 1, n do
		print("log(", i-1, ")=", log[i-1])
	end
end

--
-- print exponentiation table
--
local function printExp()
	for i = 1, n do
		print("exp(", i-1, ")=", exp[i-1])
	end
end

--
-- calculate logarithmic and exponentiation table
--
local function initMulTable()
	local a = 1

	for i = 0,ord-1 do
		exp[i] = a
		log[a] = i

		-- multiply with generator x+1 -> left shift + 1	
		a = bxor(lshift(a, 1), a)

		-- if a gets larger than order, reduce modulo irreducible polynom
		if a > ord then
			a = sub(a, irrPolynom)
		end
	end
end

initMulTable()

return {
	add = add,
	sub = sub,
	invert = invert,
	mul = mul,
	div = dib,
	printLog = printLog,
	printExp = printExp,
}