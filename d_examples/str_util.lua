--------------------------------------------------------------------------------
--脚本说明
--本脚本包含字符串处理相关操作函数
--------------------------------------------------------------------------------
--[[
FUNCTION str_util_trim
DESCRIPTION
  This function is used to trim a string
PARAMETERS
  s: the string to be trimed
RETURN VALUE
  The trimed string
]]
function str_util_trim (s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end;
--[[
FUNCTION str_util_expand
DESCRIPTION
  This function is used to expand a string
PARAMETERS
  s: the string to be expanded
RETURN VALUE
  The expanded string
EXAMPLE:
  name = "Lua"; status = "great"
  print(expand("$name is $status, isn't it?"))
  --> Lua is great, isn't it?
]]
function str_util_expand (s)
    return (string.gsub(s, "$(%w+)", function (n)
       return tostring(_G[n])
    end))
end
--[[
FUNCTION str_util_replace
DESCRIPTION
  This function is used to replace a string
PARAMETERS
  s: the string to be replaced
RETURN VALUE
  The replaced string
]]
function str_util_replace (s, pattern, reps)
    return (string.gsub(s, pattern, reps));
end;
--[[
FUNCTION str_util_split
DESCRIPTION
  This function is used to split a string
PARAMETERS
  s: the string to be splited
RETURN VALUE
  The splited string
]]
function str_util_split(szFullString, szSeparator, base)
  local nFindStartIndex = 1
  local nSplitIndex = 1
  local nSplitArray = {}
  while true do
   local nFindLastIndex = string.absfind(szFullString, szSeparator, nFindStartIndex);
   print("nFindLastIndex=", nFindLastIndex, " startIndex=", nFindStartIndex, "\r\n");
   local bak_FindStartIndex = nFindStartIndex;
   while (base and nFindLastIndex and (math.mod(nFindLastIndex,base) ~= 1)) do
     nFindStartIndex = nFindStartIndex + 1;
     nFindLastIndex = string.absfind(szFullString, szSeparator, nFindStartIndex);
   end;
   if not nFindLastIndex then
     nFindStartIndex = bak_FindStartIndex;
     nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
     break;
   end
   local sub_item = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1);
   if (sub_item and (string.len(sub_item) > 0))then
     nSplitArray[nSplitIndex] = sub_item;
   end;
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
  end
  return nSplitArray
end
--[[
FUNCTION str_util_parse_sio_report_parameter
DESCRIPTION
  This function is used to parse a parameter from the sio report string
PARAMETERS
  sio_rcvd_string: the string received from SIO
  report_header: the header of the report
  param_idx: the index of the parameter to get
  delimiter: the delimiter of the parameters
  right_token: the right token of the parameters
  remove_quota: remove quota for the parameter
RETURN VALUE
  The parsed string
]]
function str_util_parse_sio_report_parameter(sio_rcvd_string, report_header,  param_idx, delimiter, right_token, remove_quota)
  local report_header_pos = 0;
  if (not report_header) then
    return nil;
  end;
  if (report_header) then
    local idx = string.absfind(sio_rcvd_string,report_header);
	if (idx) then
	  sio_rcvd_string = string.sub(sio_rcvd_string, idx, -1);
	end;
  end;
  if (report_header_pos) then
    sio_rcvd_string = string.sub(sio_rcvd_string,report_header_pos,string.len(sio_rcvd_string));
    local left_colon_pos = string.len(report_header);
    if (left_colon_pos) then
      sio_rcvd_string = string.sub(sio_rcvd_string,left_colon_pos+1,string.len(sio_rcvd_string));
      for idx = 1, (param_idx -1), 1 do
        local left_comma_pos = string.absfind(sio_rcvd_string,delimiter);
        if (left_comma_pos) then
          sio_rcvd_string = string.sub(sio_rcvd_string,left_comma_pos+1,string.len(sio_rcvd_string));
        end;
      end;
      local right_token_pos = string.len(sio_rcvd_string) + 1;
      if (right_token) then
        right_token_pos = string.absfind(sio_rcvd_string,right_token);
      end;
      if (right_token_pos) then
        sio_rcvd_string = string.sub(sio_rcvd_string,1,right_token_pos-1);
        sio_rcvd_string = str_util_trim(sio_rcvd_string);
        if (remove_quota) then
          local len_of_parameter = string.len(sio_rcvd_string);
          if (len_of_parameter >= 2) then
            if ((string.sub(sio_rcvd_string,1,1) == "\"") and (string.sub(sio_rcvd_string,len_of_parameter,len_of_parameter) == "\"")) then
              if (len_of_parameter == 2) then
                return "";
              else
                return string.sub(sio_rcvd_string,2,len_of_parameter-1);
              end;
            end;
          end;
        else
          return sio_rcvd_string;
        end;
      end;
    end;
  end;
  print("failed to parse parameter\r\n");
  return nil;
end;
--[[
FUNCTION print_hex
DESCRIPTION
  This function is used to print a string in hex format
PARAMETERS
  data: the string to be printed
RETURN VALUE
  None
]]
function print_hex(data)
  local add_space = 1 --default 1
  local group_count = 4 --default -1
  local byte_each_line = 16 --default -1
  local add_ascii = 1 --default 0
  local hex_str = string.bin2hex(data);
  --local hex_str = string.bin2hex(data, add_space, group_count, byte_each_line, add_ascii);
  if (hex_str) then
    print(hex_str.."\r\n");
  else
    print("nil\r\n");
  end;
end;

--[[
FUNCTION str_util_convert_ascii_to_ucs2_text
DESCRIPTION
  This function is used to convert ASCII text to UCS2 text
PARAMETERS
  None
RETURN VALUE
  The converted text
]]
function str_util_convert_ascii_to_ucs2_text(ascii_text, little_endian)
  if (not ascii_text) then
    return "";
  end;
  local ucs2_chars = "";
  local char_idx;
  for char_idx = 1, string.len(ascii_text), 1 do
	local char = string.byte(ascii_text,char_idx);
	char = string.format("%02X", char);
	if (little_endian) then
	  char = char.."00";
	else
	  char = "00"..char;
	end;
	ucs2_chars = ucs2_chars..char;
  end;
  return ucs2_chars;
end;

--[[
FUNCTION str_util_ascii_bin_to_ucs2_bin_str
DESCRIPTION
  This function is used to convert binary ASCII text to UCS2 text
PARAMETERS
  None
RETURN VALUE
  The converted text
]]
function str_util_ascii_bin_to_ucs2_bin_str(ascii_text, little_endian, insert_char)
  if (not ascii_text) then
    return "";
  end;
  local ucs2_chars = "";
  local char_idx;
  if (not insert_char) then
    insert_char = 0;
  end;
  for char_idx = 1, string.len(ascii_text), 1 do
	local char = string.byte(ascii_text,char_idx);
	if (little_endian) then
	  ucs2_chars = string.appendbytes(ucs2_chars, char, 1);
	  ucs2_chars = string.appendbytes(ucs2_chars, insert_char, 1);      
	else
	  ucs2_chars = string.appendbytes(ucs2_chars, insert_char, 1);
      ucs2_chars = string.appendbytes(ucs2_chars, char, 1);
	end;
  end;
  return ucs2_chars;
end;

--[[
FUNCTION str_util_ucs2_bin_to_ascii_bin_str
DESCRIPTION
  This function is used to convert binary UCS2 text to ASCII text
PARAMETERS
  None
RETURN VALUE
  The converted text
]]
function str_util_ucs2_bin_to_ascii_bin_str(ucs2_text, little_endian)
  local ascii_text = "";
  if (not ucs2_text) then
    return "";
  end;
  local text_bytes = string.len(ucs2_text);
  for ucs2_idx = 1, text_bytes-1, 2 do
    local ucs2_code = 0;
	if (little_endian) then
	  ucs2_code = string.byte(ucs2_text, ucs2_idx) + string.byte(ucs2_text, ucs2_idx+1)*256;
	else
	  ucs2_code = string.byte(ucs2_text, ucs2_idx)*256 + string.byte(ucs2_text, ucs2_idx+1);
	end;
	ascii_text = ascii_text..string.fromint(ucs2_code, 1);
  end;
  return ascii_text;
end;