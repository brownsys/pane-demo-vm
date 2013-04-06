#!/usr/bin/python

# Initial skeleton from mininet/examples/sshd.py

from optparse import OptionParser

from mininet.net import Mininet
from mininet.cli import CLI
from mininet.log import lg
from mininet.node import Node, OVSKernelSwitch, RemoteController, CPULimitedHost
from mininet.link import TCLink
from mininet.util import irange, customConstructor

from PaneDemoUtil import LocalPaneController, PaneTopo, OVSTCSwitch, setupPaneNAT, clearPaneNAT, addDictOption



CONTROLLERDEF = 'local'
CONTROLLERS = { 'local': LocalPaneController,
                'remote': RemoteController }


class PaneDemo(object):
    "Run a PANE demo."

    def __init__(self):
        self.options = None
        self.args = None

        self.parseArgs()
        lg.setLogLevel('info')
        self.runDemo()

    def parseArgs(self):
        opts = OptionParser()
        addDictOption(opts, CONTROLLERS, CONTROLLERDEF, 'controller')
        self.options, self.args = opts.parse_args()

    def buildTopo(self):
        num_hosts = 7
        # 10 Mbps bandwidth and 2 ms delay on each link
        linkopts = dict(bw=10, delay='2ms', loss=0, use_htb=True)

        # Create an empty network with one switch
        topo = PaneTopo()
        switch = topo.addSwitch('s1')

        # Add gateway
        panenat = topo.addHost('pane-nat', inNamespace=False, cpu=0.02)
        topo.addLink(panenat, switch, **linkopts)

        # Add PANE controller
        panebrain = topo.addHost('panebrain', inNamespace=False, cpu=0.08)
        topo.addLink(panebrain, switch, **linkopts)

        # Add some regular hosts
        for h in irange(1, num_hosts):
            host = topo.addHost('host%s' % h, cpu=0.4/num_hosts)
            topo.addLink(host, switch, **linkopts)

        return topo

    def launchNetwork(self, network, host_cmd, host_cmd_opts):
        network.start()
        setupPaneNAT(network)

        print
        print "*** Hosts are running sshd at the following addresses:"
        print
        for host in network.hosts:
            host.cmd(host_cmd + ' ' + host_cmd_opts + '&')
            print host.name, host.IP()

    def teardownNetwork(self, network, host_cmd):
        print
        print "*** Shutting-down SSH daemons"
        print
        for host in network.hosts:
            host.cmd( 'kill %' + host_cmd )

        clearPaneNAT(network)
        network.stop()

    def runDemo(self, host_cmd='/usr/sbin/sshd', host_cmd_opts='-D'):
        topo = self.buildTopo()
        controller = customConstructor(CONTROLLERS, self.options.controller)

        network = Mininet(topo, controller=controller, link=TCLink, 
                          # host=CPULimitedHost, # TODO(adf) upgrade Ubuntu?
                          switch=OVSTCSwitch, ipBase='10.0.0.0/24')

        self.launchNetwork(network, host_cmd, host_cmd_opts)
        self.demo(network)
        self.teardownNetwork(network, host_cmd)

    def demo(self, network):
        # Generally, this will be overriden for more interesting demos
        print
        print "*** Type 'exit' or control-D to shut down network"
        CLI( network )


if __name__ == '__main__':
    PaneDemo()
