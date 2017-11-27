#!/bin/bash

while true; do
    if git pull | grep -q "Already up-to-date" ; then
        echo "`date`: Lua tool simreporter already up to date"
    else
        ./buildrelease.py
    fi
    echo "`date`: Sleeping for 60 seconds"
    sleep 60
done
