local _M = {}

local unzip_file = function(zipfile, output_dir)
    os.mkdir(output_dir)

    local rst
    local zip_handle = miniunz.openzip(zipfile)
    print(zip_handle)
    if( not zip_handle ) then
        print("Failed to open zip file\r\n")
        return
    end

    while( true ) do
        local filename, filesize, crypted = miniunz.get_current_entry_info(zip_handle)
        if( filename ) then
            print("filname: ", filename, " size: ", filesize, "\r\n")
        else
              print("failed to get entry\r\n")
        end
        rst = miniunz.extract_current_file(zip_handle, nil, output_dir)
        print("Unzip result is: ", rst, "\r\n")
        if( not miniunz.goto_next_entry(zip_handle) ) then
            print("No more entries\r\n")
            break
        end
    end
    rst = miniunz.closezip(zip_handle)
    print("Close result is: ", rst, "\r\n")
    collectgarbage()
end

_M.unzip_file = unzip_file

return _M