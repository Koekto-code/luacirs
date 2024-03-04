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
		self.value = value or 0 -- charge, C
		self.parent = parent
		self.capacity = 0.1 -- F
		self.cnt = List()
	end,
	volts = function(self, newvalue)
		if not newvalue then
			return self.value / self.capacity
		end
		self.value = newvalue * self.capacity
	end,

	flow = function(self, other, current, dt)
		local delta = current * dt -- unit: C
		print("delta: " .. delta)
		print("before: " .. self.value .. ", " .. other.value)
		self.value = self.value - delta;
		other.value = other.value + delta;
		print("after: " .. self.value .. ", " .. other.value)
	end,

	connect = function(self, other, resistance)
		if self.cnt and other.cnt then
			self.cnt:join(other.cnt)
			other.cnt = self.cnt
		end
		self.cnt:insert({self, other, resistance or 0.001})
	end
})

local elCoil = class (
{
	__init = function(self, ind, res)
		self.cnt = {
			elContact(0, self),
			elContact(0, self)
		}
		self.resist = res or 1 -- Ohm
		self.induct = ind or 1 -- self-inductivity, H
		self.value = 0 -- magnetic flux, Wb
	end,
	run = function(self, dt)
		local v = self.cnt[1]:volts() - self.cnt[2]:volts()
		self.value = self.value + v * dt
		local cur = self.value / self.induct
		self.cnt[1]:flow(self.cnt[2], cur, dt)
	end
})

local elCircuit = class (
{
	__init = function(self)
		self.pwr = elContact()
		self.gnd = elContact()
		self.elements = List()
		self.cnt = {}
	end,

	index = function(self, contact, elem)
		if elem then
			for i, v in ipairs(elem.cnt) do
				self:index(v)
			end
			return
		elseif not contact then
			for i, v in ipairs(self.elements) do
				self:index(nil, v)
			end
			self:index(self.gnd)
			self:index(self.pwr)
			return
		end
		local new_contacts = List()
		for i, v in ipairs(contact.cnt) do
			if not self.cnt[v] then
				self.cnt[v] = v
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
			local v = k[1]:volts() - k[2]:volts()

			local cur = v / k[3]
			-- print("current: " .. cur .. ", v: " .. v)
			k[1]:flow(k[2], cur, dt)
		end
		for i, v in ipairs(self.elements) do
			v:run(dt)
		end
	end,

	addElem = function(self, el)
		self.elements:insert(el)
	end
})

local circuit = elCircuit()

local coil = elCoil(0.01)
coil.cnt[1]:connect(circuit.gnd, 0.01)
coil.cnt[2]:connect(circuit.pwr, 0.01)

circuit:addElem(coil)
circuit:index()

circuit.pwr.value = 1
circuit.gnd.value = 0

g_current = 0

function runLoop()
	local dt = 0.001

	local charge = 0
	for k, v in pairs(circuit.cnt) do
		charge = charge + v[1].value
		charge = charge + v[2].value
	end
	-- print("charge: " .. charge)

	-- for i = 1, 50 do
		circuit:run(dt)
	-- end
	local cur = 0
	cur = cur + (circuit.pwr.value - 1)
	cur = cur + (0 - circuit.gnd.value)
	g_current = cur
	print("current: " .. cur)

	-- print("v2: " .. coil.cnt[2].value)
end

function checkVoltage()
	-- return (circuit.pwr.value - circuit.gnd.value);
	return g_current * -0.8 - 0.5
end

_G["List"] = List
_G["circuit"] = circuit
