"Utility functions for PANE Demos."

# NAT setup inspired by netcore/examples/Gateway.py

from time import sleep

from mininet.node import Controller
from mininet.topo import Topo


class LocalPaneController(Controller):
    def __init__(self, name, pane_cmd='/home/paneuser/pane/pane', ip='127.0.01',
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


def setupPaneNAT(network):
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

def clearPaneNAT(network):
    pane_nat = network.getNodeByName('pane-nat')
    pane_nat.cmd('iptables -F')
    pane_nat.cmd('iptables -Z')


# addDictOption shamelessly stolen from Mininet. thanks Brandon!
def addDictOption( opts, choicesDict, default, name, helpStr=None ):
    """Convenience function to add choices dicts to OptionParser.
       opts: OptionParser instance
       choicesDict: dictionary of valid choices, must include default
       default: default choice key
       name: long option name
       help: string"""
    if default not in choicesDict:
        raise Exception( 'Invalid  default %s for choices dict: %s' %
                        ( default, name ) )
    if not helpStr:
        helpStr = ( '|'.join( sorted( choicesDict.keys() ) ) +
                   '[,param=value...]' )
    opts.add_option( '--' + name,
                    type='string',
                    default = default,
                    help = helpStr )
