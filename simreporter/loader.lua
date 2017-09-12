--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"

collectgarbage();

function prequire(...)
    local status, lib = pcall(require, ...)
    if(status) then return lib end
    --Library failed to load, so perhaps return `nil` or something?
    print("unable to load ", ..., "\r\n")
    return nil
end

vmsleep(8000);
printdir(1);
local quarantine_version = function(version)
    file = io.open("c:/quarantined","a") assert(file)
    -- file:trunc(0)
    file:write(version, "\n")
    file:close()
end

local is_version_quarantined = function(version)
    local file = io.open("c:/quarantined","r")
    if( not file ) then
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
            print("Found version in quarantined file\r\n")
            return true
        end
    end
    return false
end

local pick_version = function()

    local dir_list, file_list = os.lsdir("c:/libs/")
    local max_version
    print("Starting\r\n")
    for i, directory in ipairs(dir_list) do
      print("Checking directory: ", directory, "\r\n")
      version = tonumber(directory)
      print("version is: ", version, "\r\n")
      if( version ) then
        if( not max_version or version > max_version ) then
            if( is_version_quarantined(version) ) then
                print("version is quarantined\r\n")
            else
                max_version = version
            end
        end
      end
    end
    collectgarbage()
    return max_version
end



local max_version = pick_version()

local original_package_path = package.path
print("Package path was: ", package.path, "\r\n")
if( max_version ) then
    package.path = "/MultiMedia/libs/" .. max_version .."/?.out;" .. original_package_path
else
    package.path = "/MultiMedia/libs/base/?.out;" .. original_package_path
end
print("Package path is: ", package.path, "\r\n")
print("Max version is: ", max_version, "\r\n")

local network_setup
local basic_threads

network_setup = prequire("network_setup")
basic_threads = prequire("basic_threads")
printdir(1);
if( network_setup == nil or basic_threads == nil ) then
    print("Unable to load modules from version ", max_version, "\r\n")
    if( max_version == "base" ) then
        print("Not removing base\r\n")
    else
        print("Quarantining version ", max_version, "\r\n")
        quarantine_version(max_version)
    end
    os.restartscript()
end

network_setup.set_network_from_sms_operator();
vmsleep(15000);

thread_list = thread.list()
print("Thread list is ", tostring(thread_list), "\r\n")

main_id = thread.identity();
print("main_id=", main_id, "\r\n");

collectgarbage();
basic_threads.start_threads();

print("exit main thread\r\n");

print(result);
