#!/usr/bin/python

import matplotlib
from pylab import *

import sys
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
        self.network.pingAll()
        subplot(111)
        semilogx()
        ion()
        hold(True)
        title("ZooKeeper Benchmark Example Results")
        xlabel("Latency of CREATE (s)")
        ylabel("Cummulative Distribution Function (CDF)")

        # Run a baseline ZooKeeper benchmark
        self.zkmanage("conf-nopane", "start")
        self.benchmark("no-pane-pre")
        self.pause(5)

        # Now run a benchmark while links are heavily loaded
        self.iperfLaunch()
        self.benchmark("no-pane-post")
        legend(('Pre', 'Post'))
        draw()
        self.iperfWait(verbose=True)
        self.pause(5)

        # Restart with a PANE-enabled ZooKeeper
        self.zkmanage("conf-nopane", "stop")
        self.pause(2)
        self.zkmanage("conf-pane", "start")
        self.pause(5)

        # Make reservations for benchmark client
        print
        print "*** Reserving bandwidth for benchmark client"
        print
        self.netexec("cat zookeeper/benchmark-resvs.txt | telnet panebrain 4242",
                     host="host7")
        self.pause(2)

        # Run the benchmark again with heavily loaded links
        self.iperfLaunch()
        self.benchmark("with-pane")
        legend(('Pre', 'Post', 'PANE'))
        draw()
        self.iperfWait(verbose=True)
        CLI(self.network)

        # Shutdown
        self.zkmanage("conf-pane", "stop")
        self.pause(5)


    def netexec(self, cmd, host="host1", verbose=False):
        h = self.network.getNodeByName(host)
        h.cmd('su -c "' + cmd + '" paneuser', verbose=verbose)

    def zkmanage(self, conf, cmd):
        msg = "Starting" if cmd == "start" else "Stopping"
        sys.stdout.write("\n*** " + msg + " ZooKeeper: ")
        sys.stdout.flush()
        self.netexec("/home/paneuser/zookeeper/zk-manage.sh %s %s" % (conf, cmd),
                     host="host7", verbose=True)
        sys.stdout.write("done\n\n")

    def benchmark(self, name):
        print
        print "*** Starting benchmark: " + name
        print
        self.netexec("/home/paneuser/zookeeper/zookeeper-benchmark/"
                     "runBenchmark.sh %s /home/paneuser/zookeeper/"
                     "benchmark-mn.conf --gnuplot" % name, host="host7",
                     verbose=True)
        t = self.readLatencies(name, "CREATE")
        plot(t, arange(0, len(t)) / float(len(t)))
        draw()

    def pause(self, length):
        sys.stdout.write("\n*** Pausing for " + str(length) + " seconds: ")
        sys.stdout.flush()
        time.sleep(length)
        sys.stdout.write("done\n\n")

    def iperfLaunch(self):
        print
        print "*** Starting bulk traffic flows with iperf"
        print

        with self.iperfWaitSemaphore:
            self.iperfWaitCount = 7 # num runners + 1
            self.iperfWaitEvent.clear()

        iperfRunner(self, "host1", False).start()
        time.sleep(1)
        iperfRunner(self, "host2", True, "host1").start()
        time.sleep(1)
        iperfRunner(self, "host3", False).start()
        time.sleep(1)
        iperfRunner(self, "host4", True, "host3").start()
        time.sleep(1)
        iperfRunner(self, "host5", False).start()
        time.sleep(1)
        iperfRunner(self, "host6", True, "host5").start()

        sys.stdout.write("Pausing for 15 seconds to let the traffic build up... ")
        sys.stdout.flush()
        time.sleep(15)
        sys.stdout.write("done\n")

    def iperfWait(self, verbose=False):
        # Based on lightweight barrier described at:
        # http://stackoverflow.com/questions/887346/synchronising-multiple-threads-in-python

        if verbose:
            sys.stdout.write("\n*** Waiting for iperf to finish... ")
            sys.stdout.flush()

        with self.iperfWaitSemaphore:
            self.iperfWaitCount -= 1
            if self.iperfWaitCount == 0:
                self.iperfWaitEvent.set()

        self.iperfWaitEvent.wait()

        if verbose:
            sys.stdout.write("done\n\n")

    def readLatencies(self, benchmark, test):
        latencies = []
        for hostnum in [0, 1, 2, 3, 4]:
            f = open("/home/paneuser/zookeeper/zookeeper-benchmark/"
                    "%s/%d-%s_timings.dat" % (benchmark, hostnum, test))
            for line in f:
                (start, end) = map(float, line.split(" "))
                latencies.append(end - start)

        return sort(latencies)


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
            cmd = "iperf -s -P 1"
        self.zkdemo.netexec(cmd, host=self.host)
        self.zkdemo.iperfWait()


if __name__ == '__main__':
    ZooKeeperDemo()
