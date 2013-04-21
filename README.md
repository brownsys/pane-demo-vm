Welcome to the PANE Demo
========================================================

This VM is configured to with example programs and demos to illustrate the
promise of Participatory Networking.

To get started:

1. Try out some scripts in the demos directory. For example:
    * `sudo demos/PaneDemo.py` launches a simple network with a PANE controller.
    * `sudo demos/ZooKeeperDemo.py` launches a PANE-enabled ZooKeeper ensemble.
These will silently launch a PANE controller within the demo.

2. To run PANE separately: `./pane/pane -c etc/pane.cfg -p 4242` and start
   demos with `--controller=remote`.

Both PANE and the demos display help with a `--help` option.
