#!/usr/bin/python

# Initial skeleton from mininet/examples/sshd.py
# NAT setup inspired by netcore/examples/Gateway.py

from mininet.net import Mininet
from mininet.cli import CLI
from mininet.log import lg
from mininet.node import Node, OVSKernelSwitch, Controller, CPULimitedHost
from mininet.topo import Topo
from mininet.link import TCLink
from mininet.util import irange

from time import sleep


# TODO(adf): alternately, it should be possible to use a remote controller
# running outside the VM. this would be great for testing.

class LocalPaneController(Controller):
    def __init__(self, name, pane_cmd='./pane/pane', ip='127.0.01',
                 paneport=4242, ofport=6633, **kwags):
        Controller.__init__(self, name, command=pane_cmd,
                            cargs='-p %d %%d' % paneport, ip=ip,
                            port=ofport, **kwags)

    def start(self):
        Controller.start(self)
        sleep(1)
        

class PaneTopo(Topo):
    def __init__(self, **opts):
        super(PaneTopo, self).__init__(opts)

    # We want pane-nat to get 10.0.0.1 and panebrain to get 10.0.0.2
    def hosts(self):
        h = super(PaneTopo, self).hosts()
        if 'panebrain' in h:
            h.remove('panebrain')
            h.insert(0, 'panebrain')
        if 'pane-nat' in h:
            h.remove('pane-nat')
            h.insert(0, 'pane-nat')
        return h


def setup_nat(network):
    pane_nat = network.getNodeByName('pane-nat')
    # TODO(adf): in a more extreme setup, we could move eth0 and pane-nat into
    # their own namespace; this would mean that only the OpenFlow network
    # would have internet connectivity (not the control network, which is also
    # where the regular VM terminals hang out.
    #
    # Intf('eth0', pane_nat)
    # .... dhcp setup .... 

    print "Configuring NAT (iptables) ..."
    pane_nat.cmd('sysctl -w net.ipv4.ip_forward=1')
    pane_nat.cmd('iptables -F')
    pane_nat.cmd('iptables -Z')
    pane_nat.cmd('iptables -A FORWARD -o eth0 -i pane-nat-eth0 -s 10.0.0.0/24 '
              '-m conntrack --ctstate NEW -j ACCEPT')
    pane_nat.cmd('iptables -A FORWARD -m conntrack --ctstate '
                 'ESTABLISHED,RELATED -j ACCEPT')
    pane_nat.cmd('iptables -A POSTROUTING -t nat -j MASQUERADE')

    # Add default gateway for the regular hosts
    for host in network.hosts:
        if host.name != "pane-nat" and host.name != "panebrain":
            host.cmd('route add default gw pane-nat %s-eth0' % host.name)



def launch_network(network, host_cmd='/usr/sbin/sshd', host_cmd_opts='-D'):
    network.start()

    setup_nat(network)

    print
    print "*** Hosts are running sshd at the following addresses:"
    print
    for host in network.hosts:
        host.cmd(host_cmd + ' ' + host_cmd_opts + '&')
        print host.name, host.IP()

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


    print
    print "*** Shutting-down SSH daemons"
    print
    for host in network.hosts:
        host.cmd( 'kill %' + host_cmd )

    pane_nat = network.getNodeByName('pane-nat')
    pane_nat.cmd('iptables -F')
    pane_nat.cmd('iptables -Z')

    network.stop()


if __name__ == '__main__':
    num_hosts = 6
    # 10 Mbps bandwidth and 2 ms delay on each link
    linkopts = dict(bw=10, delay='2ms', loss=0, use_htb=True)

    lg.setLogLevel('info')

    # Create an empty network with one switch
    topo = PaneTopo()
    switch = topo.add_switch('s1')

    # Add gateway
    panenat = topo.add_host('pane-nat', inNamespace=False, cpu=0.02)
    topo.add_link(panenat, switch, **linkopts)

    # Add PANE controller
    panebrain = topo.add_host('panebrain', inNamespace=False, cpu=0.08)
    topo.add_link(panebrain, switch, **linkopts)

    # Add some regular hosts
    for h in irange(1, num_hosts):
        host = topo.add_host('host%s' % h, cpu=0.4/num_hosts)
        topo.add_link(host, switch, **linkopts)

    # Let's get going!
    network = Mininet(topo, controller=LocalPaneController,
                      link=TCLink, 
                      # host=CPULimitedHost, # TODO(adf) upgrade Ubuntu?
                      switch=OVSKernelSwitch, ipBase='10.0.0.0/24')
    launch_network(network)
