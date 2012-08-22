#!/bin/bash

ZK_DIR="/home/pane/zookeeper/"
ZK_BIN_DIR="$ZK_DIR/pane-zookeeper/bin"

SERVER_CONF=$1
SERVER_NUM=$2
SERVER_CMD=$3

export ZOOCFGDIR=$ZK_DIR/server$SERVER_NUM/$SERVER_CONF
export ZOO_LOG_DIR=$ZK_DIR/server$SERVER_NUM/logs

if [ ! -d "$ZOOCFGDIR" ]; then
    echo "ZOOCFGDIR does not exist: $ZOOCFGDIR"
    exit
fi

$ZK_BIN_DIR/zkServer.sh $SERVER_CMD
