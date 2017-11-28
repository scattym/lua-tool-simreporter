#!/bin/bash

while true; do
    if git pull | grep -q "Already up-to-date" ; then
        echo "`date`: Lua tool simreporter already up to date"
    else
        ./buildrelease.py -n
        if [ $? -eq 0 ] ; then
            docker exec --user=root nmeaproxy bash -c 'rm /tmp/firmware/*.zip'
            image=`ls -rt build/*.zip | tail -1`
            echo "`date`: Image is ${image}"
            docker cp build/${image} nmeaproxy:/tmp/firmware
            echo "`date`: Build successful and image uploaded."
        fi
    fi
    echo "`date`: Sleeping for 60 seconds"
    sleep 60
done
