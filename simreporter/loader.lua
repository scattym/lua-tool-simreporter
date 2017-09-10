--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
collectgarbage();
vmsleep(12000);
printdir(1);
local dir_list, file_list = os.lsdir("c:/libs/")
local max_version = nil
print("Starting\r\n")
for i, directory in ipairs(dir_list) do
  print("Checking directory: ", directory, "\r\n") 
  version = tonumber(directory)
  print("version is: ", version, "\r\n")
  if( version ) then
    if( not max_version or version > max_version ) then
      max_version = version
    end
  end
end
print("Package path was: ", package.path, "\r\n")
if( max_version ) then
  package.path = "/MultiMedia/libs/" .. max_version .."/?.out;" .. package.path  
end
print("Package path is: ", package.path, "\r\n")

print("Max version is: ", max_version, "\r\n")
local tcp
local encaps
local at
local network_setup
local at_abs
local device
local basic_threads
if( nil ) then
  print("Using max version libraries\r\n");
  tcp = require "libs/", max_version, "/tcp_client"
  print(tcp)
  encaps = require "libs/", max_version, "/encapsulation"
  print(encaps)
  --local nmea_event_handler = require "nmea_event_handler"
  --local gps_timer = require "gps_timer"
  at = require "libs/", max_version, "/at_commands"
  network_setup = require "libs/", max_version, "/network_setup"
  at_abs = require "libs/", max_version, "/at_abs"
  device = require "libs/", max_version, "/device"
  basic_threads = require "libs/", max_version, "/basic_threads"
else
  print("Using default libraries\r\n")
  tcp = require "tcp_client"
  encaps = require "encapsulation"
  --local nmea_event_handler = require "nmea_event_handler"
  --local gps_timer = require "gps_timer"
  at = require "at_commands"
  network_setup = require "network_setup"
  at_abs = require "at_abs"
  device = require "device"
  basic_threads = require "basic_threads"
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
