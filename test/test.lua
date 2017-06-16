package.path = package.path .. ';' .. arg[0]:gsub('[^\\/]+$', '') .. '?.lua'
local foo = require 'foo'

local pass = true
local function check_equal(name, a, b)
  if a ~= b then
    io.stdout:write(name, ' ', 'FAIL\n')
    pass = false
  else
    io.stdout:write(name, ' ', 'PASS\n')
  end
end
check_equal('first sum',  foo.sum(1, 1), 2)
check_equal('second sum', foo.sum(1, 2), 3)
if not pass then error 'FAILED' end
