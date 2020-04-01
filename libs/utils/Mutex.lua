local timer = require('timer')
local class = require('../class')
local helpers = require('../helpers')

local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running
local setTimeout = timer.setTimeout
local insert, remove = table.insert, table.remove
local checkNumber = helpers.checkNumber

local Mutex, property, method = class('Mutex')

property('_queue')
property('_active')

function method:__init()
	self._queue = {}
	self._active = false
end

function method:lock()
	if self._active then
		local thread = running()
		insert(self._queue, thread)
		return yield()
	else
		self._active = true
	end
end

function method:unlock()
	local thread = remove(self._queue, 1)
	if thread then
		return assert(resume(thread))
	else
		self._active = false
	end
end

function method:unlockAfter(delay)
	return setTimeout(checkNumber(delay, nil, nil, 0), self.unlock, self)
end

return Mutex
