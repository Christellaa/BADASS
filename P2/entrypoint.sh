#!/bin/bash

# activate both eth0 and eth1
ip link set dev eth0 up # transport network for the VXLAN
ip link set dev eth1 up
# assign an IP address to eth0
ip addr add "${LOCAL_IP}/24" dev eth0

# create and activate the bridge (layer 2)
ip link add br0 type bridge
ip link set dev br0 up
# assign eth1 to the bridge: it will transport information to the VXLAN
ip link set dev eth1 master br0

# static = VXLAN tunnel to a determined recipient
# multicast = VXLAN tunnel using a multicast group
# create a VXLAN tunnel with a VNI (VXLAN Network Identifier) of 10 and activate it
if [ "${MODE}" = "static" ]; then
	# remote = IP address of the distant recipient of the tunnel
	# local = local IP address used for the tunnel
	ip link add vxlan10 type vxlan id 10 dev eth0 remote "${REMOTE_IP}" local "${LOCAL_IP}" dstport 4789 nolearning
	ip link set dev vxlan10 up
	# assign the VXLAN to the bridge
	# the bridge has two ports now: eth1 and vxlan10: it will transfer traffic between them
	ip link set vxlan10 master br0
	# in unicast mode, it indicates where to send Ethernet frames
	bridge fdb append 00:00:00:00:00:00 dev vxlan10 dst "${REMOTE_IP}" self permanent
elif [ "${MODE}" = "multicast" ]; then
	ip link add vxlan10 type vxlan id 10 dev eth0 group "${MULTICAST_GRP}" dstport 4789
	ip link set dev vxlan10 up
	ip link set vxlan10 master br0
else
	exit 1
fi

# launch the startup script of FRRouting
exec /usr/lib/frr/docker-start
