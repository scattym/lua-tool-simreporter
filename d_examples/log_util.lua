--------------------------------------------------------------------------------
--脚本说明
--本脚本包含日志处理相关操作函数
--------------------------------------------------------------------------------
function log_init(context)
  print("log_init\r\n");
  local dt = os.date("*t");
  --context.log_filename = string.format("C:\\Picture\\VS-MSC3401D_%04d%02d%02d%02d%02d%02d.log", dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec);
  context.log_filename = string.format("C:\\Picture\\VS-MSC3412D_log.txt", dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec);
  context.log_filehandle = nil;
  --context.log_cache = "";
  context.log_max_length = 200*1024;
  context.log_mark = 1;
end;

function logfile_length(context)
  if (not context.log_filename) then
    return 0;
  else
    local len = os.filelength(context.log_filename);
	if (len < 0) then
	  len = 0;
	end;
	return len;
  end;
end;

function logfile_open(context)
  print("logfile_open\r\n");
  local backup_file = false;
  if (os.filelength(context.log_filename) >= context.log_max_length) then
    backup_file = true;
    local dt = os.date("*t");
    local bak_log_filename = string.format("C:\\Picture\\VS-MSC3401D_%d_%04d%02d%02d%02d%02d%02d.log", context.log_mark, dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec);
	context.log_mark = context.log_mark + 1;
	os.rename(context.log_filename, bak_log_filename);
  end;
  context.log_filehandle = io.open(context.log_filename, "w");
  if (not context.log_filehandle) then
    print("ERROR! failed to open log file\r\n");
    return false;
  end;
  if (backup_file) then
    context.log_filehandle:trunc();
  end
  context.log_filehandle:seek("end");
  return true;
end;

function logfile_write_new_line(context, content)
  print("logfile_write_new_line\r\n");
  if (logfile_open(context)) then
    if (content and (string.len(content) > 0) and context.log_filehandle) then
      local dt = os.date("*t");
	  local stamp = string.format("%04d-%02d-%02d %02d:%02d:%02d  ", dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec);
	  local new_line = stamp..content.."  \n";
      context.log_filehandle:write(new_line);
    end;
    context.log_filehandle:close();
  end;
end;

function logfile_close(context)
  print("logfile_close\r\n");
  if (context.log_filehandle) then
    context.log_filehandle:close();
	context.log_filehandle = nil;
  end;
end;