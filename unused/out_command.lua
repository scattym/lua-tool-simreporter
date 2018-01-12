--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 21/10/17
-- Time: 9:44 PM
-- To change this template use File | Settings | File Templates.
--

local _M = {}
local logging = require("logging")
local logger = logging.create("out_command", 0)
local lite_com = require("lite_com")

_M.MESSAGE_TYPE_NULL = 0
_M.MESSAGE_TYPE_JSON = 1

local wait_and_parse_loop = function(callback_table)
    local OUT_CMD_EVENT = 39
    local count = 0
    thread.setevtowner(OUT_CMD_EVENT,OUT_CMD_EVENT)
    while ( true ) do
        logger(30, "Waiting for an event")
        local evt, evt_param1, evt_param2, evt_param3, evt_clock = thread.waitevt(99999999);
        logger(30, "Out fo wait evt. evt: ", evt, " p1: ", evt_param1, " p2: ", evt_param2, " p3: ", evt_param3, " clock: ", evt_clock)
        if (evt >= 0) then
            count = count + 1
            logger(30, "(count=", count, ")", os.clock(), " event = ", evt)
            if ( evt == OUT_CMD_EVENT ) then
                logger(30, "Got out command event. p1: ", evt_param1, " p2:", evt_param2, " p3:", evt_param3, " clock:", evt_clock)
                local message_type, client_id, message = lite_com.parse_command(evt_param2, evt_param3)
                if message and callback_table[client_id] then
                    logger(0, "Got message: ", message)
                    callback_table[client_id](message)
                end
            else
                logger(30, "Got an event we are not waiting for: ", evt)
            end
        end
        collectgarbage()
    end
end
_M.wait_and_parse_loop = wait_and_parse_loop

return _M