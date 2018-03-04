#!/bin/bash

cd simreporter
python buildrelease.py -n
if [ $? -eq 0 ] ; then
    export image=`ls -rt build/*.zip | tail -1`
    echo "`date`: Image is ${image}"
fi
