local _M = {}

local LOG_LEVEL = {}
LOG_LEVEL["root"] = 30
local LOG_FILENAME = ""
local LOG_FILE_FD = false
local MAX_FILE_SIZE = 1048576
if printdir then
    printdir(1)
end

local create_logger = function(library, level)
    LOG_LEVEL[library] = level
end
_M.create_logger = create_logger

local set_log_level = function(library, level)
    LOG_LEVEL[library] = level
end
_M.set_log_level = set_log_level

local set_log_file = function(filename)
    LOG_FILENAME = filename
    file = io.open(filename,"a")
    if not file then
        print("Unable to open log file\r\n")
    else
        LOG_FILE_FD = file
    end
end
_M.set_log_file = set_log_file

local close_log_file = function()
    LOG_FILE_FD:close()
    LOG_FILE_FD = false
end
_M.close_log_file = close_log_file

local log = function(library, level, ...)
    local file_line = debug.getinfo(2, "S")
    if LOG_LEVEL[library] == nil then
        LOG_LEVEL[library] = 30
    end
    if ( LOG_LEVEL[library] == nil and LOG_LEVEL["root"] <= level ) or LOG_LEVEL[library] <= level then
        local thread_index = ""
        if thread then
            thread.enter_cs(3);
            thread_index = tostring(thread.index())
        end
        print(os.clock(), ":", thread_index, ":", library, ":", file_line.linedefined, ":", level, ":")
        for i, value in ipairs(arg) do
            print(tostring(value))
        end
        print("\r\n")
        if LOG_FILE_FD ~= false then
            result = LOG_FILE_FD:write(thread_index, ":", library, ":", file_line.linedefined, ":", level, ":")
            for i, value in ipairs(arg) do
                LOG_FILE_FD:write(tostring(value))
            end
            LOG_FILE_FD:write("\n")
        end
        if thread then
            thread.leave_cs(3)
        end
        collectgarbage()
    end

end
_M.log = log

local create = function(library, default_level)
    if not default_level then
        LOG_LEVEL[library] = 30
    else
        LOG_LEVEL[library] = default_level
    end
    local f = function(level, ...)
        log(library, level, ...)
    end
    return f
end
_M.create = create

return _M