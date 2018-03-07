--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 28/10/17
-- Time: 4:48 PM
-- To change this template use File | Settings | File Templates.
--

local config = require("config")
local tcp = require("tcp_client")
local logging = require("logging")
local util = require("util")
local json = require("json")
local logger = logging.create("socket_thread", 30)
local list = require("list")
local aes = require("aes")

local _M = {}

local CRITICAL_SECTION_SOCKET_LIST = config.get_config_value("CRITICAL_SECTION_SOCKET_LIST")
local MAX_SOCK_RETRIES = 5

local MAX_BACKLOG = config.get_config_value("MAX_SOCKET_SEND_BACKLOG")
if type(MAX_BACKLOG) ~= "number" then
    MAX_BACKLOG = 10
end
local SOCKET_SEND_BUFFER_LIST = list.List(MAX_BACKLOG)


local CLIENT_TO_SOCKET = {}

--local send_data = function(client_id, data)
--    if CLIENT_TO_SOCKET[client_id] and CLIENT_TO_SOCKET[client_id] ~= -1 then
--        local err_code, bytes = socket.send(CLIENT_TO_SOCKET[client_id], data)
--    end
--end
--_M.send_data = send_data

local check_hmac_and_return_json = function(json_str)
    logger(0, "Checking command json")
    local json_table = json.decode(json_str)
    if not json_table then
        logger(30, "Unable to load json from string")
        return nil
    end
    if config.check_hmac_config(json_table) then
        logger(0, "Passed hmac test, returning table")
        return json_table
    end
    logger(30, "Failed hmac test, returning nil")
    return nil
end

local send_data = function(client_id, data, retry_attempts, encrypt)
    if data then
        local packet = {}
        if encrypt and encrypt == true then
            logger(30, "Before payload enctyption")
            packet["data"] = aes.encrypt("password", data, aes.AES128, aes.CBCMODE)
            logger(30, "After payload enctyption")
            packet["encrypted"] = true
        else
            packet["data"] = data
            packet["encrypted"] = false
        end
        packet["retry_attempts"] = 0
        packet["retry_count"] = 0
        packet["bytes"] = #packet["data"]
        if retry_attempts and type(retry_attempts) == 'number' then
            packet["retry_attempts"] = retry_attempts
        end
        thread.enter_cs(CRITICAL_SECTION_SOCKET_LIST)
        SOCKET_SEND_BUFFER_LIST:push_right(packet)
        thread.leave_cs(CRITICAL_SECTION_SOCKET_LIST)

        if CLIENT_TO_SOCKET[client_id] then
            setevt(tcp.SOCKET_SEND_READY_EVENT, CLIENT_TO_SOCKET[client_id])
        end
    end
end
_M.send_data = send_data

local parse_cli = function(cli_command)
    if cli_command == "config" then
        return config.config_as_str()
    end
end

local process_payload = function(client_id, data)
    local json_object = check_hmac_and_return_json(data)
    local return_string = ""
    if json_object then
        if json_object["command"] then
            return_string = return_string .. at.run_command(json_object["command"])
        end
        if json_object["cli"] then
            return_string = return_string .. parse_cli(json_object["cli"])
        end
        if return_string ~= "" then
            send_data(client_id, return_string, 1, true)
        end
    else
        logger(30, "Command did not pass validation.")
    end
end

local socket_thread = function(client_id, imei, version)
    local connect_string = "C0NXN:" .. imei .. ":" .. version .. "\n"
    while true do
        if config.get_config_value("ENABLE_TCP") == "true" then
            local connected = false
            local result, socket_fd = tcp.connect_host(client_id, config.get_config_value("SOCK_HOST"), config.get_config_value("SOCK_PORT"))
            if result and socket_fd ~= -1 then
                logger(0, "Connected to host: ", config.get_config_value("SOCK_HOST"), " on port: ", config.get_config_value("SOCK_PORT"), " with client id: ", client_id)
                connected = true
                CLIENT_TO_SOCKET[client_id] = socket_fd

                local err_code, bytes = socket.send(socket_fd, connect_string)

                if (err_code and (err_code == tcp.SOCK_RST_OK)) then
                    logger(0, "Data sent ok. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                else
                    logger(30, "Data not sent. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                    connected = false
                    socket.close(socket_fd)
                    CLIENT_TO_SOCKET[client_id] = -1
                    tcp.close_network(client_id)
                end
            else
                logger(30, "Connection to host: ", config.get_config_value("SOCK_HOST"), " port: ", config.get_config_value("SOCK_PORT"), " client_id: ", client_id, " failed")
            end
            while(connected) do
                logger(0, "Waiting for a read event on socket ", socket_fd)
                local data_available, send_ready, closed = tcp.wait_read_event(socket_fd, config.get_config_value("SOCK_HEARTBEAT_INTERVAL"))
                logger(0, "Read event has returned for socket ", socket_fd)

                if data_available then
                    local err_code, data = socket.recv(socket_fd, 100)
                    logger(0, "Data received. err_code: ", tostring(err_code), ", data: ", tostring(data))
                    if (err_code and (err_code == tcp.SOCK_RST_SOCK_FAILED)) then
                        logger(30, "Socket recv failed: ", tostring(err_code), ", data: ", tostring(data))
                        closed = true
                    end

                    if closed then
                        logger(30, "connection closed")
                        connected = false
                    else
                        if( data ~= nil ) then
                            process_payload(client_id, data)
                        end
                    end
                elseif send_ready then
                    while SOCKET_SEND_BUFFER_LIST:length() > 0 do
                        thread.enter_cs(CRITICAL_SECTION_SOCKET_LIST)
                        local buffer = SOCKET_SEND_BUFFER_LIST:pop_left()
                        thread.leave_cs(CRITICAL_SECTION_SOCKET_LIST)

                        local header = "DATA:" .. tostring(buffer["bytes"]) .. ">"
                        if buffer["encrypted"] == true then
                            header = "ENC" .. header
                        end
                        local err_code, bytes = socket.send(socket_fd, header .. buffer["data"])
                        if (err_code and (err_code == tcp.SOCK_RST_OK)) then
                            logger(0, "Data sent ok. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                        else
                            logger(30, "Data not sent. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                            connected = false
                            if buffer["retry"] and buffer["retry_count"] < buffer["retry_attempts"] then
                                buffer["retry_count"] = buffer["retry_count"] + 1
                                thread.enter_cs(CRITICAL_SECTION_SOCKET_LIST)
                                SOCKET_SEND_BUFFER_LIST:push_left(buffer)
                                thread.leave_cs(CRITICAL_SECTION_SOCKET_LIST)
                            end
                        end
                    end
                else
                    local err_code, bytes = socket.send(socket_fd, "C0NXN>")
                    if (err_code and (err_code == tcp.SOCK_RST_OK)) then
                        logger(0, "Data sent ok. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                    else
                        logger(30, "Data not sent. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes))
                        connected = false
                    end
                end
                if not connected then
                    socket.close(socket_fd)
                    CLIENT_TO_SOCKET[client_id] = -1
                    tcp.close_network(client_id)
                end
            end
        end
        logger(0, "Sleeping")
        thread.sleep(config.get_config_value("TCP_SLEEP_TIME"))
    end
end
_M.socket_thread = socket_thread

return _M

