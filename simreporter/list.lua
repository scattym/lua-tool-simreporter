--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 31/12/17
-- Time: 11:39 AM
-- To change this template use File | Settings | File Templates.
--
local logging = require("logging")

local logger = logging.create("list", 30)

local List = {}
List.__index = List -- failed table lookups on the instances should fallback to the class table, to get methods

setmetatable(List, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
  end,
})

function List:_init(max_length)
    -- return {first = 0, last = -1 }
    if not max_length then
        max_length = 10
    end
    self.first = 0
    self.last = -1
    self.count = 0
    self.max_length = max_length
    return self

end

function List:check_length_and_maybe_delete()
    if self.count > self.max_length then
        self:pop_right()
    end
end

function List:push_left(value)
    self.count = self.count + 1
    self:check_length_and_maybe_delete()
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function List:push_right(value)
    self.count = self.count + 1
    self:check_length_and_maybe_delete()
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function List:pop_left()
    local first = self.first
    if first > self.last then error("list is empty") end
    local value = self[first]
    self[first] = nil                -- to allow garbage collection
    self.first = first + 1
    self.count = self.count - 1
    return value
end

function List:pop_right()
    local last = self.last
    if self.first > last then error("list is empty") end
    local value = self[last]
    self[last] = nil                 -- to allow garbage collection
    self.last = last - 1
    self.count = self.count - 1
    return value
end

function List:length()
    return self.count
end

function List:print()
    print("##################")
    for i=self.first,self.last do
        print(self[i])
    end
end

-------------------- Aged List --------------------
--local AgedList = {}
--AgedList.__index = AgedList
--
--setmetatable(AgedList, {
--  __index = List, -- this is what makes the inheritance work
--  __call = function (cls, ...)
--    local self = setmetatable({}, cls)
--    self:_init(...)
--    return self
--  end,
--})
--
--function AgedList:_init(max_length)
--  List:_init(max_length) -- call the base class constructor
--end
--
--function AgedList:get_value()
--  return self.value + self.value2
--end

return {
  List = List,
}