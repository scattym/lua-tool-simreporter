local sock = require("socket")

local socket = {}

local sock_fd_used = {}
for i=1,16 do sock_fd_used[i] = false end

local sock_fd_arr = {}
for i=1,16 do sock_fd_arr[i] = 0 end

local create = function(app_handle, sock_type)
  print("socket: create: " .. app_handle .. " " .. tostring(sock_type))
  for i=1,16 do
    if sock_fd_used[i] == false then
      sock_fd_used[i] = true
      return i
    end
  end
  return 0
end
socket.create = create

local close = function(sock_fd)
  print("socket: close: " .. sock_fd)
  sock:close(sock_fd_arr[sock_fd_arr])
  sock_fd_used[sock_fd] = false
  sock_fd_array[sock_fd] = 0
  return true
end
socket.close = close

local keepalive = function(sock_fd, keepalive)
  print("socket: keepalive: " .. tostring(sock_fd) .. " " .. tostring(keepalive))
  return true
end
socket.keepalive = keepalive

local connect = function(sock_fd, ip_address, port, timeout)
  print("socket: connect: " .. tostring(sock_fd) .. " " .. ip_address .. " " .. port .. " " .. timeout)
  sock_fd_arr[sock_fd] = sock.connect(ip_address, port)
  return true, true
end
socket.connect = connect

local select = function(sock_fd, event_mask)
  print("socket: select: " .. tostring(sock_fd) .. " " .. tostring(event_mask))
  return true
end
socket.select = select

local send = function(sock_fd, data, timeout)
  print("socket: send: " .. tostring(sock_fd) .. " " .. tostring(data) .. " " .. timeout)
  sock_fd_arr[sock_fd]:send(data)
  return 0, string.len(data)
end
socket.send = send

local recv = function(sock_fd, timeout)
  print("socket: recv: " .. tostring(sock_fd) .. " " .. tostring(timeout))
  sock_fd_arr[sock_fd]:settimeout(1000)
  data, err, partial = sock_fd_arr[sock_fd]:receive(1024)
  print("data is " .. tostring(data))
  print("error is " .. tostring(err))
  print("partial is " .. tostring(partial))
  return 0, tostring(partial)
end
socket.recv = recv


return socket  