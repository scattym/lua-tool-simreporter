local _M = {}

local LOGGERS = {}
printdir(1)

local create_logger = function(library, level)
    LOGGERS[library] = level
end
_M.create_logger = create_logger

local log = function(library, level, ...)
    local file_line = debug.getinfo(2, "S")
    if LOGGERS[library] == nil then
        LOGGERS[library] = 30
    end
    if LOGGERS[library] == nil or LOGGERS[library] <= level then
        thread.enter_cs(3);
        print(library, ":", file_line.linedefined, ":", level, ":")
        for i, value in ipairs(arg) do
            print(tostring(value))
        end
        print("\r\n")
        thread.leave_cs(3);
        collectgarbage()
    end

end
_M.log = log

return _M