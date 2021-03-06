--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"

collectgarbage();

function prequire(...)
    local status, lib = pcall(require, ...)
    if status then return lib end
    --Library failed to load, so perhaps return `nil` or something?
    print("unable to load ", ..., "\r\n")
    return nil
end

function split(str, delim)
    local result,pat,lastPos = {},"(.-)" .. delim .. "()",1
    for part, pos in string.gfind(str, pat) do
        table.insert(result, part); lastPos = pos
    end
    table.insert(result, string.sub(str, lastPos))
    return result
end

DEBUG_LEVEL = 10
vmsleep(7000);
printdir(1);
sio.clear()
sio.send("ATE0\r\n")
local MIN_BAT_LEVEL = 5
local ate_response = sio.recv(5000)

local function get_battery_level()
    local bat_percent = 0
    sio.clear()
    sio.send("AT+CBC\r\n")
    local battery_response = sio.recv(5000)
    local batt_table = split(battery_response, "\r\n")
    for i,line in pairs(batt_table) do
        print("Line is " .. line .. "\r\n")
        if line:match("+CBC:") then
            print("In cbc line\r\n")
            local line_table = split(line, ",")
            if #line_table == 3 then
                print("Matched. Battery is at " .. line_table[2] .. "\r\n")
                bat_percent = tonumber(line_table[2])
                if not bat_percent then
                    print("Battery percentage not retrieved. Setting to 0\r\n")
                    bat_percent = 0
                end
            else
                print("Count does not match" .. #line_table .. "\r\n")
            end
        end
    end
    return bat_percent
end

while get_battery_level() < MIN_BAT_LEVEL do
    print("Battery level to low. Sleeping\r\n")
    vmsleep(5000)
end
print("Battery ok.\r\n")
sio.send("ATE1\r\n")
ate_response = sio.recv(5000)


quarantine_version = function(version)
    print("Quarantining version: ", version, "\r\n")
    if version and not string.equal(version, "base") then
        file = io.open("c:/quarantined","a")
        if not file then
            print("Unable to open quarantined file\r\n")
        else
            -- file:trunc(0)
            result = file:write(version, "\n")
            print("File write result: ", result, "\r\n")
            file:close()
        end
    end
end

is_version_quarantined = function(version)
    local file = io.open("c:/quarantined","r")
    if not file  then
        print("No file, so not quarantined\r\n")
        return false
    end

    while true do
        local line = file:read("*l")
        if line == nil then
            print("Reached end of quarantined file\r\n")
            return false
        end
        print("line is ", line, "<\r\n")
        if( string.equal(line, version) ) then
            print("Found version ", version, " in quarantined file\r\n")
            return true
        end
    end
    return false
end

local delete_dir = function(directory)
    print("Removing directory: ", directory, "\r\n")
    if directory[#directory] ~= "/" then
        directory = directory .. "/"
    end
    if string.equal(directory:lower(), "c:/") then
        print("Can't remove root directory\r\n")
        return false
    elseif string.equal(directory:lower(), "c:/libs/base/") then
        print("Can't remove base libs directory\r\n")
        return false
    end
    local dir_list, file_list = os.lsdir(directory)
    for i, dir in ipairs(dir_list) do
        print("Calling out to delete directory: ", directory, dir, "/\r\n")
        delete_dir(directory .. dir .. "/")
    end
    for i, file in ipairs(file_list) do
        print("Deleting file: ", directory, file, "\r\n")
        local file_delete = os.delfile(directory .. file)
        print("File delete result: ", file_delete, "\r\n")
    end
    local dir_delete = os.rmdir(directory)
    print("Directory delete result: ", dir_delete, "\r\n")
end

local compile_files_if_needed = function(directory)
    sio.send("AT+FSCD=" .. directory .. "\r\n")
    rsp = sio.recv(5000)
    print("Change directory response was ", rsp, "\r\n")
    local dir_list, file_list = os.lsdir(directory)
    for i, file in ipairs(file_list) do
        if string.match(file, "lua") then
            print("Compiling file: ", directory, file, "\r\n" )
            local cmd = 'AT+CSCRIPTCL="' .. file .. '"\r\n'
            sio.send(cmd)
            rsp = sio.recv(5000)
            print("Compile response was ", rsp, "\r\n")
            if rsp:match("ERROR") then
                print("Failed so not deleting\r\n")
            else
                os.delfile(directory .. file)
            end
        end
    end
    sio.send("AT+FSCD=c:/\r\n")
    rsp = sio.recv(5000)
    print("Change directory response was ", rsp, "\r\n")

end

local pick_version = function()

    local dir_list, file_list = os.lsdir("c:/libs/")
    local max_version
    print("Starting\r\n")
    for i, directory in ipairs(dir_list) do
        print("Checking directory: ", directory, "\r\n")
        local version = tonumber(directory)
        print("version is: ", version, "\r\n")
        if not version then
            print("Unable to convert ", directory, " to a version number\r\n")
        else
            if not max_version or version > max_version then
                if( is_version_quarantined(version) ) then
                    print("version is quarantined. Deleting files.\r\n")
                    delete_dir("c:/libs/" .. version .. "/")
                else
                    print("max version now set to: ", version, "\r\n")
                    compile_files_if_needed("c:/libs/" .. version .. "/")
                    max_version = version
                end
            end
        end
    end
    collectgarbage()
    return max_version
end

local max_version = pick_version()
local running_version;

local original_package_path = package.path
print("Package path was: ", package.path, "\r\n")
if( max_version ) then
    package.path = "/MultiMedia/libs/" .. max_version .."/?.out;" .. original_package_path
    running_version = max_version
else
    package.path = "/MultiMedia/libs/base/?.out;" .. original_package_path
    running_version = "base"
end
print("Package path is: ", package.path, "\r\n")
print("Running version is: ", running_version, "\r\n")

local basic_threads

basic_threads = prequire("basic_threads")
printdir(1);
if( basic_threads == nil ) then
    print("Unable to load modules from version ", running_version, "\r\n")
    if running_version == "base" then
        print("Not quarantining base\r\n")
    else
        print("Quarantining version ", running_version, "\r\n")
        quarantine_version(running_version)
        os.restartscript()
        print("Script restart failed. Resetting device\r\n")
        thread.sleep(60000)
        sio.send("AT+CRESET\r\n")
        thread.sleep(7200000)
        print("Device restart failed\r\n")
    end
end

collectgarbage()

main_id = thread.identity();
print("main_id=", main_id, "\r\n");

collectgarbage();
print("Starting threads\r\n")
local status, result = pcall(basic_threads.start_threads(running_version))

print("exit main thread\r\n");

print(result);
sio.send("AT+CRESET\r\n")
