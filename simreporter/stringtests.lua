
util = require "util"
test_str = " +CSPN: \"YES OPTUS\",1\r\n\r\nOK\r\n"
result_table = util.split(test_str, "\r\n")

for num = 1,#result_table do
    print(result_table[num])
end;
print(result_table)

