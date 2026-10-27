#!/bin/bash

# start FRRouting in background, so the routing services are available for the configuration
exec /usr/lib/frr/docker-start &
FRR_PID=$!

# wait for BGPD, OSPFD and ISISD to be activated
while true; do
	output=$(vtysh -c "show watchfrr" 2>/dev/null) || continue

	if grep -i 'bgpd.*up' <<< "$output" >/dev/null &&
	grep -i 'ospfd.*up' <<< "$output" >/dev/null &&
	grep -i 'isisd.*up' <<< "$output" >/dev/null; then
		break
	fi

	sleep 1
done

# configure the route reflector
# router bgp 1 = start configuring BGP of the Autonomous System number 1
# neighbor [...] = create BGP neighbors named ibgp, define remote AS at 1 for the neighbors using this group, and use the loopback interface as source address of BGP connections
# iBGP = internal BGP
# we use the loopback to not depend directly on a physical interface to establish the BGP session
# bgp listen [...] = RR listens to incoming BGP connections of a specific address prefix, and associate them to the iBGP group
# address[...] to exit-address[...] = activate EVPN comunication with neighbors from the iBGP group, and define these neighbors as clients from the RR
# router ospf [...] = take all IPv4 interfaces' addresses corresponding to the prefix /0 and assign them to the OSPF area 0 (area 0 = the backbone of OSPF)
if [ "$ROLE" = "rr" ]; then
	vtysh <<EOF
conf t
router bgp 1
 neighbor ibgp peer-group
 neighbor ibgp remote-as 1
 neighbor ibgp update-source lo
 bgp listen range 1.1.1.0/29 peer-group ibgp
 address-family l2vpn evpn
  neighbor ibgp activate
  neighbor ibgp route-reflector-client
 exit-address-family
exit
router ospf
 network 0.0.0.0/0 area 0
end
EOF

# create and activate the Ethernet bridge and the VXLAN interface, then link the VXLAN and the given ethernet to the bridge
# no addresses are given to the VXLAN because BGP EVPN does it
# interface lo [...] = assign the loopback interface to the OSPF area 0
# interface $RR_ETH [...] = activate OSPF on the given interface at the area 0
# router bgp 1 = configure BGP in the AS number 1
# neighbor [...] = declare the RR with address 1.1.1.1 is the BGP neighbor in this same AS, and use the leaf loopback as source address of its BGP session
# address-family[...] to exit-address[...] = activate EVPN communication with the RR, and advertise all local VNI VXLAN
elif [ "$ROLE" = "leaf" ]; then
	ip link add br0 type bridge
	ip link set dev br0 up

	ip link add vxlan10 type vxlan id 10 dstport 4789
	ip link set dev vxlan10 up
	ip link set vxlan10 master br0
	ip link set dev "$HOST_ETH" master br0

	vtysh <<EOF
conf t
interface lo
 ip ospf area 0.0.0.0
exit
interface $RR_ETH
 ip ospf area 0.0.0.0
exit
router bgp 1
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
exit
router ospf
end
EOF

else
	exit 1

fi

# maintain the script until the FRRouting process ends
wait "$FRR_PID"
