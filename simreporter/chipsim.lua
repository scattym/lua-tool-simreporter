
printdir = function(var)
  print("printdir" .. tostring(var))
  return true
end

vmsleep = function(var)
  os.execute("sleep " .. tonumber(1))
end