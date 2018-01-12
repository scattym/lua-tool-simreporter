--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 31/12/17
-- Time: 11:47 AM
-- To change this template use File | Settings | File Templates.
--

local list = require("list")

local my_list = list.List(5)

my_list:push_right("test")
print(my_list:length())
print(my_list:pop_left())
print(my_list:length())
my_list:push_right("test1")
my_list:print()
my_list:push_right("test2")
my_list:print()
my_list:push_right("test3")
my_list:print()
my_list:push_right("test4")
my_list:print()
my_list:push_right("test5")
my_list:print()
my_list:push_right("test6")
my_list:print()
my_list:push_right("test7")
my_list:print()
my_list:push_right("test8")
my_list:print()
print(my_list:length())

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

function DataQueue:add_message(message, headers, host, port, path, encrypt)
    local payload = {}
    payload["os_clock"] = os.clock()
    payload["message"] = message
    payload["host"] = host
    payload["port"] = port
    payload["path"] = path
    payload["headers"] = headers
    payload["encrypt"] = encrypt
    payload["failure_count"] = 0
    --thread.enter_cs(REPORTER_CRITICAL_SECTION)
    self.data_list:push_left(payload)
    --thread.leave_cs(REPORTER_CRITICAL_SECTION)
    --thread.signal_notify(REPORTER_THREAD, 1)
end

function DataQueue:requeue_message(payload)
    payload["failure_count"] = payload["failure_count"] + 1
    if payload["failure_count"] < config.get_config_value("MAX_HTTP_REPORTER_PAYLOAD_ATTEMPTS") then
        --thread.enter_cs(REPORTER_CRITICAL_SECTION)
        self.data_list:push_right(payload)
        --thread.leave_cs(REPORTER_CRITICAL_SECTION)
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

local DATA_QUEUE = DataQueue(5)

local make_http_post_headers = function(host, url, length, headers)
    logger(0, "Host is ", tostring(host));
    logger(0, "URL is ", tostring(url));
    logger(0, "data is ", tostring(data));
    local http_req = "";
    http_req = http_req .. "POST " .. tostring(url) .. " ";
    http_req = http_req .. "HTTP/1.1\r\nHost: ";
    http_req = http_req .. tostring(host);
    http_req = http_req .. "\r\n";
    http_req = http_req .. "User-Agent: SimCom/1.0\r\n" -- (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\n";
    http_req = http_req .. "Authorization: bc733796ca38178dbee79f68ba4271e97fe170d4\r\n";
    http_req = http_req .. "Accept: text/html\r\n" --,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\n";
    --http_req = http_req .. "Accept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\n";
    for key, value in pairs(headers) do
        http_req = http_req .. key .. ": " .. value .. "\r\n"
    end
    http_req = http_req .. "Content-Type: application/octet-stream\r\n";
    http_req = http_req .. "Connection: close\r\n";
    http_req = http_req .. "Content-Length: " .. length .. "\r\n";
    http_req = http_req .. "\r\n";

    return http_req;
end

-- HTTP/1.0 500 INTERNAL SERVER ERROR
-- HTTP/1.0 200 OK
local parse_http_headers = function(response)
    local headers = {}
    headers["response_code"] = "000"
    if not response then
        logger(30, "Did not get a header string to parse. Response is nil.")
    else
        for line in response:gmatch("([^\r\n]*)\r\n?") do
            logger(0, "Line is ", line)

            local type, code, msg = line:match("([Hh][Tt][Tt][Pp]/[0-9].[0-9])%s+([0-9]*)%s+(.*)")
            if( type and code and msg ) then
                logger(0, "Type: ", type, " code: ", code, " msg: ", msg)
                headers["response_code"] = code
            else
                for key, value in line:gmatch("(%S*):%s*(.*)") do
                    logger(0, "key is ", key, " value is ", value)
                    if( key and value ) then
                        headers[key] = value
                    end

                end
            end
        end
    end
    logger(0, "Finished parsing headers")
    collectgarbage()
    return headers
end

local function TotalLength(HeaderLength, ContentLength)
   return HeaderLength + ContentLength
end

-- Assume that Buff holds buffer to receive socket data
local parse_http_response = function (buffer)
    local payload = ""
    local _, HeaderLength = buffer:find('\r\n\r\n')
    local ContentLength = buffer:match("Content%-Length:%s(%d+)\r\n")
    if (not ContentLength or not HeaderLength) then
        logger(30, 'Badly formed HTTP response.'..buffer)
        return {}, ""
    end
    local ExpectedLength = TotalLength(HeaderLength, ContentLength)
    if (#buffer < ExpectedLength) then
        logger(30, "Bad content length field. Expected: ", ExpectedLength, " but got", #buffer)
        return {}, ""
    end


    logger(0, "Preparing header buffer")
    local header_buf = buffer:sub(1, HeaderLength)
    logger(0, "Parsing headers")
    local headers = parse_http_headers(header_buf)
    logger(0, "Extracting payload")
    payload = buffer:sub(HeaderLength+1, HeaderLength+ContentLength)
    --logger(0, "Payload is >", payload, "<\r\n")
    collectgarbage()
    return headers, payload
end

local http_connect_send_close = function(host, port, url, data, headers, encrypt)
    if data == nil then
        data = ""
    end
    if not headers then
        headers = {}
    end
    if type(encrypt) == "boolean" and encrypt == true then
        headers["encrypted"] = "true"
    end
    if type(encrypt) == "table" and encrypt["key"] ~= nil and encrypt["enc_key"] ~= nil then
        headers["iv"] = rsa.num_to_hex(encrypt["iv"])
        headers["sk"] = rsa.num_to_hex(encrypt["enc_key"])
        headers["encrypted"] = "true"
    end

    local payload = ""
    if encrypt ~= false and data ~= nil and data ~= "" then

        logger(0, "About to encrypt payload: ", data);
        collectgarbage()
        payload = aes.encrypt("password", data, aes.AES128, aes.CBCMODE)
        logger(0, "Encrypted payload is ", util.tohex(payload))
        logger(10, "Encrypted payload length is ", #payload)
        collectgarbage()

    else

        payload = data
        logger(0, "Not encrypting ", tostring(payload))

    end
    local payload_length = 0
    if payload ~= nil then
        payload_length = #payload
    end

    if( not REPORTER_CLIENT_ID ) then
        logger(30, "Invalid client id: ", REPORTER_CLIENT_ID);
    else
        logger(20, "Callout to http://", host, ":", port, url)
        logger(20, "Length is ", payload_length)
        local http_preamble = make_http_post_headers(host, url, payload_length, headers)
        local result, response = tcp.send_data(REPORTER_CLIENT_ID, host, port, http_preamble, payload)
        logger(10, "Response is ", response)
        if( result and response ) then
            local headers, response_payload = parse_http_response(response)
            collectgarbage()
            return result, headers, response_payload
        end
    end;
    collectgarbage()
    return false, "", ""
end

local function http_reporter_thread_f()

    local key_data = true

    while true do
        if not REPORTER_THREAD or not thread.running(REPORTER_THREAD) then
            logger(30, "Reporter thread not running yet. Sleeping for 10 seconds")
            thread.sleep(10000);
        end
        -- local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(1000000)
        local waited_mask = thread.signal_wait(255, 100000)

        logger(30, "out of event wait")
        local failure_count = 0
        -- logger(30, "waited evt: ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock)
        while DATA_QUEUE:length() > 0 do
            local data = DATA_QUEUE:get_message()
            if data then
                local headers = {}
                headers["age"] = system.get_uptime() - data["os_clock"]
                local result, headers, response = http_connect_send_close(
                    data["host"],
                    data["port"],
                    data["path"],
                    data["message"],
                    headers,
                    data["encrypt"]
                )
                logger(30, "Result is >", tostring(result), "< and response is: ", response)
                if result and headers["response_code"] == "200" then
                    logger(30, "Data was sent to url: http://", data["host"], ":", data["port"], data["path"])
                else
                    logger(30,
                        "Data was sent to url: http://", data["host"], ":", data["port"], data["path"],
                        " and result is ", tostring(result), " and response is ", response
                    )
                    failure_count = failure_count + 1
                    DATA_QUEUE.requeue_message(data)
                end
                collectgarbage();
            else
                logger(30, "Data to send but no data returned. Object is: ", data)
                failure_count = failure_count + 1
            end
        end
        if failure_count >= config.get_config_value("MAX_HTTP_REPORTER_SEND_ATTEMPTS") then
            logger(30, "Too many failed attempts. Giving up for now. Failed count is: ", failure_count)
            break
        end
    end
end

local function start_thread()
    local http_reporter_thread = thread.create(http_reporter_thread_f)
    local running = thread.run(http_reporter_thread)
    logger(10, "HTTP reporter thread start result is ", tostring(running))
    return http_reporter_thread, running
end

local function add_message(message, headers, host, port, path, encrypt)
    DATA_QUEUE:add_message(message, headers, host, port, path, encrypt)
end
local api = {
    add_message = add_message,
    start_thread = start_thread,
}

add_message("test", "test", "test", "test", "test", "test")
return api