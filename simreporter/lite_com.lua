--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 21/10/17
-- Time: 8:04 PM
-- To change this template use File | Settings | File Templates.
--
local _M = {}
if not bit then
    bit = require("bit")
end

local logging = require("logging")
local logger = logging.create("lite_com", 0)

local BUFFER = {}
local BUFFER_TIMEOUT = 5

local get_byte = function(word, byte)
    a = {}
    a[3] = bit.band(bit.rshift(word, 24), 0xFF);
    a[2] = bit.band(bit.rshift(word, 16), 0xFF);
    a[1] = bit.band(bit.rshift(word, 8), 0xFF);
    a[0] = bit.band(word, 0xFF);
    return a[byte]
end

local check_buffer_complete = function(client_id)
    local complete
    complete = true
    if BUFFER[client_id] then
        if BUFFER[client_id]["total"] then
            total = BUFFER[client_id]["total"]
            for i=1,total do
                if not BUFFER[client_id][i] then
                    complete = false
                end
            end
        end
    end
    print("Complete is ", complete)
    return complete
end

local join_buffer = function(client_id)
    local return_string = ""
    if BUFFER[client_id] then
        if BUFFER[client_id]["total"] then
            local total = BUFFER[client_id]["total"]
            for i=1,total do
                for j=3,0,-1 do
                    local byte = get_byte(BUFFER[client_id][i], j)
                    if byte ~= 0 then
                        return_string = return_string .. string.char(byte)
                    end
                end
            end
        end
    end
    return return_string
end

local add_word = function(client_id, packet_num, word)
    BUFFER[client_id][packet_num] = word
end

local has_client_timed_out = function(client_id)
    if BUFFER[client_id] and BUFFER[client_id]["clock"] then
        if os.clock() - BUFFER[client_id]["clock"] > BUFFER_TIMEOUT then
            return true
        end
    end
    return false
end

local parse_multi_message = function(client_id, packet_num, total_packets, word)
    logger(0, "Packet: ", packet_num, " of ", total_packets)
    if packet_num == 0 or total_packets == 0 or packet_num > total_packets then
        logger(30, "Invalid packet counts. packet_num: ", packet_num, " total_packets: ", total_packets)
        return
    end
    if BUFFER[client_id] and BUFFER[client_id]["total"] and not has_client_timed_out(client_id) then
        if total_packets == BUFFER[client_id]["total"] then
            add_word(client_id, packet_num, word)
        end
    else
        BUFFER[client_id] = {}
        BUFFER[client_id]["total"] = total_packets
        BUFFER[client_id]["clock"] = os.clock()
        add_word(client_id, packet_num, word)
    end
    if check_buffer_complete(client_id) then
        local return_string = join_buffer(client_id)
        BUFFER[client_id] = {}
        return return_string
    end
end


-- 0x01 0x01 0x01 0x20, 0x65 0x65, 0x65, 0x65
local parse_command = function(word1, word2)
    local message
    local message_type = get_byte(word1, 3)
    local client_id = get_byte(word1, 2)
    local packet_num = get_byte(word1, 1)
    local total = get_byte(word1, 0)
    if message_type == 0x01 then
        message = parse_multi_message(client_id, packet_num, total, word2)
    end
    return message_type, client_id, message
end
_M.parse_command = parse_command

--message_type, client_id, message = parse_command(0x01010102,0x65656565)
--print(message)
--message_type, client_id, message = parse_command(0x01010202,0x66666666)
--print(message)
--message_type, client_id, message = parse_command(0x01010102,0x65656567)
--print(message)
--message_type, client_id, message = parse_command(0x01010202,0x66666600)
--print(message)
--message_type, client_id, message = parse_command(0x01010302,0x66666600)
--print(message)

return _M