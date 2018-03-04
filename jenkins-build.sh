#!/bin/bash

BB_USER="mjclark1"
BB_TICKET="yxdetAz5P4uH8qjuXER9"
BB_AUTH_STRING=${BB_USER}:${BB_TICKET}

cd simreporter
python buildrelease.py -n
if [ $? -eq 0 ] ; then
    export image=`ls -rt build/*.zip | tail -1`
    echo "`date`: Image is ${image}"
    echo "`date`: Build successful and image uploaded."
    without_zip=`echo ${image} | sed 's/.zip//g'`
    tag_name=`basename ${without_zip}`
    git tag ${tag_name}
    git push --tags
    curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/poslive/lua-tool-simreporter/downloads" --form files=@"${image}"
fi
