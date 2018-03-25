--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 31/12/17
-- Time: 10:52 AM
-- To change this template use File | Settings | File Templates.
--


local logging = require("logging")
local list = require("list")
local json = require("json")
local util = require("util")
local aes = require("aes")
local http_lib = require("http_lib")
local CONFIG

local logger = logging.create("http_reporter", 30)

local REPORTER_THREAD
local REPORTER_CLIENT_ID
local REPORTER_CRITICAL_SECTION
local MESSAGE_ID_COUNTER = 0
local BACK_OFF_TIME = 0
local BACK_OFF_UNTIL = 0

local HTTP_REPORTER_RUNNING_VERSION
local HTTP_REPORTER_IMEI
local SESSION_KEY
local LOGIN_PAYLOAD
local SESSION_UUID
local LOGGED_IN = false


local function set_config(config)
    if not REPORTER_CLIENT_ID then
        REPORTER_CLIENT_ID = config.get_config_value("NET_CLIENT_ID_HTTP_REPORTER")
    end
    if not REPORTER_CRITICAL_SECTION then
        REPORTER_CRITICAL_SECTION = config.get_config_value("CRITICAL_SECTION_HTTP_REPORTER")
    end
    CONFIG = config
end

local DataQueue = {}
DataQueue.__index = DataQueue -- failed table lookups on the instances should fallback to the class table, to get methods

setmetatable(DataQueue, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
  end,
})

function DataQueue:_init(max_length)
    self.data_list = list.List(max_length)
    return self
end

local function message_to_payload(call_back, message, headers, host, port, path, encrypt)
    local payload = {}
    MESSAGE_ID_COUNTER = MESSAGE_ID_COUNTER + 1
    payload["message_id"] = MESSAGE_ID_COUNTER
    payload["os_clock"] = os.clock()
    payload["message"] = message
    payload["host"] = host
    payload["port"] = port
    payload["path"] = path
    payload["encrypt"] = encrypt
    payload["call_back"] = call_back
    payload["failure_count"] = 0
    if headers == nil then
        headers = {}
    end
    if CONFIG.get_config_value("USE_SESSION_KEY") == "true" and SESSION_UUID ~= nil then
        payload["encrypt"] = {}
        payload["encrypt"]["ki"] = SESSION_UUID
        payload["encrypt"]["key"] = SESSION_KEY
    end
    headers["v"] = HTTP_REPORTER_RUNNING_VERSION
    headers["i"] = HTTP_REPORTER_IMEI
    payload["headers"] = headers
    return payload

end
-- format of call_back is function(data["message_id"], result, headers, response)
function DataQueue:add_message(call_back, message, headers, host, port, path, encrypt)
    local payload = message_to_payload(call_back, message, headers, host, port, path, encrypt)

    logger(0, "Adding message to queue: ", payload)
    thread.enter_cs(REPORTER_CRITICAL_SECTION)
    self.data_list:push_left(payload)
    thread.leave_cs(REPORTER_CRITICAL_SECTION)
    logger(0, "Message added. Queue length is: ", self.data_list:length())
    if REPORTER_THREAD then
        thread.signal_notify(REPORTER_THREAD, 1)
    end
    logger(0, "Signal has been sent")
    return payload["message_id"]
end

function DataQueue:requeue_message(payload)
    logger(0, "Putting message back on queue. Payload: ", payload)
    payload["failure_count"] = payload["failure_count"] + 1
    if payload["failure_count"] < CONFIG.get_config_value("MAX_HTTP_REPORTER_PAYLOAD_ATTEMPTS") then

        thread.enter_cs(REPORTER_CRITICAL_SECTION)
        self.data_list:push_right(payload)
        thread.leave_cs(REPORTER_CRITICAL_SECTION)
    else
        logger(30, "Max attempts exceeded. Not adding back to queue.")
    end
end

function DataQueue:get_message()
    thread.enter_cs(REPORTER_CRITICAL_SECTION)
    local message = self.data_list:pop_left()
    thread.leave_cs(REPORTER_CRITICAL_SECTION)
    return message
end

function DataQueue:length()
    return self.data_list:length()
end

local DATA_QUEUE = DataQueue(200)

local function login(imei, running_version, session_key, enc_login_message)
    if imei and running_version and session_key and enc_login_message then
        HTTP_REPORTER_IMEI = imei
        HTTP_REPORTER_RUNNING_VERSION = running_version
        SESSION_KEY = session_key
        LOGIN_PAYLOAD = enc_login_message
    end
    if not LOGIN_PAYLOAD then
        logger(30, "No login payload. Login not possible.")
        return false
    else
        if LOGGED_IN then
            logger(0, "Already logged in")
            return true
        else
            logger(30, "Payload as hex is ", LOGIN_PAYLOAD)
            local as_str = util.fromhex(LOGIN_PAYLOAD)
            local result, headers, response = http_lib.http_connect_send_close(
                REPORTER_CLIENT_ID,
                CONFIG.get_config_value("UPDATE_HOST"),
                CONFIG.get_config_value("UPDATE_PORT"),
                "/v3/login",
                as_str,
                {}
            )
            if( not result or not string.equal(headers["response_code"], "200") ) then
                logger(30, "Login failed. Result was: ", result, " and response code: ", headers["response_code"])
                return false
            else
                logger(30, "Login sucessful. Result was: ", result, " and response code: ", headers["response_code"])
                local decrypted = aes.decrypt_raw_key(SESSION_KEY, response, aes.AES128, aes.CBCMODE)
                if decrypted then
                    local response_table = json.decode(decrypted)
                    if response_table then
                        local uuid = response_table["uuid"]
                        logger(30, "uuid is ", uuid)
                        SESSION_UUID = uuid
                        LOGGED_IN = true
                        return true
                    end
                end
            end
        end
    end
    logger(30, "End of login.")
    return false
end

local function http_reporter_thread_f()
    local key_data = true

    while true do
        if CONFIG.get_config_value("USE_SESSION_KEY") == "true" then
            login()
            collectgarbage()
        end

        while true do
            -- local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(1000000)
            local waited_mask = thread.signal_wait(255, 100000)
            logger(10, "out of thread.signal_wait")

            if os.clock() < BACK_OFF_UNTIL then
                logger(
                    0,
                    "Not sending data as we haven't reach the back off timer. BACK_OFF_UNTIL: ",
                    BACK_OFF_UNTIL,
                    " current time: ",
                    os.clock()
                )
            else
                logger(
                    0,
                    "Back off timer is ok. BACK_OFF_UNTIL: ",
                    BACK_OFF_UNTIL,
                    " current time: ",
                    os.clock()
                )

                local failure_count = 0

                local max_attempts_exceeded = false
                while DATA_QUEUE:length() > 0 and not max_attempts_exceeded do
                    logger(0, "Getting message off of queue, queue length is ", DATA_QUEUE:length())
                    local message = DATA_QUEUE:get_message()
                    if message then
                        local headers = message["headers"]
                        headers["age"] = os.clock() - message["os_clock"]
                        local result, headers, response = http_lib.http_connect_send_close(
                            REPORTER_CLIENT_ID,
                            message["host"],
                            message["port"],
                            message["path"],
                            message["message"],
                            headers,
                            message["encrypt"]
                        )
                        if message["call_back"] then
                            local pcall_result = pcall(message["call_back"], message["message_id"], result, headers, response)
                            logger(0, "Callback result was: ", pcall_result)
                        end
                        logger(20, "Result is >", tostring(result), "< and response is: ", response)
                        if result and headers["response_code"] == "200" then
                            logger(20, "Data was sent to url: http://", message["host"], ":", message["port"], message["path"])
                            BACK_OFF_TIME = 0
                        else
                            logger(30,
                                "Data was not sent to url: http://", message["host"], ":", message["port"], message["path"],
                                " and result is ", tostring(result), " and response is ", response
                            )
                            failure_count = failure_count + 1
                            DATA_QUEUE:requeue_message(message)
                            if headers["response_code"] == "403" then
                                LOGGED_IN = false
                                break -- break back to login again
                            end

                        end
                        collectgarbage();
                    else
                        logger(30, "Data to send but no data returned. Object is: ", message)
                        failure_count = failure_count + 1
                    end
                    logger(0, "About to check failure count")
                    if failure_count >= CONFIG.get_config_value("MAX_HTTP_REPORTER_SEND_ATTEMPTS") then
                        logger(30, "Too many failed attempts. Giving up for now. Failed count is: ", failure_count)
                        if BACK_OFF_TIME == 0 then
                            BACK_OFF_TIME = 2
                        elseif BACK_OFF_TIME < 480 then
                            BACK_OFF_TIME = BACK_OFF_TIME * 2
                        end
                        logger(0, "Backing off for ", BACK_OFF_TIME, " seconds")
                        BACK_OFF_UNTIL = os.clock() + BACK_OFF_TIME
                        logger(0, "Backing off until ", BACK_OFF_UNTIL)
                        max_attempts_exceeded = true
                    end
                    collectgarbage();
                end

            end

        end
    end
end

local function http_reporter_thread_wrapper()
    while true do
        local result = pcall(http_reporter_thread_f)
        logger(30, "HTTP reporter thread exited. Sleeping before restart. pcall result: ", result)
        thread.sleep(10000)
    end
end

local function start_thread(imei, running_version, key, login_payload)
    HTTP_REPORTER_IMEI = imei
    HTTP_REPORTER_RUNNING_VERSION = running_version
    SESSION_KEY = key
    LOGIN_PAYLOAD = login_payload
    local http_reporter_thread = thread.create(http_reporter_thread_wrapper)
    local running = thread.run(http_reporter_thread)
    REPORTER_THREAD = http_reporter_thread
    logger(10, "HTTP reporter thread start result is ", tostring(running))
    return http_reporter_thread, running
end

local function add_message(call_back, message, headers, host, port, path, encrypt)
    return DATA_QUEUE:add_message(call_back, message, headers, host, port, path, encrypt)
end


-- Not thread safe, so don't call once main threads have started
local function synchronous_http_get(host, port, path, headers)
    local payload = message_to_payload(nil, nil, headers, host, port, path, true)
    logger(0, "Calling out for a synchronous http get")
    return http_lib.http_connect_send_close(
        CONFIG.get_config_value("NET_CLIENT_ID_HTTP_SYNC"),
        payload["host"],
        payload["port"],
        payload["path"],
        payload["message"],
        payload["headers"],
        payload["encrypt"]
    )
    --return false, "", ""
end

local api = {
    add_message = add_message,
    start_thread = start_thread,
    login = login,
    synchronous_http_get = synchronous_http_get,
    set_config = set_config,
}

return api
