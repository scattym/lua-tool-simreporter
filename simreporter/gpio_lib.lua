--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 31/12/17
-- Time: 10:52 AM
-- To change this template use File | Settings | File Templates.
--


local logging = require("logging")
local list = require("list")
local http_lib = require("http_lib")
local config = require("config")

local logger = logging.create("gpio", 0)

local GPIO_HANDLER_THREAD
local CRITICAL_SECTION_GPIO_HANDLER = config.get_config_value("CRITICAL_SECTION_GPIO_HANDLER")
local CRITICAL_SECTION_GPIO_LIST = config.get_config_value("CRITICAL_SECTION_GPIO_LIST")
local GPIO_HANDLER_TABLE = {}

local MAX_BACKLOG = config.get_config_value("MAX_GPIO_EVENT_BACKLOG")
if type(MAX_BACKLOG) ~= "number" then
    MAX_BACKLOG = 10
end
local GPIO_EVENT_LIST = list.List(MAX_BACKLOG)

--[[
--Must be called before the wait event thread is started
 ]]
local add_gpio_handler = function(gpio_pin, default_level_low_high, level_edge, low_high, no_save_save, gpio_func)
    -- disable default pin functionality
    -- sio.send("AT+CGFUNC=" .. tostring(gpio_pin) .. ",0\r\n")
    -- sio.clear()
    gpio.setv(default_level_low_high)
    gpio.setdrt(gpio_pin, 0, 1) -- Set input and save
    gpio.settrigtype(gpio_pin, level_edge, low_high, no_save_save)

    thread.enter_cs(CRITICAL_SECTION_GPIO_HANDLER)
    GPIO_HANDLER_TABLE[gpio_pin] = gpio_func
    thread.leave_cs(CRITICAL_SECTION_GPIO_HANDLER)
    logger(30, "Added handler for gpio ", gpio_pin, " with func ", gpio_func)
end

--[[
--Runs in event farmer thread context. Must be kept small
 ]]
local function gpio_event_handler_cb(evt, evt_p1, evt_p2, evt_p3, evt_clock)
    local event = {}
    if GPIO_HANDLER_TABLE[evt_p1] then
        event["PIN"] = evt_p1
        event["STATE"] = evt_p2
        event["CLOCK"] = evt_clock
        thread.enter_cs(CRITICAL_SECTION_GPIO_LIST)
        GPIO_EVENT_LIST:push_right(event)
        thread.leave_cs(CRITICAL_SECTION_GPIO_LIST)
        if GPIO_HANDLER_THREAD then
            thread.signal_notify(GPIO_HANDLER_THREAD, 1)
        else
            logger(30, "No GPIO handler thread to signal")
        end
    end
    return true
end

local function gpio_handler_thread_f()
    GPIO_HANDLER_THREAD = thread.identity()
    while true do
        -- local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(1000000)
        local waited_mask = thread.signal_wait(255, 1000000)
        logger(10, "out of thread.signal_wait")
        local event
        while GPIO_EVENT_LIST:length() > 0 do
            logger(30, "About to try and get event")
            thread.enter_cs(CRITICAL_SECTION_GPIO_LIST)
            event = GPIO_EVENT_LIST:pop_left()
            thread.leave_cs(CRITICAL_SECTION_GPIO_LIST)
            logger(30, "List has returned")
            if event then
                logger(30, "We have an event")
                for key, value in pairs(GPIO_HANDLER_TABLE) do
                    logger(30, "looping over ", key, " with func ", value)
                    if key == event["PIN"] and value then
                        local result = pcall(value, event["PIN"], event["STATE"], event["CLOCK"])
                        logger(30, "GPIO function callout result was: ", result)
                    end
                end
            end
        end

    end
end

local function gpio_handler_thread_wrapper()
    while true do
        local result = pcall(gpio_handler_thread_f)
        logger(30, "GPIO handler thread exited. Sleeping before restart. pcall result: ", result)
        thread.sleep(10000)
    end
end


local api = {
    add_gpio_handler = add_gpio_handler,
    gpio_event_handler_cb = gpio_event_handler_cb,
    gpio_handler_thread_wrapper = gpio_handler_thread_wrapper,
    --synchronous_http_get = synchronous_http_get,
}

return api
