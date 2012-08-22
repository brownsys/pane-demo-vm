#!/bin/bash

ZK_DIR="/home/pane/zookeeper/"

SERVER_CONF=$1
SERVER_CMD=$2

if [ "$SERVER_CONF" != "conf-pane" ] && [ "$SERVER_CONF" != "conf-nopane" ]; then
    echo "Invalid ZooKeeper configuration requested."
    exit
fi

ssh host1 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 1 $SERVER_CMD
ssh host2 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 2 $SERVER_CMD
ssh host3 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 3 $SERVER_CMD
ssh host4 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 4 $SERVER_CMD
ssh host5 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 5 $SERVER_CMD
