#!/bin/bash
THETA_VERSION="v4.2.2"

apt-get install libgomp1 -y

wget "https://github.com/ftsrg/theta/releases/download/$THETA_VERSION/theta-xsts-cli.jar" -O ./theta-xsts-cli.jar
wget "https://github.com/ftsrg/theta/raw/$THETA_VERSION/lib/libz3.so" -O ./libz3.so
wget "https://github.com/ftsrg/theta/raw/$THETA_VERSION/lib/libz3java.so" -O ./libz3java.so
