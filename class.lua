local make_class
make_class = function(...)
	local args = {...}
	if not #args then
		error("missing table")
	end

	local mt = {}

	for i, v in ipairs(args) do
		local src
		if i == #args then
			src = v
		else
			src = getmetatable(v)
		end
		for k, vv in pairs(src) do
			if k == "__index" and vv == src then
				-- the method is implicitly added
			else
				mt[k] = vv
			end
		end
	end

	if not mt.__index then
		mt.__index = mt
	end
	local init = mt.__init or function() end

	local template = {}
	setmetatable(template, {
		__call = function(_, ...)
			local inst = {}
			setmetatable(inst, mt)
			init(inst, ...)
			return inst
		end,
		__concat = function(self, other)
			return make_class(self, other)
		end,
		__metatable = mt
	})
	mt.template = template
	return template
end

local class = {}
local mt = {}
setmetatable(class, mt)

function mt.__call(_, ...)
	return make_class(...)
end

class.isSame = function(c, c1)
	-- @todo test
	return getmetatable(c) == getmetatable(c1)
end

class.base = function(c)
	return getmetatable(c).template
end

return class
