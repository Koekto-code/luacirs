local class = require "class"

local List = class (
{
	__init = function(self, cons)
		for i, v in ipairs(cons or {}) do
			self[i] = v
		end
	end,

	insert = table.insert,
	concat = table.concat,
	remove = table.remove,
	move = table.move,
	sort = table.sort,
	pack = table.pack,
	unpack = table.unpack,

	join = function(self, other)
		for _, v in ipairs(other) do
			self:insert(v)
		end
		return self
	end,

	find = function(self, value, begin)
		for i = begin or 1, #self do
			if self[i] == value then
				return i
			end
		end
	end,

	__concat = function(self, other)
		return class.base(self)(self):join(other)
	end,

	__tostring = function(self)
		local lst = {}
		for i, v in ipairs(self) do
			lst[i] = tostring(v)
		end
		return self:concat(", ")
	end
})

local elContact = class (
{
	__init = function(self, value, parent)
		self.value = value or 0 -- charge
		self.parent = parent
		self.capacity = 1
		self.cnt = List()
	end,
	connect = function(self, other, resistance)
		if self.cnt and other.cnt then
			self.cnt:join(other.cnt)
			other.cnt = self.cnt
		end
		self.cnt:insert({self, other, resistance or 1})
	end
})

local elCircuit = class (
{
	__init = function(self)
		self.pwr = elContact()
		self.gnd = elContact()
		self.cnt = {}
	end,

	index = function(self, elem)
		local new_contacts = List()
		for i, v in ipairs(elem.cnt) do
			if not self.cnt[v] then
				self.cnt[v] = true
				new_contacts:insert(v)
			end
		end
		for i, v in ipairs(new_contacts) do
			self:index(v[1])
			self:index(v[2])
		end
	end,

	run = function(self, dt)
		for k, v in pairs(self.cnt) do
			local diff = k[1].value - k[2].value

			local delta = diff * dt / k[3]
			if math.abs(delta * 2) > math.abs(diff) then
				delta = diff * 0.5
			end
			k[1].value = k[1].value - delta
			k[2].value = k[2].value + delta
		end
	end
})

local circuit = elCircuit()

local cnt1 = elContact()
cnt1:connect(circuit.gnd, 3) -- 3 Ohm-equivalents
cnt1:connect(circuit.pwr, 1) -- 1 Ohm-eq

circuit:index(circuit.gnd)

for i = 1, 20000 do
	circuit.pwr.value = 1 -- 1 Volt-eq
	circuit.gnd.value = 0
	circuit:run(0.001)
	if i % 1000 == 0 then
		print (
			"U1: " ..
			tostring(cnt1.value - circuit.gnd.value) ..
			" Volt-eq, U2: " ..
			tostring(circuit.pwr.value - cnt1.value) ..
			" Volt-eq"
		)
	end
end
