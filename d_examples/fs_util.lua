--------------------------------------------------------------------------------
--脚本说明
--本脚本包含文件系统相关操作函数
--------------------------------------------------------------------------------
function fs_util_init(context)
  print("fs_util_init\r\n");
  context.fs_efs_dir = {};
  context.fs_efs_dir[1] = "C:\\";
  context.fs_efs_dir[2] = "C:\\Picture\\";
  context.fs_efs_dir[3] = "C:\\Video\\";
  context.fs_efs_dir[4] = "C:\\VideoCall\\";
  --context.fs_efs_dir[4] = "D:\\Picture\\";
  --context.fs_efs_dir[5] = "D:\\Video\\";
  --context.fs_efs_dir[6] = "D:\\VideoCall\\";
  --context.fs_efs_dir[7] = "C:\\Audio\\";
  --context.fs_efs_dir[8] = "D:\\Audio\\";
  
  context.fs_loca_type = {};
  context.fs_loca_type.flash = 0;--inner efs
  context.fs_loca_type.tfcard = 1;--tfcard
end;

function fs_util_get_dir_no(context, dir)
  for idx = 1, table.maxn(context.fs_efs_dir), 1 do
    if (string.startwith(dir,context.fs_efs_dir[idx])) then
	  return idx;
	end;
  end;
  return nil;
end;

function fs_util_get_current_dir(context)
  local header = "\r\n+FSCD:";
  local rsp, idx = sio_send_and_recv2(context, "AT+FSCD?\r\n", header, "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    local end_pos = string.absfind(rsp, "\r\n", 3);
	if (end_pos) then	  
	  local result = string.sub(rsp, string.len(header)+1, end_pos-1);
	  if (result) then
	    result = str_util_trim(result);
	  end;
	  print("succeeded in calling fs_util_get_current_dir, file=",result,"\r\n");
	  return result;
	end;
    return nil;
  else
    return nil;
  end;
end;

function fs_util_set_current_dir(context, dir)
  if (not dir) then
    return;
  end;
  dir = str_util_replace(dir, "\\", "/");
  local header = "\r\n+FSCD:";
  local rsp, idx = sio_send_and_recv2(context, "AT+FSCD="..dir.."\r\n", header, "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    local end_pos = string.absfind(rsp, "\r\n", 3);
	if (end_pos) then	  
	  local result = string.sub(rsp, string.len(header)+1, end_pos-1);
	  if (result) then
	    result = str_util_trim(result);
	  end;
	  print("succeeded in calling fs_util_get_current_dir, file=",result,"\r\n");
	  return result;
	end;
    return nil;
  else
    return nil;
  end;
end;

function fs_util_mkdir(context, dir)
  if (not dir) then
    return;
  end;
  dir = str_util_replace(dir, "\\", "/");
  local rsp, idx = sio_send_and_recv2(context, "AT+FSMKDIR="..dir.."\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    return true;
  else
    return false;
  end;
end;

function fs_util_rmdir(context, dir)
  if (not dir) then
    return;
  end;
  dir = str_util_replace(dir, "\\", "/");
  local rsp, idx = sio_send_and_recv2(context, "AT+FSRMDIR="..dir.."\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    return true;
  else
    return false;
  end;
end;

function fs_util_del(context, filename)
  if (not filename) then
    return;
  end;
  filename = str_util_replace(filename, "\\", "/");
  local rsp, idx = sio_send_and_recv2(context, "AT+FSDEL="..filename.."\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    return true;
  else
    return false;
  end;
end;

function fs_util_rename(context, old_filename, new_filename)
  if (not old_filename or not new_filename) then
    return;
  end;
  filename = str_util_replace(filename, "\\", "/");
  local rsp, idx = sio_send_and_recv2(context, "AT+FSRENAME="..old_filename..","..new_filename.."\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    return true;
  else
    return false;
  end;
end;

function fs_util_attri(context, filename)
  if (not filename) then
    return;
  end;
  filename = str_util_replace(filename, "\\", "/");
  local header = "\r\n+FSATTRI:";
  local rsp, idx = sio_send_and_recv2(context, "AT+FSATTRI="..filename.."\r\n", header, "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    local end_pos = string.absfind(rsp, "\r\n", 3);
	if (end_pos) then	  
	  local filesize = str_util_parse_sio_report_parameter(rsp,header,1,",",",",false);
	  local datetime = str_util_parse_sio_report_parameter(rsp,header,2,",","\r\n",false);
	  if (filesize) then
	    filesize = tonumber(filesize);
	  end;
	  local result = string.sub(rsp, string.len(header)+1, end_pos-1);
	  if (result) then
	    result = str_util_trim(result);
	  end;	  
	  print("succeeded in calling fs_util_attri, atrri=",result,"\r\n");
	  return result;
	end;
    return nil;
  else
    return nil;
  end;
end;

function fs_util_get_memory_info(context)
  local header = "\r\n+FSMEM:";
  local rsp, idx = sio_send_and_recv2(context, "AT+FSMEM\r\n", header, "\r\nERROR\r\n", 5000);
  if ((idx == 1)) then
    --test
	--rsp = "\r\n+FSMEM: C:(11348480, 2201600), D:(255533056, 42754048)\r\n\r\nOK\r\n";
	--end of test
    local end_pos = string.absfind(rsp, "\r\n", 3);
	if (end_pos) then	  
	  local result = string.sub(rsp, string.len(header)+1, end_pos-1);
	  if (result) then
	    result = str_util_trim(result);
	  end;	  
	  local diskc_start_pos = string.absfind(rsp, "C:(");
	  if (diskc_start_pos) then
	    local diskc_end_pos = string.absfind(rsp, ")", diskc_start_pos);
		if (diskc_end_pos) then
		  local diskc_info = string.sub(rsp, diskc_start_pos+3, diskc_end_pos-1);
		  local diskd_info = nil;
		  local diskd_start_pos = string.absfind(rsp, "D:(");
		  if (diskd_start_pos) then
		    local diskd_end_pos = string.absfind(rsp, ")", diskd_start_pos);
			if (diskd_end_pos) then
		      diskd_info = string.sub(rsp, diskd_start_pos+3, diskd_end_pos-1);
		    end;
		  end;
		  local diskc_total_size = nil;
		  local diskc_used_size = nil;
		  local diskd_total_size = nil;
		  local diskd_used_size = nil;
		  if (diskc_info) then
		    local comma_pos = string.absfind(diskc_info, ",");
			if (comma_pos) then
			  diskc_total_size = tonumber(str_util_trim(string.sub(diskc_info,1,comma_pos-1)));
			  diskc_used_size = tonumber(str_util_trim(string.sub(diskc_info,comma_pos+1,-1)));
			end;
		  end;
		  if (diskd_info) then
		    local comma_pos = string.absfind(diskd_info, ",");
			if (comma_pos) then
			  diskd_total_size = tonumber(str_util_trim(string.sub(diskd_info,1,comma_pos-1)));
			  diskd_used_size = tonumber(str_util_trim(string.sub(diskd_info,comma_pos+1,-1)));
			end;
		  end;		  
		  print("diskc_info=",diskc_info, "\r\n");
		  print("diskd_info=",diskd_info, "\r\n");
		  local result_tab = {};
		  result_tab.diskc_total_size = diskc_total_size;
		  result_tab.diskc_used_size = diskc_used_size;
		  result_tab.diskd_total_size = diskd_total_size;
		  result_tab.diskd_used_size = diskd_used_size;
		  print("succeeded in calling fs_util_get_memory_info\r\n");
		  return result_tab;
		end;
	  end;	  
	  
	  return nil;
	end;
    return nil;
  else
    return nil;
  end;
end;

function fs_util_loca(context, loca)
  local header = "\r\n+FSLOCA:";
  local cmd = "AT+FSLOCA?\r\n";
  if (loca) then
    cmd = "AT+FSLOCA="..loca.."\r\n";
  end;
  local rsp, idx = sio_send_and_recv3(context, cmd, header, "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx == 1) then
    local end_pos = string.absfind(rsp, "\r\n", 3);
	if (end_pos) then	  
	  local result = string.sub(rsp, string.len(header)+1, end_pos-1);
	  if (result) then
	    result = str_util_trim(result);
	  end;	  
	  if (result) then
	    result = tonumber(result);
	  end;
	  print("succeeded in calling fs_util_loca, loca=",result,"\r\n");
	  return result;
	end;
    return nil;
  elseif (idx == 2) then
    if (not loca) then
	  return nil;
	end;
    return true;
  else
    return nil;
  end;
end;

function fs_util_unit_test(context)
  print("-------------------1----------------------\r\n");
  local fsloca = fs_util_loca(context, loca);
  print("-------------------2----------------------\r\n");
  local memory_info = fs_util_get_memory_info(context);
  print(memory_info.diskc_total_size, " ", memory_info.diskc_used_size, " ", memory_info.diskd_total_size, " ", memory_info.diskd_used_size, "\r\n");
end;
