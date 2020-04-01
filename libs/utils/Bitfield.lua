local class = require('../class')
local helpers = require('../helpers')

local reverse = string.reverse
local insert, concat = table.insert, table.concat
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local lshift = bit.lshift
local isInstance = class.isInstance
local checkNumber = helpers.checkNumber

local codec = {}
for n, char in ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('()(.)') do
	codec[n - 1] = char
end

local function checkBase(base)
	return checkNumber(base, 10, true, 2, 36)
end

local function checkLength(len)
	return checkNumber(len, 10, true, 1)
end

local function checkValue(value, base)
	base = base and checkBase(base) or 10
	return checkNumber(value, base, true, 0, 0x7FFFFFFF)
end

local function checkBit(bit)
	return checkNumber(bit, 10, true, 1, 31)
end

local Bitfield, property, method, get = class('Bitfield')

property('_value')

local function checkBitfield(obj)
	if isInstance(obj, Bitfield) then
		return obj.value
	end
	return error('cannot perform operation', 2)
end

function method:__init(v, base)
	self._value = v and checkValue(v, base) or 0
end

function method:__eq(other)
	return checkBitfield(self) == checkBitfield(other)
end

function method:__lt(other)
	return checkBitfield(self) < checkBitfield(other)
end

function method:__le(other)
	return checkBitfield(self) <= checkBitfield(other)
end

function method:__add(other)
	return Bitfield(checkBitfield(self) + checkBitfield(other))
end

function method:__sub(other)
	return Bitfield(checkBitfield(self) - checkBitfield(other))
end

function method:__mod(other)
	return Bitfield(checkBitfield(self) % checkBitfield(other))
end

function method:__mul(other)
	if tonumber(other) then
		return Bitfield(checkBitfield(self) * other)
	elseif tonumber(self) then
		return Bitfield(self * checkBitfield(other))
	else
		return error('cannot perform operation')
	end
end

function method:__div(other)
	if tonumber(other) then
		return Bitfield(checkBitfield(self) / other)
	elseif tonumber(self) then
		return error('division not commutative')
	else
		return error('cannot perform operation')
	end
end

function method:toString(base, len)
	local n = self.value
	local ret = {}
	base = base and checkBase(base) or 2
	len = len and checkLength(len) or 1
	while n > 0 do
		local r = n % base
		insert(ret, codec[r])
		n = (n - r) / base
	end
	while #ret < len do
		insert(ret, '0')
	end
	return reverse(concat(ret))
end

function method:toBin(len)
	return self:toString(2, len)
end

function method:toOct(len)
	return self:toString(8, len)
end

function method:toDec(len)
	return self:toString(10, len)
end

function method:toHex(len)
	return self:toString(16, len)
end

function method:enableBit(n) -- 1-indexed
	n = checkBit(n)
	return self:enableValue(lshift(1, n - 1))
end

function method:disableBit(n) -- 1-indexed
	n = checkBit(n)
	return self:disableValue(lshift(1, n - 1))
end

function method:toggleBit(n) -- 1-indexed
	n = checkBit(n)
	return self:toggleValue(lshift(1, n - 1))
end

function method:hasBit(n) -- 1-indexed
	n = checkBit(n)
	return self:hasValue(lshift(1, n - 1))
end

function method:enableValue(v, base)
	v = checkValue(v, base)
	self._value = bor(self._value, v)
end

function method:disableValue(v, base)
	v = checkValue(v, base)
	self._value = band(self._value, bnot(v))
end

function method:toggleValue(v, base)
	v = checkValue(v, base)
	self._value = bxor(self._value, v)
end

function method:hasValue(v, base)
	v = checkValue(v, base)
	return band(self._value, v) == v
end

function method:union(other) -- bits in either A or B
	return Bitfield(bor(checkBitfield(self), checkBitfield(other)))
end

function method:complement(other) -- bits in A but not in B
	return Bitfield(band(checkBitfield(self), bnot(checkBitfield(other))))
end

function method:difference(other) -- bits in A or B but not in both
	return Bitfield(bxor(checkBitfield(self), checkBitfield(other)))
end

function method:intersection(other) -- bits in both A and B
	return Bitfield(band(checkBitfield(self), checkBitfield(other)))
end

----

function get:value()
	return self._value
end

return Bitfield
