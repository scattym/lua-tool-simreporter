#!/bin/bash

while true; do
    if git pull | grep -q "Already up-to-date" ; then
        echo "`date`: Lua tool simreporter already up to date"
    else
        ./buildrelease.py -n
        result=$?
        if [ ${result} == 0 ] ; then
            docker exec --user=root nmeaproxy bash -c 'rm /tmp/firmware/*.zip'
            image=`ls -rt build | tail -1`
            docker cp ${image} nmeaproxy:/tmp/firmware
        fi
    fi
    echo "`date`: Sleeping for 60 seconds"
    sleep 60
done
