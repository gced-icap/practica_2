#!/bin/ash
set -eux

ip=$1
fqdn=$(hostname --fqdn)
domain=$(hostname --domain)
dn=$(hostname)

# update packages index
apk update

# configure the shell
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

##
## setup NAT
##

# install iptables
apk add iptables
rc-update add iptables 

# enable IPv4 forwarding
sysctl net.ipv4.ip_forward=1
sed -i -E 's,^\s*#?\s*(net.ipv4.ip_forward=).+,\11,g' /etc/sysctl.conf

# NAT through eth0
iptables -t nat -A POSTROUTING -s "$ip/24" ! -d "$ip/24" -o eth0 -j MASQUERADE

# save iptables rules to be load on boot
/etc/init.d/iptables save

##

# configure hosts
cat >/etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost
$ip $fqdn $dn
EOF

#
# provision the NFS server
# see exports(5)

apk add nfs-utils

install -d -o nobody -g nogroup -m 700 /srv/nfs/shared01
install -d -o nobody -g nogroup -m 700 /srv/nfs/shared02
install -d -m 700 /etc/exports.d

echo "/srv/nfs/shared01 $ip/24(fsid=1,rw,no_subtree_check)" >/etc/exports.d/shared01.exports
echo "/srv/nfs/shared02 $ip/24(fsid=2,rw,no_subtree_check)" >/etc/exports.d/shared02.exports
exportfs -a

rc-service nfs start
rc-update add nfs

showmount -e $ip

# test access to the NFS server using NFSv3 and NFSv4 (TCP).
cat >/etc/rpc <<EOF
nfs             100003  nfsprog
EOF

rpcinfo -t $ip nfs 3
rpcinfo -t $ip nfs 4
