#!/usr/bin/python

import time
import threading

from mininet.cli import CLI

from PaneDemo import PaneDemo

class ZooKeeperDemo(PaneDemo):
    network = None
    iperfWaitCount = 0
    iperfWaitSemaphore = threading.Semaphore()
    iperfWaitEvent = threading.Event()

    def demo(self, network):
        self.network = network

        # Run a baseline ZooKeeper benchmark
        self.zkmanage("conf-nopane", "start")
        self.benchmark("no-pane-pre")
        self.pause(5)

        # Now run a benchmark while links are heavily loaded
        self.iperfLaunch()
        self.benchmark("no-pane-post")
        print "Waiting for iperf to finish..."
        self.iperfWait()
        self.pause(5)

        # Restart with a PANE-enabled ZooKeeper
        self.zkmanage("conf-nopane", "stop")
        self.pause(2)
        self.zkmanage("conf-nopane", "start") # XXX change when pane is creating multiple queues properly
        self.pause(5)

        # Run the benchmark again with heavily loaded links
        self.iperfLaunch()
        self.benchmark("with-pane")
        print "Waiting for iperf to finish..."
        self.iperfWait()
        self.pause(5)

        # Shutdown
        self.zkmanage("conf-nopane", "stop") # XXX change when pane is creating multiple queues properly


    def netexec(self, cmd, host="host1", verbose=False):
        h = self.network.getNodeByName(host)
        h.cmd('su -c "' + cmd + '" paneuser', verbose=verbose)

    def zkmanage(self, conf, cmd):
        msg = "Starting" if cmd == "start" else "Stopping"
        print
        print "*** " + msg + " ZooKeeper:"
        print
        self.netexec("/home/paneuser/zookeeper/zk-manage.sh %s %s" % (conf, cmd),
                     host="panebrain")

    def benchmark(self, name):
        print
        print "*** Starting benchmark: " + name
        print
        self.netexec("/home/paneuser/zookeeper/zookeeper-benchmark/"
                  "runBenchmark.sh %s --gnuplot" % name, host="panebrain")

    def pause(self, length):
        print
        print "*** Pausing for " + str(length) + " seconds"
        print
        time.sleep(length)

    def iperfLaunch(self):
        print
        print "*** Starting bulk traffic flows with iperf"
        print

        with self.iperfWaitSemaphore:
            self.iperfWaitCount = 7 # num runners + 1

        iperfRunner(self, "host1", False).start()
        iperfRunner(self, "host2", True, "host1").start()
        iperfRunner(self, "host3", False).start()
        iperfRunner(self, "host4", True, "host3").start()
        iperfRunner(self, "host5", False).start()
        iperfRunner(self, "host6", True, "host5").start()

        print "Pausing for 15 seconds to let the traffic build up..."
        time.sleep(15)

    def iperfWait(self):
        # Based on lightweight barrier described at:
        # http://stackoverflow.com/questions/887346/synchronising-multiple-threads-in-python
        with self.iperfWaitSemaphore:
            self.iperfWaitCount -= 1
            if self.iperfWaitCount == 0:
                self.iperfWaitEvent.set()

        self.iperfWaitEvent.wait()


class iperfRunner(threading.Thread):
    zkdemo = None
    host = None
    client = None
    target = None

    def __init__(self, zkdemo, host, client, target=None):
        self.zkdemo = zkdemo
        self.host = host
        self.client = client
        self.target = target
        threading.Thread.__init__(self)

    def run(self):
        if self.client:
            cmd = "iperf -c %s -d -t 240" % self.target
        else:
            cmd = "iperf -s"
        self.zkdemo.netexec(cmd, host=self.host)
        self.zkdemo.iperfWait()


if __name__ == '__main__':
    ZooKeeperDemo()
