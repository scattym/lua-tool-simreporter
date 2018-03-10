#!/bin/bash

BB_USER="mjclark1"
BB_TICKET="yxdetAz5P4uH8qjuXER9"
BB_AUTH_STRING=${BB_USER}:${BB_TICKET}

cd simreporter
python buildrelease.py -n
if [ $? -eq 0 ] ; then
    cd build
    export image=`ls -rt *.zip | tail -1`
    echo "`date`: Image is ${image}"
    curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/poslive/lua-tool-simreporter/downloads" --form files=@"${image}"
fi
