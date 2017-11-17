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
local logger = logging.create("socket_thread", 30)

local _M = {}

local CLIENT_TO_SOCKET = {}

local send_data = function(client_id, data)
    if CLIENT_TO_SOCKET[client_id] and CLIENT_TO_SOCKET[client_id] ~= -1 then
        local err_code, bytes = socket.send(CLIENT_TO_SOCKET[client_id], data)
    end
end
_M.send_data = send_data

local socket_thread = function(client_id)
    while true do
        if config.get_config_value("ENABLE_TCP") then
            local connected = false
            local result, socket_fd = tcp.connect_host(client_id, config.get_config_value("SOCK_HOST"), config.get_config_value("SOCK_PORT"))
            if result and socket_fd ~= -1 then
                logger(0, "Connected to host: ", config.get_config_value("SOCK_HOST"), " on port: ", config.get_config_value("SOCK_PORT"), " with client id: ", client_id)
                connected = true
                CLIENT_TO_SOCKET[client_id] = socket_fd
            else
                logger(30, "Connection to host: ", config.get_config_value("SOCK_HOST"), " port: ", config.get_config_value("SOCK_PORT"), " client_id: ", client_id, " failed")
            end
            while(connected) do
                logger(0, "Waiting for a read event on socket ", socket_fd, "\r\n")
                local data_available, closed = tcp.wait_read_event(socket_fd, 100000)
                logger(0, "Read event has returned for socket ", socket_fd, "\r\n")

                if data_available then
                    local err_code, data = socket.recv(socket_fd, 100)
                    logger(0, "Data received. err_code: ", tostring(err_code), ", data: ", tostring(data), "\r\n")
                    if (err_code and (err_code == tcp.SOCK_RST_SOCK_FAILED)) then
                        logger(30, "Socket recv failed: ", tostring(err_code), ", data: ", tostring(data), "\r\n")
                        closed = true
                    end

                    if closed then
                        logger(30, "connection closed\r\n")
                        connected = false
                    else
                        if( data ~= nil ) then
                            local return_string = at.run_command(string.gsub(data, "[\r\n]", ""))
                            if return_string ~= nil then
                                local err_code, bytes = socket.send(socket_fd, return_string)

                                if (err_code and (err_code == tcp.SOCK_RST_OK)) then
                                    logger(0, "Data sent ok. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes), "\r\n")
                                else
                                    logger(30, "Data not sent. err_code: ", tostring(err_code), " bytes sent: ", tostring(bytes), "\r\n")
                                    connected = false
                                end
                            end
                        end
                    end
                end
                if not connected then
                    socket.close(socket_fd)
                    CLIENT_TO_SOCKET[client_id] = -1
                    tcp.close_network(client_id)
                end
            end
        end
        logger(0, "Sleeping\r\n")
        thread.sleep(config.get_config_value("TCP_SLEEP_TIME"))
    end
end
_M.socket_thread = socket_thread

return _M

