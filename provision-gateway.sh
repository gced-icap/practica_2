#!/bin/bash
set -eux

ip=$1
fqdn=$(hostname --fqdn)
domain=$(hostname --domain)
dn=$(hostname)

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# This is neccessary to avoid apt lock error
#echo '[INFO] Waiting for unattended upgrades to complete'
#while [ $(pgrep -cf "apt|dpkg|unattended") -gt 0 ]; do
#  sleep 0.5
#done
# update the package cache.
#apt-get update

# make sure the local apt cache is up to date.
while true; do
    apt-get update && break || sleep 5
done

# configure the shell.
cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=nano
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

#
# setup NAT.
# see https://help.ubuntu.com/community/IptablesHowTo

apt-get install -y iptables iptables-persistent

# enable IPv4 forwarding.
sysctl net.ipv4.ip_forward=1
sed -i -E 's,^\s*#?\s*(net.ipv4.ip_forward=).+,\11,g' /etc/sysctl.conf

# NAT through eth0.
iptables -t nat -A POSTROUTING -s "$ip/24" ! -d "$ip/24" -o eth0 -j MASQUERADE

# load iptables rules on boot.
iptables-save >/etc/iptables/rules.v4

cat >/etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost
$ip $fqdn $dn gateway
EOF

#
# provision the NFS server.
# see exports(5).

apt-get install -y nfs-kernel-server
install -d -o nobody -g nogroup -m 700 /srv/nfs/shared01
install -d -o nobody -g nogroup -m 700 /srv/nfs/shared02
install -d -m 700 /etc/exports.d
echo "/srv/nfs/shared01 $ip/24(fsid=0,rw,no_subtree_check)" >/etc/exports.d/shared01.exports
echo "/srv/nfs/shared02 $ip/24(fsid=0,rw,no_subtree_check)" >/etc/exports.d/shared02.exports
exportfs -a

# test access to the NFS server using NFSv3 (UDP and TCP) and NFSv4 (TCP).
showmount -e $ip
rpcinfo -u $ip nfs 3
rpcinfo -t $ip nfs 3
rpcinfo -t $ip nfs 4
