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

echo $URL
echo $TOKEN
echo $NAME

docker build --build-arg url=$URL --build-arg token=$TOKEN --build-arg name=$NAME -t "sysy-action-runner:latest" .