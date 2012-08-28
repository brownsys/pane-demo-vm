#!/usr/bin/python

from mininet.cli import CLI

from PaneDemo import PaneDemo

class ZooKeeperDemo(PaneDemo):

    def demo(self, network):
        print
        print "*** Starting ZooKeeper:"
        print
        host1 = network.getNodeByName('host1')
        host1.cmd('su -c "/home/paneuser/zookeeper/zk-manage.sh conf-pane start"'
                  ' paneuser', verbose=True)

        print
        print "*** Type 'exit' or control-D to shut down network"
        CLI( network )

        print
        print "*** Stopping ZooKeeper:"
        print
        host1 = network.getNodeByName('host1')
        host1.cmd('su -c "/home/paneuser/zookeeper/zk-manage.sh conf-pane stop"'
                  ' paneuser', verbose=True)

if __name__ == '__main__':
    ZooKeeperDemo()
