#!/bin/bash

ZK_DIR="/home/paneuser/zookeeper/"
SSH_OPTS="-o StrictHostKeyChecking=no"

SERVER_CONF=$1
SERVER_CMD=$2

if [ "$SERVER_CONF" != "conf-pane" ] && [ "$SERVER_CONF" != "conf-nopane" ]; then
    echo "Invalid ZooKeeper configuration requested."
    exit
fi

ssh $SSH_OPTS host1 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 1 $SERVER_CMD
ssh $SSH_OPTS host2 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 2 $SERVER_CMD
ssh $SSH_OPTS host3 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 3 $SERVER_CMD
ssh $SSH_OPTS host4 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 4 $SERVER_CMD
ssh $SSH_OPTS host5 $ZK_DIR/zk-server-wrapper.sh $SERVER_CONF 5 $SERVER_CMD
