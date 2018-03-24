--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 31/12/17
-- Time: 10:52 AM
-- To change this template use File | Settings | File Templates.
--
local logging = require("logging")
local tcp = require("tcp_client")
local aes = require("aes")
local util = require("util")

local logger = logging.create("http_lib", 30)

local HTL_IMEI
local HTL_VERSION

local set_device_params = function(imei, version)
    HTL_IMEI = imei
    HTL_VERSION = version
end

local make_http_headers = function(host, path, length, headers)
    logger(0, "Host is ", tostring(host));
    logger(0, "Path is ", tostring(path));
    local http_req = "";
    local method = "POST"
    if length == 0 then
        method = "GET"
    end
    http_req = http_req .. method .. " " .. tostring(path) .. " ";
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
    http_req = http_req .. "Connection: close\r\n";
    if length ~= 0 then
        http_req = http_req .. "Content-Type: application/octet-stream\r\n";
        http_req = http_req .. "Content-Length: " .. length .. "\r\n";
    end
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

local http_connect_send_close = function(client_id, host, port, path, data, headers, encrypt)
    if data == nil then
        data = ""
    end
    if not headers then
        headers = {}
    end
    if encrypt and type(encrypt) == "boolean" and encrypt == true then
        headers["encrypted"] = "true"
    end

    local iv = aes.getRandomData(16)
    if encrypt and type(encrypt) == "table" and encrypt["ki"] ~= nil and encrypt["key"] ~= nil then
        -- headers["iv"] = rsa.num_to_hex(encrypt["iv"])
        -- headers["sk"] = rsa.num_to_hex(encrypt["enc_key"])
        headers["iv"] = util.tohex(iv)
        headers["encrypted"] = "true"
        headers["ki"] = encrypt["ki"]
        headers["key"] = util.tohex(encrypt["key"])
        headers["ver"] = HTL_VERSION
        headers["i"] = HTL_IMEI
    end

    local payload = ""
    if encrypt ~= nil and encrypt ~= false and data ~= nil and data ~= "" then

        logger(0, "About to encrypt payload: ", data);
        collectgarbage()
        logger(0, "Encrypt is ", encrypt)

        if type(encrypt) == "table" and encrypt["key"] then
            logger(0, "Encrypting with key. IV", util.tohex(iv), " key ", util.tohex(encrypt["key"]))
            payload = aes.encrypt_raw_key(encrypt["key"], data, aes.AES128, aes.CBCMODE, iv)
        else
            logger(0, "Encrypting with default")
            payload = aes.encrypt("password", data, aes.AES128, aes.CBCMODE)
        end
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

    if( not client_id ) then
        logger(30, "Invalid client id: ", client_id);
    else
        logger(20, "Callout to http://", host, ":", port, path)
        logger(20, "Length is ", payload_length)
        local http_preamble = make_http_headers(host, path, payload_length, headers)
        local result, response = tcp.send_data(client_id, host, port, http_preamble, payload)
        logger(0, "Response is ", response)
        if( result and response ) then
            local headers, response_payload = parse_http_response(response)
            collectgarbage()
            if headers["encrypted"] == "true" then
                logger(10, "Encrypted hex payload is ", aes.toHexString(response_payload))
                local decrypted = aes.decrypt("password", response_payload, aes.AES128, aes.CBCMODE)
                logger(10, "decrypted payload is ", decrypted)
                response_payload = decrypted
                collectgarbage()
            end
            return result, headers, response_payload
        end
    end;
    collectgarbage()
    return false, "", ""
end

-- Not thread safe, so don't call once main threads have started
local function synchronous_http_get(client_id, host, port, path, headers)
    logger(0, "Calling out for a synchronous http get")
    return http_connect_send_close(client_id, host, port, path, "", {}, false)
    --return false, "", ""
end



local api = {
    synchronous_http_get = synchronous_http_get,
    http_connect_send_close = http_connect_send_close,
    set_device_params = set_device_params,
}

return api