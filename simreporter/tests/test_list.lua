--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 21/2/18
-- Time: 11:28 PM
-- To change this template use File | Settings | File Templates.
--
require("tests/device_emulation")

local list_lib = require("list")

local list_instance = list_lib:List(5)

local value = list_instance:pop_left()

print(value)





