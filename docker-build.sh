#!/bin/bash

while [ -z $URL ]; do
    echo -n "[URL of the git repo]:"
    read URL
done

while [ -z $TOKEN ]; do
    echo -n "[Token to add runner]:"
    read TOKEN
done

if [ -z $NAME ]; then
    echo -n "[Runner name (default hostname)]:"
    read NAME
fi

if [ -z $NAME ]; then
    NAME=$(hostname)
fi

docker build --build-arg url=$URL --build-arg token=$TOKEN --build-arg name=$NAME --build-arg uid=$UID --build-arg gid=$(getent group docker | awk -F: '{print $3}') -t "sysy-action-runner:latest" .
