#!/bin/bash

BB_USER="mjclark1"
BB_TICKET="yxdetAz5P4uH8qjuXER9"
BB_AUTH_STRING=${BB_USER}:${BB_TICKET}
while true; do
    if git pull | grep -q "Already up-to-date" ; then
        echo "`date`: Lua tool simreporter already up to date"
    else
        ./buildrelease.py -n
        if [ $? -eq 0 ] ; then
            docker exec --user=root nmeaproxy bash -c 'rm /tmp/firmware/*.zip'
            image=`ls -rt build/*.zip | tail -1`
            echo "`date`: Image is ${image}"
            docker cp ${image} nmeaproxy:/tmp/firmware
            if [ $? -eq 0 ] ; then
                echo "`date`: Build successful and image uploaded."
                without_zip=`echo ${image} | sed 's/.zip//g'`
                tag_name=`basename ${without_zip}`
                git tag ${tag_name}
                git push --tags
                curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/${BB_USER}/${lua-tool-simreporter}/downloads" --form files=@"${image}"
            fi
        fi
    fi
    echo "`date`: Sleeping for 60 seconds"
    sleep 60
done
