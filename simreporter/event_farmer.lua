_M = {}

local config = require("config")
local util = require("util")
local logging = require("logging")
local logger = logging.create("event_farmer", 0)

local EVENT_CRITICAL_SECTION = config.get_config_value("CRITICAL_SECTION_EVENT_HANDLER")
local EVENT_HANDLER_TABLE = {}

--[[
--Must be called before the wait event thread is started
 ]]
local add_event_handler = function(event_id, event_func)
    thread.enter_cs(EVENT_CRITICAL_SECTION)
    EVENT_HANDLER_TABLE[event_id] = event_func
    thread.leave_cs(EVENT_CRITICAL_SECTION)
end
_M.add_event_handler = add_event_handler

local wait_for_event_thread = function()
    thread.enter_cs(EVENT_CRITICAL_SECTION)
    for key, value in pairs(EVENT_HANDLER_TABLE) do
        if value then
            thread.setevtowner(key, key)
        end
    end
    thread.leave_cs(EVENT_CRITICAL_SECTION)
    while (true) do
        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(150000);
        if (evt ~= -1) then
            logger(0, "waited event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock);
        end
        for key, value in pairs(EVENT_HANDLER_TABLE) do
            if evt == key and value ~= nil then
                local result = pcall(value, evt, evt_p1, evt_p2, evt_p3, evt_clock)
                logger(30, "event function callout result was: ", result)
            end
        end

    end
end
_M.wait_for_event_thread = wait_for_event_thread

local function event_handler_thread_wrapper()
    while true do
        local result = pcall(wait_for_event_thread)
        logger(30, "Event handler thread exited. Sleeping before restart. pcall result: ", result)
        thread.sleep(10000)
    end
end
_M.event_handler_thread_wrapper = event_handler_thread_wrapper

return _M