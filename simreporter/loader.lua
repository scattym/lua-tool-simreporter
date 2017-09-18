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
DEBUG_LEVEL = 10
vmsleep(3000);
printdir(1);

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
            print("Reached end of file\r\n")
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
    if string.equal(directory:lower(), "c:/") then
        print("Can't remove root directory\r\n")
        return false
    elseif string.equal(directory:lower(), "c:/base") then
        print("Can't remove root directory\r\n")
        return false
    end
    local dir_list, file_list = os.lsdir("c:/libs/"..version.."/")
    for i, dir in ipairs(dir_list) do 
        delete_dir()
    for i, file in ipairs(file_list) do
        print("Deleting file: ", "c:/libs/"..version.."/"..file, "\r\n")
        local file_delete = os.delfile("c:/libs/"..version.."/"..file)
        print("File delete result: ", file_delete, "\r\n")
    end
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
                    local dir_list, file_list = os.lsdir("c:/libs/"..version.."/")
                    for i, file in ipairs(file_list) do
                        print("Deleting file: ", "c:/libs/"..version.."/"..file, "\r\n")
                        local file_delete = os.delfile("c:/libs/"..version.."/"..file)
                        print("File delete result: ", file_delete, "\r\n")
                    end
                    print("Deleting directory: ", "c:/libs/"..version.."/", "\r\n")
                    local dir_delete = os.rmdir("c:/libs/"..version.."/")
                    print("Directory delete result: ", dir_delete, "\r\n")
                else
                    print("max version now set to: ", max_version, "\r\n")
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
print("Max version is: ", max_version, "\r\n")

local network_setup
local basic_threads

network_setup = prequire("network_setup")
basic_threads = prequire("basic_threads")
printdir(1);
if( network_setup == nil or basic_threads == nil ) then
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

network_setup.set_network_from_sms_operator();
vmsleep(15000);

thread_list = thread.list()
print("Thread list is ", tostring(thread_list), "\r\n")

main_id = thread.identity();
print("main_id=", main_id, "\r\n");

collectgarbage();
print("Starting threads\r\n")
basic_threads.start_threads(running_version);

print("exit main thread\r\n");

print(result);
