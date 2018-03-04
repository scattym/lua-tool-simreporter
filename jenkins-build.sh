#!/bin/bash

cd simreporter
python buildrelease.py -n
        if [ $? -eq 0 ] ; then
            export image=`ls -rt build/*.zip | tail -1`
            echo "`date`: Image is ${image}"
#            if [ $? -eq 0 ] ; then
#                echo "`date`: Build successful and image uploaded."
#                without_zip=`echo ${image} | sed 's/.zip//g'`
#                tag_name=`basename ${without_zip}`
#                git tag ${tag_name}
#                git push --tags
#                curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/${BB_USER}/lua-tool-simreporter/downloads" --form files=@"${image}"
#            fi
        fi
    fi
