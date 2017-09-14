local _M = {}

local unzip_file = function(zipfile, output_dir)
    os.mkdir(output_dir)

    local result = true
    local zip_handle = miniunz.openzip(zipfile)
    print(zip_handle)
    if( not zip_handle ) then
        print("Failed to open zip file\r\n")
        return false
    end

    while( true ) do
        local filename, filesize, crypted = miniunz.get_current_entry_info(zip_handle)
        if( filename ) then
            print("filname: ", filename, " size: ", filesize, "\r\n")
        else
            print("failed to get entry\r\n")
        end
        local unzip_result = miniunz.extract_current_file(zip_handle, nil, output_dir)
        if( unzip_result ~= 0 ) then
            result = false
        end
        print("Unzip result is: ", unzip_result, "\r\n")
        if( not miniunz.goto_next_entry(zip_handle) ) then
            print("No more entries\r\n")
            break
        end
    end
    close_result = miniunz.closezip(zip_handle)
    print("Close result is: ", close_result, "\r\n")
    collectgarbage()
    return result
end

_M.unzip_file = unzip_file

return _M