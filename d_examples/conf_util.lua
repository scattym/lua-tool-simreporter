--------------------------------------------------------------------------------
--脚本说明
--本脚本包含系统配置以及OTAD Phone number manager相关操作函数
--------------------------------------------------------------------------------
--[[
  This file contains the configuration file loading and saving functions
]]
function conf_util_init(context)
  print("conf_util_init\r\n");
  context.conf_filename = "C:\\otad.conf";
  context.conf_phone_number_manager_filename = "C:\\otad_pn.conf"; 
  context.conf_phone_number_manager_filename_w = "C:\\otad_pn_w.conf"; 
  
  context.phone_number_list = {};
end;
--[[
FUNCTION conf_util_load
DESCRIPTION
  This function is used to load configuration from EFS
PARAMETERS
  None
RETURN VALUE
  None
]]
function conf_util_load(context)
  local file = io.open(context.conf_filename, "r");
  if (not file) then
    conf_util_save(context);
	return;
  end;
  local cnt;

  --------------------------------------------
  cnt = file:read("*l");
  if (cnt) then
    context.current_log_info_report_type = tonumber(cnt);
  else
    file:close();
    return;
  end;
  --------------------------------------------
  --[[cnt = file:read("*l");
  if (cnt) then
    context.current_log_info_report_phone_number = cnt;
  else
    file:close();
    return;
  end;
  --]]
  --------------------------------------------
    cnt = file:read("*l");
  if (cnt) then
    context.current_log_info_report_ip_addr = cnt;
  else
    file:close();
    return;
  end;
  --------------------------------------------

  file:close();
end;
--[[
FUNCTION conf_util_save
DESCRIPTION
  This function is used to save configuration to EFS
PARAMETERS
  None
RETURN VALUE
  None
]]
function conf_util_save(context)
  local file = io.open(context.conf_filename, "w");
  if (not file) then
    return;
  end;
  file:trunc();

  file:write(context.current_log_info_report_type.."\n");
  --file:write(context.current_log_info_report_phone_number.."\n");
  file:write(context.current_log_info_report_ip_addr.."\n");

  file:close();
end;

function conf_util_reset(context)
  conf_util_save(context);
end;

function conf_util_load_pn_manager(context)
  print("conf_util_load_pn_manager(in)\r\n");
  local file = io.open(context.conf_phone_number_manager_filename, "r");
  if (not file) then
    print("conf_util_load_pn_manager() -- otad_pn.conf is not exsit\r\n");
	return;
  end;
  local cnt;
  local cnt_tmp;
  local phonenum;

  --------------------------------------------
  cnt = file:read("*l");
  if (cnt) then 
    --清空Phone num list
    for index = 1, table.maxn(context.phone_number_list), 1 do
        table.remove(context.phone_number_list, index);
    end;
    
    phonenum = cnt;    
    cnt_tmp = cnt;
    
    while(true) do
      if(nil == cnt_tmp)then
        break;
      end;
      local resultFind = string.find(cnt_tmp, "|", 1);
      
      if(resultFind) then
        if(resultFind > 1) then
            phonenum = string.sub(cnt_tmp, 1, resultFind-1);
            if(table.maxn(context.phone_number_list) < 10) then
                table.insert(context.phone_number_list, phonenum);
            else
                break;
            end;
            print("have phonenum = ", phonenum,"\r\n");
        else
        end;       
        
      else
        if(cnt_tmp and (string.len(cnt_tmp) > 0)) then
            phonenum = cnt_tmp;            
            if(table.maxn(context.phone_number_list) < 10) then
                table.insert(context.phone_number_list, phonenum);
            else
                break;
            end;            
            print("have phonenum = ", phonenum, "\r\n");
        end;
        
        break;
      end;
      
      cnt_tmp = string.sub(cnt_tmp, resultFind + 1, string.len(cnt_tmp));
    end;
    
  else
    file:close();
    return;
  end;

  file:close();
  
  print("conf_util_load_pn_manager(out)\r\n");
end;

function conf_util_save_pn_manager(context)
  local file = io.open(context.conf_phone_number_manager_filename_w, "w");
  if (not file) then
    return;
  end;
  --写文件之间，清空文件内容。
  file:trunc();

  if (context.phone_number_list) then
    for index = 1, table.maxn(context.phone_number_list), 1 do
      file:write(context.phone_number_list[index].."|");
      print("conf_util_save_pn_manager() -->> ", context.phone_number_list[index], "\r\n");
    end;
  end;
  
    --[[清空Phone num list
    for index = 1, table.maxn(context.phone_number_list), 1 do
        print("clear the phone number list\r\n");
        table.remove(context.phone_number_list, index);
    end;
    --]]
  file:close();
end;

function conf_util_reset_pn_manager(context)
    conf_util_save_pn_manager(context);
end;