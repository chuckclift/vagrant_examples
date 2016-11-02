#!/bin/sh

PUBLIC=enp0s8
LAN1=enp0s3
LAN2=enp0s9

CLIENT=10.0.1.2
SERVER=10.0.0.2

iptables --flush

# allow host to receive traffic
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# allow client(10.0.1.2) to ssh to server (10.0.0.2)
iptables -t filter -I FORWARD 1 -p tcp -s $CLIENT -d $SERVER  --dport 22 -m conntrack --ctstate=NEW,ESTABLISHED  -j ACCEPT

# adding NATing for server and client
iptables -t nat -A POSTROUTING -o $PUBLIC -j MASQUERADE


# forward ICMP traffic
iptables -A FORWARD -i $PUBLIC -o $LAN1 -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN1 -o $PUBLIC -p icmp -j ACCEPT 

iptables -A FORWARD -i $PUBLIC -o $LAN2 -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN2 -o $PUBLIC -p icmp -j ACCEPT 

# forward DNS traffic
iptables -A FORWARD -i $PUBLIC -o $LAN1 -p udp  --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN1 -o $PUBLIC -p udp  --dport 53 -j ACCEPT 
                                                          
iptables -A FORWARD -i $PUBLIC -o $LAN2 -p udp  --sport 53 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $LAN2 -o $PUBLIC -p udp  --dport 53 -j ACCEPT 

# ssh port forwarding 
iptables -A PREROUTING -t nat -i $PUBLIC -p tcp --dport 3000 -j DNAT --to 10.0.0.2:22
iptables -A FORWARD -p tcp -i $PUBLIC -o $LAN1 -d 10.0.0.2 --dport 22 -j ACCEPT

iptables -A PREROUTING -t nat -i $PUBLIC -p tcp --dport 3001 -j DNAT --to $CLIENT:22
iptables -A FORWARD -p tcp -i $PUBLIC -o $LAN2 -d $CLIENT --dport 22 -j ACCEPT

# default drop
iptables -A FORWARD -j DROP
iptables -A INPUT -j DROP
