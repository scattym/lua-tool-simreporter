--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 28/10/17
-- Time: 2:27 PM
-- To change this template use File | Settings | File Templates.
--

-- utility.lua
-- ~~~~~~~~~~~
-- Please do not remove the following notices.
-- Copyright (c) 2011 by Geekscape Pty. Ltd.
-- Documentation: http://http://geekscape.github.com/mqtt_lua
-- License: AGPLv3 http://geekscape.org/static/aiko_license.html
-- Version: 0.2 2012-06-01
--
-- Notes
-- ~~~~~
-- - Works on the Sony PlayStation Portable (aka Sony PSP) ...
--     See http://en.wikipedia.org/wiki/Lua_Player_HM
--
-- ToDo
-- ~~~~
-- - shift_left() should mask bits past the 8, 16, 32 and 64-bit boundaries.
-- ------------------------------------------------------------------------- --

-- ------------------------------------------------------------------------- --
local logging = require("logging")
local logger = logging.create("mqtt_library", 30)

local debug_flag = false

local function set_debug(value) debug_flag = value end

local function debug(message)
  if (debug_flag) then logger(30, message) end
end

-- ------------------------------------------------------------------------- --

local function dump_string(value)
  local index

  for index = 1, string.len(value) do
    logger(30, string.format("%d: %02x", index, string.byte(value, index)))
  end
end

-- ------------------------------------------------------------------------- --

local timer

local function get_time()
    return os.clock()
end

local function expired(last_time, duration, type)
  local time_expired = get_time() >= (last_time + duration)

  if (time_expired) then debug("Event: " .. type) end
  return(time_expired)
end

-- ------------------------------------------------------------------------- --

local function shift_left(value, shift)
  return(value * 2 ^ shift)
end

local function shift_right(value, shift)
  return(math.floor(value / 2 ^ shift))
end

-- ------------------------------------------------------------------------- --

local function table_to_string(table)
  local result = ''

  if (type(table) == 'table') then
    result = '{ '

    for index = 1, #table do
      result = result .. table_to_string(table[index])
      if (index ~= #table) then
        result = result .. ', '
      end
    end

    result = result .. ' }'
  else
    result = tostring(table)
  end

  return(result)
end

-- ------------------------------------------------------------------------- --
-- Define Utility "module"
-- ~~~~~~~~~~~~~~~~~~~~~~~

local Utility = {}

Utility.set_debug = set_debug
Utility.debug = debug
Utility.dump_string = dump_string
Utility.get_time = get_time
Utility.expired = expired
Utility.shift_left = shift_left
Utility.shift_right = shift_right
Utility.table_to_string = table_to_string

-- For ... Utility = require("utility")

return(Utility)

-- ------------------------------------------------------------------------- --

