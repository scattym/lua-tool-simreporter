local socket = require("socket")

network = {}

local set_tcp_ka_param = function(max_check_timers, interval)
  print("network: set_tcp_ka_param" .. max_check_timers .. " " .. interval)
  return true
end
network.set_tcp_ka_param = set_tcp_ka_param

local set_tcp_retran_param = function(set_tcp_retran_param, set_tcp_retran_param)
  print("network: set_tcp_retran_param: " .. set_tcp_retran_param .. " " .. set_tcp_retran_param)
  return true
end
network.set_tcp_retran_param = set_tcp_retran_param

local set_dns_timeout_param = function(max_network_retry_open_times, network_open_timeout, max_dns_query_times)
  print("network: set_dns_timeout_param: " .. max_network_retry_open_times .. " " .. network_open_timeout .. " " .. max_dns_query_times)
  return true
end
network.set_dns_timeout_param = set_dns_timeout_param

local open = function(cid, timeout)
  print("network: open: " .. cid .. " " .. timeout)
  return 1
end
network.open = open

local close = function(app_handle)
  print("network: close: " .. app_handle)
  return true
end
network.close = close

local local_ip = function(app_handle)
  print ("network: local_ip: " .. app_handle)
  return "10.1.1.28"
end
network.local_ip = local_ip

local mtu = function(app_handle)
  print ("network: mtu: " .. app_handle)
  return 1024
end
network.mtu = mtu

local resolve = function(domain, cid)
  print("network: resolve: " .. domain .. " " .. cid)
  return "10.1.1.28"
end
network.resolve = resolve

local status = function(app_handle)
  print ("network: status: " .. app_handle)
  return 4
end
network.status = status

local dorm = function(app_handle, operation)
  print("network: dorm: " .. app_handle .. " " .. tostring(operation))
  return true
end
network.dorm = dorm


return network
